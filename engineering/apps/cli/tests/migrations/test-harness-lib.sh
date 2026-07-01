#!/usr/bin/env bash
# Unit tests for scripts/lib/harness.sh — the single-source-of-truth harness
# adapter. Asserts each capability function for every v1 harness plus the
# unknown-harness path.

set -euo pipefail

# shellcheck source=/dev/null
source "$PDEQ_REPO_ROOT/scripts/lib/harness.sh"

test_harness_agent_file() {
  assert_eq "CLAUDE.md" "$(harness_agent_file claude)" "claude agent file"
  assert_eq "AGENTS.md" "$(harness_agent_file codex)" "codex agent file"
  assert_eq "AGENTS.md" "$(harness_agent_file pi)"    "pi agent file"
  # Unknown harness returns non-zero (the install-time validity check).
  if harness_agent_file bogus >/dev/null 2>&1; then
    echo "  FAIL: harness_agent_file accepted an unknown harness" >&2; return 1
  fi
}

test_harness_agent_style() {
  assert_eq "import"  "$(harness_agent_style claude)" "claude uses @import"
  assert_eq "symlink" "$(harness_agent_style codex)"  "codex uses symlink"
  assert_eq "symlink" "$(harness_agent_style pi)"     "pi uses symlink"
}

test_harness_commands_dir() {
  assert_eq ".claude/commands" "$(harness_commands_dir claude)" "claude commands dir"
  assert_eq "" "$(harness_commands_dir codex)" "codex has no commands dir"
  assert_eq "" "$(harness_commands_dir pi)"    "pi has no commands dir"
}

test_harness_is_known() {
  for h in claude codex pi; do
    harness_is_known "$h" || { echo "  FAIL: $h not recognized" >&2; return 1; }
  done
  if harness_is_known nope; then
    echo "  FAIL: unknown harness reported as known" >&2; return 1
  fi
}

test_harness_resolve_precedence() {
  # CLI override wins.
  assert_eq $'codex\npi' "$(harness_resolve /nonexistent.json codex,pi)" "cli override"
  # Default when no config and no override.
  assert_eq "claude" "$(harness_resolve /nonexistent.json)" "default claude"
  # Parse from a pdeq.json harnesses array.
  local tmp; tmp=$(mktemp)
  printf '{ "harnesses": ["codex", "claude"] }\n' > "$tmp"
  assert_eq $'codex\nclaude' "$(harness_resolve "$tmp")" "parsed from config"
  rm -f "$tmp"
}

# The roster is the single enumeration; every recognized harness is in it.
test_harness_roster() {
  assert_eq "claude codex pi" "$PDEQ_KNOWN_HARNESSES" "roster contents"
  local h
  for h in $PDEQ_KNOWN_HARNESSES; do
    harness_is_known "$h" || { echo "  FAIL: roster member $h fails is_known" >&2; return 1; }
  done
}
