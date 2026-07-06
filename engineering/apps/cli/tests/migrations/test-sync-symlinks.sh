#!/usr/bin/env bash
# Tests for scripts/sync-symlinks.sh — the in-session symlink reconciliation
# that /pdeq-update runs (as `sync-symlinks.sh --prune --json`) right after the
# submodule bump. Verifies FR-migrations-update-in-session.
#
# Covers: TC-migrations-update-in-session-new-command, TC-migrations-update-symlink-prune
#
# Sourced by run-all.sh; relies on assert.sh + fixture.sh helpers and on the
# PDEQ_REPO_ROOT export. Each test runs in a subshell with its own fixture.

set -euo pipefail

# A newly-shipped command in the bumped submodule becomes invocable mid-session:
# sync-symlinks creates the managed symlink and --json reports it as created.
# TC-migrations-update-in-session-new-command
test_sync_creates_new_command() {
  local fx; fx=$(make_consumer_fixture claude)
  add_pdeq_command "$fx" "pdeq-update.md"
  local out; out=$(run_sync "$fx" --prune --json)

  assert_contains "$out" '".claude/commands/pdeq-update.md"' "new command in created[]"
  assert_file_exists "$fx/.claude/commands/pdeq-update.md"
  # The symlink must resolve to the submodule source.
  assert_eq "$(cat "$fx/.pdeq/pdeq-rules/commands/pdeq-update.md")" \
            "$(cat "$fx/.claude/commands/pdeq-update.md")" "symlink resolves to source"
  rm -rf "$fx"
}

# A managed symlink whose target was removed in the new pdeq version is deleted
# by --prune and reported in deleted[].
# TC-migrations-update-symlink-prune
test_sync_prune_removes_stale() {
  local fx; fx=$(make_consumer_fixture claude)
  mkdir -p "$fx/.claude/commands"
  ln -s "../../.pdeq/pdeq-rules/commands/pdeq-gone.md" "$fx/.claude/commands/pdeq-gone.md"
  local out; out=$(run_sync "$fx" --prune --json)

  assert_contains "$out" '".claude/commands/pdeq-gone.md"' "stale link in deleted[]"
  if [ -L "$fx/.claude/commands/pdeq-gone.md" ]; then
    echo "  FAIL: stale symlink was not pruned" >&2; rm -rf "$fx"; return 1
  fi
  rm -rf "$fx"
}

# Regression: in --json mode the script must run to completion and emit valid
# JSON. A prior version's note_* helpers ended in `[[ … ]] && printf`, returning
# 1 under set -e when JSON suppressed the printf, aborting on the first file.
# TC-migrations-update-in-session-new-command
test_sync_json_mode_completes() {
  local fx; fx=$(make_consumer_fixture claude)
  add_pdeq_command "$fx" "pdeq-status.md"
  printf 'echo helper\n' > "$fx/.pdeq/scripts/helper.sh"
  local out rc
  set +e
  out=$(run_sync "$fx" --prune --json); rc=$?
  set -e
  assert_exit_code 0 "$rc" "sync --json exits clean"
  # Exactly one JSON object on stdout, with both keys, no error text.
  assert_contains "$out" '{"created":' "json has created key"
  assert_contains "$out" '"deleted":' "json has deleted key"
  assert_not_contains "$out" "unbound" "no shell error leaked"
  rm -rf "$fx"
}

# Symlinks the consumer authored that do NOT point into .pdeq/ must survive
# --prune untouched.
# TC-migrations-update-symlink-prune
test_sync_preserves_consumer_symlinks() {
  local fx; fx=$(make_consumer_fixture claude)
  mkdir -p "$fx/.claude/commands"
  ln -s "/dev/null" "$fx/.claude/commands/my-own.md"
  run_sync "$fx" --prune --json >/dev/null
  if [ ! -L "$fx/.claude/commands/my-own.md" ]; then
    echo "  FAIL: consumer-owned symlink was pruned" >&2; rm -rf "$fx"; return 1
  fi
  rm -rf "$fx"
}

# A second sync is a no-op: nothing created or deleted when already in sync.
# TC-migrations-update-in-session-new-command
test_sync_idempotent() {
  local fx; fx=$(make_consumer_fixture claude)
  add_pdeq_command "$fx" "pdeq-impact.md"
  run_sync "$fx" --prune --json >/dev/null          # first sync creates the link
  local out; out=$(run_sync "$fx" --prune --json)    # second sync
  assert_contains "$out" '{"created":[],"deleted":[]}' "second sync is a no-op"
  rm -rf "$fx"
}

# Harness parity: a command-less harness (codex at v1) gets NO command symlinks —
# harness_commands_dir is empty, so the per-harness commands loop skips it — but
# scripts/ is still synced unconditionally. The command source is picked up by
# the agent reading the prompt file directly, so no commands dir is created.
_assert_no_command_symlinks() {
  local harness="$1"
  local fx; fx=$(make_consumer_fixture "$harness")
  add_pdeq_command "$fx" "pdeq-update.md"
  printf 'echo hi\n' > "$fx/.pdeq/scripts/helper.sh"
  local out; out=$(run_sync "$fx" --prune --json)
  # scripts still synced...
  assert_contains "$out" '"scripts/helper.sh"' "$harness: scripts synced"
  # ...but no command symlink surface.
  assert_not_contains "$out" '.claude/commands' "$harness: no command symlink in report"
  if [ -e "$fx/.claude/commands/pdeq-update.md" ]; then
    echo "  FAIL: $harness got a .claude/commands symlink it should not have" >&2
    rm -rf "$fx"; return 1
  fi
  rm -rf "$fx"
}

# TC-migrations-update-in-session-new-command
test_sync_codex_no_command_symlinks() { _assert_no_command_symlinks codex; }

# Pi reads markdown prompt templates from .pi/prompts/, so a pi consumer DOES get
# a command symlink surface — one .pi/prompts/pdeq-*.md per command source.
# TC-migrations-update-in-session-new-command
test_sync_pi_command_symlinks() {
  local fx; fx=$(make_consumer_fixture pi)
  add_pdeq_command "$fx" "pdeq-update.md"
  local out; out=$(run_sync "$fx" --prune --json)
  assert_contains "$out" '.pi/prompts/pdeq-update.md' "pi: command symlink in report"
  if [ ! -L "$fx/.pi/prompts/pdeq-update.md" ]; then
    echo "  FAIL: pi did not get its .pi/prompts symlink" >&2
    rm -rf "$fx"; return 1
  fi
  # And nothing leaks into .claude/commands.
  assert_not_contains "$out" '.claude/commands' "pi: no claude command dir"
  rm -rf "$fx"
}
