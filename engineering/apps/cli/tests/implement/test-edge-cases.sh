#!/usr/bin/env bash
# Edge-case tests: missing main, bad base, missing index, fallback no-match.
# Implements: TC-implement-missing-main, TC-implement-bad-base,
#             TC-implement-missing-index, TC-implement-fallback-no-match

source "$(dirname "$0")/lib/assert.sh"
source "$(dirname "$0")/lib/fixture.sh"

test_bad_base_ref() {
  local fx
  fx=$(make_implement_fixture)
  set +e
  out=$(run_context "$fx" --base notarealref 2>&1)
  rc=$?
  set -e
  assert_eq "1" "$rc" "bad base exits 1"
  assert_contains "$out" "unknown base ref" "bad base message"
}

test_fallback_no_matching_spec() {
  local fx
  fx=$(make_implement_fixture)
  set +e
  out=$(run_context "$fx" --base HEAD nonexistent 2>&1)
  rc=$?
  set -e
  assert_eq "1" "$rc" "missing feature exits 1"
  assert_contains "$out" "no spec found for feature 'nonexistent'" "missing feature message"
}

test_missing_index_warns_not_fails() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  commit_fixture "$fx" "feature: add widget"
  rm "$fx/index.md"
  set +e
  out=$(run_context "$fx" 2>&1)
  rc=$?
  set -e
  assert_eq "0" "$rc" "missing index exits 0"
  assert_contains "$out" "index.md not found" "missing index warning"
  assert_contains "$out" "(index.md not present)" "empty index-rows section"
}

test_empty_spec_crashes_no_more() {
  # bash 3.2 regression guard: a prose-only spec edit (zero slugs) must not
  # crash under set -u. This is the critical-fix case from review.
  local fx
  fx=$(make_implement_fixture)
  # edit the baseline product spec with no slugs
  cat > "$fx/product/widget.md" <<'MD'
# Widget

Just prose. No requirements defined here.
MD
  commit_fixture "$fx" "feature: prose-only edit"
  set +e
  out=$(run_context "$fx" 2>&1)
  rc=$?
  set -e
  assert_eq "0" "$rc" "zero-slug spec change exits 0"
  assert_contains "$out" "scope=spec-diff" "scope still derived"
}

test_qa_only_no_fr_crashes_no_more() {
  # bash 3.2 regression guard: a QA-only spec change yields only TC- slugs,
  # leaving FR_SLUGS empty. Must not crash.
  local fx
  fx=$(make_implement_fixture)
  seed_qa_spec "$fx" widget "TC-ex-widget-happy"
  commit_fixture "$fx" "feature: QA-only spec change"
  set +e
  out=$(run_context "$fx" 2>&1)
  rc=$?
  set -e
  assert_eq "0" "$rc" "QA-only change exits 0"
  assert_contains "$out" "TC-ex-widget-happy" "TC slug in scope"
  assert_contains "$out" "(no Code Map rows for in-scope FRs)" "empty FR_SLUGS handled"
}
