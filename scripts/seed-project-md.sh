#!/usr/bin/env bash
#
# Seed project.md — the project orientation file — at the specs root.
#
# Creates project.md from a skeleton if it does not exist; a no-op if it
# already exists (idempotent). Used by scripts/init.sh on fresh install and
# by the project-orientation migration's mechanical block for existing
# projects, so the skeleton has one source of truth.
#
# Usage:
#   ./scripts/seed-project-md.sh [specs-root]
#   PDEQ_SPECS_ROOT=apps/api ./scripts/seed-project-md.sh
#
# The specs root is resolved as: the positional arg, else $PDEQ_SPECS_ROOT,
# else pdeq.json's specsRoot, else the current directory. Relative to the
# git root when a git repo is detected.
#
# Exit codes:
#   0 — project.md exists (created or already present)
#   1 — could not resolve a writable specs root

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"

resolve_specs_root() {
  local explicit="${1:-}"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "$explicit"
    return
  fi
  if [[ -n "${PDEQ_SPECS_ROOT:-}" ]]; then
    printf '%s\n' "$PDEQ_SPECS_ROOT"
    return
  fi
  local config
  for candidate in "$GIT_ROOT/pdeq.json" "$SCRIPT_DIR/../pdeq.json" ./pdeq.json; do
    if [[ -f "$candidate" ]]; then
      config="$candidate"
      break
    fi
  done
  if [[ -n "${config:-}" ]]; then
    local val
    val="$(sed -n 's/.*"specsRoot"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$config" | head -n 1)"
    printf '%s\n' "${val:-.}"
    return
  fi
  printf '.\n'
}

SPECS_ROOT="$(resolve_specs_root "${1:-}")"

# Make the specs root absolute relative to the git root (or cwd if not a repo).
if [[ "$SPECS_ROOT" != /* ]]; then
  if [[ -n "$GIT_ROOT" ]]; then
    SPECS_DIR="$GIT_ROOT/$SPECS_ROOT"
  else
    SPECS_DIR="$PWD/$SPECS_ROOT"
  fi
else
  SPECS_DIR="$SPECS_ROOT"
fi

mkdir -p "$SPECS_DIR"
DEST="$SPECS_DIR/project.md"

if [[ -f "$DEST" ]]; then
  printf '%s\n' "project.md already exists at ${SPECS_ROOT#/}/ — no change"
  exit 0
fi

# Implements: FR-project-orientation-file, FR-project-orientation-migration-seeds
cat > "$DEST" <<'MD'
# <Project Name>

## What this is
TODO: 2-4 sentences. What the product does, who it's for.

## Platforms
TODO: the platforms this project targets (from pdeq.json).

## Tech stack
TODO: one paragraph or short list. The engineering choices the project made.

## Standing specs
Cross-cutting specs every builder MUST respect, regardless of feature.

| Spec | Lane / Path | Governs |
|---|---|---|

## How to operate
- **Build a feature:** `/pdeq-kickoff <description>` — product → design → engineering → QA, one lane at a time.
- **Cardinal rule:** markdown first, code second. Change the spec, then the code — never the reverse.
- **Decisions:** append to `decisions-pending.md`; the pre-commit hook merges into `decisions.md` at commit time.
- **Traceability:** update `index.md` when you create or reference a requirement slug.
- **Audits:** `./scripts/audit-traceability.sh` (and lane/structure/temporal/coverage audits). The pre-commit hook runs the blocking ones.
MD

printf '%s\n' "Created project.md at ${SPECS_ROOT#/}/"
