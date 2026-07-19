#!/usr/bin/env bash
# Tests for scripts/seed-project-md.sh — the project-orientation seed script.
#
# Covers: AC-project-orientation-fresh-install (seed creates project.md with
# the required sections) and AC-project-orientation-migration-idempotent
# (re-running is a no-op).

set -euo pipefail

# shellcheck source=/dev/null
source "$PDEQ_REPO_ROOT/engineering/apps/cli/tests/migrations/lib/assert.sh"

SEED="$PDEQ_REPO_ROOT/scripts/seed-project-md.sh"

test_seed_creates_project_md() {
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t projorient)
  ( cd "$dir" && git init -q )
  cat > "$dir/pdeq.json" <<'JSON'
{ "pdeqVersion": "0.11.0", "specsRoot": ".", "platforms": ["cli"] }
JSON

  local out
  out=$(cd "$dir" && "$SEED" . 2>&1)
  assert_contains "$out" "Created project.md" "seed reports creation"
  [[ -f "$dir/project.md" ]] || { echo "  FAIL: project.md not created" >&2; return 1; }

  local body
  body=$(cat "$dir/project.md")
  assert_contains "$body" "## What this is" "has What this is section"
  assert_contains "$body" "## Platforms" "has Platforms section"
  assert_contains "$body" "## Tech stack" "has Tech stack section"
  assert_contains "$body" "## Standing specs" "has Standing specs section"
  assert_contains "$body" "## How to operate" "has How to operate section"

  rm -rf "$dir"
}

test_seed_is_idempotent() {
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t projorient)
  ( cd "$dir" && git init -q )
  cat > "$dir/pdeq.json" <<'JSON'
{ "pdeqVersion": "0.11.0", "specsRoot": ".", "platforms": ["cli"] }
JSON

  ( cd "$dir" && "$SEED" . >/dev/null 2>&1 )
  local before
  before=$(cat "$dir/project.md")

  local out
  out=$(cd "$dir" && "$SEED" . 2>&1)
  assert_contains "$out" "already exists" "seed reports no-op on rerun"

  local after
  after=$(cat "$dir/project.md")
  assert_eq "$before" "$after" "rerun does not modify project.md"

  rm -rf "$dir"
}

test_seed_respects_specs_root() {
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t projorient)
  ( cd "$dir" && git init -q )
  cat > "$dir/pdeq.json" <<'JSON'
{ "pdeqVersion": "0.11.0", "specsRoot": "apps/api", "platforms": ["web"] }
JSON
  mkdir -p "$dir/apps/api"  # init.sh creates the specs root before seeding

  ( cd "$dir" && "$SEED" >/dev/null 2>&1 )
  [[ -f "$dir/apps/api/project.md" ]] || { echo "  FAIL: project.md not created at specsRoot" >&2; return 1; }

  rm -rf "$dir"
}

test_seed_bails_on_missing_specs_root() {
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t projorient)
  ( cd "$dir" && git init -q )
  cat > "$dir/pdeq.json" <<'JSON'
{ "pdeqVersion": "0.11.0", "specsRoot": "typo/path", "platforms": ["cli"] }
JSON

  local out rc
  out=$(cd "$dir" && "$SEED" 2>&1)
  rc=$?
  [[ "$rc" -ne 0 ]] || { echo "  FAIL: seed did not bail on missing specs root" >&2; return 1; }
  assert_contains "$out" "does not exist" "seed reports missing specs root"
  [[ ! -f "$dir/typo/path/project.md" ]] || { echo "  FAIL: seed created file in nonexistent path" >&2; return 1; }

  rm -rf "$dir"
}
