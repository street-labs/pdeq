#!/usr/bin/env bash
#
# Shared QA Coverage Matrix parser library.
# Sourced by audit-traceability.sh and audit-coverage.sh.
#
# Usage in a shell script:
#   source "$(dirname "$0")/lib/qa-matrix.sh"
#
# Exports one function:
#   parse_qa_matrix <spec_file>
#     Reads the Coverage Matrix section from a QA markdown file and emits
#     tab-separated lines: status<tab>tc_slug1,tc_slug2,...
#     Only rows that cite at least one TC- slug are emitted.
#     Rows without TC slugs (prose coverage) are skipped.

# Implements: FR-code-mapping-audit-qa-status-evidence (shared parser)
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
    # Extract all TC slugs from the requirement and test-case columns (all cells except status).
    tcs = re.findall(r'TC-[a-z0-9-]+', ' '.join(cells[:-1]))
    if not tcs:
        continue
    seen = set(); uniq = []
    for t in tcs:
        if t not in seen: seen.add(t); uniq.append(t)
    print(f"{status}\t{','.join(uniq)}")
PY
}
