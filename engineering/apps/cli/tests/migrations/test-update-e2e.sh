#!/usr/bin/env bash
# Full-flow E2E for /pdeq-update against a REAL `.pdeq` submodule. This is the
# [auto] shell layer of the upgrade-entrypoint TCs: it runs the actual
# orchestrator sequence — `git submodule update --remote --force .pdeq` (the
# bump), `sync-symlinks.sh --prune --json` (in-session reconciliation), and the
# `migrate.sh list-pending` / `bump` loop — and asserts on filesystem + version
# state. The agent chain prompt and surface-output regex are the [semi-auto] /
# [manual] companions and are not exercised here.
#
# Covers (shell-state half): TC-migrations-update-happy, TC-migrations-update-decline-chain,
# TC-migrations-update-symlink-prune, TC-migrations-update-in-session-new-command.

set -euo pipefail

# Accept path: bump advances the pin to 0.4.0, reconciliation creates the newly
# shipped command and prunes the one removed in 0.4.0, the pending set is the
# three breaking versions, and applying them advances recorded to the pin.
# TC-migrations-update-happy / TC-migrations-update-symlink-prune / TC-migrations-update-in-session-new-command
test_update_e2e_happy() {
  local fx; fx=$(make_submodule_fixture)
  local pre post
  pre=$(git -C "$fx/.pdeq" rev-parse HEAD)
  assert_eq "0.2.1" "$(cat "$fx/.pdeq/VERSION")" "pre-bump pinned VERSION"

  # Step 1 — the bump.
  git_sub "$fx" submodule update --remote --force .pdeq >/dev/null 2>&1
  post=$(git -C "$fx/.pdeq" rev-parse HEAD)
  assert_eq "0.4.0" "$(cat "$fx/.pdeq/VERSION")" "post-bump pinned VERSION"
  if [ "$pre" = "$post" ]; then
    echo "  FAIL: pin SHA did not advance" >&2; rm -rf "$(dirname "$fx")"; return 1
  fi

  # Step 2 — in-session symlink reconciliation.
  local json; json=$(run_sync "$fx" --prune --json)
  assert_contains "$json" '".claude/commands/pdeq-update.md"' "new command in created[]"
  assert_contains "$json" '".claude/commands/pdeq-legacy.md"' "removed command in deleted[]"
  assert_file_exists "$fx/.claude/commands/pdeq-update.md"
  assert_eq "# update" "$(cat "$fx/.claude/commands/pdeq-update.md")" "new command resolves to bumped source"
  if [ -e "$fx/.claude/commands/pdeq-legacy.md" ]; then
    echo "  FAIL: dangling legacy symlink not pruned" >&2; rm -rf "$(dirname "$fx")"; return 1
  fi
  if [ ! -L "$fx/.claude/commands/pdeq-kickoff.md" ]; then
    echo "  FAIL: surviving command symlink was dropped" >&2; rm -rf "$(dirname "$fx")"; return 1
  fi

  # Step 4 — pending detection against the advanced pin.
  assert_eq $'0.3.0\n0.3.2\n0.4.0' "$(run_migrate "$fx" list-pending)" "pending set after bump"

  # Step 5 (accept) — the chained migrate loop advances recorded to the pin.
  run_migrate "$fx" bump 0.3.0 >/dev/null
  run_migrate "$fx" bump 0.3.2 >/dev/null
  run_migrate "$fx" bump 0.4.0 >/dev/null
  assert_eq "0.4.0" "$(run_migrate "$fx" recorded)" "recorded advanced to pin"
  assert_eq "" "$(run_migrate "$fx" list-pending)" "nothing pending after accept"

  rm -rf "$(dirname "$fx")"
}

# Decline path: after the bump the consumer answers `n`, so no `bump` runs. The
# pin stays advanced but recorded stays at 0.2.1 with the full pending set
# intact — and a later plain `/pdeq-migrate` (the bump loop) resolves it with no
# recovery flag.
# TC-migrations-update-decline-chain
test_update_e2e_decline() {
  local fx; fx=$(make_submodule_fixture)
  git_sub "$fx" submodule update --remote --force .pdeq >/dev/null 2>&1
  run_sync "$fx" --prune --json >/dev/null   # reconciliation still happens in the bump phase

  # Decline → no bump invoked.
  assert_eq "0.4.0" "$(cat "$fx/.pdeq/VERSION")" "pin advanced even on decline"
  assert_eq "0.2.1" "$(run_migrate "$fx" recorded)" "recorded unchanged on decline"
  assert_eq $'0.3.0\n0.3.2\n0.4.0' "$(run_migrate "$fx" list-pending)" "full pending set survives decline"

  # Later /pdeq-migrate converges without --from or any recovery affordance.
  run_migrate "$fx" bump 0.3.0 >/dev/null
  run_migrate "$fx" bump 0.3.2 >/dev/null
  run_migrate "$fx" bump 0.4.0 >/dev/null
  assert_eq "0.4.0" "$(run_migrate "$fx" recorded)" "follow-up migrate converges recorded to pin"
  assert_eq "" "$(run_migrate "$fx" list-pending)" "nothing pending after recovery"

  rm -rf "$(dirname "$fx")"
}
