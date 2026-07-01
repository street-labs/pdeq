#!/usr/bin/env bash
#
# Lane-discipline regression: the coffee-shop auth spec.
#
# Proves the two enforcement layers are complementary, not redundant. The
# seeded product/auth.md carries vendor, protocol, host-as-product, command-
# surface, and exit-code bleed — the exact class of leak the deterministic
# backstop (scripts/audit-lanes.sh) is blind to unless the project configures
# the terms, and that the agent-run Lane Reviewer (Layer 2) is meant to catch.
#
# This script exercises Layer 1 only (deterministic, scriptable):
#   1. With no laneAudit config, Layer 1 MISSES the structural bleed
#      (none of Square/OAuth/CLI/"authorization code exchange"/… are defaults).
#   2. With the project's laneAudit terms configured, Layer 1 then flags the
#      lexical leaks (Square, OAuth) — the tunable backstop closes the lexical
#      gap, but still cannot see the purely structural bleed.
#
# The Layer 2 (agent review) evidence for the same fixture lives alongside in
# coffee-auth-layer2-review.md.
#
# Fixtures are built in a mktemp dir (git-init'd, since audit-lanes.sh derives
# its root from `git rev-parse --show-toplevel`) and torn down on exit — nothing
# is written into the real repo, so the real lane/traceability audits are
# unaffected.
#
# Usage: ./engineering/apps/cli/tests/lane-discipline/regression-coffee-auth.sh

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../../../.." && pwd)"
AUDIT="$REPO_ROOT/scripts/audit-lanes.sh"

# Reuse the shared assertion helpers from the code-mapping suite.
# shellcheck source=../code-mapping/lib/assert.sh
source "$REPO_ROOT/engineering/apps/cli/tests/code-mapping/lib/assert.sh"

# ── Build the seeded coffee-auth fixture in a temp git repo ────────────────
make_coffee_fixture() {
  local root
  root="$(mktemp -d)"
  ( cd "$root" && git init -q && git config user.email t@t.co && git config user.name t )
  mkdir -p "$root/product"
  cat > "$root/product/auth.md" <<'SPEC'
# Coffee Shop — Auth

## Overview
Customers sign in to earn rewards. Auth is exercised from a command-line host
today, before any mobile UI exists.

## Requirements

### Core
- The system authenticates the customer with Square via an OAuth authorization
  code exchange, validating a CSRF state parameter, then stores the access token
  and refresh token.
- Subsequent CLI invocations reuse the stored token without re-prompting.
- The customer runs `coffee auth login` to begin sign-in and `coffee auth
  status` to check it.

### Non-Functional
- A command-line host stores the tokens locally with platform-appropriate
  protection.

## Acceptance Criteria
- Running `coffee auth login` with valid credentials exits non-zero on failure.
SPEC
  echo "$root"
}

# ── Test 1: no config → Layer 1 is blind to the structural bleed ───────────
test_layer1_misses_bleed_without_config() {
  local root out code
  root="$(make_coffee_fixture)"
  printf '{ "pdeqVersion": "0.4.0", "platforms": ["cli"] }\n' > "$root/pdeq.json"

  out="$( cd "$root" && "$AUDIT" 2>&1 )"; code=$?
  rm -rf "$root"

  # None of the bleed terms are in the built-in defaults, so Layer 1 passes —
  # this is precisely the gap the Lane Reviewer exists to close.
  assert_exit_code 0 "$code" "no-config: audit passes (misses bleed)" || return 1
  assert_contains "$out" "No lane discipline violations" "no-config: clean" || return 1
  assert_not_contains "$out" "Square" "no-config: Square not flagged" || return 1
  assert_not_contains "$out" "OAuth"  "no-config: OAuth not flagged"  || return 1
}

# ── Test 2: with laneAudit → Layer 1 flags the lexical leaks ───────────────
test_layer1_flags_lexical_leaks_with_config() {
  local root out code
  root="$(make_coffee_fixture)"
  cat > "$root/pdeq.json" <<'CFG'
{ "pdeqVersion": "0.4.0", "platforms": ["cli"],
  "laneAudit": { "vendors": ["Square"], "protocols": ["OAuth"] } }
CFG

  out="$( cd "$root" && "$AUDIT" 2>&1 )"; code=$?
  rm -rf "$root"

  # Configuring the project's own vendor/protocol terms makes the deterministic
  # backstop catch the lexical leaks. It still cannot see purely structural
  # bleed ("subsequent CLI invocations", "exits non-zero") — that stays Layer 2's job.
  assert_exit_code 1 "$code" "with-config: audit fails on lexical leaks" || return 1
  assert_contains "$out" "Square" "with-config: Square flagged" || return 1
  assert_contains "$out" "OAuth"  "with-config: OAuth flagged"  || return 1
}

# ── Runner (standalone; also compatible with a test_* discovery runner) ────
main() {
  local total=0 passed=0 failed=()
  for t in test_layer1_misses_bleed_without_config test_layer1_flags_lexical_leaks_with_config; do
    total=$((total + 1))
    if "$t"; then
      echo "  PASS: $t"; passed=$((passed + 1))
    else
      echo "  FAIL: $t"; failed+=("$t")
    fi
  done
  echo ""
  echo "lane-discipline regression: $passed/$total passed"
  [ ${#failed[@]} -eq 0 ]
}

main "$@"
