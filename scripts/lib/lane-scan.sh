#!/usr/bin/env bash
#
# Shared lane-scanning primitives, sourced by scripts/audit-lanes.sh (warn-only
# lexical backstop) and scripts/audit-structure.sh (blocking structural check).
# Keeping the scanner and the config reader in one place means the slug-strip,
# code-fence handling, and literal-escape rules have a single implementation.
#
# No jq dependency — pdeq.json is read with inline python3, matching the
# convention in audit-traceability.sh. python3 is already a hard pdeq dependency.
# (Marker for FR-lane-discipline-content-class-precision sits on pcre_scan below,
#  the unit that realizes the slug-strip + fence-skip precision.)

# ─── Project-tunable red-flag terms (from pdeq.json) ───────────────────────
# Reads laneAudit.{vendors,protocols,platforms,libraries} and prints them as a
# regex-escaped, `|`-joined alternation body. Extends the built-in defaults —
# never replaces them. Tolerant of a missing file or missing keys (prints
# nothing, never errors). Honors PDEQ_CONFIG_PATH for fixture pointing.
# Implements: FR-lane-discipline-project-terms
read_lane_terms() {
  local cfg="${PDEQ_CONFIG_PATH:-}"
  if [ -z "$cfg" ] || [ ! -f "$cfg" ]; then return; fi
  python3 -c "
import json, re, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    la = data.get('laneAudit') or {}
    keys = sys.argv[2].split(',') if len(sys.argv) > 2 and sys.argv[2] else ('vendors','protocols','platforms','libraries')
    terms = []
    for key in keys:
        terms.extend(la.get(key) or [])
    seen = set(); out = []
    for t in terms:
        if not t or t in seen:
            continue
        seen.add(t)
        out.append(re.escape(t))
    print('|'.join(out))
except Exception:
    pass
" "$cfg" "${1:-}" 2>/dev/null || true
}

# ─── Portable line scanner (python3 re, not grep -P) ───────────────────────
# Prints "<lineno>:<line>" for every line of $2 matching python regex $1.
# $3 (optional): flag string; contains "i" for case-insensitive matching.
# $4 (optional): if "fence", lines inside ``` fenced blocks and Markdown
#                indented-code (4-space / tab) lines are NOT scanned.
#
# Requirement slugs are permanent identifiers, not prose — a term embedded in a
# slug is never lane bleed, so slug tokens are stripped before matching. This is
# surgical: only the slug token is removed, so real prose on the same line still
# matches. Uses python3 (a hard pdeq dependency) instead of `grep -P`, which
# BSD grep (macOS, where the pre-commit hook runs) rejects — that silent no-op
# is exactly the bug this avoids.
# Implements: FR-lane-discipline-lexical-backstop, FR-lane-discipline-content-class-precision, FR-lane-discipline-exclude-terms
pcre_scan() {
  python3 -c "
import sys, re, os
pat, path = sys.argv[1], sys.argv[2]
flagstr = sys.argv[3] if len(sys.argv) > 3 else ''
skip_fence = (len(sys.argv) > 4 and sys.argv[4] == 'fence')
flags = re.I if 'i' in flagstr else 0
try:
    rx = re.compile(pat, flags)
except re.error:
    sys.exit(0)
slug_rx = re.compile(r'(?:FR|NFR|AC|TC)-[a-z0-9-]+')
# Project-declared domain-legitimate terms (laneAudit.exclude) are stripped from
# each line before matching — surgically, so a non-excluded flagged term on the
# same line still matches. Passed via env so every caller honors it unchanged.
excl_body = os.environ.get('PDEQ_EXCLUDE_RX', '')
excl_rx = re.compile(r'\b(?:%s)\b' % excl_body, re.I) if excl_body else None
fence_rx = re.compile(r'^\s*\`\`\`')
indent_rx = re.compile(r'^(?: {4,}|\t)')
in_fence = False
try:
    with open(path, encoding='utf-8', errors='replace') as f:
        for i, line in enumerate(f, 1):
            if skip_fence:
                if fence_rx.match(line):
                    in_fence = not in_fence
                    continue
                if in_fence or indent_rx.match(line):
                    continue
            probe = slug_rx.sub('', line)
            if excl_rx is not None:
                probe = excl_rx.sub('', probe)
            if rx.search(probe):
                sys.stdout.write('%d:%s\n' % (i, line.rstrip('\n')))
except OSError:
    pass
" "$1" "$2" "${3:-}" "${4:-}"
}
