#!/usr/bin/env bash
# Fixture builder helpers for implement-context.sh tests.
#
# Each test builds a throwaway git repo (mktemp) seeded with a minimal spec
# tree, invokes scripts/implement-context.sh against it, and asserts on the
# stdout bundle. The script is sourced from the real pdeq repo so it runs
# against the implementation under test, not a copy.
#
# make_implement_fixture
#   Creates a fresh mktemp git repo with pdeq.json, an initial commit on
#   `main` containing a baseline product spec, and checks out a `feature`
#   branch. Prints the absolute fixture path on stdout.
#
# seed_product_spec <fixture> <feature> <slug>...
#   Writes product/<feature>.md with a definition-pattern requirement line
#   (`**Label** \`FR-...\`:`) per slug.
#
# seed_engineering_spec <fixture> <feature> <slug:location:status>...
#   Writes engineering/cli/<feature>.md with a Code Map table row per entry.
#
# seed_qa_spec <fixture> <feature> <tc-slug>...
#   Writes qa/cli/<feature>.md with a test case per TC slug.
#
# seed_index_row <fixture> <slug> <defined-in> <code>
#   Appends a row to index.md.
#
# seed_code_file <fixture> <relpath> <content>
#   Writes a code file under the fixture and stages it.
#
# commit_fixture <fixture> <message>
#   Commits all changes in the fixture on the current branch.

SCRIPT_UNDER_TEST="${PDEQ_REPO_ROOT:-$(cd "$(dirname "$0")/../../../../.." && pwd)}/scripts/implement-context.sh"

make_implement_fixture() {
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t implement-fixture)
  mkdir -p "$dir/product" "$dir/engineering/cli" "$dir/qa/cli" "$dir/src"
  cat > "$dir/pdeq.json" <<'JSON'
{
  "pdeqVersion": "0.12.0",
  "specsRoot": ".",
  "platforms": ["cli"]
}
JSON
  cat > "$dir/index.md" <<'MD'
# Traceability Index

## Index

| Slug | Type | Defined In | Referenced In | Code |
|------|------|------------|---------------|------|
MD
  git -C "$dir" init -q
  git -C "$dir" config user.email test@pdeq
  git -C "$dir" config user.name test
  git -C "$dir" symbolic-ref HEAD refs/heads/main
  # baseline product spec so the branch has something to diverge from
  cat > "$dir/product/widget.md" <<'MD'
# Widget

## Overview
Baseline. No requirements yet.
MD
  git -C "$dir" add -A
  git -C "$dir" commit -qm "main: baseline specs"
  git -C "$dir" checkout -q -b feature
  echo "$dir"
}

seed_product_spec() {
  local fixture="$1" feature="$2"
  shift 2
  local file="$fixture/product/$feature.md"
  {
    echo "# $feature"
    echo ""
    echo "## Requirements"
    echo ""
    for slug in "$@"; do
      echo "- **Placeholder** \`$slug\`: placeholder description."
    done
  } > "$file"
}

seed_engineering_spec() {
  local fixture="$1" feature="$2"
  shift 2
  local file="$fixture/engineering/cli/$feature.md"
  {
    echo "---"
    echo "product-hash: 0000"
    echo "product-slugs: []"
    echo "---"
    echo "# $feature — Technical Spec"
    echo ""
    echo "## Code Map"
    echo ""
    echo "| Slug | Planned location | Status |"
    echo "|---|---|---|"
    for entry in "$@"; do
      local slug loc status
      slug="${entry%%:*}"
      local rest="${entry#*:}"
      loc="${rest%%:*}"
      status="${rest##*:}"
      echo "| $slug | $loc | $status |"
    done
  } > "$file"
}

seed_qa_spec() {
  local fixture="$1" feature="$2"
  shift 2
  local file="$fixture/qa/cli/$feature.md"
  {
    echo "---"
    echo "product-hash: 0000"
    echo "product-slugs: []"
    echo "---"
    echo "# $feature — Test Plan"
    echo ""
    echo "## Test Cases"
    for slug in "$@"; do
      echo ""
      echo "#### Placeholder \`$slug\`"
      echo "- **Type**: auto"
    done
  } > "$file"
}

seed_index_row() {
  local fixture="$1" slug="$2" defined_in="$3" code="${4:-}"
  local type="${slug%%-*}"
  if [ -n "$code" ]; then
    echo "| $slug | $type | $defined_in | | $code |" >> "$fixture/index.md"
  else
    echo "| $slug | $type | $defined_in | | |" >> "$fixture/index.md"
  fi
}

seed_code_file() {
  local fixture="$1" relpath="$2" content="$3"
  local abspath="$fixture/$relpath"
  mkdir -p "$(dirname "$abspath")"
  printf '%s\n' "$content" > "$abspath"
}

commit_fixture() {
  local fixture="$1" message="$2"
  git -C "$fixture" add -A
  git -C "$fixture" commit -qm "$message"
}

# run_context <fixture> [args...] — invoke the script under test, print stdout
run_context() {
  local fixture="$1"
  shift
  ( cd "$fixture" && PDEQ_CONFIG_PATH="$fixture/pdeq.json" bash "$SCRIPT_UNDER_TEST" "$@" )
}
