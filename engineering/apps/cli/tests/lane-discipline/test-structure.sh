#!/usr/bin/env bash
#
# Layer 1b — blocking structural content check (scripts/audit-structure.sh).
#
# Exercises the deterministic, BLOCKING structural check against seeded fixtures.
# Unlike the warn-only lexical backstop, this check aborts on high-confidence
# content-class bleed in product, design, and engineering specs. Covers the
# Layer 1b acceptance criteria in qa/cli/lane-discipline.md.
#
# Fixtures are built in mktemp git repos and torn down on exit — nothing is
# written into the real repo. The audit is invoked by absolute path, so it
# sources the real scripts/lib/lane-scan.sh while deriving its content root and
# pdeq.json from the fixture's cwd.
#
# Usage: ./engineering/apps/cli/tests/lane-discipline/test-structure.sh

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../../../.." && pwd)"
AUDIT="$REPO_ROOT/scripts/audit-structure.sh"

# shellcheck source=../code-mapping/lib/assert.sh
source "$REPO_ROOT/engineering/apps/cli/tests/code-mapping/lib/assert.sh"

new_fixture() {
  local root; root="$(mktemp -d)"
  ( cd "$root" && git init -q && git config user.email t@t.co && git config user.name t )
  mkdir -p "$root/product" "$root/product/cli" "$root/design/cli" "$root/engineering/cli"
  printf '{ "platforms": ["cli"], "laneAudit": { "libraries": ["Vapor"], "platforms": ["iOS"] } }\n' > "$root/pdeq.json"
  echo "$root"
}
run_audit() { ( cd "$1" && shift; "$@" "$AUDIT" 2>&1 ); }

# ── Presentation / construction / platform bleed in a shared product spec ──
test_presentation_blocks() {
  local root out code; root="$(new_fixture)"
  printf '# X\n- The user sees a **dropdown** and can **swipe** the row.\n- Sizing is 240px.\n' > "$root/product/x.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "presentation: blocks" || return 1
  assert_contains "$out" "dropdown" "presentation: element flagged" || return 1
  assert_contains "$out" "240px" "presentation: value flagged" || return 1
}

test_construction_blocks() {
  local root out code; root="$(new_fixture)"
  printf '# Z\n- Calls GET /api/orders.\n- Built on Vapor.\n' > "$root/product/z.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "construction: blocks" || return 1
  assert_contains "$out" "/api/orders" "construction: api flagged" || return 1
  assert_contains "$out" "Vapor" "construction: library flagged" || return 1
}

test_platform_blocks_base_but_not_supplement() {
  local root out code; root="$(new_fixture)"
  printf '# Y\n- Data is stored in localStorage.\n- Works on iOS only.\n' > "$root/product/y.md"
  printf '# CLI supp\n- On iOS the token persists.\n' > "$root/product/cli/y.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "platform-as-product: blocks in base spec" || return 1
  assert_contains "$out" "product/y.md" "platform: base spec flagged" || return 1
  assert_not_contains "$out" "product/cli/y.md" "platform: supplement NOT flagged" || return 1
}

# ── Platform-name defaults (no config) + per-project laneAudit extension ───
test_platform_default_names_block() {
  local root out code; root="$(new_fixture)"
  # No platforms in laneAudit — these must block purely from the built-in defaults.
  printf '{ "platforms": ["ios","android","mac"] }\n' > "$root/pdeq.json"
  printf '# Checkout\n- On iOS and Android the flow differs.\n- Uses the macOS keychain.\n' > "$root/product/checkout.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "platform names: block from defaults" || return 1
  assert_contains "$out" "iOS" "platform names: iOS flagged" || return 1
  assert_contains "$out" "macOS" "platform names: macOS flagged" || return 1
}

test_vendor_config_blocks() {
  local root out code; root="$(new_fixture)"
  # POS-agnostic product doc in a project that uses Square: Square is bleed.
  printf '{ "platforms": ["ios"], "laneAudit": { "vendors": ["Square"] } }\n' > "$root/pdeq.json"
  printf '# Pay\n- Payments are captured through Square.\n' > "$root/product/pay.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "vendor config: Square blocks" || return 1
  assert_contains "$out" "Square" "vendor config: Square flagged" || return 1
}

# ── Negative: clean spec + incidental (fenced / slug) matches pass ─────────
test_clean_passes() {
  local root out code; root="$(new_fixture)"
  printf '# Clean\n- The customer can save a draft and resume it later.\n' > "$root/product/x.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "clean: passes" || return 1
  assert_contains "$out" "No structural lane violations" "clean: reports clean" || return 1
}

test_incidental_passes() {
  local root out code; root="$(new_fixture)"
  printf '# I\n```\nuser can swipe and see a dropdown\n```\nThe slug `FR-ex-swipe-gesture` is fine.\n' > "$root/product/i.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "incidental: fenced+slug not blocked" || return 1
}

# ── Downstream lanes ───────────────────────────────────────────────────────
test_downstream_design_blocks() {
  local root out code; root="$(new_fixture)"
  printf '# D\n- Render the list with React.\n- Fetch via GET /api/x.\n' > "$root/design/cli/x.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "downstream design: blocks" || return 1
  assert_contains "$out" "React" "downstream design: framework flagged" || return 1
}

test_downstream_eng_definition_blocks_reference_passes() {
  local root out code; root="$(new_fixture)"
  printf '# E\n- **New Thing** `FR-ex-x-new`: the system does a thing.\n\nSee `FR-ex-x-new` in prose (reference, ok).\n\n| FR-ex-x-new | scripts/x.sh | done |\n' > "$root/engineering/cli/x.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "downstream eng: definition blocks" || return 1
  # Exactly one violation line: the definition, not the reference or Code-Map row.
  local n; n="$(printf '%s\n' "$out" | grep -c 'engineering/cli/x.md')"
  assert_eq "1" "$n" "downstream eng: only the definition trips, not references" || return 1
}

# ── laneAudit.exclude — domain-legitimate terms ───────────────────────────
test_exclude_passes() {
  local root out code; root="$(new_fixture)"
  printf '{ "platforms": ["macos"], "laneAudit": { "exclude": ["macOS","Linux","Windows","TypeScript","Python"] } }\n' > "$root/pdeq.json"
  printf '# A\n- The tool must run on macOS, Linux, and Windows.\n- It supports TypeScript and Python.\n' > "$root/product/a.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "exclude: only-excluded-terms line passes" || return 1
}

test_exclude_surgical() {
  local root out code; root="$(new_fixture)"
  printf '{ "platforms": ["macos"], "laneAudit": { "exclude": ["macOS"] } }\n' > "$root/pdeq.json"
  printf '# B\n- On macOS the app shows a **sidebar**.\n' > "$root/product/b.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "exclude: surgical — line still blocks on non-excluded term" || return 1
  assert_contains "$out" "sidebar" "exclude: sidebar still flagged" || return 1
}

test_exclude_optional() {
  local root out code; root="$(new_fixture)"
  printf '{ "platforms": ["macos"] }\n' > "$root/pdeq.json"
  printf '# A\n- The tool must run on macOS, Linux, and Windows.\n' > "$root/product/a.md"
  out="$(run_audit "$root")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "exclude: absent list behaves as before (macOS blocks)" || return 1
}

# ── Escape hatch ───────────────────────────────────────────────────────────
test_escape_hatch_demotes() {
  local root out code; root="$(new_fixture)"
  printf '# X\n- The user sees a **dropdown** and can **swipe** the row.\n' > "$root/product/x.md"
  out="$(run_audit "$root" env PDEQ_ALLOW_DRIFT=1)"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "escape hatch: exit 0" || return 1
  assert_contains "$out" "suppressed by PDEQ_ALLOW_DRIFT" "escape hatch: names suppression" || return 1
}

main() {
  local total=0 passed=0 failed=()
  for t in \
    test_presentation_blocks test_construction_blocks \
    test_platform_blocks_base_but_not_supplement \
    test_platform_default_names_block test_vendor_config_blocks \
    test_clean_passes test_incidental_passes \
    test_downstream_design_blocks \
    test_downstream_eng_definition_blocks_reference_passes \
    test_exclude_passes test_exclude_surgical test_exclude_optional \
    test_escape_hatch_demotes; do
    total=$((total + 1))
    if "$t"; then echo "  PASS: $t"; passed=$((passed + 1))
    else echo "  FAIL: $t"; failed+=("$t"); fi
  done
  echo ""
  echo "lane-discipline structural (Layer 1b): $passed/$total passed"
  [ ${#failed[@]} -eq 0 ]
}

main "$@"
