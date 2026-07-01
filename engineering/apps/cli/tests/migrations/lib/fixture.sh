#!/usr/bin/env bash
# Fixture builder helpers for migrations / pdeq-update tests.
#
# These build a *consumer* fixture: a git repo with a `.pdeq/` directory that
# stands in for the pinned submodule (a plain directory is enough — the helpers
# under test, sync-symlinks.sh and migrate.sh, read the working tree, not the
# submodule's git history). The real `git submodule update --remote` bump is
# git's own behavior and is exercised by the [semi-auto] companion, not here.
#
# make_consumer_fixture [harnesses_csv]
#   Fresh mktemp dir with pdeq.json (harnesses default "claude"), a git repo,
#   and an empty `.pdeq/{scripts,pdeq-rules/commands,migrations}` tree plus
#   `.pdeq/VERSION`. Echoes the absolute fixture path.
#
# set_recorded <fixture> <version>    — write pdeqVersion into pdeq.json
# set_pinned   <fixture> <version>    — write .pdeq/VERSION
# add_pdeq_command <fixture> <name>   — add .pdeq/pdeq-rules/commands/<name>
# add_migration <fixture> <version>   — add a mechanical-only .pdeq/migrations/<version>.md
# run_sync     <fixture> [args...]    — run sync-symlinks.sh in the fixture (stdout+stderr)
# run_migrate  <fixture> <sub...>     — run migrate.sh in the fixture (stdout only)

make_consumer_fixture() {
  local harnesses="${1:-claude}"
  local dir
  dir=$(mktemp -d 2>/dev/null || mktemp -d -t migrations-fixture)
  mkdir -p "$dir/.pdeq/scripts" "$dir/.pdeq/pdeq-rules/commands" "$dir/.pdeq/migrations"
  # harnesses as a JSON array
  local arr="" h
  IFS=',' read -ra hs <<< "$harnesses"
  for h in "${hs[@]}"; do
    [[ -n "$arr" ]] && arr+=", "
    arr+="\"$h\""
  done
  cat > "$dir/pdeq.json" << JSON
{
  "pdeqVersion": "0.2.1",
  "specsRoot": ".",
  "codeRoot": ".",
  "platforms": ["cli"],
  "harnesses": [$arr],
  "selfHost": false
}
JSON
  echo "0.2.1" > "$dir/.pdeq/VERSION"
  git -C "$dir" init -q
  git -C "$dir" config user.email test@pdeq
  git -C "$dir" config user.name test
  git -C "$dir" add -A
  git -C "$dir" commit -qm init
  echo "$dir"
}

set_recorded() {
  local fixture="$1" version="$2"
  # Replace the pdeqVersion value in place.
  sed -i.bak "s/\"pdeqVersion\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"pdeqVersion\": \"$version\"/" "$fixture/pdeq.json"
  rm -f "$fixture/pdeq.json.bak"
}

set_pinned() {
  local fixture="$1" version="$2"
  echo "$version" > "$fixture/.pdeq/VERSION"
}

add_pdeq_command() {
  local fixture="$1" name="$2"
  printf '<!-- a pdeq command -->\n# %s\n' "$name" > "$fixture/.pdeq/pdeq-rules/commands/$name"
}

add_migration() {
  local fixture="$1" version="$2"
  cat > "$fixture/.pdeq/migrations/$version.md" << EOF
---
version: $version
breaking: true
---
# Migration $version

## Mechanical
- touch a sentinel.
EOF
}

run_sync() {
  local fixture="$1"; shift
  ( cd "$fixture" && "$PDEQ_REPO_ROOT/scripts/sync-symlinks.sh" "$@" 2>&1 )
}

run_migrate() {
  local fixture="$1"; shift
  ( cd "$fixture" && PDEQ_CONFIG_PATH="$fixture/pdeq.json" "$PDEQ_REPO_ROOT/scripts/migrate.sh" "$@" )
}

# make_submodule_fixture
#   Builds a *real* submodule scenario for the full bump E2E: a "pdeq remote"
#   git repo with v0.2.1 → v0.4.0 history on branch `main`, and a consumer repo
#   whose `.pdeq` submodule is pinned at v0.2.1. v0.4.0 adds migrations
#   0.3.0/0.3.2/0.4.0, ships a new `pdeq-update.md` command, and removes
#   `pdeq-legacy.md`. The consumer pre-seeds `.claude/commands` symlinks for
#   pdeq-legacy (dangles after the bump → should prune) and pdeq-kickoff (stays).
#   Echoes the consumer path; the caller cleans the whole tree with
#   `rm -rf "$(dirname "$fixture")"`.
make_submodule_fixture() {
  local root remote consumer pin021 v
  root=$(mktemp -d 2>/dev/null || mktemp -d -t migrations-sub)
  remote="$root/pdeq-remote"; consumer="$root/consumer"

  git init -q -b main "$remote"
  git -C "$remote" config user.email test@pdeq
  git -C "$remote" config user.name test
  mkdir -p "$remote/scripts" "$remote/pdeq-rules/commands" "$remote/migrations"
  echo "0.2.1" > "$remote/VERSION"
  echo "echo helper" > "$remote/scripts/old-helper.sh"
  printf '# kickoff\n' > "$remote/pdeq-rules/commands/pdeq-kickoff.md"
  printf '# legacy\n'  > "$remote/pdeq-rules/commands/pdeq-legacy.md"
  git -C "$remote" add -A; git -C "$remote" commit -qm v0.2.1
  pin021=$(git -C "$remote" rev-parse HEAD)
  echo "0.4.0" > "$remote/VERSION"
  for v in 0.3.0 0.3.2 0.4.0; do
    printf -- '---\nversion: %s\nbreaking: true\n---\n# Migration %s\n## Mechanical\n- noop\n' "$v" "$v" > "$remote/migrations/$v.md"
  done
  printf '# update\n' > "$remote/pdeq-rules/commands/pdeq-update.md"
  rm "$remote/pdeq-rules/commands/pdeq-legacy.md"
  git -C "$remote" add -A; git -C "$remote" commit -qm v0.4.0

  git init -q -b main "$consumer"
  git -C "$consumer" config user.email test@pdeq
  git -C "$consumer" config user.name test
  # Local-path submodule transport is gated behind protocol.file.allow; set it
  # inline so the clone subprocess inherits it via the env.
  git -C "$consumer" -c protocol.file.allow=always submodule add -q -b main "$remote" .pdeq
  git -C "$consumer/.pdeq" checkout -q "$pin021"     # pin BEHIND the branch tip
  cat > "$consumer/pdeq.json" << 'JSON'
{ "pdeqVersion": "0.2.1", "specsRoot": ".", "codeRoot": ".", "platforms": ["cli"], "harnesses": ["claude"], "selfHost": false }
JSON
  mkdir -p "$consumer/.claude/commands"
  ( cd "$consumer" \
    && ln -s ../../.pdeq/pdeq-rules/commands/pdeq-legacy.md  .claude/commands/pdeq-legacy.md \
    && ln -s ../../.pdeq/pdeq-rules/commands/pdeq-kickoff.md .claude/commands/pdeq-kickoff.md )
  git -C "$consumer" add -A; git -C "$consumer" commit -qm "consumer@0.2.1"
  echo "$consumer"
}

# git_sub <fixture> <git args…> — run git in the fixture with local-file
# submodule transport enabled (needed for `submodule update --remote`).
git_sub() {
  local fixture="$1"; shift
  git -C "$fixture" -c protocol.file.allow=always "$@"
}
