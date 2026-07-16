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
# Living specs describe what IS, not what will be, is being planned, or is being set up for future work.
# Patterns catch: phasing language, future-tense statements, planning/setup framing, and WIP markers.
# Patterns are curated to minimize false positives — bare words like "future", "later", "established"
# are too common in legitimate meta-description (e.g., "the established pattern") and would cause
# noise. Use targeted multi-word patterns where possible.
DEFAULT_PATTERNS=(
  # Phasing / versioning
  "\\bMVP\\b"
  "\\bphase [0-9IVX]+\\b"
  "\\biteration [0-9]+\\b"
  "\\bV[0-9]+\\b"
  "\\binitial release\\b"
  "\\bfirst version\\b"
  # Future-tense constructions (specific enough to avoid false positives)
  "\\bwill be added\\b"
  "\\bto be implemented\\b"
  "\\bwill support\\b"
  "\\bwill include\\b"
  "\\bwill provide\\b"
  "\\bwill allow\\b"
  "\\bwill enable\\b"
  "\\bnot yet\\b"
  # Planning / phasing vocabulary
  "\\bplanned for\\b"
  "\\beventually\\b"
  "\\bupcoming\\b"
  "\\bnext (?:release|version|phase|iteration)\\b"
  # Setup / framing language — words that frame a feature as preparatory rather than
  # describing present state. Catches active present-tense forms ("establishes",
  # "establishing") that frame features as becoming rather than being. Avoided: bare
  # "established" (past participle / adjective like "the pattern established in this
  # feature" is common in spec meta-description and not planning language), bare
  # "scaffold" (too common for generated-file descriptions).
  "\bestablishing\b"
  "\bestablishes\b"
  "\bgroundwork\b"
  "\bsets the stage\b"
  "\bserves as (?:a|the) basis\b"
  "\blays? (?:a|the) groundwork\b"
  "\bpaves? the way\b"
  # Work-in-progress markers (spec content describing unfinished work)
  "\bunder development\b"
  "\bTODO\b"
  "\bFIXME\b"
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
# Resolution order:
#   1. Start with DEFAULT_PATTERNS
#   2. If temporalAudit.patterns is a non-empty array, replace with those (skip 3-4)
#   3. Remove any patterns listed in temporalAudit.exclude
#   4. Add any patterns listed in temporalAudit.include
PATTERNS=("${DEFAULT_PATTERNS[@]}")
if [[ -f pdeq.json ]] && command -v jq &>/dev/null; then
  CUSTOM_PATTERNS=$(jq -r '.temporalAudit.patterns[]? // empty' pdeq.json 2>/dev/null || true)
  if [[ -n "$CUSTOM_PATTERNS" ]]; then
    # Full replacement: ignores exclude/include
    PATTERNS=()
    while IFS= read -r pattern; do
      PATTERNS+=("$pattern")
    done <<< "$CUSTOM_PATTERNS"
  else
    # Apply exclude (remove matching patterns from defaults)
    EXCLUDE_PATTERNS=$(jq -r '.temporalAudit.exclude[]? // empty' pdeq.json 2>/dev/null || true)
    if [[ -n "$EXCLUDE_PATTERNS" ]]; then
      declare -a EXCLUDE_LIST
      while IFS= read -r exclude_pattern; do
        EXCLUDE_LIST+=("$exclude_pattern")
      done <<< "$EXCLUDE_PATTERNS"
      NEW_PATTERNS=()
      for pattern in "${PATTERNS[@]}"; do
        EXCLUDED=false
        for exclude in "${EXCLUDE_LIST[@]}"; do
          if [[ "$pattern" == "$exclude" ]]; then
            EXCLUDED=true
            break
          fi
        done
        if [[ "$EXCLUDED" == false ]]; then
          NEW_PATTERNS+=("$pattern")
        fi
      done
      PATTERNS=("${NEW_PATTERNS[@]}")
    fi
    # Apply include (add project-specific patterns on top)
    INCLUDE_PATTERNS=$(jq -r '.temporalAudit.include[]? // empty' pdeq.json 2>/dev/null || true)
    if [[ -n "$INCLUDE_PATTERNS" ]]; then
      while IFS= read -r include_pattern; do
        PATTERNS+=("$include_pattern")
      done <<< "$INCLUDE_PATTERNS"
    fi
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
    elif [[ "$matched_line" =~ ("will be added"|"to be implemented"|"planned for"|"will support"|"will include"|"will provide"|"will allow"|"will enable") ]]; then
      SUGGESTION="Rewrite in present tense describing what IS (not what will be)"
    elif [[ "$matched_line" =~ (establishing|establishes|establish|foundation|groundwork|scaffold|sets the stage|serves as a basis|laying the groundwork|paves the way) ]]; then
      SUGGESTION="Rewrite in present tense describing current state, not setup/preparation for future work"
    elif [[ "$matched_line" =~ (future|later|eventually|upcoming|next) ]]; then
      SUGGESTION="Move to roadmap or rewrite in present tense"
    elif [[ "$matched_line" =~ (under development|TODO|FIXME) ]]; then
      SUGGESTION="Rewrite as present tense or remove — spec describes shipped state, not work in progress"
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
