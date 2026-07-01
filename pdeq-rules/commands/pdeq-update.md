<!-- Implements: FR-migrations-update-command, FR-migrations-update-bumps-pin, FR-migrations-update-chains, FR-migrations-update-in-session, FR-migrations-update-noop, FR-migrations-update-bump-failure, FR-migrations-update-dry-run -->
# Pdeq Update: $ARGUMENTS

Advance the pinned `.pdeq` submodule to the latest available release on its lineage, reconcile the consumer's symlinks, and offer to chain into `/pdeq-migrate` to apply any migrations that the bump made pending. You are the update orchestrator. Shell helpers do the git plumbing and symlink reconciliation; you drive the loop, capture state between phases, and prompt the consumer between the bump and the migration.

Follow the steps below in order. Do not skip. Abort on any non-zero exit from a shell helper unless a step explicitly says to tolerate failure.

---

## Step 0 — Parse arguments

`$ARGUMENTS` contains the flags passed to `/pdeq-update`. Recognized forms:

| Form | Meaning |
|---|---|
| (empty) | Bump the pin, prompt to chain, run `/pdeq-migrate` on accept. |
| `--dry-run` | Preview the would-be bump target and the migrations a real run would queue. No writes, no pin change, no symlink changes, no prompt. |

Parse into one local: `DRY_RUN` (bool). Any other argument: print `✗ unknown argument: <arg>` to stderr and exit non-zero. No `--from` flag (recovery from a failed previous run is via `/pdeq-migrate`, not `/pdeq-update`). No `--yes` flag — the chain prompt is mandatory by design; headless/CI flows should drive the shell helpers directly rather than `/pdeq-update`.

---

## Step 1 — Self-host refusal (pdeq repo only)

Detect whether you are running inside the pdeq repository itself. The detection is:

```
SELF_HOST=0
if [[ -f VERSION && -f .gitmodules ]]; then
  PDEQ_SUB_URL=$(git config --file .gitmodules submodule..pdeq.url 2>/dev/null || true)
  ORIGIN_URL=$(git config --get remote.origin.url 2>/dev/null || true)
  if [[ -n "$PDEQ_SUB_URL" && -n "$ORIGIN_URL" && "$PDEQ_SUB_URL" == "$ORIGIN_URL" ]]; then
    SELF_HOST=1
  fi
fi
```

If `SELF_HOST == 1`, print:

```
✗ /pdeq-update is disabled inside the pdeq repository.

  This project is pdeq itself. The .pdeq/ submodule is intentionally pinned
  to a previous-stable version for the bootstrap chain — see AGENTS.md
  §Bootstrap chain. Advancing it via /pdeq-update would defeat that property.

  /pdeq-update will not run. No files changed.

  What to do:
    Follow the maintainer release flow (cut the release, then advance the
    self-pin manually, then run /pdeq-migrate against pdeq's own specs).
```

Exit 2. Satisfies `FR-migrations-update-command` (self-host edge case).

If detection is ambiguous (`.gitmodules` missing, URL comparison unreliable), default to consumer behavior — refusing inside a fork that has a slightly different remote URL would be a worse failure mode than running `/pdeq-update` in a consumer project that for some reason lacks `.gitmodules`.

---

## Step 2 — Capture pre-bump state

```
PRE_PIN_SHA=$(git -C .pdeq rev-parse HEAD)
PRE_PINNED=$(scripts/migrate.sh pinned)        # reads .pdeq/VERSION
RECORDED=$(scripts/migrate.sh recorded || true)   # may be empty if pre-baseline
```

If `scripts/migrate.sh pinned` fails (no `.pdeq/VERSION`), stop and report the failure verbatim — this is an installation problem.

---

## Step 3 — Bump phase

### 3a. Dry-run preview

If `DRY_RUN`:

1. Fetch without checkout to learn what would advance to:
   ```
   git -C .pdeq fetch --tags 2>&1 | tail -5
   AVAILABLE_SHA=$(git -C .pdeq rev-parse origin/HEAD 2>/dev/null || git -C .pdeq rev-parse FETCH_HEAD)
   AVAILABLE=$(git -C .pdeq show "$AVAILABLE_SHA":VERSION 2>/dev/null | head -n 1 | tr -d '[:space:]')
   ```
2. Print the dry-run preview matching design Surface 13:
   ```
   pdeq: pinned <PRE_PINNED> → available <AVAILABLE>   [DRY RUN — no writes]

   ▸ Bumping pinned pdeq reference
     • would advance pinned pdeq <PRE_PINNED> → <AVAILABLE>
   ```
3. Then preview what migrations would become pending. Do **not** advance the submodule. Compute the would-be pending set by reading the migration files visible to the fetched (but not checked-out) tree:
   ```
   WOULD_PEND=$(git -C .pdeq ls-tree -r --name-only "$AVAILABLE_SHA" migrations/ \
                 | grep -oE 'migrations/[0-9]+\.[0-9]+\.[0-9]+\.md' \
                 | sed 's|migrations/||; s|\.md$||')
   # Filter to (RECORDED, AVAILABLE], same comparator as scripts/migrate.sh.
   ```
4. Print the `▸ Migrating` region using the dry-run vocabulary from `/pdeq-migrate --dry-run` (Surface 4), indented two spaces. For each pending version, print `  • mechanical    would …` and `  • semantic      …`. End with the trailer:
   ```
   [DRY RUN] Pin not advanced. Recorded version not changed. No files modified.
             Run /pdeq-update to apply.
   ```
5. Exit 0. Satisfies `FR-migrations-update-dry-run`, `AC-migrations-update-dry-run`.

### 3b. Real bump

If not `DRY_RUN`:

1. Print the opening status line. Until we've advanced the submodule we don't know `AVAILABLE` precisely — print using `<PRE_PINNED>` for both ends, then re-print the final available version once we know it. To avoid the print-twice flicker, fetch first, then compute, then print:
   ```
   git -C .pdeq fetch --tags 2>&1 | tail -5 || BUMP_FAIL="fetch"
   AVAILABLE_SHA=$(git -C .pdeq rev-parse origin/HEAD 2>/dev/null || true)
   AVAILABLE=$(git -C .pdeq show "$AVAILABLE_SHA":VERSION 2>/dev/null | head -n 1 | tr -d '[:space:]')
   ```
   If the fetch failed, jump to Step 3c (bump-failure).
2. Print:
   ```
   pdeq: pinned <PRE_PINNED> → available <AVAILABLE>

   ▸ Bumping pinned pdeq reference
   ```
3. No-op short-circuit. If `AVAILABLE_SHA == PRE_PIN_SHA`, the remote had no advance:
   ```
   ~ Already at <PRE_PINNED> — nothing to update.
   ```
   Exit 0. Do not run sync-symlinks, do not run `/pdeq-migrate`. Satisfies `FR-migrations-update-noop`, `AC-migrations-update-noop`.
4. Advance the submodule:
   ```
   git submodule update --remote --force .pdeq 2>&1
   ```
   On non-zero exit, jump to Step 3c (bump-failure). On success:
   ```
   POST_PIN_SHA=$(git -C .pdeq rev-parse HEAD)
   POST_PINNED=$(scripts/migrate.sh pinned)
   ```
   Print:
   ```
     ✓ pinned pdeq advanced <PRE_PINNED> → <POST_PINNED>
   ```
5. Reconcile symlinks for the new submodule contents:
   ```
   SYMLINK_REPORT=$(scripts/sync-symlinks.sh --prune --json)
   ```
   Capture `created` and `deleted` arrays from the JSON for the final summary. Compute updated commands (file content changed in the new submodule):
   ```
   UPDATED_COMMANDS=$(git -C .pdeq diff --name-only "$PRE_PIN_SHA" "$POST_PIN_SHA" -- '.claude/commands/*.md' 'pdeq-rules/commands/*.md' \
                       | sed 's|^.*/||; s|\.md$||' | sort -u)
   # Filter out any name that is also in the JSON's `created` or `deleted` arrays.
   ```

Satisfies `FR-migrations-update-bumps-pin`.

### 3c. Bump-failure path

When the fetch or `git submodule update` step exits non-zero, print Surface 14:

```
✗ failed: could not fetch latest pdeq reference.
          underlying error: <captured stderr — one line, the most diagnostic one>

✗ /pdeq-update failed at the bump step.

  Pinned pdeq version:   <PRE_PINNED>  (unchanged)
  Recorded pdeq version: <RECORDED>  (unchanged)
  No migration ran.

  What to do:
    1. Resolve the cause above (check network, credentials, or the
       remote URL configured for the pdeq submodule).
    2. Re-run /pdeq-update. The bump will be retried from the current pin.

  Your working tree is unchanged.
```

Exit 1. Do NOT run `scripts/sync-symlinks.sh`. Do NOT invoke any part of `/pdeq-migrate`. Satisfies `FR-migrations-update-bump-failure`, `AC-migrations-update-bump-failure`.

---

## Step 4 — Pending detection + chain prompt

Compute the pending set against the just-advanced pin:

```
PENDING=$(scripts/migrate.sh list-pending)
```

Print the one-line summary even when the set is empty (this is the consumer's cue that the bump succeeded and any work-to-do has been enumerated):

- If `PENDING` is non-empty:
  ```

    <N> migrations pending: <v1>, <v2>, …, <vN>
  ```
- If `PENDING` is empty (the chain will go through Surface 3b — non-breaking advance — once we run it), print nothing extra here and skip the prompt; jump straight to Step 5 with `CHAIN_CHOSEN=auto`.

### 4a. Prompt (only when `PENDING` is non-empty)

Issue the chain prompt to the consumer. In a Claude Code session, use the AskUserQuestion tool with a binary yes/no question:

> Question: `Apply pending migrations now?` (header: `Apply migrations`)
> Options: `Yes — apply now` (recommended) / `No — leave bump in place, run /pdeq-migrate later`

Treat answers `Yes` (or an empty/default response in non-Claude harnesses that map a bare Enter to yes) as accept. Treat anything else — `No`, an unexpected token, an error fetching the answer — as decline. The "any non-accept token declines" rule is the safer default; a confused or echoing agent reply should not silently begin a mutating run.

Echo the user's answer back inline for the captured transcript:

```
? Apply pending migrations now? [Y/n]: <y-or-n>
```

Set `CHAIN_CHOSEN` to `accept` or `decline` accordingly.

---

## Step 5 — Chain handoff

### 5a. If `CHAIN_CHOSEN ∈ {accept, auto}`

Print:

```

▸ Migrating
```

Then execute the `/pdeq-migrate` workflow as defined in `.pdeq/pdeq-rules/commands/pdeq-migrate.md` (consumer context) or `pdeq-rules/commands/pdeq-migrate.md` (self-host context — though Step 1 above should have exited before reaching here in that case). Read the file in full and follow it as written, with these adaptations:

1. **Indent every emitted line by two spaces.** The chained-region's nested visual under `▸ Migrating` is two spaces of indent. Apply this prefix to the migrate workflow's status line, count line, every `▸ <version>` header, every `✓`/`~`/`✗` block line, and the inner success summary.
2. **The migrate workflow's argument parsing should treat `$ARGUMENTS` as empty** for the inner run — this is not a `--dry-run` chain (dry-run never reaches Step 5; it exited at Step 3a), and we never accept `--from` at this layer.
3. **On chained-migration failure**: per design Surface 12's failure-mode rule, the failing block's `✗` line prints at the chained-region's two-space indent (so the failing-block context stays visually attached to its migration header). Then print one blank line, **drop the indent prefix entirely**, and print Surface 5's `✗ Migration X.Y.Z failed at the <block> step.` summary plus its `Recorded pdeq version` / `Pinned pdeq version` / `Remaining` / `What to do` recovery block left-aligned (no indent). Do NOT print the Step 5b final summary below. Exit 1.

On successful completion of the inner migrate workflow (every pending migration applied, or the non-breaking-advance no-op path completed), drop the indent and proceed to Step 5b.

Satisfies `FR-migrations-update-chains`, `AC-migrations-update-end-to-end`.

### 5b. Final summary (accept-and-success path)

Print:

```

✓ pdeq: updated to <POST_PINNED>
```

Then, in fixed order — `New` → `Updated` → `Removed` — print each line that has a non-empty set. Omit any whose set is empty. If all three sets are empty, omit all three lines and proceed directly to the diff-reminder.

```
  New commands available: /<name>, /<name>
  Updated commands: /<name>
  Removed commands: /<name>
  Review the diff before committing.
```

The `New commands available` set is the basenames (`.md` stripped, slash prefixed) in `SYMLINK_REPORT.created` whose path contains a `commands` segment. The `Removed commands` set is the same for `SYMLINK_REPORT.deleted`. The `Updated commands` set is `UPDATED_COMMANDS` from Step 3b.5, minus any name that appears in the new or removed sets.

Exit 0. Satisfies `FR-migrations-update-in-session`, `AC-migrations-update-in-session`.

### 5c. If `CHAIN_CHOSEN == decline`

Print Surface 15 — bumped-but-not-migrated:

```

~ pdeq: bumped to <POST_PINNED>; migrations not applied.
  Recorded pdeq version: <RECORDED>  (unchanged)
  Pinned pdeq version:   <POST_PINNED>  (advanced)
  Pending:               <v1>, <v2>, …, <vN>

  New commands available: /<name>
  Updated commands: /<name>
  Removed commands: /<name>

  Run /pdeq-migrate when ready to apply the pending migrations.
  Review the bump (.pdeq, .gitmodules, symlinks under scripts/ and the harness command dir) with `git diff` before committing.
```

Same rules for `New / Updated / Removed`: omit lines with empty sets; omit the entire commands paragraph if all three are empty. The `Recorded` line stays at the pre-bump value (the chained migrate did NOT run, so `scripts/migrate.sh bump` was NOT invoked).

Exit 0. The bump itself stays in place — the consumer chose to inspect before migrating, not to abort the upgrade.

---

## Output style reference

| Glyph | ANSI | When |
|---|---|---|
| `✓` | green `\033[0;32m` | successful bump, final updated-to summary, or inner-migrate success |
| `~` | yellow `\033[0;33m` | no-op (already at latest), declined chain, or absent migration block |
| `✗` | red `\033[0;31m` | bump failure, chained-migration failure, self-host refusal |
| `?` | cyan `\033[0;36m` | chain prompt line |
| `•` | no color | dry-run preview line prefix |
| `▸` | no color | top-level region header (`Bumping…`, `Migrating`) or migration header inside the chained region |

Tone rules:

- Always print the opening `pdeq: pinned X → available Y` line first, before any work.
- The bump phase emits exactly one of: `✓ pinned pdeq advanced X → Y`, `~ Already at X — nothing to update.`, or `✗ failed: …`.
- The chain prompt is the only interactive moment; everything else is non-interactive output.
- On decline, both versions are reported with annotations (`(unchanged)`, `(advanced)`) so the consumer sees the asymmetry without inferring it.
