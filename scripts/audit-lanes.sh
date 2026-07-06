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

warn() {
  violations+=("$1")
  echo "  ⚠  $1"
}

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
  exit 0
else
  echo "✗ Found ${#violations[@]} potential lane violation(s) in product specs."
  echo "  Review each violation — some may be acceptable (e.g., 'browser' in a web-specific product/web/ spec)."
  exit 1
fi
