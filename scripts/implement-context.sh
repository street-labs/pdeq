#!/usr/bin/env bash
#
# implement-context.sh — produce a single-pass context bundle for /pdeq-implement.
#
# Joins git spec-diff scope against the traceability index and emits one
# complete, deterministically-ordered bundle to stdout. The implementing agent
# reads it once and starts coding — zero context-gathering toolcalls.
#
# Usage:
#   ./scripts/implement-context.sh [--base main|HEAD|working|<ref>] [feature|slug]
#
# Flags:
#   --base <ref>   Base to diff spec tree against. Default: main (merge-base main HEAD).
#                  HEAD or working = uncommitted only. Any other value = explicit git ref.
#
# Arguments:
#   feature|slug   Fallback scope when the spec tree has no changes vs the base
#                  (the redo case). Resolves the in-scope spec set from the
#                  feature name or a slug's defining product spec.
#
# Exit codes:
#   0  success (including the nothing-to-implement case, which prints to stderr
#      and emits no bundle)
#   1  error (bad base ref, no main branch, no matching spec for a positional arg)
#
# Env:
#   PDEQ_CONFIG_PATH  Path to pdeq.json. Default: <repo>/pdeq.json
#
# The bundle is ephemeral: this script writes nothing to disk. stdout is the
# bundle; stderr carries human-readable diagnostics.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$SCRIPT_DIR")"
PDEQ_CONFIG_PATH="${PDEQ_CONFIG_PATH:-$ROOT/pdeq.json}"

# ponytail: single temp file for the slug set; cleaned on exit. No fixtures, no cache.
SLUGS_TMP="$(mktemp)"
trap 'rm -f "$SLUGS_TMP"' EXIT

# ─── specsRoot resolution (no jq dependency, matches seed-project-md.sh) ──────
read_specs_root() {
  local config="$PDEQ_CONFIG_PATH"
  if [ ! -f "$config" ]; then echo "."; return; fi
  local val
  val="$(sed -n 's/.*"specsRoot"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$config" | head -n 1)"
  if [ -n "$val" ]; then echo "$val"; else echo "."; return; fi
}

SPECS_ROOT_REL="$(read_specs_root)"
if [[ "$SPECS_ROOT_REL" == "." || "$SPECS_ROOT_REL" == "" ]]; then
  SPECS_ROOT="$ROOT"
else
  SPECS_ROOT="$ROOT/$SPECS_ROOT_REL"
fi

# Slug grammar — matches audit-traceability.sh. Includes TC (QA specs in scope).
SLUG_REGEX='(FR|NFR|AC|TC)-[a-z0-9-]+'

# ─── argument parsing ────────────────────────────────────────────────────────
BASE=""
POSITIONAL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      shift
      if [[ $# -eq 0 ]]; then
        echo "implement: --base requires a value" >&2; exit 1
      fi
      BASE="$1"; shift
      ;;
    --base=*)
      BASE="${1#--base=}"; shift
      ;;
    -h|--help)
      sed -n '3,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0
      ;;
    *)
      if [ -n "$POSITIONAL" ]; then
        echo "implement: unexpected extra argument '$1' (only one feature/slug accepted)" >&2
        exit 1
      fi
      POSITIONAL="$1"; shift
      ;;
  esac
done

# ─── helpers ─────────────────────────────────────────────────────────────────
rel_path() {
  local abs="$1"
  printf '%s' "${abs#$ROOT/}"
}

# Escape a string for use in a grep -E pattern.
grep_escape() {
  printf '%s' "$1" | sed 's/[][\\/.*^$()+?{}|]/\\&/g'
}

# ─── base resolution ─────────────────────────────────────────────────────────
# Implements: FR-implement-default-base, FR-implement-base-options
resolve_base() {
  local requested="${BASE:-main}"
  case "$requested" in
    main)
      if git rev-parse --verify --quiet main >/dev/null 2>&1; then
        git merge-base main HEAD
      elif git rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
        git merge-base origin/main HEAD
      else
        echo "implement: no main branch found; pass --base <ref>" >&2
        exit 1
      fi
      ;;
    HEAD|working)
      echo "HEAD"
      ;;
    *)
      if git rev-parse --verify --quiet "$requested" >/dev/null 2>&1; then
        git rev-parse --verify "$requested"
      else
        echo "implement: unknown base ref '$requested'" >&2
        exit 1
      fi
      ;;
  esac
}

BASE_REF="$(resolve_base)"
BASE_DISPLAY="${BASE:-main}"
# working is a synonym for HEAD; display the canonical form.
[[ "$BASE_DISPLAY" == "working" ]] && BASE_DISPLAY="HEAD"
if [[ "$BASE_DISPLAY" != "main" && "$BASE_DISPLAY" != "HEAD" ]]; then
  BASE_DISPLAY="$BASE_REF"
fi

# ─── spec scope derivation ───────────────────────────────────────────────────
# Implements: FR-implement-spec-diff-scope
spec_pathspecs=()
for d in product design engineering qa; do
  spec_pathspecs+=("${SPECS_ROOT#$ROOT/}/$d")
done
# If specsRoot is ROOT, the pathspec becomes "./product" etc. — normalize.
spec_pathspecs=("${spec_pathspecs[@]/#\.\//}")

changed_specs=()
while IFS= read -r line; do
  [ -n "$line" ] && changed_specs+=("$line")
done < <(
  git diff --name-status --diff-filter=AM "$BASE_REF" -- "${spec_pathspecs[@]+"${spec_pathspecs[@]}"}" 2>/dev/null \
    | awk '{print $2}' | LC_ALL=C sort
)

SCOPE_SOURCE=""
in_scope_specs=()

# ─── fallback scope resolution ───────────────────────────────────────────────
# Implements: FR-implement-fallback-scope
# Matches the definition pattern (backtick-wrapped slug after a bold label),
# not bare grep -rl, so a cross-referenced slug does not resolve to the wrong feature.
resolve_fallback_scope() {
  local arg="$1"
  local feature=""

  if [[ "$arg" =~ ^((FR|NFR|AC|TC)-[a-z0-9-]+)$ ]]; then
    # Find the product spec that DEFINES the slug.
    local pat
    pat="$(grep_escape "$arg")"
    local defining_file=""
    while IFS= read -r f; do
      if grep -qE "\*\*[^*]+\*\* \`$pat\`" "$ROOT/$f" 2>/dev/null; then
        defining_file="$f"; break
      fi
    done < <(find "$SPECS_ROOT/product" -name '*.md' ! -name 'AGENTS.md' ! -name 'CLAUDE.md' 2>/dev/null | sed "s|^$ROOT/||" | LC_ALL=C sort)
    if [ -z "$defining_file" ]; then
      echo "implement: no spec found defining slug '$arg'" >&2; exit 1
    fi
    feature="$(basename "$defining_file" .md)"
  else
    feature="$arg"
    if [ ! -f "$SPECS_ROOT/product/$feature.md" ]; then
      echo "implement: no spec found for feature '$feature'" >&2; exit 1
    fi
  fi

  local found=0
  [ -f "$SPECS_ROOT/product/$feature.md" ] && { in_scope_specs+=("$(rel_path "$SPECS_ROOT/product/$feature.md")"); found=1; }
  for lane in design engineering qa; do
    [ -d "$SPECS_ROOT/$lane" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] && { in_scope_specs+=("$(rel_path "$f")"); found=1; }
    done < <(find "$SPECS_ROOT/$lane" -name "$feature.md" ! -name 'AGENTS.md' ! -name 'CLAUDE.md' 2>/dev/null | LC_ALL=C sort)
  done
  if [ "$found" -eq 0 ]; then
    echo "implement: no spec found for feature '$feature'" >&2; exit 1
  fi
}

# Implements: FR-implement-no-arg-default
if [[ ${#changed_specs[@]} -gt 0 ]]; then
  SCOPE_SOURCE="spec-diff"
  for f in "${changed_specs[@]+"${changed_specs[@]}"}"; do in_scope_specs+=("$f"); done
elif [[ -n "$POSITIONAL" ]]; then
  SCOPE_SOURCE="fallback"
  resolve_fallback_scope "$POSITIONAL"
else
  # Implements: FR-implement-empty-scope
  echo "implement: nothing to implement (no spec changes since $BASE_DISPLAY and no feature/slug given)" >&2
  exit 0
fi

# ─── slug extraction ─────────────────────────────────────────────────────────
# Implements: FR-implement-slug-inventory
{
  for f in "${in_scope_specs[@]+"${in_scope_specs[@]}"}"; do
    grep -hoE "$SLUG_REGEX" "$ROOT/$f" 2>/dev/null || true
  done
} | LC_ALL=C sort -u > "$SLUGS_TMP"

SLUGS=()
while IFS= read -r s; do
  [ -n "$s" ] && SLUGS+=("$s")
done < "$SLUGS_TMP"

FR_SLUGS=()
for s in "${SLUGS[@]+"${SLUGS[@]}"}"; do
  [[ "$s" =~ ^FR- ]] && FR_SLUGS+=("$s")
done

INDEX_FILE="$ROOT/index.md"
HAS_INDEX="yes"
[ ! -f "$INDEX_FILE" ] && { echo "implement: index.md not found at $INDEX_FILE; emitting empty index-rows section" >&2; HAS_INDEX="no"; }

# ─── index + code-map lookup ─────────────────────────────────────────────
# Implements: FR-implement-index-rows, FR-implement-code-map

# ─── code-file collection (index Code column + Code Map Planned location) ────
# Implements: FR-implement-current-code
collect_code_files() {
  if [ "$HAS_INDEX" = "yes" ]; then
    for slug in "${SLUGS[@]+"${SLUGS[@]}"}"; do
      local pat; pat="$(grep_escape "$slug")"
      grep -E "^\| \`?$pat\`? \|" "$INDEX_FILE" 2>/dev/null | awk -F'|' '{
        gsub(/^ +| +$/,"",$(NF-1))
        n=split($(NF-1), parts, ", ")
        for (i=1;i<=n;i++) {
          gsub(/^ +| +$/,"",parts[i])
          sub(/:[0-9]+.*$/, "", parts[i])
          if (parts[i] != "" && parts[i] != "—") print parts[i]
        }
      }'
    done
  fi
  for f in "${in_scope_specs[@]+"${in_scope_specs[@]}"}"; do
    case "$f" in
      engineering/*)
        local abs="$ROOT/$f"; [ -f "$abs" ] || continue
        awk -F'|' '
          /^## Code Map/ { in_map=1; next }
          /^## / { in_map=0 }
          in_map && /^\|/ && !/^\| *Slug/ && !/^\|--/ {
            gsub(/^ +| +$/,"",$3)
            n=split($3, parts, "; ")
            for (i=1;i<=n;i++) {
              gsub(/^ +| +$/,"",parts[i])
              sub(/:[0-9]+.*$/, "", parts[i])
              if (parts[i] != "" && parts[i] != "—") print parts[i]
            }
          }
        ' "$abs" 2>/dev/null
        ;;
    esac
  done
}

# ─── bundle assembly (deterministic order) ───────────────────────────────────
# Implements: FR-implement-single-pass-context, NFR-implement-determinism, FR-implement-changed-specs, FR-implement-context-ephemeral
emit_bundle() {
  echo "=== implement-context: base=$BASE_DISPLAY, scope=$SCOPE_SOURCE ==="
  echo ""

  echo "## Changed spec files"
  if [[ ${#in_scope_specs[@]} -gt 0 ]]; then
    for f in "${in_scope_specs[@]+"${in_scope_specs[@]}"}"; do echo "$f"; done
  else
    echo "(none)"
  fi
  echo ""

  echo "## In-scope slugs"
  if [[ ${#SLUGS[@]} -gt 0 ]]; then
    for s in "${SLUGS[@]+"${SLUGS[@]}"}"; do echo "$s"; done
  else
    echo "(none)"
  fi
  echo ""

  echo "## Spec contents"
  for f in $(printf '%s\n' "${in_scope_specs[@]+"${in_scope_specs[@]}"}" | LC_ALL=C sort); do
    echo "### $f"
    if [ -f "$ROOT/$f" ]; then cat "$ROOT/$f"; else echo "(file not found)"; fi
    echo ""
  done

  echo "## Index rows"
  if [ "$HAS_INDEX" = "yes" ]; then
    local printed=0
    for slug in "${SLUGS[@]+"${SLUGS[@]}"}"; do
      local pat; pat="$(grep_escape "$slug")"
      local row
      row="$(grep -E "^\| \`?$pat\`? \|" "$INDEX_FILE" 2>/dev/null | head -n1 || true)"
      if [ -n "$row" ]; then echo "$row"; printed=1; fi
    done
    [ "$printed" -eq 0 ] && echo "(no in-scope slugs found in index)"
  else
    echo "(index.md not present)"
  fi
  echo ""

  echo "## Code map"
  local cm_printed=0
  for slug in "${FR_SLUGS[@]+"${FR_SLUGS[@]}"}"; do
    local pat; pat="$(grep_escape "$slug")"
    for f in "${in_scope_specs[@]+"${in_scope_specs[@]}"}"; do
      case "$f" in
        engineering/*)
          local abs="$ROOT/$f"; [ -f "$abs" ] || continue
          local row
          row="$(awk -v slug="$slug" '
            /^## Code Map/ { in_map=1; next }
            /^## / { in_map=0 }
            in_map && $0 ~ "^\\| `?"slug"`? \\|" { print; exit }
          ' "$abs" 2>/dev/null)"
          if [ -n "$row" ]; then echo "$row"; cm_printed=1; break; fi
          ;;
      esac
    done
  done
  [ "$cm_printed" -eq 0 ] && echo "(no Code Map rows for in-scope FRs)"
  echo ""

  echo "## Current code state"
  local code_files
  code_files="$(collect_code_files | LC_ALL=C sort -u)"
  if [ -z "$code_files" ]; then
    echo "(no code locations referenced)"
  else
    while IFS= read -r cf; do
      [ -z "$cf" ] && continue
      echo "### $cf"
      if [ -f "$ROOT/$cf" ]; then
        git diff "$BASE_REF" -- "$cf" 2>/dev/null || echo "(git diff failed)"
      else
        echo "planned, not yet present"
      fi
      echo ""
    done <<< "$code_files"
  fi
}

emit_bundle
