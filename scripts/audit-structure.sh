#!/usr/bin/env bash
#
# Blocking structural content check (lane-discipline Layer 1b).
#
# Unlike the warn-only lexical backstop (audit-lanes.sh), this check is scoped to
# high-precision structural content classes and BLOCKS a commit on a violation.
# It guards three lanes:
#   - product   — shared specs must be behavior-only and platform-neutral
#   - design    — must not prescribe implementation technology / API contracts
#   - engineering — must not DEFINE product requirements (only reference them)
#
# Exit codes:
#   0 — no violations (or all violations suppressed by PDEQ_ALLOW_DRIFT=1)
#   1 — one or more violations found and not suppressed
#
# Escape hatch:
#   PDEQ_ALLOW_DRIFT=1 ./scripts/audit-structure.sh   # demote blocks to warnings
#
# Can be run standalone: ./scripts/audit-structure.sh [--check]
# (Implements markers sit on the functions/blocks that realize each slug, below.)

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
PRODUCT_DIR="$ROOT/product"
DESIGN_DIR="$ROOT/design"
ENG_DIR="$ROOT/engineering"
PDEQ_CONFIG_PATH="${PDEQ_CONFIG_PATH:-$ROOT/pdeq.json}"
export PDEQ_CONFIG_PATH
PDEQ_ALLOW_DRIFT="${PDEQ_ALLOW_DRIFT:-}"

PDEQ_LIB_DIR="$(cd "$(dirname "$0")" && pwd)/lib"
# shellcheck source=lib/lane-scan.sh
. "$PDEQ_LIB_DIR/lane-scan.sh"

violations=()
suppressed=()

# record <file:lineno:text> <condition-label>
# Implements: FR-lane-discipline-blocking-enforcement, FR-lane-discipline-blocking-escape-hatch
record() {
  if [ -n "$PDEQ_ALLOW_DRIFT" ]; then
    suppressed+=("$2")
    echo "  ⚠  (suppressed by PDEQ_ALLOW_DRIFT) $1"
  else
    violations+=("$1")
    echo "  ✗  $1"
  fi
}

# scan_class <regex> <file> <label> [ci]  — slug-stripping, fence-skipping scan
# Implements: FR-lane-discipline-content-class-check
scan_class() {
  local pat="$1" file="$2" label="$3" ci="${4:-}"
  local rel="${file#$ROOT/}"
  local matches
  matches=$(pcre_scan "$pat" "$file" "$ci" "fence" || true)
  if [ -n "$matches" ]; then
    while IFS= read -r m; do
      [ -n "$m" ] && record "$rel:$m" "$label"
    done <<< "$matches"
  fi
}

echo "Auditing structural lane discipline (blocking)..."
echo ""

# ─── Term sets ─────────────────────────────────────────────────────────────
# Curated, high-precision defaults. Deliberately narrower than audit-lanes.sh:
# this check blocks, so ambiguous domain nouns (menu, cart, card, page, list,
# tab) are excluded — breadth comes from project laneAudit terms + Layer 2.
css_terms="[0-9]+px|[0-9]+rem|font-family|monospace|sans-serif|background-color|border-radius|border-left|padding:|margin:|flex:|grid:|z-index|overflow:"
element_terms="modal|dialog box|sidebar|dropdown|tooltip|scrollbar|viewport|breadcrumb|carousel|segmented control|radio button|checkbox|thumbnail|context menu|nav bar|status bar"
# "click" is deliberately excluded — it is idiom-heavy in prose ("click through
# a mockup", "one-click") and too false-positive-prone for a blocking check.
# A project that wants it blocked can add it via laneAudit.
gesture_terms="tap|swipe|pinch|long-press|double-tap|drag-and-drop|hover"
api_patterns='(GET|POST|PUT|DELETE|PATCH)\s+/api/|`/api/'
web_terms="browser|viewport|DOM\b|localStorage|sessionStorage|window\.close|navigator\.|web app|web-based"
# Unambiguous platform/OS names — naming one in a SHARED spec is platform-as-product
# bleed. Deliberately only the low-false-positive names; ambiguous platform words
# (bare "web", "Mac" vs "MAC address", "server") are left to per-project
# laneAudit.platforms, which a project adds in pdeq.json.
platform_names="iOS|iPadOS|watchOS|tvOS|Android|macOS|OS X|Windows|Linux"
tech_terms="React|TypeScript|Shiki|Vite|SwiftUI|AppKit|tree-sitter|Zustand|Tailwind|pnpm|npm|Prism\.js|CodeMirror|webpack|DOMPurify|rehype|remark|markdown-it"

# Project terms by category (block, because the project declared them red flags).
construction_extra=$(read_lane_terms "libraries,protocols,vendors")
platform_extra=$(read_lane_terms "platforms")
libraries_extra=$(read_lane_terms "libraries")

if [ ! -d "$PRODUCT_DIR" ]; then
  echo "product/ directory not found."
  exit 1
fi

# ─── 1. Product content-class check ────────────────────────────────────────
echo "[1/3] Product specs — presentation, construction, platform-as-product..."
# Presentation + construction apply to ALL product specs (base + platform
# supplements): naming how it looks / how it's built is bleed anywhere in product.
product_all=$(find "$PRODUCT_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)
if [ -n "$product_all" ]; then
  construction="$api_patterns"
  [ -n "$construction_extra" ] && construction="$construction|$construction_extra"
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    scan_class "($css_terms)" "$file" "presentation:value"
    scan_class "\b($element_terms)\b" "$file" "presentation:element"
    scan_class "\b($gesture_terms)\b" "$file" "interaction:gesture"
    scan_class "($construction)" "$file" "technical:construction"
  done <<< "$product_all"
fi

# Platform-as-product applies only to TOP-LEVEL (shared) product specs — a
# platform supplement (product/<platform>/x.md) may legitimately name its host.
product_base=$(find "$PRODUCT_DIR" -maxdepth 1 -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)
if [ -n "$product_base" ]; then
  platform_pat="$web_terms|$platform_names"
  [ -n "$platform_extra" ] && platform_pat="$platform_pat|$platform_extra"
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    scan_class "\b($platform_pat)" "$file" "platform:as-product" "i"
  done <<< "$product_base"
fi
echo ""

# ─── 2. Downstream: design specs must not carry engineering content ────────
# Implements: FR-lane-discipline-downstream-scan
echo "[2/3] Design specs — engineering bleed..."
if [ -d "$DESIGN_DIR" ]; then
  design_eng="$tech_terms"
  [ -n "$libraries_extra" ] && design_eng="$design_eng|$libraries_extra"
  design_files=$(find "$DESIGN_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)
  if [ -n "$design_files" ]; then
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      scan_class "\b($design_eng)\b" "$file" "design:engineering-bleed"
      scan_class "($api_patterns)" "$file" "design:engineering-bleed"
    done <<< "$design_files"
  fi
fi
echo ""

# ─── 3. Downstream: engineering specs must not DEFINE product requirements ──
echo "[3/3] Engineering specs — product-requirement definitions..."
# A requirement DEFINITION (product's job) has the bold-label + backtick-slug +
# colon form, or the AC checkbox form. A REFERENCE (engineering's job — prose,
# Code Map rows) does not. This scan keeps slug tokens intact (unlike pcre_scan),
# because the slug syntax IS the signal.
if [ -d "$ENG_DIR" ]; then
  eng_files=$(find "$ENG_DIR" -name "*.md" -not -name "CLAUDE.md" -not -name "AGENTS.md" 2>/dev/null || true)
  if [ -n "$eng_files" ]; then
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      rel="${file#$ROOT/}"
      matches=$(python3 -c "
import sys, re
path = sys.argv[1]
# Definition: '- **Label** \`FR-ex-x-y\`:' ; or checkbox '- [ ] **Label** \`AC-ex-x-y\`'
defn = re.compile(r'^\s*[-*]\s+\*\*.+\*\*\s+\`(?:FR|NFR|AC)-[a-z0-9-]+\`\s*:')
chk  = re.compile(r'^\s*[-*]\s+\[[ xX]\]\s+.*\`AC-[a-z0-9-]+\`')
in_fence = False
try:
    with open(path, encoding='utf-8', errors='replace') as f:
        for i, line in enumerate(f, 1):
            if re.match(r'^\s*\`\`\`', line):
                in_fence = not in_fence; continue
            if in_fence: continue
            if defn.match(line) or chk.match(line):
                sys.stdout.write('%d:%s\n' % (i, line.rstrip('\n')))
except OSError:
    pass
" "$file" || true)
      if [ -n "$matches" ]; then
        while IFS= read -r m; do
          [ -n "$m" ] && record "$rel:$m" "engineering:product-definition"
        done <<< "$matches"
      fi
    done <<< "$eng_files"
  fi
fi
echo ""

# ─── Summary ───────────────────────────────────────────────────────────────
if [ -n "$PDEQ_ALLOW_DRIFT" ] && [ ${#suppressed[@]} -gt 0 ]; then
  echo "PDEQ_ALLOW_DRIFT=1 active — suppressed ${#suppressed[@]} structural block(s):"
  printf '  - %s\n' $(printf '%s\n' "${suppressed[@]}" | sort -u)
  echo "  These would block the commit without the override."
  exit 0
fi

if [ ${#violations[@]} -eq 0 ]; then
  echo "✓ No structural lane violations found."
  exit 0
else
  echo "✗ Found ${#violations[@]} structural lane violation(s) — commit blocked."
  echo "  Fix the spec, or override this commit with: PDEQ_ALLOW_DRIFT=1 git commit ..."
  exit 1
fi
