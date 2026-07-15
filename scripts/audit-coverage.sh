#!/usr/bin/env bash
# Implements: FR-coverage-audit-independent
#
# QA Coverage Auditor.
#
# Detects when code has been shipped for a requirement but QA coverage has not
# been executed. Joins the marker-derived Code column from index.md against
# each feature's QA Coverage Matrix, and exits non-zero when a feature has
# realizing code whose coverage rows are non-terminal.
#
# Exit codes:
#   0 — all features with realizing code have terminal coverage status
#       (or all failures suppressed by PDEQ_ALLOW_DRIFT=1)
#   1 — one or more features have realizing code but non-terminal coverage
#
# Flags:
#   --check    Explicit CI mode (identical behavior, same as default)
#
# Env:
#   PDEQ_CONFIG_PATH         Path to pdeq.json. Default: <repo>/pdeq.json
#   PDEQ_ALLOW_DRIFT=1       Demote all blocks to warnings; exit 0.
#   NO_COLOR=1               Suppress ANSI color codes in output.
#
# Dependencies:
#   - scripts/audit-coverage.py  (the core audit logic)
#   - index.md                   (must exist, Code column populated)
#   - qa/<platform>/<feature>.md (per-feature coverage matrices)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$SCRIPT_DIR")"
INDEX="$ROOT/index.md"
PDEQ_CONFIG_PATH="${PDEQ_CONFIG_PATH:-$ROOT/pdeq.json}"
PDEQ_ALLOW_DRIFT="${PDEQ_ALLOW_DRIFT:-}"
NO_COLOR="${NO_COLOR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) shift ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [ -n "$NO_COLOR" ]; then RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
else RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BOLD="\033[1m"; RESET="\033[0m"
fi

echo -e "${BOLD}QA Coverage Audit${RESET}"
echo ""

if [ ! -f "$INDEX" ]; then
  echo -e "  ${RED}✗${RESET}  index.md not found at $INDEX" >&2
  exit 1
fi

# ─── Run core audit logic ────────────────────────────────────────────────────

PY_SCRIPT="$SCRIPT_DIR/audit-coverage.py"
if [ ! -f "$PY_SCRIPT" ]; then
  echo -e "  ${RED}✗${RESET}  audit-coverage.py not found alongside this script" >&2
  exit 1
fi

# Capture python output to temp file so we can read it in the current shell
# (avoiding subshell issues with while-read pipelines)
tmpout=$(mktemp)
trap "rm -f '$tmpout'" EXIT

set +e
ROOT="$ROOT" INDEX="$INDEX" PDEQ_CONFIG="$PDEQ_CONFIG_PATH" PDEQ_ALLOW_DRIFT="$PDEQ_ALLOW_DRIFT" \
  python3 "$PY_SCRIPT" > "$tmpout" 2>&1
py_rc=$?
set -e

block_count=0
warn_count=0

while IFS= read -r line; do
  case "$line" in
    CLEAR:*)
      echo -e "  ${GREEN}✓${RESET}  ${line#CLEAR:}" >&2
      ;;
    WARN:*)
      echo -e "  ${YELLOW}⚠${RESET}  ${line#WARN:}" >&2
      warn_count=$((warn_count + 1))
      ;;
    BLOCK:*)
      echo -e "  ${RED}✗${RESET}  ${line#BLOCK:}" >&2
      block_count=$((block_count + 1))
      ;;
    SUPPRESS:*)
      echo -e "  ${YELLOW}⚠${RESET}  (suppressed by PDEQ_ALLOW_DRIFT) ${line#SUPPRESS:}" >&2
      ;;
    NO_DATA)
      echo -e "  ${YELLOW}⚠${RESET}  No product-defined slugs found in index.md" >&2
      ;;
    FAIL:*)
      echo -e "  ${RED}✗${RESET}  ${line#FAIL:}" >&2
      block_count=$((block_count + 1))
      ;;
  esac
done < "$tmpout"

rm -f "$tmpout"
trap - EXIT

echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────

if [ "$py_rc" -eq 0 ]; then
  if [ "$warn_count" -gt 0 ]; then
    echo "ⓘ  $warn_count warning(s) emitted." >&2
  fi
  echo -e "${GREEN}✓${RESET} QA coverage audit passed." >&2
  exit 0
else
  if [ -n "$PDEQ_ALLOW_DRIFT" ]; then
    echo -e "${YELLOW}PDEQ_ALLOW_DRIFT=1 active${RESET} — coverage blocks suppressed." >&2
    exit 0
  fi
  echo ""
  echo -e "${RED}✗ Found ${block_count} feature(s) with code but non-terminal coverage.${RESET}" >&2
  echo "  Override for this commit: PDEQ_ALLOW_DRIFT=1 git commit ..." >&2
  exit 1
fi
