#!/usr/bin/env bash
#
# Traceability auditor.
# Checks that requirement slugs are defined, indexed, and cross-referenced correctly.
# Also scans for inline `Implements:` markers in code and reconciles against product
# slugs, Code Map rows in engineering specs, and the `Code` column of index.md.
#
# Exit codes:
#   0 — all checks pass (or all failures suppressed by PDEQ_ALLOW_DRIFT=1)
#   1 — one or more issues found
#
# Flags:
#   --check    Strict mode (CI): do not rewrite index.md; fail on Code-column drift.
#
# Env:
#   PDEQ_CONFIG_PATH                    Path to pdeq.json. Default: <repo>/pdeq.json
#   PDEQ_ALLOW_DRIFT=1                  Demote all blocks to warnings; rewrite index regardless.
#   PDEQ_CODE_MAPPING_GRACE=<int>       Grace period for uncovered FRs (default: 5).
#   PDEQ_CODE_MAPPING_SKIP_INDEX_REWRITE=1  Short-circuit phase 9 entirely.
#   PDEQ_FORCE_GREP=1                   Force the grep marker-scan fallback even
#                                       when ripgrep is present (test seam).
#
# Can be run standalone (./scripts/audit-traceability.sh) or as a git pre-commit hook.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
INDEX="$ROOT/index.md"
PRODUCT_DIR="$ROOT/product"
DESIGN_DIR="$ROOT/design"
ENGINEERING_DIR="$ROOT/engineering"
QA_DIR="$ROOT/qa"

PDEQ_CONFIG_PATH="${PDEQ_CONFIG_PATH:-$ROOT/pdeq.json}"
PDEQ_ALLOW_DRIFT="${PDEQ_ALLOW_DRIFT:-}"
PDEQ_CODE_MAPPING_GRACE="${PDEQ_CODE_MAPPING_GRACE:-5}"
PDEQ_CODE_MAPPING_SKIP_INDEX_REWRITE="${PDEQ_CODE_MAPPING_SKIP_INDEX_REWRITE:-}"

CHECK_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_MODE=1; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

errors=()
warnings=()
suppressed=()

# errf and warnf: "f" for "failure-class/warning with optional override demotion."
errf() {
  if [ -n "$PDEQ_ALLOW_DRIFT" ]; then
    suppressed+=("$1")
    echo "  ⚠  (suppressed by PDEQ_ALLOW_DRIFT) $1"
  else
    errors+=("$1")
    echo "  ✗  $1"
  fi
}
warnf() {
  warnings+=("$1")
  echo "  ⚠  $1"
}

# ─── Existing slug-set helpers ───────────────────────────────────────────────

# Implements: FR-code-mapping-audit-validates-slug
collect_defined_slugs() {
  local dir="$1"
  if [ ! -d "$dir" ]; then return; fi
  find "$dir" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" -print0 2>/dev/null \
    | xargs -0 grep -hoE '`(FR-[a-z0-9-]+|NFR-[a-z0-9-]+|AC-[a-z0-9-]+)`' 2>/dev/null \
    | tr -d '`' | sort -u || true
}

collect_referenced_slugs() {
  local dir="$1"
  if [ ! -d "$dir" ]; then return; fi
  # Filter out the `FR-ex-*` / `NFR-ex-*` / `AC-ex-*` / `TC-ex-*` example-slug
  # convention — these are placeholders used in fixture descriptions, prose
  # examples, or rename-example sections. Documented in root AGENTS.md.
  find "$dir" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" -print0 2>/dev/null \
    | xargs -0 grep -hoE '`(FR-[a-z0-9-]+|NFR-[a-z0-9-]+|AC-[a-z0-9-]+|TC-[a-z0-9-]+)`' 2>/dev/null \
    | tr -d '`' \
    | grep -vE '^(FR|NFR|AC|TC)-ex-' \
    | sort -u || true
}

collect_indexed_slugs() {
  if [ ! -f "$INDEX" ]; then return; fi
  grep -oE '(FR-[a-z0-9-]+|NFR-[a-z0-9-]+|AC-[a-z0-9-]+|TC-[a-z0-9-]+)' "$INDEX" 2>/dev/null \
    | sort -u || true
}

collect_indexed_paths() {
  if [ ! -f "$INDEX" ]; then return; fi
  grep -oE '(product|design|engineering|qa)/[^ ,|]+\.md' "$INDEX" 2>/dev/null \
    | sort -u || true
}

# ─── pdeq.json parsing (no jq dependency) ────────────────────────────────────

# Returns "true" or "false". Implements: FR-code-mapping-audit-scan
read_selfhost() {
  if [ ! -f "$PDEQ_CONFIG_PATH" ]; then
    echo "false"
    return
  fi
  if grep -qE '"selfHost"[[:space:]]*:[[:space:]]*true' "$PDEQ_CONFIG_PATH" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# Returns space-separated list of extra exclude globs.
read_exclude_patterns() {
  if [ ! -f "$PDEQ_CONFIG_PATH" ]; then return; fi
  # Extract the codeMappingExclude array body, then pick out quoted strings.
  python3 -c "
import json, sys
try:
    with open('$PDEQ_CONFIG_PATH') as f:
        data = json.load(f)
    pats = data.get('codeMappingExclude') or []
    print(' '.join(pats))
except Exception:
    pass
" 2>/dev/null || true
}

# ─── Marker scanner ──────────────────────────────────────────────────────────

SELF_HOST=$(read_selfhost)
EXTRA_EXCLUDES=$(read_exclude_patterns)

# Default exclusions. .pdeq/ only excluded when not in self-host mode.
# Implements: FR-code-mapping-audit-scan
build_exclude_args_rg() {
  local args=()
  local excludes=(
    "!.git/**" "!node_modules/**" "!vendor/**" "!dist/**" "!build/**"
    "!target/**" "!.venv/**" "!__pycache__/**"
    "!*.lock" "!*.min.js" "!*.map"
  )
  if [ "$SELF_HOST" != "true" ]; then
    excludes+=("!.pdeq/**")
  fi
  for pat in "${excludes[@]}"; do
    args+=(--glob "$pat")
  done
  for pat in $EXTRA_EXCLUDES; do
    args+=(--glob "!$pat")
  done
  printf '%s\n' "${args[@]}"
}

build_exclude_args_grep() {
  local args=()
  local dirs=(".git" "node_modules" "vendor" "dist" "build" "target" ".venv" "__pycache__")
  if [ "$SELF_HOST" != "true" ]; then
    dirs+=(".pdeq")
  fi
  for d in "${dirs[@]}"; do
    args+=(--exclude-dir="$d")
  done
  args+=(--exclude="*.lock" --exclude="*.min.js" --exclude="*.map")
  printf '%s\n' "${args[@]}"
}

# Core scan regex. Matches any marker form across supported file kinds.
# Word-boundary lookahead `(?![a-z0-9-])` prevents FR-auth matching inside FR-auth-login.
# Implements: NFR-code-mapping-precision
MARKER_REGEX='^.*(//|#|--|<!--|/\*)[[:space:]]*Implements:[[:space:]]*(FR|NFR|AC)-[a-z0-9-]+(?![a-z0-9-])([[:space:]]*,[[:space:]]*(FR|NFR|AC)-[a-z0-9-]+(?![a-z0-9-]))*([[:space:]]*-->|[[:space:]]*\*/)?[[:space:]]*$'

# Emits tab-separated "slug\tfile\tline" tuples on stdout, sorted by file path.
# Implements: FR-code-mapping-audit-scan, FR-code-mapping-marker-presence
scan_markers() {
  local hits_file
  hits_file=$(mktemp)
  trap "rm -f '$hits_file'" RETURN

  if command -v rg >/dev/null 2>&1 && [ -z "${PDEQ_FORCE_GREP:-}" ]; then
    local rg_args=()
    while IFS= read -r a; do rg_args+=("$a"); done < <(build_exclude_args_rg)
    rg --pcre2 --hidden --with-filename --line-number --no-heading --sort path \
       "${rg_args[@]}" "$MARKER_REGEX" "$ROOT" 2>/dev/null > "$hits_file" || true
  else
    # scan_markers writes its marker TSV to stdout (captured by the caller), so
    # this diagnostic MUST go to stderr — otherwise the warning line is parsed as
    # a marker row (empty file/line) and reported as a bogus "orphan marker at ::".
    # (grep -P requires GNU grep; on a BSD-grep host with no rg the fallback finds
    # nothing rather than erroring — install ripgrep for full coverage there.)
    warnf "ripgrep not found; using grep fallback — audit may be slower than 2s target" >&2
    local grep_args=()
    while IFS= read -r a; do grep_args+=("$a"); done < <(build_exclude_args_grep)
    grep -rnP "${grep_args[@]}" "$MARKER_REGEX" "$ROOT" 2>/dev/null \
      | sort -t: -k1,1 > "$hits_file" || true
  fi

  # Each hit is "file:line:content" (rg) or "file:line:content" (grep).
  # Enforce per-extension syntax rule, then emit each cited slug as its own row.
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local file line content ext open_token
    file="${hit%%:*}"
    rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    ext="${file##*.}"

    # Which comment-open token does this file kind allow?
    case "$ext" in
      ts|tsx|js|jsx|mjs|cjs|go|swift|java|kt|c|cc|cpp|h|hpp|rs|scala|dart)
        open_token='//' ;;
      sh|bash|zsh|py|rb|pl|yaml|yml|toml)
        open_token='#' ;;
      sql)
        open_token='--' ;;
      md|html|xml|svg)
        open_token='<!--' ;;
      css|scss)
        open_token='/*' ;;
      *)
        continue ;;  # Unknown extension — skip (ignored by scan).
    esac

    # Verify the actual marker open-token matches the file-kind rule.
    # (The unified regex matches any kind; the per-file filter enforces correctness.)
    if [[ "$open_token" == '<!--' ]]; then
      if ! grep -qE '<!--[[:space:]]*Implements:.*-->[[:space:]]*$' <<<"$content"; then
        continue
      fi
    elif [[ "$open_token" == '/*' ]]; then
      if ! grep -qE '/\*[[:space:]]*Implements:.*\*/[[:space:]]*$' <<<"$content"; then
        continue
      fi
    else
      # Line-comment kinds: require the kind's open token to literally precede `Implements:`.
      if ! grep -qE "${open_token}[[:space:]]*Implements:" <<<"$content"; then
        continue
      fi
    fi

    # Extract each slug cited on this line.
    local slugs
    slugs=$(echo "$content" | grep -oE '(FR|NFR|AC)-[a-z0-9-]+' || true)
    while IFS= read -r slug; do
      [ -z "$slug" ] && continue
      # Normalize file path relative to ROOT for deterministic output.
      local relfile="${file#$ROOT/}"
      printf '%s\t%s\t%s\n' "$slug" "$relfile" "$line"
    done <<< "$slugs"
  done < "$hits_file" | sort -u
}

# ─── Code Map parser ─────────────────────────────────────────────────────────

# Emits "slug\tpath\tstatus" tuples for the Code Map in a given engineering spec.
# Implements: FR-code-mapping-planned-paths, FR-code-mapping-planned-paths-living
parse_code_map() {
  local spec="$1"
  [ -f "$spec" ] || return 0
  CODE_MAP_SPEC="$spec" python3 << 'PY'
import os, re, sys, pathlib
path = pathlib.Path(os.environ["CODE_MAP_SPEC"])
text = path.read_text()
m = re.search(r'^## +Code Map\s*$', text, flags=re.MULTILINE)
if not m:
    sys.exit(0)
start = m.end()
rest = text[start:]
next_h = re.search(r'^#{1,2} ', rest, flags=re.MULTILINE)
section = rest if not next_h else rest[:next_h.start()]
for line in section.splitlines():
    line = line.strip()
    if not line.startswith('|'):
        continue
    if re.match(r'\|[-: ]+\|', line):
        continue
    cells = [c.strip() for c in line.strip('|').split('|')]
    if len(cells) != 3:
        continue
    slug, loc, status = cells
    if slug.lower() == 'slug':
        continue
    slug = slug.strip().strip('"').strip("'")
    # Strip backticks if present (Markdown table cells sometimes wrap slug in `...`).
    slug = slug.replace('`', '').strip()
    if not re.match(r'^(FR|NFR|AC)-[a-z0-9-]+$', slug):
        continue
    print(f"{slug}\t{loc}\t{status}")
PY
}

# ─── Coverage + grace period ─────────────────────────────────────────────────

# Returns integer: number of commits modifying the product spec file since the
# slug's introductory commit. Implements: FR-code-mapping-audit-coverage-grace
grace_delta() {
  local slug="$1"
  local product_spec="$2"
  [ -f "$product_spec" ] || { echo 0; return; }

  local intro
  intro=$(cd "$ROOT" && git log --diff-filter=A --format=%H -S"$slug" -- "${product_spec#$ROOT/}" 2>/dev/null | head -n 1 || true)
  if [ -z "$intro" ]; then
    # Slug may have been added in an unstaged/unommitted change, or shallow clone cut history.
    # Check whether product spec has shallow-clone marker.
    if [ -f "$ROOT/.git/shallow" ]; then
      warnf "shallow clone detected — grace period not enforced for $slug"
    fi
    echo 0
    return
  fi
  local delta
  delta=$(cd "$ROOT" && git rev-list --count "$intro..HEAD" -- "${product_spec#$ROOT/}" 2>/dev/null || echo 0)
  echo "$delta"
}

# ─── Index Code column rewrite ───────────────────────────────────────────────

# Rewrites index.md's Code column from the given markers TSV.
# Writes to stdout; caller handles mv into place.
# Implements: FR-code-mapping-index-code-locations, FR-code-mapping-index-populated
rewrite_index_code_column() {
  local markers_tsv="$1"
  INDEX_PATH="$INDEX" MARKERS_TSV="$markers_tsv" python3 << 'PY'
import os, re, pathlib, collections
idx = pathlib.Path(os.environ["INDEX_PATH"])
markers = collections.defaultdict(list)
with open(os.environ["MARKERS_TSV"]) as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 3: continue
        slug, path, lineno = parts
        markers[slug].append(f"{path}:{lineno}")

text = idx.read_text()
lines = text.split("\n")
out = []
header_seen = False
for line in lines:
    # Detect header row with Slug|Type|Defined In|Referenced In (optionally + Code)
    if line.startswith("| Slug |"):
        if "| Code |" not in line:
            # Insert Code column before closing pipe
            line = line.rstrip("|").rstrip() + " | Code |"
        header_seen = True
        out.append(line)
        continue
    if line.startswith("|------|") or line.startswith("|---"):
        # Table separator: ensure exactly 5 column segments
        # (Slug|Type|Defined In|Referenced In|Code). Idempotent — appends only
        # the missing trailing segments. The earlier version stripped the
        # closing pipe before appending one back, so the column count never grew
        # and every run fattened the last cell by six dashes (non-convergent,
        # violating NFR-code-mapping-determinism).
        sep = line.rstrip()
        cols = sep.count("|") - 1
        while cols < 5:
            sep += "------|"
            cols += 1
        out.append(sep)
        continue
    # Data row?
    if line.startswith("| ") and line.count("|") >= 5:
        cells = [c for c in line.strip().strip("|").split("|")]
        cells = [c.strip() for c in cells]
        # Existing rows may have 4 cells (no Code column yet) or 5 (already has Code).
        if len(cells) == 4:
            cells.append("")  # New empty Code cell
        elif len(cells) != 5:
            out.append(line)
            continue
        slug = cells[0].strip()
        if re.match(r'^(FR|NFR|AC|TC)-[a-z0-9-]+$', slug):
            locs = markers.get(slug, [])
            cells[4] = ", ".join(sorted(locs))
        out.append("| " + " | ".join(cells) + " |")
        continue
    out.append(line)
idx.write_text("\n".join(out))
PY
}

# ─── QA Coverage Matrix status integrity ─────────────────────────────────────

# Collect TC- slugs cited in source/test code. A TC slug in a code file is
# evidence that an automated test references it; TC slugs in .md specs are plan
# citations, not test evidence, so spec markdown is filtered out by extension.
# Emits unique sorted TC- slugs on stdout.
collect_tc_in_code() {
  # rg --with-filename --no-line-number -o emits `path:match`, so the code
  # extension is followed by a colon, not end-of-line. Match `.ext:` to keep
  # only code files (drops .md spec citations). The match (last field) has no
  # colon, so awk -F: '{print $NF}' extracts it cleanly.
  local code_ext_re='\.(swift|ts|tsx|js|jsx|mjs|cjs|go|java|kt|c|cc|cpp|h|hpp|rs|scala|dart|sh|bash|zsh|py|rb|pl|sql):'
  if command -v rg >/dev/null 2>&1; then
    local rg_args=()
    while IFS= read -r a; do rg_args+=("$a"); done < <(build_exclude_args_rg)
    rg --pcre2 --hidden --with-filename --no-line-number --no-heading \
       "${rg_args[@]}" -o 'TC-[a-z0-9-]+' "$ROOT" 2>/dev/null \
       | grep -E "$code_ext_re" | awk -F: '{print $NF}' | sort -u || true
  else
    local grep_args=() ext
    local code_exts=(swift ts tsx js jsx mjs cjs go java kt c cc cpp h hpp rs scala dart sh bash zsh py rb pl sql)
    while IFS= read -r a; do grep_args+=("$a"); done < <(build_exclude_args_grep)
    for ext in "${code_exts[@]}"; do grep_args+=("--include=*.$ext"); done
    grep -rhoP "${grep_args[@]}" 'TC-[a-z0-9-]+' "$ROOT" 2>/dev/null | sort -u || true
  fi
}

# Emits "status\ttc_csv" rows for each Coverage Matrix row that cites >=1 TC slug.
# Rows without TC slugs (e.g. structural coverage described in prose) are skipped.
parse_qa_matrix() {
  local spec="$1"
  [ -f "$spec" ] || return 0
  QA_MATRIX_SPEC="$spec" python3 << 'PY'
import os, re, pathlib, sys
path = pathlib.Path(os.environ["QA_MATRIX_SPEC"])
text = path.read_text()
m = re.search(r'^##\s+Coverage Matrix\s*$', text, flags=re.MULTILINE)
if not m:
    sys.exit(0)
start = m.end()
rest = text[start:]
next_h = re.search(r'^#{1,2} ', rest, flags=re.MULTILINE)
section = rest if not next_h else rest[:next_h.start()]
for line in section.splitlines():
    s = line.strip()
    if not s.startswith('|'):
        continue
    if re.match(r'\|[-: ]+\|', s):
        continue
    cells = [c.strip() for c in s.strip('|').split('|')]
    if len(cells) < 3:
        continue
    status = cells[-1]
    tcs = re.findall(r'TC-[a-z0-9-]+', ' '.join(cells[:-1]))
    if not tcs:
        continue
    seen = set(); uniq = []
    for t in tcs:
        if t not in seen: seen.add(t); uniq.append(t)
    print(f"{status}\t{','.join(uniq)}")
PY
}

# True if $1 has a "Test Execution Results" section that names the TC slug $2 and
# records a status line matching $3 (Pass/Fail). Per-TC (not per-file) so a collective
# execution record cannot evidence a TC it never named.
qa_file_has_manual_status() {
  local file="$1" tc="$2" want="$3"
  [ -f "$file" ] || return 1
  QA_ER_FILE="$file" QA_ER_TC="$tc" QA_ER_WANT="$want" python3 << 'PY'
import os, re, pathlib, sys
text = pathlib.Path(os.environ["QA_ER_FILE"]).read_text()
tc = os.environ["QA_ER_TC"]; want = os.environ["QA_ER_WANT"]
lines = text.split("\n"); n = len(lines); i = 0
def is_heading(l): return re.match(r'^#{1,6}\s', l) is not None
while i < n:
    if re.match(r'^#{3,4}\s+Test Execution Results', lines[i]):
        j = i + 1; body = []
        while j < n and not is_heading(lines[j]):
            body.append(lines[j]); j += 1
        sect = "\n".join(body)
        has_tc = tc in sect
        has_status = re.search(r'(\*\*)?Status(\*\*)?:\s*' + re.escape(want), sect, re.IGNORECASE) is not None
        if has_tc and has_status:
            sys.exit(0)
        i = j; continue
    i += 1
sys.exit(1)
PY
}

# Implements: FR-code-mapping-audit-qa-status-evidence
# Reject a QA Coverage Matrix row marked Pass with no evidence (no TC slug cited
# in code and no manual Test Execution Results record), and a row marked Fail
# with no manual execution record. Rows without TC slugs are not auto-verifiable.
check_qa_status_integrity() {
  [ -d "$QA_DIR" ] || return 0
  local tc_in_code
  tc_in_code=$(collect_tc_in_code)
  while IFS= read -r -d '' spec; do
    local relspec="${spec#$ROOT/}"
    while IFS=$'\t' read -r status tc_csv; do
      [ -z "$status" ] && continue
      case "$status" in
        *[Pp]ass*|PASS)
          local evidenced=0 tc
          IFS=',' read -ra tcs <<< "$tc_csv"
          for tc in "${tcs[@]}"; do
            if grep -qx "$tc" <<<"$tc_in_code" || qa_file_has_manual_status "$spec" "$tc" "Pass"; then evidenced=1; break; fi
          done
          if [ "$evidenced" -eq 0 ]; then
            errf "$relspec Coverage Matrix marks [$tc_csv] as Pass but no test code cites any of its TC slugs and no Test Execution Results record names them"
          fi
          ;;
        *[Ff]ail*|FAIL)
          local tc evidenced=0
          IFS=',' read -ra tcs <<< "$tc_csv"
          for tc in "${tcs[@]}"; do
            if qa_file_has_manual_status "$spec" "$tc" "Fail"; then evidenced=1; break; fi
          done
          if [ "$evidenced" -eq 0 ]; then
            errf "$relspec Coverage Matrix marks [$tc_csv] as Fail but no Test Execution Results record names them"
          fi
          ;;
        *[Ss]kip*)
          ;;  # Intentionally not run in this environment — no evidence required.
        "Not started"|"In progress"|Pending|Blocked|planned|""|"—")
          ;;  # No evidence required for non-terminal statuses.
        *)
          warnf "$relspec Coverage Matrix has unrecognized status '$status' for [$tc_csv]"
          ;;
      esac
    done < <(parse_qa_matrix "$spec")
  done < <(find "$QA_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" -print0 2>/dev/null)
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo "Auditing traceability..."
echo ""

if [ ! -f "$INDEX" ]; then
  errf "index.md not found at project root"
  echo ""
  echo "Found ${#errors[@]} issue(s)."
  exit 1
fi

# Phases 1–4: existing traceability checks (slug definition, references, paths)

defined_slugs=$(collect_defined_slugs "$PRODUCT_DIR")
indexed_slugs=$(collect_indexed_slugs)

design_refs=$(collect_referenced_slugs "$DESIGN_DIR")
engineering_refs=$(collect_referenced_slugs "$ENGINEERING_DIR")
qa_refs=$(collect_referenced_slugs "$QA_DIR")

all_downstream_refs=$(printf '%s\n%s\n%s\n' "$design_refs" "$engineering_refs" "$qa_refs" | grep -v '^$' | sort -u || true)

if [ -n "$defined_slugs" ]; then
  echo "[1/9] Defined slugs present in index..."
  while IFS= read -r slug; do
    if ! echo "$indexed_slugs" | grep -qx "$slug"; then
      errf "$slug defined in product/ but missing from index.md"
    fi
  done <<< "$defined_slugs"
  echo ""
fi

if [ -n "$all_downstream_refs" ]; then
  echo "[2/9] Downstream references have definitions..."
  while IFS= read -r slug; do
    if [[ "$slug" == TC-* ]]; then continue; fi
    if [ -n "$defined_slugs" ] && echo "$defined_slugs" | grep -qx "$slug"; then
      continue
    fi
    errf "$slug referenced downstream but not defined in product/"
  done <<< "$all_downstream_refs"
  echo ""
fi

if [ -n "$all_downstream_refs" ]; then
  echo "[3/9] Downstream references present in index..."
  while IFS= read -r slug; do
    if [[ "$slug" == TC-* ]]; then continue; fi
    if [ -n "$indexed_slugs" ] && echo "$indexed_slugs" | grep -qx "$slug"; then
      continue
    fi
    errf "$slug referenced downstream but missing from index.md"
  done <<< "$all_downstream_refs"
  echo ""
fi

echo "[4/9] Index file paths exist..."
indexed_paths=$(collect_indexed_paths)
if [ -n "$indexed_paths" ]; then
  while IFS= read -r filepath; do
    if [ ! -f "$ROOT/$filepath" ]; then
      errf "index.md references $filepath but file does not exist"
    fi
  done <<< "$indexed_paths"
fi
echo ""

# ─── Phase 5: Marker scan + orphan/retirement reconciliation ─────────────────

echo "[5/9] Marker scan + slug validation..."
markers_tsv=$(mktemp)
trap "rm -f '$markers_tsv'" EXIT
scan_markers > "$markers_tsv" || true

# Phase 5 + 6 combined: any marker citing a slug not in $defined_slugs is orphan/retired.
# Implements: FR-code-mapping-audit-validates-slug, FR-code-mapping-marker-retirement-blocks
while IFS=$'\t' read -r slug file line; do
  [ -z "$slug" ] && continue
  if ! echo "$defined_slugs" | grep -qx "$slug"; then
    errf "orphan marker at $file:$line: $slug not defined in any current product spec"
  fi
done < "$markers_tsv"
echo ""

# ─── Phase 5b: Scope rule (warn only) ───────────────────────────────────────

echo "[5b/9] Marker scope check..."
# Implements: FR-code-mapping-marker-scope, AC-code-mapping-marker-scope-enforced
# A marker is flagged iff the file has at least one named-unit declaration AND
# the marker is more than one line above the first such declaration. A marker
# at or below `first_decl_line`, or exactly on `first_decl_line - 1`, is
# correctly scoped (sits inside or immediately above an implementing unit) and
# is NOT flagged regardless of its absolute line number. This eliminates the
# false-positive class where a marker on, e.g., line 3 of a short component
# whose function declaration begins on line 1 was warned on by the prior
# `line <= 5` heuristic. See engineering/cli/code-mapping.md §Scope rule.
DECL_REGEX='^(export[[:space:]]+)?(function[[:space:]]+|async[[:space:]]+function|def[[:space:]]+|func[[:space:]]+|class[[:space:]]+)|^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\('
while IFS=$'\t' read -r slug file line; do
  [ -z "$slug" ] && continue
  case "${file##*.}" in
    md|html|xml|svg|yaml|yml|toml) continue ;;  # No function concept.
  esac
  # `|| true` because set -e + pipefail abort the script when grep finds no
  # match (exit 1). Empty `first_decl_line` is the documented "no declaration"
  # branch — handled below.
  first_decl_line=$(grep -nE "$DECL_REGEX" "$ROOT/$file" 2>/dev/null | head -n 1 | cut -d: -f1 || true)
  # No declaration in the file → scope rule does not apply (top-level-only file).
  [ -z "$first_decl_line" ] && continue
  # Warn iff marker is more than one line above the first declaration.
  if [ "$((line + 1))" -lt "$first_decl_line" ]; then
    warnf "marker above first named unit at $file:$line (first declaration at line $first_decl_line) — move inside or immediately above the implementing unit"
  fi
done < "$markers_tsv"
echo ""

# ─── Phase 7: Code Map validation ───────────────────────────────────────────

echo "[7/9] Code Map validation..."
# Exempt slugs from phase 8 coverage.
unimplemented_slugs_file=$(mktemp)
trap "rm -f '$markers_tsv' '$unimplemented_slugs_file'" EXIT

if [ -d "$ENGINEERING_DIR" ]; then
  while IFS= read -r -d '' spec; do
    while IFS=$'\t' read -r slug loc status; do
      [ -z "$slug" ] && continue
      case "$status" in
        unimplemented)
          echo "$slug" >> "$unimplemented_slugs_file"
          ;;
        implemented)
          # Validate every location exists AND has a marker citing the slug.
          if [ "$loc" != "—" ] && [ -n "$loc" ]; then
            IFS=';' read -ra locs <<< "$loc"
            for one in "${locs[@]}"; do
              one="${one## }"; one="${one%% }"
              # Strip ":line" or ":function_name" suffix (anything after first colon).
              filepart="${one%%:*}"
              if [ -n "$filepart" ] && [ ! -f "$ROOT/$filepart" ]; then
                errf "${spec#$ROOT/} Code Map lists $slug as implemented at $filepart but file does not exist"
              fi
            done
            if ! grep -qE "^${slug}\s" "$markers_tsv" 2>/dev/null; then
              errf "${spec#$ROOT/} Code Map lists $slug as implemented but no marker cites it in the code"
            fi
          fi
          ;;
        planned)
          # Planned: location is aspirational — file may not exist yet. Skip validation.
          ;;
      esac
    done < <(parse_code_map "$spec")
  done < <(find "$ENGINEERING_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" -print0 2>/dev/null)
fi
sort -u "$unimplemented_slugs_file" -o "$unimplemented_slugs_file" 2>/dev/null || true
echo ""

# ─── Phase 7b: QA Coverage Matrix status integrity ──────────────────────────

echo "[7b/9] QA Coverage Matrix status integrity..."
check_qa_status_integrity
echo ""

# ─── Phase 8: Coverage + grace period ────────────────────────────────────────

echo "[8/9] Coverage + grace period..."
# Implements: FR-code-mapping-audit-coverage, FR-code-mapping-audit-coverage-blocks,
# FR-code-mapping-audit-coverage-grace
if [ -n "$defined_slugs" ]; then
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    [[ "$slug" != FR-* ]] && continue  # Coverage rule applies only to FRs.
    # Skip if acknowledged unimplemented.
    if grep -qx "$slug" "$unimplemented_slugs_file" 2>/dev/null; then
      continue
    fi
    # Has marker?
    if grep -qE "^${slug}\s" "$markers_tsv" 2>/dev/null; then
      continue
    fi
    # Uncovered. Compute grace delta.
    # Find the product spec file that defines this slug.
    product_spec=$(grep -lP "\`${slug}\`" "$PRODUCT_DIR"/*.md 2>/dev/null | head -n 1 || true)
    if [ -z "$product_spec" ]; then
      continue  # Shouldn't happen — defined_slugs came from product/
    fi
    delta=$(grace_delta "$slug" "$product_spec")
    if [ "$delta" -lt "$PDEQ_CODE_MAPPING_GRACE" ]; then
      warnf "$slug defined but has no marker (grace: $delta/$PDEQ_CODE_MAPPING_GRACE commits)"
    else
      errf "$slug defined but has no marker (grace expired at $delta/$PDEQ_CODE_MAPPING_GRACE)"
    fi
  done <<< "$defined_slugs"
fi
echo ""

# ─── Phase 9: Index Code column rewrite ─────────────────────────────────────

if [ -n "$PDEQ_CODE_MAPPING_SKIP_INDEX_REWRITE" ]; then
  echo "[9/9] Index Code column rewrite — skipped (PDEQ_CODE_MAPPING_SKIP_INDEX_REWRITE=1)"
  echo ""
else
  echo "[9/9] Index Code column rewrite..."
  if [ "$CHECK_MODE" -eq 1 ]; then
    # Strict mode: rewrite into a tmpfile, diff, fail if changed.
    tmpidx=$(mktemp)
    cp "$INDEX" "$tmpidx"
    INDEX_BACKUP="$INDEX"
    INDEX="$tmpidx"
    rewrite_index_code_column "$markers_tsv"
    if ! diff -q "$INDEX_BACKUP" "$tmpidx" >/dev/null 2>&1; then
      errf "index.md Code column out of date — run ./scripts/audit-traceability.sh locally and commit the result"
    fi
    INDEX="$INDEX_BACKUP"
    rm -f "$tmpidx"
  else
    # Default mode: refresh the working-tree index.md in place so it reflects
    # current markers. The developer reviews and commits the result.
    before=$(cat "$INDEX")
    rewrite_index_code_column "$markers_tsv"
    after=$(cat "$INDEX")
    if [ "$before" != "$after" ]; then
      echo "  ⓘ index.md Code column updated"
      # Pre-commit hook context (GIT_INDEX_FILE set): stage ONLY the rewrite,
      # applied to the *staged* version of index.md, so unrelated unstaged edits
      # to the working-tree file are never swept into the commit.
      # The whole working-tree file is never `git add`-ed.
      # Implements: FR-code-mapping-index-populated
      if [ -n "${GIT_INDEX_FILE:-}" ]; then
        rel="${INDEX#$ROOT/}"
        staged_idx=$(mktemp)
        if git -C "$ROOT" show ":$rel" > "$staged_idx" 2>/dev/null; then
          # Apply the same Code-column rewrite to the staged blob, then stage
          # just that blob via update-index (does not touch the working tree).
          INDEX_WT="$INDEX"; INDEX="$staged_idx"
          rewrite_index_code_column "$markers_tsv"
          INDEX="$INDEX_WT"
          blob=$(git -C "$ROOT" hash-object -w "$staged_idx" 2>/dev/null || true)
          if [ -n "$blob" ]; then
            git -C "$ROOT" update-index --cacheinfo 100644 "$blob" "$rel" 2>/dev/null || true
          fi
        else
          # index.md not in the index yet (brand-new file being added): there is
          # nothing unstaged to protect, so stage the working-tree file directly.
          git -C "$ROOT" add "$INDEX" 2>/dev/null || true
        fi
        rm -f "$staged_idx"
      fi
    fi
  fi
  echo ""
fi

# ─── Summary ─────────────────────────────────────────────────────────────────

if [ ${#warnings[@]} -gt 0 ]; then
  echo "ⓘ  ${#warnings[@]} warning(s) emitted."
fi

if [ ${#suppressed[@]} -gt 0 ]; then
  echo ""
  echo "PDEQ_ALLOW_DRIFT=1 active — suppressed ${#suppressed[@]} condition(s):"
  for s in "${suppressed[@]}"; do
    echo "  - $s"
  done
fi

if [ ${#errors[@]} -eq 0 ]; then
  echo "✓ All traceability checks passed."
  exit 0
else
  echo ""
  echo "✗ Found ${#errors[@]} traceability issue(s). Fix them before committing."
  echo "  Override for this commit: PDEQ_ALLOW_DRIFT=1 git commit ..."
  exit 1
fi
