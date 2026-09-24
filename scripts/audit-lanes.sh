#!/usr/bin/env bash
#
# Lane discipline auditor for product specs.
# Scans product/ for terms that indicate design or engineering bleed.
#
# Exit codes:
#   0 — no violations found
#   1 — one or more violations found
#
# Can be run standalone: ./scripts/audit-lanes.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
PRODUCT_DIR="$ROOT/product"
PDEQ_CONFIG_PATH="${PDEQ_CONFIG_PATH:-$ROOT/pdeq.json}"

violations=()

# Shared scanning primitives (read_lane_terms, pcre_scan) live in the sourced
# lib so this warn-only backstop and the blocking audit-structure.sh share one
# implementation of slug-stripping, literal-escape, and config reading.
PDEQ_LIB_DIR="$(cd "$(dirname "$0")" && pwd)/lib"
# shellcheck source=lib/lane-scan.sh
. "$PDEQ_LIB_DIR/lane-scan.sh"

# Honor laneAudit.exclude so a domain-legitimate term does not even warn.
PDEQ_EXCLUDE_RX="$(read_lane_terms "exclude")"
export PDEQ_EXCLUDE_RX

warn() {
  # Layer 1.5 — automated finding triage (laneAudit.jevTriage, opt-in).
  # A high-confidence "allowed" answer from the judgment service demotes the
  # finding to a labeled note; every other answer keeps the ⚠ verbatim.
  # Implements: FR-lane-discipline-jev-triage, FR-lane-discipline-jev-labeled
  if [ "$PDEQ_JEV_TRIAGE" = "1" ] && jev_triage_allowed "$1"; then
    demoted+=("$1")
    echo "  ✓ allowed (jev triage: legitimate mention) $1"
    return
  fi
  violations+=("$1")
  echo "  ⚠  $1"
}

# ─── Layer 1.5: automated finding triage ───────────────────────────────────
# Asks the jev CLI to classify one finding. Returns 0 only when the answer is
# "allowed" at confidence >= 0.85; any failure (missing binary, non-zero exit,
# unparsable output, low confidence) returns 1, keeping the finding — triage
# can only demote, never hide (FR-lane-discipline-jev-failsafe).
# ponytail: 0.85 threshold is a hardcoded constant; promote to a config key only if a project needs a different one.
# Implements: FR-lane-discipline-jev-failsafe, FR-lane-discipline-jev-triage
jev_triage_allowed() {
  local resp
  resp=$(printf '%s' "$1" | jev --json choice \
    "Classify this product-spec line flagged for lane-discipline bleed" \
    "violation=The line prescribes implementation, platform, or technical detail as a requirement" \
    "allowed=Legitimate mention: orientation in an overview, or a per-host constraint in a non-functional requirement" \
    2>/dev/null) || return 1
  python3 -c "
import json, sys
try:
    c = json.loads(sys.argv[1])['answers']['choice']
    sys.exit(0 if c.get('choice') == 'allowed' and float(c.get('confidence', 0)) >= 0.85 else 1)
except Exception:
    sys.exit(1)
" "$resp"
}

# Triage is opt-in and off the default path: only when laneAudit.jevTriage is
# true AND jev is installed does any external call happen.
# Implements: NFR-lane-discipline-jev-opt-in
PDEQ_JEV_TRIAGE=0
demoted=()
if [ "$(read_lane_flags jevTriage)" = "true" ] && command -v jev >/dev/null 2>&1; then
  PDEQ_JEV_TRIAGE=1
fi

echo "Auditing lane discipline in product specs..."
echo ""

if [ ! -d "$PRODUCT_DIR" ]; then
  echo "product/ directory not found."
  exit 1
fi

# Collect all product spec files (top-level and platform subfolders, excluding CLAUDE.md)
product_files=$(find "$PRODUCT_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)

if [ -z "$product_files" ]; then
  echo "No product spec files found."
  exit 0
fi

# ─── Technology names (engineering bleed) ──────────────────────────────────
echo "[1/4] Checking for technology, vendor, protocol, and platform references..."
# Built-in default term list. Extended (never replaced) by laneAudit terms from
# pdeq.json so a project can flag its own vendors/protocols/platforms/libraries.
# Implements: FR-lane-discipline-lexical-backstop, FR-lane-discipline-default-terms
tech_terms="React|TypeScript|Shiki|Vite|SwiftUI|AppKit|tree-sitter|Zustand|Tailwind|pnpm|npm|Prism\.js|CodeMirror|webpack|DOMPurify|rehype|remark|markdown-it"
extra_terms=$(read_lane_terms)
if [ -n "$extra_terms" ]; then
  tech_terms="$tech_terms|$extra_terms"
fi

while IFS= read -r file; do
  relpath="${file#$ROOT/}"
  matches=$(pcre_scan "\b($tech_terms)\b" "$file" || true)
  if [ -n "$matches" ]; then
    while IFS= read -r match; do
      warn "$relpath:$match"
    done <<< "$matches"
  fi
done <<< "$product_files"
echo ""

# ─── CSS/UI implementation terms (design/engineering bleed) ────────────────
echo "[2/4] Checking for CSS/UI implementation terms..."
# Match px/rem values like "240px" or "1.5rem", font-family, specific font names, CSS properties
css_terms="[0-9]+px|[0-9]+rem|font-family|monospace|sans-serif|background-color|border-radius|border-left|padding:|margin:|flex:|grid:|z-index|overflow:"

while IFS= read -r file; do
  relpath="${file#$ROOT/}"
  matches=$(pcre_scan "($css_terms)" "$file" || true)
  if [ -n "$matches" ]; then
    while IFS= read -r match; do
      # Skip lines that are in code blocks (start with spaces/tabs + backtick context)
      warn "$relpath:$match"
    done <<< "$matches"
  fi
done <<< "$product_files"
echo ""

# ─── API endpoint patterns (engineering bleed) ─────────────────────────────
echo "[3/4] Checking for API endpoint patterns..."
api_patterns='(GET|POST|PUT|DELETE|PATCH)\s+/api/|`/api/'

while IFS= read -r file; do
  relpath="${file#$ROOT/}"
  matches=$(pcre_scan "$api_patterns" "$file" || true)
  if [ -n "$matches" ]; then
    while IFS= read -r match; do
      warn "$relpath:$match"
    done <<< "$matches"
  fi
done <<< "$product_files"
echo ""

# ─── Web-specific terms in base product specs ──────────────────────────────
echo "[4/4] Checking for web-specific terms in base product specs..."
# Only check top-level product/*.md (not product/web/*.md)
web_terms="browser|viewport|DOM\b|CSS\b|HTML\b|localStorage|sessionStorage|window\.close|navigator\."

base_files=$(find "$PRODUCT_DIR" -maxdepth 1 -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)

if [ -n "$base_files" ]; then
  while IFS= read -r file; do
    relpath="${file#$ROOT/}"
    matches=$(pcre_scan "\b($web_terms)" "$file" "i" || true)
    if [ -n "$matches" ]; then
      while IFS= read -r match; do
        warn "$relpath:$match"
      done <<< "$matches"
    fi
  done <<< "$base_files"
fi
echo ""

# ─── Summary ──────────────────────────────────────────────────────────────

if [ ${#violations[@]} -eq 0 ]; then
  echo "✓ No lane discipline violations found in product specs."
  if [ ${#demoted[@]} -gt 0 ]; then
    echo "  (${#demoted[@]} finding(s) pre-cleared by automated triage — see the ✓ lines above; the advisory lane review remains authoritative.)"
  fi
  exit 0
else
  echo "✗ Found ${#violations[@]} potential lane violation(s) in product specs."
  echo "  Review each violation — some may be acceptable (e.g., 'browser' in a web-specific product/web/ spec)."
  exit 1
fi
