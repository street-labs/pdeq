#!/usr/bin/env bash
# scripts/sync-symlinks.sh
#
# Reconcile the consumer-side symlinks that mirror pdeq's scripts/ and per-harness
# commands/ directories from the .pdeq submodule into the consumer's git root.
#
# Used by:
#   - scripts/init.sh (initial install; called without --prune since there is
#     nothing yet to prune)
#   - pdeq-rules/commands/pdeq-update.md (after a submodule bump; called with
#     --prune so commands removed in the new pdeq version are deleted, and
#     with --json so the orchestrator can build the "New/Updated/Removed
#     commands" listing in the final summary)
#
# Flags:
#   --prune   Also delete symlinks under managed dirs whose targets no longer
#             resolve (file removed from the source side).
#   --json    Emit a single JSON document {"created":[...], "deleted":[...]}
#             instead of the human-readable green/yellow report. Symlinks left
#             in place are not reported (matching init.sh's "skip" behavior).
#
set -euo pipefail

# Source the shared harness adapter (single source of truth), resolving this
# script's real dir through symlinks (portable to bash 3.2 / BSD readlink). When
# run from a consumer, this file is a symlink into .pdeq/scripts/, so the lib
# resolves to .pdeq/scripts/lib/harness.sh.
_pdeq_self="${BASH_SOURCE[0]}"
while [ -h "$_pdeq_self" ]; do
  _pdeq_dir="$(cd -P "$(dirname "$_pdeq_self")" && pwd)"
  _pdeq_self="$(readlink "$_pdeq_self")"
  [ "${_pdeq_self#/}" = "$_pdeq_self" ] && _pdeq_self="$_pdeq_dir/$_pdeq_self"
done
# shellcheck source=lib/harness.sh
. "$(cd -P "$(dirname "$_pdeq_self")" && pwd)/lib/harness.sh"

OPT_PRUNE=0
OPT_JSON=0
for arg in "$@"; do
  case "$arg" in
    --prune) OPT_PRUNE=1 ;;
    --json)  OPT_JSON=1  ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "sync-symlinks.sh: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

# ─── Resolution ─────────────────────────────────────────────────────────────

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PDEQ_DIR=".pdeq"
PDEQ_PATH="$GIT_ROOT/$PDEQ_DIR"

# Self-host context: if .pdeq doesn't exist but a sibling pdeq-rules/ does,
# the script is running inside the pdeq repo itself. In that case the source
# dirs live at the git root (not under .pdeq/), and the symlinks resolved by
# init.sh are already in place — sync-symlinks has nothing useful to do.
if [[ ! -d "$PDEQ_PATH" ]]; then
  if [[ -d "$GIT_ROOT/pdeq-rules" ]]; then
    if [[ "$OPT_JSON" == "1" ]]; then
      echo '{"created":[],"deleted":[]}'
    fi
    exit 0
  fi
  echo "sync-symlinks.sh: $PDEQ_DIR not found at $GIT_ROOT" >&2
  exit 2
fi

# ─── Harness resolution (via the shared adapter) ────────────────────────────

# harness_commands_dir + PDEQ_KNOWN_HARNESSES come from lib/harness.sh (sourced
# above). Resolve the enabled harness list through the shared resolver so the
# parse logic isn't duplicated here.
HARNESSES_ARR=()
while IFS= read -r _h; do
  [[ -n "$_h" ]] && HARNESSES_ARR+=("$_h")
done < <(harness_resolve "$GIT_ROOT/pdeq.json")

# ─── State accumulators ─────────────────────────────────────────────────────

CREATED_FILES=()
DELETED_FILES=()

# ─── Output helpers ─────────────────────────────────────────────────────────

if [[ "$OPT_JSON" == "0" ]] && [[ -t 1 ]]; then
  G='\033[0;32m'; Y='\033[0;33m'; R='\033[0;31m'; N='\033[0m'
else
  G=''; Y=''; R=''; N=''
fi

# Each helper ends in an `if` (not `[[ … ]] && printf`) so it always returns 0.
# A trailing `&&` short-circuit returns 1 in --json mode (printf skipped), which
# under `set -e` would abort the whole sync on the first file touched.
note_created() {
  CREATED_FILES+=("$1")
  if [[ "$OPT_JSON" == "0" ]]; then printf "${G}✓${N} created %s\n" "$1"; fi
}
note_deleted() {
  DELETED_FILES+=("$1")
  if [[ "$OPT_JSON" == "0" ]]; then printf "${Y}~${N} pruned %s (target no longer exists)\n" "$1"; fi
}
note_skip() {
  if [[ "$OPT_JSON" == "0" ]]; then printf "  skip %s (already linked)\n" "$1"; fi
}

# ─── Sync one directory ─────────────────────────────────────────────────────
#
# Args:
#   $1 = source dir (absolute, under $PDEQ_PATH)
#   $2 = dest dir (absolute, under $GIT_ROOT)
#   $3 = relative target prefix (e.g. "../.pdeq/scripts/" or "../../.pdeq/pdeq-rules/commands/")
#   $4 = label for reporting (e.g. "scripts" or ".claude/commands")
#   $5 = glob restriction (e.g. "*.md") for what to consider a managed file in
#        the dest dir during --prune; empty means all files.
# Implements: FR-migrations-update-in-session
sync_dir() {
  local src_dir="$1" dest_dir="$2" rel_prefix="$3" label="$4" glob="$5"
  [[ ! -d "$src_dir" ]] && return 0
  mkdir -p "$dest_dir"

  local src name dest
  for src in "$src_dir"/*; do
    [[ ! -e "$src" ]] && continue
    name="$(basename "$src")"
    dest="$dest_dir/$name"
    if [[ -L "$dest" || -e "$dest" ]]; then
      note_skip "$label/$name"
    else
      ln -s "${rel_prefix}${name}" "$dest"
      note_created "$label/$name"
    fi
  done

  if [[ "$OPT_PRUNE" == "1" ]]; then
    local dangling f
    # Match either everything or just the requested glob — bash glob in
    # nullglob-equivalent style via a guard inside the loop.
    for f in "$dest_dir"/*; do
      [[ ! -L "$f" ]] && continue
      if [[ -n "$glob" ]]; then
        case "$(basename "$f")" in
          $glob) ;;
          *) continue ;;
        esac
      fi
      # Only prune symlinks pointing into the pdeq submodule; leave
      # consumer-authored symlinks alone.
      local target
      target=$(readlink "$f")
      [[ "$target" != *"$PDEQ_DIR/"* ]] && continue
      if [[ ! -e "$f" ]]; then
        rm "$f"
        note_deleted "$label/$(basename "$f")"
      fi
    done
  fi
}

# ─── scripts/ — always synced (no harness gating) ───────────────────────────

sync_dir \
  "$PDEQ_PATH/scripts" \
  "$GIT_ROOT/scripts" \
  "../$PDEQ_DIR/scripts/" \
  "scripts" \
  ""

# ─── per-harness commands/ ──────────────────────────────────────────────────

for h in "${HARNESSES_ARR[@]}"; do
  cmd_dir=$(harness_commands_dir "$h") || continue
  [[ -z "$cmd_dir" ]] && continue

  # Compute the relative prefix from <git-root>/<cmd_dir>/ back to <git-root>/<pdeq-dir>/pdeq-rules/commands/.
  # depth = count of '/' in cmd_dir plus 1 (each level needs one '../').
  depth=$(echo "$cmd_dir" | tr -cd '/' | wc -c)
  depth=$((depth + 1))
  ups=""
  for ((i=0; i<depth; i++)); do ups="../$ups"; done

  sync_dir \
    "$PDEQ_PATH/pdeq-rules/commands" \
    "$GIT_ROOT/$cmd_dir" \
    "${ups}$PDEQ_DIR/pdeq-rules/commands/" \
    "$cmd_dir" \
    "*.md"
done

# ─── JSON emission ──────────────────────────────────────────────────────────

if [[ "$OPT_JSON" == "1" ]]; then
  emit_array() {
    local first=1 item
    printf '['
    for item in "$@"; do
      if [[ "$first" == "1" ]]; then first=0; else printf ','; fi
      # Escape backslash and double-quote for JSON.
      item="${item//\\/\\\\}"
      item="${item//\"/\\\"}"
      printf '"%s"' "$item"
    done
    printf ']'
  }
  # Use the `${arr[@]+"${arr[@]}"}` guard: under `set -u`, expanding an empty
  # array as `"${arr[@]}"` is an unbound-variable error in bash 3.2 (macOS
  # default). An empty `deleted` set is the common case for /pdeq-update.
  printf '{"created":'
  emit_array ${CREATED_FILES[@]+"${CREATED_FILES[@]}"}
  printf ',"deleted":'
  emit_array ${DELETED_FILES[@]+"${DELETED_FILES[@]}"}
  printf '}\n'
fi
