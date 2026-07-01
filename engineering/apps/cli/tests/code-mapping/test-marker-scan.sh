#!/usr/bin/env bash
# Tests for the marker scan phase: TC-code-mapping-marker-matches,
# TC-code-mapping-multi-slug, TC-code-mapping-scan-finds-markers,
# TC-code-mapping-orphan-blocks, TC-code-mapping-near-match-ignored,
# TC-code-mapping-grep-fallback-correctness.
# Sourced by run-all.sh — do not execute directly.

test_marker_matches() {
  local f
  f=$(make_fixture)
  seed_product_spec "$f" "x" "FR-x-one"
  seed_index "$f" "FR-x-one"
  seed_marker "$f" "src/main.ts" "FR-x-one"
  local out
  out=$(run_audit "$f")
  assert_contains "$out" "All traceability checks passed" "marker matches FR-x-one"
  assert_index_code_column "FR-x-one" "src/main.ts:1" "$f/index.md"
}

test_multi_slug_marker() {
  local f
  f=$(make_fixture)
  seed_product_spec "$f" "x" "FR-x-one" "FR-x-two"
  seed_index "$f" "FR-x-one" "FR-x-two"
  mkdir -p "$f/src"
  echo "// Implements: FR-x-one, FR-x-two" > "$f/src/main.ts"
  run_audit "$f" > /dev/null
  assert_index_code_column "FR-x-one" "src/main.ts:1" "$f/index.md"
  assert_index_code_column "FR-x-two" "src/main.ts:1" "$f/index.md"
}

test_grep_fallback_no_orphan_pollution() {
  # Regression (TC-code-mapping-grep-fallback-correctness): when ripgrep is unavailable
  # the scanner falls back to grep. It used to print its "ripgrep not found"
  # warning to STDOUT — the same stream that carries the marker TSV — so the
  # warning was parsed as a marker row (empty file/line) and reported as a bogus
  # "orphan marker at ::", blocking commits for any consumer without rg.
  # PDEQ_FORCE_GREP forces the fallback so this is deterministic on any host.
  local f
  f=$(make_fixture)
  seed_product_spec "$f" "x" "FR-x-one"
  seed_index "$f" "FR-x-one"
  seed_marker "$f" "src/main.ts" "FR-x-one"

  # Combined stream must carry no bogus orphan for an otherwise-valid fixture.
  local out
  out=$(PDEQ_FORCE_GREP=1 run_audit "$f" || true)
  assert_not_contains "$out" "orphan marker" "grep fallback emits no bogus orphan"

  # And the diagnostic must be on stderr, not the captured stdout data stream.
  local stdout_only
  stdout_only=$(cd "$f" && PDEQ_CONFIG_PATH="$f/pdeq.json" PDEQ_FORCE_GREP=1 \
    "$PDEQ_REPO_ROOT/scripts/audit-traceability.sh" --check 2>/dev/null || true)
  assert_not_contains "$stdout_only" "ripgrep not found" "rg warning stays off stdout"
}

test_orphan_marker_blocks() {
  local f
  f=$(make_fixture)
  seed_product_spec "$f" "x" "FR-x-one"
  seed_index "$f" "FR-x-one"
  seed_marker "$f" "src/main.ts" "FR-x-bogus"
  local out status
  out=$(run_audit "$f" || true)
  status=$?
  assert_contains "$out" "orphan marker" "orphan surfaced"
  assert_contains "$out" "FR-x-bogus" "orphan names slug"
}

test_near_match_ignored() {
  local f
  f=$(make_fixture)
  seed_product_spec "$f" "x" "FR-x-one"
  seed_index "$f" "FR-x-one"
  # Contains the slug-prefix but not a complete marker; should not count.
  mkdir -p "$f/src"
  cat > "$f/src/prose.md" << 'MD'
# Notes

The FR- prefix means something. This is not a marker: FR-x.
MD
  local out
  out=$(run_audit "$f" 2>&1 || true)
  # FR-x-one should remain uncovered (grace warning OK since no git history)
  assert_not_contains "$out" "orphan marker" "no orphan emitted for prose"
}
