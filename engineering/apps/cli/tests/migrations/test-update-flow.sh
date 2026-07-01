#!/usr/bin/env bash
# Tests for the /pdeq-update version-math flow, exercised through the shell
# helpers the orchestrator drives after the bump: migrate.sh list-pending and
# migrate.sh bump.
#
# The submodule bump itself (`git submodule update --remote --force .pdeq`) is
# git's behavior and is covered by the [semi-auto] companion; here we simulate
# the post-bump working tree (pin advanced + migration files present, recorded
# not yet moved) and assert the recorded-version transitions for the accept,
# decline, and no-op paths.
#
# Covers: TC-migrations-update-noop-current, and the filesystem-state half of
# TC-migrations-update-happy (accept) / TC-migrations-update-decline-chain.

set -euo pipefail

# Build a fixture in the "just bumped, not yet migrated" state: pin 0.4.0 with
# three pending migration files, recorded still 0.2.1.
_bumped_fixture() {
  local fx; fx=$(make_consumer_fixture claude)
  set_pinned "$fx" "0.4.0"
  add_migration "$fx" "0.3.0"
  add_migration "$fx" "0.3.2"
  add_migration "$fx" "0.4.0"
  echo "$fx"
}

# After the bump, the pending set is exactly the migrations in (recorded, pinned],
# ascending. This is what the chain prompt summarizes ("3 migrations pending: …").
# TC-migrations-update-happy
test_update_pending_set_after_bump() {
  local fx; fx=$(_bumped_fixture)
  local pending; pending=$(run_migrate "$fx" list-pending)
  assert_eq $'0.3.0\n0.3.2\n0.4.0' "$pending" "pending set ascending"
  rm -rf "$fx"
}

# Accept path: the chained migration loop bumps recorded forward to each applied
# version. Once it reaches the pin, list-pending is empty — the project is fully
# migrated.
# TC-migrations-update-happy
test_update_accept_advances_recorded() {
  local fx; fx=$(_bumped_fixture)
  # Simulate the chained loop applying each migration in order.
  run_migrate "$fx" bump 0.3.0 >/dev/null
  run_migrate "$fx" bump 0.3.2 >/dev/null
  run_migrate "$fx" bump 0.4.0 >/dev/null
  assert_eq "0.4.0" "$(run_migrate "$fx" recorded)" "recorded advanced to pin"
  assert_eq "" "$(run_migrate "$fx" list-pending)" "no migrations pending after accept"
  rm -rf "$fx"
}

# Decline path: the consumer answers `n`, so NO bump runs. The pin stays advanced
# (0.4.0) but recorded stays at 0.2.1, and the full pending set remains — a later
# /pdeq-migrate resolves it with no recovery flag.
# TC-migrations-update-decline-chain
test_update_decline_leaves_recorded() {
  local fx; fx=$(_bumped_fixture)
  # No bump is invoked on decline.
  assert_eq "0.2.1" "$(run_migrate "$fx" recorded)" "recorded unchanged on decline"
  assert_eq "0.4.0" "$(run_migrate "$fx" pinned)" "pin stayed advanced on decline"
  assert_eq $'0.3.0\n0.3.2\n0.4.0' "$(run_migrate "$fx" list-pending)" \
            "full pending set survives decline (recoverable via /pdeq-migrate)"
  rm -rf "$fx"
}

# No-op path: recorded already equals pin, so there is nothing pending and the
# chain prompt is skipped entirely.
# TC-migrations-update-noop-current
test_update_noop_when_current() {
  local fx; fx=$(make_consumer_fixture claude)
  set_pinned "$fx" "0.4.0"
  set_recorded "$fx" "0.4.0"
  add_migration "$fx" "0.3.0"
  add_migration "$fx" "0.4.0"
  assert_eq "" "$(run_migrate "$fx" list-pending)" "nothing pending when recorded == pin"
  rm -rf "$fx"
}
