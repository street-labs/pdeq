#!/usr/bin/env bash
# Implements: FR-living-spec-temporal-audit-patterns, FR-living-spec-temporal-audit-modes
# Scans authoritative specs for temporal/phasing language.
# Usage:
#   ./scripts/audit-temporal.sh             # scan and report, exit 0 always
#   ./scripts/audit-temporal.sh --check     # scan and exit 1 on any findings
#   ./scripts/audit-temporal.sh --staged    # scan only staged files

set -euo pipefail

# Implements: FR-living-spec-temporal-audit-exemptions
# Directories to scan (authoritative specs only)
SCAN_DIRS=("product" "design" "engineering" "qa")

# Directories/files to skip
SKIP_PATTERNS=(
  "roadmap/"
  "decisions.md"
  "decisions-pending.md"
  "AGENTS.md"
  "CLAUDE.md"
)

# Implements: FR-living-spec-temporal-audit-patterns
# Default temporal language patterns (overridable via pdeq.json)
DEFAULT_PATTERNS=(
  "\\bMVP\\b"
  "\\bphase [0-9IVX]+\\b"
  "\\biteration [0-9]+\\b"
  "\\bV[0-9]+\\b"
  "\\binitial release\\b"
  "\\bfirst version\\b"
  "\\bwill be added\\b"
  "\\bto be implemented\\b"
  "\\bplanned for\\b"
  "\\beventually\\b"
  "\\bupcoming\\b"
  "\\bnext release\\b"
)

MODE="report"
STAGED_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --staged)
      STAGED_ONLY=true
      shift
      ;;
    *)
      echo "Usage: $0 [--check] [--staged]"
      exit 1
      ;;
  esac
done

# Load patterns from pdeq.json if present
PATTERNS=("${DEFAULT_PATTERNS[@]}")
if [[ -f pdeq.json ]] && command -v jq &>/dev/null; then
  CUSTOM_PATTERNS=$(jq -r '.temporalAudit.patterns[]? // empty' pdeq.json 2>/dev/null || true)
  if [[ -n "$CUSTOM_PATTERNS" ]]; then
    PATTERNS=()
    while IFS= read -r pattern; do
      PATTERNS+=("$pattern")
    done <<< "$CUSTOM_PATTERNS"
  fi
fi

# Build grep pattern (combine all patterns with OR)
GREP_PATTERN=""
for pattern in "${PATTERNS[@]}"; do
  if [[ -z "$GREP_PATTERN" ]]; then
    GREP_PATTERN="$pattern"
  else
    GREP_PATTERN="$GREP_PATTERN|$pattern"
  fi
done

# Collect files to scan
FILES_TO_SCAN=()

if [[ "$STAGED_ONLY" == true ]]; then
  # Scan only staged markdown files in scan dirs
  while IFS= read -r file; do
    # Check if file is in one of the scan dirs
    for dir in "${SCAN_DIRS[@]}"; do
      if [[ "$file" == "$dir/"* ]]; then
        # Check if file should be skipped
        SKIP=false
        for skip_pattern in "${SKIP_PATTERNS[@]}"; do
          if [[ "$file" == *"$skip_pattern"* ]]; then
            SKIP=true
            break
          fi
        done
        if [[ "$SKIP" == false ]]; then
          FILES_TO_SCAN+=("$file")
        fi
        break
      fi
    done
  done < <(git diff --cached --name-only --diff-filter=ACM | grep '\.md$' || true)
else
  # Scan all markdown files in scan dirs
  for dir in "${SCAN_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r file; do
        # Check if file should be skipped
        SKIP=false
        for skip_pattern in "${SKIP_PATTERNS[@]}"; do
          if [[ "$file" == *"$skip_pattern"* ]]; then
            SKIP=true
            break
          fi
        done
        if [[ "$SKIP" == false ]]; then
          FILES_TO_SCAN+=("$file")
        fi
      done < <(find "$dir" -type f -name '*.md')
    fi
  done
fi

if [[ ${#FILES_TO_SCAN[@]} -eq 0 ]]; then
  echo "No specs found to scan."
  exit 0
fi

# Implements: FR-living-spec-temporal-audit-rewording
# Scan files and collect findings
FINDINGS=()
FINDING_COUNT=0

for file in "${FILES_TO_SCAN[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  # Scan file with grep
  while IFS=: read -r line_num matched_line; do
    # Extract the matched pattern for suggestion
    SUGGESTION=""
    if [[ "$matched_line" =~ MVP ]]; then
      SUGGESTION="Move to roadmap, or rewrite as present tense if shipped"
    elif [[ "$matched_line" =~ phase|iteration ]]; then
      SUGGESTION="Move to roadmap with FRR- slugs, or delete if obsolete"
    elif [[ "$matched_line" =~ V[0-9] ]]; then
      SUGGESTION="Move to roadmap/V2 section or rewrite in present tense"
    elif [[ "$matched_line" =~ "will be added"|"to be implemented"|"planned for" ]]; then
      SUGGESTION="Move to roadmap or rewrite as present tense"
    else
      SUGGESTION="Move to roadmap or rewrite in present tense"
    fi

    FINDINGS+=("$file:$line_num: $(echo "$matched_line" | sed 's/^[[:space:]]*//' | head -c 80) [Suggestion: $SUGGESTION]")
    ((FINDING_COUNT++)) || true
  done < <(grep -nE "$GREP_PATTERN" "$file" 2>/dev/null || true)
done

# Report findings
if [[ $FINDING_COUNT -gt 0 ]]; then
  echo "Temporal language audit found $FINDING_COUNT issue(s):"
  echo ""
  for finding in "${FINDINGS[@]}"; do
    echo "  $finding"
  done
  echo ""

  if [[ "$MODE" == "check" ]]; then
    exit 1
  fi
else
  echo "✓ No temporal language detected."
fi

exit 0
