#!/usr/bin/env bash
# Bundle-completeness tests: single-pass sections, slug inventory, index rows,
# code map, current code state, TC inclusion, determinism, nothing-persisted.
# Implements: TC-implement-single-pass, TC-implement-bundle-sections,
#             TC-implement-slug-inventory, TC-implement-index-rows,
#             TC-implement-code-map, TC-implement-current-code,
#             TC-implement-current-code-absent, TC-implement-tc-included,
#             TC-implement-determinism, TC-implement-context-not-persisted

source "$(dirname "$0")/lib/assert.sh"
source "$(dirname "$0")/lib/fixture.sh"

test_single_pass_all_sections() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/widget.ts:planned"
  seed_index_row "$fx" "FR-ex-widget-x" "product/widget.md" "src/widget.ts:10"
  seed_code_file "$fx" "src/widget.ts" "export function widget() { return 1; }"
  commit_fixture "$fx" "feature: add widget"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "## Changed spec files" "section present"
  assert_contains "$out" "## In-scope slugs" "section present"
  assert_contains "$out" "## Spec contents" "section present"
  assert_contains "$out" "## Index rows" "section present"
  assert_contains "$out" "## Code map" "section present"
  assert_contains "$out" "## Current code state" "section present"
}

test_slug_inventory_sorted() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-zzz" "FR-ex-widget-aaa"
  commit_fixture "$fx" "feature: add widget slugs"
  local out
  out=$(run_context "$fx")
  # aaa should appear before zzz (ascending byte order)
  local aaa_idx zzz_idx
  aaa_idx=$(printf '%s\n' "$out" | grep -n 'FR-ex-widget-aaa' | head -1 | cut -d: -f1)
  zzz_idx=$(printf '%s\n' "$out" | grep -n 'FR-ex-widget-zzz' | head -1 | cut -d: -f1)
  [ -n "$aaa_idx" ] && [ -n "$zzz_idx" ] || { echo "  FAIL: slugs not found" >&2; return 1; }
  [ "$aaa_idx" -lt "$zzz_idx" ] || { echo "  FAIL: slugs not sorted ascending" >&2; return 1; }
}

test_index_rows_present() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_index_row "$fx" "FR-ex-widget-x" "product/widget.md" "src/widget.ts:10"
  commit_fixture "$fx" "feature: add widget"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "| FR-ex-widget-x |" "index row present"
  assert_contains "$out" "src/widget.ts:10" "index code column present"
}

test_code_map_rows_present() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/widget.ts:planned"
  commit_fixture "$fx" "feature: add widget"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "| FR-ex-widget-x | src/widget.ts | planned |" "code map row present"
}

test_current_code_state_included() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/widget.ts:planned"
  seed_index_row "$fx" "FR-ex-widget-x" "product/widget.md" "src/widget.ts:10"
  seed_code_file "$fx" "src/widget.ts" "export function widget() { return 1; }"
  git -C "$fx" add -A
  git -C "$fx" commit -qm "feature: add widget + code"
  # uncommitted edit to the code file
  seed_code_file "$fx" "src/widget.ts" "export function widget() { return 2; }"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "### src/widget.ts" "code file header present"
  assert_contains "$out" "return 2" "current code state (diff) present"
}

test_current_code_absent_noted() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/future.ts:planned"
  commit_fixture "$fx" "feature: add widget (planned code absent)"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "### src/future.ts" "planned code file header present"
  assert_contains "$out" "planned, not yet present" "absent code noted"
}

test_tc_slugs_included() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_qa_spec "$fx" widget "TC-ex-widget-happy"
  commit_fixture "$fx" "feature: add widget with QA spec"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "TC-ex-widget-happy" "TC slug in inventory"
}

test_determinism_identical_runs() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/widget.ts:planned"
  seed_index_row "$fx" "FR-ex-widget-x" "product/widget.md" "src/widget.ts:10"
  commit_fixture "$fx" "feature: add widget"
  local r1 r2
  r1=$(run_context "$fx")
  r2=$(run_context "$fx")
  assert_eq "$r1" "$r2" "deterministic output"
}

test_context_not_persisted() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  commit_fixture "$fx" "feature: add widget"
  local before_hash
  before_hash=$(git -C "$fx" status --porcelain | wc -l | tr -d ' ')
  run_context "$fx" >/dev/null 2>&1 || true
  local after_hash
  after_hash=$(git -C "$fx" status --porcelain | wc -l | tr -d ' ')
  assert_eq "$before_hash" "$after_hash" "no files written by script"
}
