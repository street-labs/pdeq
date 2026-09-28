#!/usr/bin/env bash
#
# Alignment pre-screen: cheap per-slice drift check between requirements and
# the code their traceability mapping points at.
#
# For each FR slug in index.md with a non-empty Code column, the slice is the
# requirement's defining line (product spec from "Defined In") plus a bounded
# code window around the first cited file:line. One jev --json choice call per
# slice: aligned | drift. Thresholds are symmetric: the screen acts only on
# confident answers — aligned at confidence >= 0.85 passes, drift at >= 0.85
# escalates, anything else (either direction below threshold, missing or
# erroring service) leaves the slice unassessed — nothing doubtful ever
# passes or escalates on a guess.
#
# Advisory: no hook references this script. Exit 1 only when a drift
# escalation exists, as a report signal — no gate consumes it.
#
# Usage: ./scripts/alignment-check.sh [feature]
#   [feature] narrows the screen to slugs defined in product/<feature>.md
#
# Implements: FR-conformance-jev-slice, FR-conformance-jev-classify
# Implements: FR-conformance-jev-escalate, FR-conformance-jev-opt-in
# Implements: NFR-conformance-jev-failsafe, NFR-conformance-jev-economy

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
FEATURE="${1:-}"

[ -f "$ROOT/index.md" ] || { echo "index.md not found at $ROOT/index.md"; exit 2; }

# ponytail: 0.85 threshold hardcoded, same as lane triage; promote to config only if a project needs a different one.
ALIGNED_MIN=0.85

# screen_slice <slug> <spec> <loc> — emits one report line, bumps counters.
screen_slice() {
  local slug="$1" spec="$2" loc="$3"
  local file="${loc%%:*}" line="${loc##*:}"
  if [ ! -f "$ROOT/$file" ]; then
    echo "? unassessed   $slug  $loc  (code file missing)"
    UNASSESSED=$((UNASSESSED + 1))
    return
  fi
  local req code resp decision action rest
  req="$(grep -m1 -F -- "$slug" "$ROOT/$spec" 2>/dev/null || true)"
  [ -n "$req" ] || req="(requirement text not found in $spec)"
  code="$(sed -n "$(( line > 8 ? line - 8 : 1 )),$(( line + 12 ))p" "$ROOT/$file" 2>/dev/null || true)"
  if ! resp="$(printf 'Requirement (%s):\n%s\n\nCode at %s:\n%s\n' "$slug" "$req" "$loc" "$code" \
      | jev --json choice \
        "Does this code slice implement the requirement?" \
        "aligned=The code realizes the behavior the requirement specifies" \
        "drift=The code contradicts, omits, or only pretends to realize the requirement" \
      2>/dev/null)"; then
    echo "? unassessed   $slug  $loc  (judgment service unavailable)"
    UNASSESSED=$((UNASSESSED + 1))
    return
  fi
  # One python call does parse + threshold and decides: pass | escalate | unassessed.
  decision="$(python3 -c '
import json, sys
try:
    c = json.loads(sys.argv[1])["answers"]["choice"]
    verdict, conf = c.get("choice", ""), float(c.get("confidence", 0))
    if verdict in ("aligned", "drift") and conf >= float(sys.argv[2]):
        print("pass" if verdict == "aligned" else "escalate", conf)
    else:
        print("unassessed", (verdict or "no-answer") + "@" + str(conf))
except Exception:
    print("unassessed", "parse-error")
' "$resp" "$ALIGNED_MIN" 2>/dev/null)"
  read -r action rest <<< "$(printf '%s' "${decision:-unassessed parse-error}")"
  case "$action" in
    pass)
      echo "✓ aligned     $slug  $loc  ($rest)"
      ALIGNED=$((ALIGNED + 1))
      ;;
    escalate)
      echo "⚠ drift        $slug  $loc  ($rest) — escalate to /pdeq-conform ${spec#product/}"
      ESCALATED=$((ESCALATED + 1))
      ;;
    *)
      echo "? unassessed   $slug  $loc  ($rest)"
      UNASSESSED=$((UNASSESSED + 1))
      ;;
  esac
}

ALIGNED=0; ESCALATED=0; UNASSESSED=0

echo "Alignment pre-screen: requirement -> code slices from index.md"
echo ""

# Emit "slug<TAB>spec<TAB>loc" triples from the index table: FR rows with a
# non-empty Code column, example slugs skipped, optional feature filter.
triples="$(awk -F'|' -v feature="$FEATURE" '
  /^\|/ && !/^\|[- ]+\|/ {
    gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4); gsub(/^ +| +$/, "", $6)
    if ($2 !~ /^FR-/ || $2 ~ /-ex-/) next
    if (feature != "" && $4 !~ ("product/" feature ".md")) next
    if ($6 == "") next
    split($6,locs,",")
    gsub(/^ +| +$/, "", locs[1])
    if (locs[1] == "") next
    print $2 "\t" $4 "\t" locs[1]
  }' "$ROOT/index.md")"

if [ -z "$triples" ]; then
  echo "No FR slugs with code locations${FEATURE:+ in product/$FEATURE.md} — nothing to screen."
  exit 0
fi

while IFS="$(printf '\t')" read -r slug spec loc; do
  screen_slice "$slug" "$spec" "$loc"
done <<< "$triples"

echo ""
echo "Summary: $ALIGNED aligned, $ESCALATED escalated, $UNASSESSED unassessed"
[ "$ESCALATED" -eq 0 ]
