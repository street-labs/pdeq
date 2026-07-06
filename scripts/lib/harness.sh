#!/usr/bin/env bash
#
# pdeq harness adapter — the SINGLE source of truth for which harnesses exist
# and what each one needs. Sourced by scripts/init.sh and scripts/sync-symlinks.sh
# (and available to any other script) so the adapter is defined exactly once.
#
# A "harness" is a coding-agent runtime (claude, codex, pi). pdeq is
# harness-agnostic at its core; everything harness-specific is expressed here as
# a small capability shim. Adding a harness is a matter of adding one branch to
# each capability function below and the identifier to pdeq.schema.json's enum.
#
# Capability model (one function per axis; keep them pure — name in, value out):
#   harness_agent_file   <h>  -> the per-lane agent-instructions filename
#   harness_commands_dir <h>  -> dir for markdown slash commands ("" = unsupported)
#   harness_agent_style  <h>  -> how the agent file is written: import | symlink
#
# Bash 3.2 compatible (no associative arrays): capabilities are case statements.

# Guard against double-sourcing.
[ -n "${_PDEQ_HARNESS_LIB_SOURCED:-}" ] && return 0
_PDEQ_HARNESS_LIB_SOURCED=1

# The canonical roster. The ONE place the harness set is enumerated; every other
# "list of harnesses" (user-facing strings, cleanup sweeps) derives from this.
PDEQ_KNOWN_HARNESSES="claude codex pi"

# True if $1 is a recognized harness.
# Implements: FR-harness-agnostic-v1-harness-set, FR-harness-agnostic-unknown-rejected
harness_is_known() {
  case " $PDEQ_KNOWN_HARNESSES " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Per-lane agent-instructions filename. Returns non-zero for an unknown harness
# (callers use this as the validity check before any filesystem writes).
harness_agent_file() {
  case "$1" in
    claude)     echo "CLAUDE.md" ;;
    codex|pi)   echo "AGENTS.md" ;;
    *)          return 1 ;;
  esac
}

# Directory (relative to git root) where the harness expects markdown-defined
# slash commands. Empty means the harness has no markdown slash-command surface
# (codex at v1) — the consumer invokes pdeq workflows by asking the agent in
# prose to read the prompt file directly. Pi reads markdown prompt templates
# from .pi/prompts/*.md ($ARGUMENTS/$1 expansion), the same shape as pdeq's
# command sources, so it gets a native /pdeq-* palette like claude.
#
# Implements: FR-harness-agnostic-commands-per-harness
harness_commands_dir() {
  case "$1" in
    claude)     echo ".claude/commands" ;;
    pi)         echo ".pi/prompts" ;;
    codex)      echo "" ;;
    *)          echo "" ;;
  esac
}

# How the per-lane agent file is materialized:
#   import  — write a one-line `@<canonical>` wrapper (harness supports @import;
#             lets the consumer append project-specific prose below it)
#   symlink — symlink straight to the canonical agent file
#
# Implements: FR-harness-agnostic-claude-import, FR-harness-agnostic-symlink-include
harness_agent_style() {
  case "$1" in
    claude)     echo "import" ;;
    *)          echo "symlink" ;;
  esac
}

# Resolve the enabled harness list. Prints one harness per line (trimmed).
# Precedence: CLI override ($2, comma-separated) > pdeq.json harnesses array
# ($1 = config path) > default "claude".
#
# Implements: FR-harness-agnostic-config
harness_resolve() {
  local config_path="$1" cli_override="${2:-}"
  local out=() tok raw inner
  if [ -n "$cli_override" ]; then
    IFS=',' read -ra out <<< "$cli_override"
  elif [ -f "$config_path" ]; then
    # Extract just the array body between [ and ] so the field name isn't
    # picked up, then pull quoted lowercase tokens.
    raw=$(tr -d '\n' < "$config_path" \
          | grep -oE '"harnesses"[[:space:]]*:[[:space:]]*\[[^]]*\]' | head -n1)
    if [ -n "$raw" ]; then
      inner="${raw#*\[}"; inner="${inner%\]}"
      while IFS= read -r tok; do
        [ -n "$tok" ] && out+=("$tok")
      done < <(echo "$inner" | grep -oE '"[a-z][a-z0-9-]*"' | tr -d '"')
    fi
  fi
  [ ${#out[@]} -eq 0 ] && out=("claude")
  local h
  for h in "${out[@]}"; do
    h="${h// /}"
    [ -n "$h" ] && echo "$h"
  done
}
