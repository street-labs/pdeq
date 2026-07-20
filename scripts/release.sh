#!/usr/bin/env bash
# pdeq release tagger — cut, push, and verify a v<version> tag at HEAD on main.
#
# Run AFTER the version-bump PR is merged to main and you've pulled.
# Usage: scripts/release.sh <version>   (e.g. scripts/release.sh 0.13.0)
#
# This is the mechanical tail of the release procedure documented in
# CONTRIBUTING.md §Releasing. It does not bump VERSION, author the CHANGELOG
# entry, or write the migration — those are authoring steps done in the PR.
# It closes the one step that's easy to forget: the tag.
set -euo pipefail

ver="${1:?usage: scripts/release.sh <version> e.g. 0.13.0}"
tag="v${ver}"

# Sanity: the working tree's VERSION must agree with the tag we're cutting.
# Cuts a mismatched-bump-then-tag mistake (bumped VERSION, tagged the old SHA).
current="$(cat VERSION 2>/dev/null || true)"
if [ "$current" != "$ver" ]; then
  echo "release: VERSION is '${current}', expected '${ver}'. Pull main and re-check." >&2
  exit 1
fi

# Refuse a dirty tree so we never tag uncommitted state.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "release: working tree dirty; commit or stash before tagging." >&2
  exit 1
fi

head="$(git rev-parse --short HEAD)"
echo "release: tagging ${head} as ${tag}"
git tag -a "$tag" -m "pdeq ${ver}"
git push origin "$tag"

echo "release: verifying remote..."
if ! git ls-remote --tags origin | grep -q "refs/tags/${tag}$"; then
  echo "release: FAILED to verify ${tag} on remote." >&2
  exit 1
fi
echo "release: ${tag} pushed and verified at ${head}."
