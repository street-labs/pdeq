#!/usr/bin/env bash
#
# Automated alignment pre-screen (scripts/alignment-check.sh) test suite.
#
# A stub `jev` on PATH supplies canned judgment responses; fixtures are built
# in mktemp git repos with a product spec, a small code file, and an index.md
# whose Code column points at the code. Asserts the aligned/escalate/unassessed
# decision rule, the fail-safe paths, the invocation opt-in, and that no hook
# ever references the screen. Covers the pre-screen ACs in qa/cli/conformance.md.
#
# No real network call ever happens: `jev` is either the stub or absent.
#
# Usage: ./engineering/apps/cli/tests/conformance/test-jev-alignment.sh

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../../../.." && pwd)"
SCREEN="$REPO_ROOT/scripts/alignment-check.sh"

# shellcheck source=../code-mapping/lib/assert.sh
source "$REPO_ROOT/engineering/apps/cli/tests/code-mapping/lib/assert.sh"

STUB_DIR="$(mktemp -d)"
cat > "$STUB_DIR/jev" <<'STUB'
#!/usr/bin/env bash
[ -n "${JEV_STUB_LOG:-}" ] && echo "call" >> "$JEV_STUB_LOG"
case "${JEV_STUB_MODE:-error}" in
  error) exit 1 ;;
  *) printf '{"answers":{"choice":{"choice":"%s","confidence":%s}}}' "${JEV_STUB_MODE%%@*}" "${JEV_STUB_MODE##*@}" ;;
esac
STUB
chmod +x "$STUB_DIR/jev"

cleanup() { rm -rf "$STUB_DIR"; }
trap cleanup EXIT

new_fixture() {
  local root; root="$(mktemp -d)"
  ( cd "$root" && git init -q && git config user.email t@t.co && git config user.name t )
  mkdir -p "$root/product" "$root/code"
  cat > "$root/product/x.md" <<'EOF'
# X
- **Do the thing** `FR-x-do-thing`: The tool writes the output file before printing done.
- **Fail loudly** `FR-x-fail-loud`: The tool exits 1 when the output file is missing.
EOF
  cat > "$root/code/code.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
write_out() {
  printf 'done' > out.txt
  echo "done"
}
main() {
  if [ ! -f out.txt ]; then
    exit 1
  fi
  write_out
}
EOF
  cat > "$root/index.md" <<'EOF'
# Traceability Index

| Slug | Type | Defined In | Referenced In | Code |
|------|------|------------|---------------|------|
| FR-x-do-thing | FR | product/x.md | engineering/cli/x.md | code/code.sh:5 |
| FR-x-fail-loud | FR | product/x.md | engineering/cli/x.md | code/code.sh:10 |
EOF
  echo "$root"
}

# run_screen <root> <stub-mode|none> [feature-arg]
run_screen() {
  local root="$1" mode="$2" feature="${3:-}"
  (
    cd "$root" || exit 9
    if [ "$mode" = "none" ]; then
      export PATH="/usr/bin:/bin"
    else
      export PATH="$STUB_DIR:$PATH"
      export JEV_STUB_MODE="$mode"
      export JEV_STUB_LOG="$root/jev-calls.log"
      : > "$JEV_STUB_LOG"
    fi
    "$SCREEN" $feature 2>&1
  )
}

call_count() { [ -f "$1/jev-calls.log" ] && wc -l < "$1/jev-calls.log" | tr -d ' ' || echo 0; }

# ── Aligned: high confidence passes quietly ────────────────────────────────
test_aligned_passes() {
  local root out code calls
  root="$(new_fixture)"
  out="$(run_screen "$root" "aligned@0.95")"; code=$?; calls="$(call_count "$root")"; rm -rf "$root"
  assert_exit_code 0 "$code" "aligned: exit 0 with no escalation" || return 1
  assert_contains "$out" "✓ aligned" "aligned: ✓ line present" || return 1
  assert_contains "$out" "FR-x-do-thing" "aligned: slug named" || return 1
  assert_contains "$out" "code/code.sh:5" "aligned: evidence location cited" || return 1
  assert_not_contains "$out" "⚠" "aligned: nothing escalated" || return 1
  assert_contains "$out" "2 aligned, 0 escalated, 0 unassessed" "aligned: summary counts" || return 1
  assert_eq "2" "$calls" "aligned: one jev call per slice" || return 1
}

# ── Drift: escalates despite the fixture's valid markers ───────────────────
test_drift_escalates() {
  local root out code
  root="$(new_fixture)"
  out="$(run_screen "$root" "drift@0.95")"; code=$?; rm -rf "$root"
  assert_exit_code 1 "$code" "drift: exit 1 report signal" || return 1
  assert_contains "$out" "⚠ drift" "drift: escalated line present" || return 1
  assert_contains "$out" "escalate to /pdeq-conform" "drift: escalation path named" || return 1
  assert_not_contains "$out" "✓ aligned" "drift: nothing passes" || return 1
}

# ── Low confidence: unassessed, never passes ───────────────────────────────
test_low_confidence_unassessed() {
  local root out code
  for mode in "aligned@0.40" "drift@0.40"; do
    root="$(new_fixture)"
    out="$(run_screen "$root" "$mode")"; code=$?; rm -rf "$root"
    assert_exit_code 0 "$code" "low-conf($mode): no escalation, exit 0" || return 1
    assert_contains "$out" "? unassessed" "low-conf($mode): reported unassessed" || return 1
    assert_not_contains "$out" "✓ aligned" "low-conf($mode): nothing passes" || return 1
    assert_not_contains "$out" "⚠" "low-conf($mode): nothing escalates on a guess" || return 1
  done
}

# ── Service error: unassessed, no traceback ────────────────────────────────
test_service_error_unassessed() {
  local root out code
  root="$(new_fixture)"
  out="$(run_screen "$root" "error")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "error: unassessed is not drift, exit 0" || return 1
  assert_contains "$out" "? unassessed" "error: slices unassessed" || return 1
  assert_not_contains "$out" "✓ aligned" "error: nothing passes" || return 1
  assert_not_contains "$out" "Traceback" "error: no traceback leaked" || return 1
}

# ── Fail-safe: jev absent ────────────────────────────────────────────────────────
test_jev_missing_unassessed() {
  local root out code
  root="$(new_fixture)"
  out="$(run_screen "$root" "none")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "missing: behaves as unassessed" || return 1
  assert_contains "$out" "? unassessed" "missing: slices unassessed" || return 1
  assert_not_contains "$out" "✓ aligned" "missing: nothing passes" || return 1
}

# ── Threshold boundary: inclusive at 0.85 ──────────────────────────────────
test_threshold_boundary() {
  local root out code
  root="$(new_fixture)"
  out="$(run_screen "$root" "aligned@0.84")"; code=$?; rm -rf "$root"
  assert_not_contains "$out" "✓ aligned" "threshold: 0.84 does not pass" || return 1

  root="$(new_fixture)"
  out="$(run_screen "$root" "aligned@0.85")"; code=$?; rm -rf "$root"
  assert_exit_code 0 "$code" "threshold: 0.85 passes" || return 1
  assert_contains "$out" "✓ aligned" "threshold: 0.85 shows ✓" || return 1
}

# ── Feature filter narrows scope ───────────────────────────────────────────
test_feature_filter() {
  local root out calls
  root="$(new_fixture)"
  out="$(run_screen "$root" "aligned@0.95" "y")"
  calls="$(call_count "$root")"; rm -rf "$root"
  assert_contains "$out" "nothing to screen" "filter: unknown feature screens nothing" || return 1
  assert_eq "0" "$calls" "filter: no calls for out-of-scope feature" || return 1
}

# ── No default-path calls: no hook references the screen ───────────────────
test_no_hook_reference() {
  local hits
  hits="$(grep -rl "alignment-check" "$REPO_ROOT/hooks" 2>/dev/null || true)"
  assert_eq "" "$hits" "opt-in: no hook invokes the screen" || return 1
}

# ── Runner ─────────────────────────────────────────────────────────────────
tests=(
  test_aligned_passes
  test_drift_escalates
  test_low_confidence_unassessed
  test_service_error_unassessed
  test_jev_missing_unassessed
  test_threshold_boundary
  test_feature_filter
  test_no_hook_reference
)
pass=0; fail=0
for t in "${tests[@]}"; do
  if "$t"; then
    echo "PASS: $t"; pass=$((pass+1))
  else
    echo "FAIL: $t"; fail=$((fail+1))
  fi
done
echo "jev-alignment: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
