#!/usr/bin/env bash
# Scope-derivation tests: no-arg, default-base, base options, fallback.
# Implements: TC-implement-no-arg-scope, TC-implement-default-base, TC-implement-base-head,
#             TC-implement-base-explicit, TC-implement-fallback-feature,
#             TC-implement-fallback-slug, TC-implement-empty-scope

source "$(dirname "$0")/lib/assert.sh"
source "$(dirname "$0")/lib/fixture.sh"

test_no_arg_scope_from_spec_changes() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  seed_engineering_spec "$fx" widget "FR-ex-widget-x:src/widget.ts:planned"
  commit_fixture "$fx" "feature: add widget FR"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "scope=spec-diff" "no-arg derives spec-diff scope"
  assert_contains "$out" "FR-ex-widget-x" "in-scope slug present"
  assert_contains "$out" "product/widget.md" "changed spec file listed"
}

test_default_base_is_branch_point() {
  local fx
  fx=$(make_implement_fixture)
  # spec change committed on main AFTER the branch point should be excluded
  git -C "$fx" checkout -q main
  seed_product_spec "$fx" baseline "FR-ex-baseline-only"
  commit_fixture "$fx" "main: add baseline FR after branch point"
  git -C "$fx" checkout -q feature
  seed_product_spec "$fx" widget "FR-ex-widget-x"
  commit_fixture "$fx" "feature: add widget FR"
  local out
  out=$(run_context "$fx")
  assert_contains "$out" "FR-ex-widget-x" "branch-side change in scope"
  assert_not_contains "$out" "FR-ex-baseline-only" "pre-branch main change excluded"
}

test_base_head_restricts_to_uncommitted() {
  local fx
  fx=$(make_implement_fixture)
  # committed spec change in one file
  seed_product_spec "$fx" committed "FR-ex-widget-committed"
  commit_fixture "$fx" "feature: committed spec change"
  # uncommitted edit in a DIFFERENT file (file-level over-inclusion means
  # all slugs in a changed file are in scope, so the two must be in separate
  # files to distinguish base scope)
  cat > "$fx/product/uncommitted.md" <<'MD'
# Uncommitted

## Requirements

- **Placeholder** `FR-ex-widget-uncommitted`: placeholder.
MD
  local out
  out=$(run_context "$fx" --base HEAD)
  assert_contains "$out" "FR-ex-widget-uncommitted" "uncommitted file in HEAD scope"
  assert_not_contains "$out" "FR-ex-widget-committed" "committed-only file excluded from HEAD scope"
}

test_base_working_alias() {
  local fx
  fx=$(make_implement_fixture)
  cat > "$fx/product/uncommitted.md" <<'MD'
# Uncommitted

## Requirements

- **Placeholder** `FR-ex-widget-uncommitted`: placeholder.
MD
  local head_out working_out
  head_out=$(run_context "$fx" --base HEAD)
  working_out=$(run_context "$fx" --base working)
  assert_eq "$head_out" "$working_out" "working == HEAD"
}

test_base_explicit_ref() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" widget "FR-ex-widget-a"
  commit_fixture "$fx" "feature: change A"
  local tag_ref
  tag_ref=$(git -C "$fx" rev-parse HEAD)
  seed_product_spec "$fx" widget "FR-ex-widget-a" "FR-ex-widget-b"
  commit_fixture "$fx" "feature: change B"
  local out
  out=$(run_context "$fx" --base "$tag_ref")
  assert_contains "$out" "FR-ex-widget-b" "change since explicit base in scope"
}

test_fallback_scope_by_feature() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" auth "FR-ex-auth-email-login"
  seed_engineering_spec "$fx" auth "FR-ex-auth-email-login:src/auth.ts:planned"
  seed_qa_spec "$fx" auth "TC-ex-auth-login-happy"
  commit_fixture "$fx" "feature: add auth (no spec diff vs base will use fallback)"
  # Use --base HEAD so there's no spec diff, forcing fallback
  local out
  out=$(run_context "$fx" --base HEAD auth)
  assert_contains "$out" "scope=fallback" "fallback scope source"
  assert_contains "$out" "FR-ex-auth-email-login" "fallback feature slug in scope"
  assert_contains "$out" "product/auth.md" "fallback feature product spec included"
  assert_contains "$out" "engineering/cli/auth.md" "fallback feature engineering spec included"
}

test_fallback_scope_by_slug() {
  local fx
  fx=$(make_implement_fixture)
  seed_product_spec "$fx" auth "FR-ex-auth-email-login"
  seed_engineering_spec "$fx" auth "FR-ex-auth-email-login:src/auth.ts:planned"
  commit_fixture "$fx" "feature: add auth"
  local out
  out=$(run_context "$fx" --base HEAD FR-ex-auth-email-login)
  assert_contains "$out" "scope=fallback" "slug fallback scope source"
  assert_contains "$out" "FR-ex-auth-email-login" "slug resolved"
  assert_contains "$out" "product/auth.md" "slug resolved to correct feature"
}

test_empty_scope_exits_cleanly() {
  local fx
  fx=$(make_implement_fixture)
  local out rc
  set +e
  out=$(run_context "$fx" --base HEAD 2>&1)
  rc=$?
  set -e
  assert_eq "0" "$rc" "empty scope exits 0"
  assert_contains "$out" "nothing to implement" "empty scope message"
}
