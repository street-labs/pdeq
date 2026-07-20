---
product-hash: d8165b1fdd09d7b72bec024e1c9188472de068cc3d387ea3e2d1109d32904008
product-slugs: [AC-implement-base-option, AC-implement-context-not-persisted, AC-implement-default-base, AC-implement-empty-scope, AC-implement-fallback-scope, AC-implement-markers-audit, AC-implement-no-arg-scope, AC-implement-single-pass, FR-implement-audit-done-check, FR-implement-base-options, FR-implement-changed-specs, FR-implement-code-map, FR-implement-command, FR-implement-context-ephemeral, FR-implement-current-code, FR-implement-default-base, FR-implement-empty-scope, FR-implement-fallback-scope, FR-implement-implements-requirements, FR-implement-index-rows, FR-implement-no-arg-default, FR-implement-runs-loop, FR-implement-single-pass-context, FR-implement-slug-inventory, FR-implement-spec-diff-scope, NFR-implement-determinism]
---
# Implement — CLI Technical Spec

> Based on requirements in `../../product/implement.md`
> (No design spec — feature has no UI surface. Design lane is explicitly N/A.)

## What We're Building

Technically, this feature is two artifacts: (a) a shell script `scripts/implement-context.sh` that joins git history against the traceability index and emits one complete context bundle to stdout, and (b) a slash-command prompt `pdeq-rules/commands/pdeq-implement.md` that shells out to the script and then instructs the implementing agent to write code, add markers, run the engineering/QA loop, and re-run the traceability audit. No new runtime dependency, no new config field, no persisted state. The script is the bulk of the work; the command file is a thin instruction layer.

The design is shaped by one decision the owner made explicit during brainstorm: **context gathering is a script, not a sequence of agent toolcalls.** An implementing agent that has to read each spec file, grep the index, and diff each code location one call at a time burns its budget on gathering before it writes a line of code. `implement-context.sh` does all of that in one process and hands the agent a single stdin it can read once. The agent's first action is to write code, not to discover what to write.

The second shaping decision: **git diff on the spec tree drives scope; the index is the second hop.** Which specs changed tells us *what* is in scope; the index tells us *where the code is*. This is the natural complement to kickoff — kickoff writes specs, implement diffs them. The feature/slug argument is a fallback for the redo case where specs are unchanged.

## Technical Approach

### Two artifacts, one flow

```
/pdeq-implement [--base main|HEAD|<ref>] [feature|slug]
        │
        ├── scripts/implement-context.sh   →  stdout: the context bundle
        │
        └── command prompt reads bundle, instructs agent to:
                1. implement every in-scope FR per the Code Map
                2. add # Implements: markers
                3. run the engineering/QA loop to green
                4. re-run audit-traceability.sh (done-check)
```

### `scripts/implement-context.sh` — the context producer

A POSIX bash script (`set -euo pipefail`, bash 3.2 compatible — no associative arrays, no `mapfile`). No new install dependency; it uses `git`, `grep`/`rg` (optional), standard coreutils, and `awk` for index parsing. Reads `pdeq.json` for `specsRoot`.

**Argument parsing.**

```
implement-context.sh [--base <ref>] [feature|slug]
```

- `--base` accepts `main` (default), `HEAD` or `working` (synonyms — uncommitted only), or an explicit git ref.
- A single positional argument is treated as a feature name or slug (fallback scope).

**Base resolution.**

| `--base` | Resolved base | Diff form |
|---|---|---|
| `main` (default) | `git merge-base main HEAD` | `git diff <base> -- <specdirs>` (committed-on-branch + uncommitted) |
| `HEAD` / `working` | `HEAD` | `git diff HEAD -- <specdirs>` (uncommitted only) |
| `<ref>` | the ref as-is | `git diff <ref> -- <specdirs>` |

`git diff <base>` (no second endpoint) compares the working tree against `<base>`, so the `main` default captures every spec change made on the branch *and* any uncommitted edits — exactly the state a builder is in when they run implement mid-session. This is what makes `AC-implement-default-base` hold.

If `main` does not exist as a local ref, fall back to `origin/main`; if neither exists, error with a clear message (the project has no main branch to diff from).

**Spec scope derivation.**

1. `git diff --name-status --diff-filter=AM <base> -- <specsRoot>/product/ <specsRoot>/design/ <specsRoot>/engineering/ <specsRoot>/qa/` → list of Added/Modified spec files. (Deleted specs are out of scope — a removed spec means a feature was retired, not implemented. Renames are rare in the spec tree; if needed later, add `R` to the filter.)
2. If the list is non-empty, those files are the in-scope spec set. Every slug defined in them is in scope (file-level over-inclusion, per `FR-implement-spec-diff-scope`).
3. If the list is empty and a positional `feature|slug` was given, resolve scope from it instead (fallback):
   - **Feature** → in-scope spec files are `<specsRoot>/product/<feature>.md` plus `<specsRoot>/design/*/<feature>.md`, `<specsRoot>/engineering/*/<feature>.md`, `<specsRoot>/qa/*/<feature>.md` (globbed across platform subfolders). Missing files are skipped with a note.
   - **Slug** → find the product spec file that defines the slug (`grep -rl "<slug>" <specsRoot>/product/`), then resolve its feature and proceed as above.
4. If the list is empty and no positional was given → print `implement: nothing to implement (no spec changes since <base> and no feature/slug given)` to stderr, exit 0. This is `FR-implement-empty-scope`.

**Slug extraction.**

Scan each in-scope spec file for `(FR|NFR|AC|TC)-[a-z0-9-]+` (case-sensitive prefix). Deduplicate, sort ascending by byte order. `TC-` is included here (unlike the drift-detection `product-slugs` convention) because QA specs are in scope and the implementing agent needs the test-case context. The extraction regex matches the one in `scripts/audit-traceability.sh` so the two never disagree on what counts as a slug.

**Index row lookup.**

Parse `index.md`'s table. The index is a pipe-delimited markdown table with columns `Slug | Type | Defined In | Referenced In | Code`. For each in-scope slug, emit the matching row. Parsing uses `awk -F'|'` over lines that start with `| ` and contain the slug in the first field. (The index is regenerated by the audit, so its shape is stable; the parser only needs to handle the documented column layout.)

**Code Map extraction.**

For each in-scope engineering spec, parse its `## Code Map` section: a pipe-delimited table `Slug | Planned location | Status`. Emit the rows whose Slug is in the in-scope set. This gives the agent the planned locations and `implemented`/`planned`/`unimplemented` status per FR.

**Current code state.**

Collect the set of code file paths from two sources: the index `Code` column (split on `, ` to get `file:line` entries, take the file part) and the Code Map `Planned location` column (split on `; `, take file part, drop `—`). For each unique existing file, emit `git diff <base> -- <file>` so the agent sees current uncommitted/branch state. For files that don't yet exist (planned but not created), note `planned, not yet present`. This is `FR-implement-current-code`.

**Bundle assembly — deterministic order.**

Output is emitted to stdout in a fixed section order so two runs against the same scope produce identical output (`NFR-implement-determinism`):

```
=== implement-context: base=<base>, scope=<source> ===

## Changed spec files
<name-status list>

## In-scope slugs
<sorted slug list, one per line>

## Spec contents
<for each in-scope spec file, in sorted path order: a header line + the file's current content>

## Index rows
<for each in-scope slug, in sorted order: the index row>

## Code map
<for each in-scope FR, in sorted order: the code map row>

## Current code state
<for each unique code file, in sorted path order: a header + git diff or "planned, not yet present">
```

Nothing is written to disk. The bundle exists only on stdout for the command prompt to consume. This is `FR-implement-context-ephemeral`.

### `pdeq-rules/commands/pdeq-implement.md` — the command prompt

A markdown prompt file in the same shape as the other `pdeq-*.md` command sources. It carries the inline marker for the command-level FRs at the top (mirroring `pdeq-visualize.md`'s pattern), then instructs the agent to:

1. Read `pdeq.json` for `specsRoot`.
2. Run `scripts/implement-context.sh` with the user's arguments (or no arguments for the default).
3. If the script exits 0 with empty output (nothing to implement), report that and stop.
4. Read the context bundle from the script's stdout.
5. For every in-scope `FR-` per the Code Map: write the realizing code at the planned location, add the language-appropriate `# Implements:` / `// Implements:` marker, set Code Map status to `implemented` in the engineering spec.
6. Enter the engineering/QA iteration loop: run tests, fix failures (updating specs first per the cardinal rule if behavior changes), re-run until green.
7. Re-run `scripts/audit-traceability.sh` to repopulate the index `Code` column from the new markers. A passing audit is the completion signal.
8. Print a summary: which FRs were implemented, which files changed, audit result.

The prompt explicitly forbids persisting the context bundle or any sequenced plan — no writes under `.pdeq/`, no plan files, no index entries for the bundle. Ephemeral by construction.

### Harness materialization

`pdeq-rules/commands/pdeq-implement.md` is the canonical source. The installer (`scripts/init.sh` via `scripts/lib/harness.sh`) materializes it into `.claude/commands/pdeq-implement.md` for Claude and `.pi/prompts/pdeq-implement.md` for Pi, exactly as it does for the existing command set. Codex reads the canonical file directly (no slash-command surface). No new harness adapter axis is needed — `FR-harness-agnostic-commands-per-harness` already covers materializing a new command file. The script `scripts/implement-context.sh` lives in the submodule and is available in every consumer install unchanged.

## Data Model

No persistent data model. The feature is stateless: it reads git state, the spec tree, and `index.md` at invocation time and emits to stdout. Nothing is written, nothing is cached, nothing is migrated. The only "state" is the user's current branch and working tree, which git already tracks.

## API / Interface Design

The command surface is the slash command `/pdeq-implement`. The script surface is `scripts/implement-context.sh` (also usable directly by a human or another script). The script's stdout contract is the deterministic bundle layout above; its stderr carries human-readable diagnostics and the nothing-to-implement message. Exit codes: `0` for success (including the nothing-to-implement case), non-zero for errors (bad base ref, missing main, unparseable index).

## Component Architecture

Two components, no shared module:

- `scripts/implement-context.sh` — self-contained. Sources `scripts/lib/` only if a shared helper (e.g. `specsRoot` resolution) already exists there; otherwise resolves `pdeq.json` inline like the other scripts.
- `pdeq-rules/commands/pdeq-implement.md` — self-contained prompt. References the script by relative path.

No changes to `scripts/audit-traceability.sh`, `scripts/init.sh`, or `scripts/lib/harness.sh` are required for the core feature. The installer's command-materialization loop picks up the new file automatically because it globs `pdeq-rules/commands/pdeq-*.md`.

## State Management

None. Stateless invocation.

## Error Handling

- **Bad `--base` ref** — `git rev-parse --verify` fails; print `implement: unknown base ref '<ref>'` to stderr, exit non-zero.
- **No `main` and no `origin/main`** — print `implement: no main branch found; pass --base <ref>` to stderr, exit non-zero.
- **Positional feature with no matching spec** — print `implement: no spec found for feature '<feature>'` to stderr, exit non-zero. (Distinct from empty-scope, which is exit 0.)
- **Slug not found in any product spec** — same, naming the slug.
- **`index.md` missing or unparseable** — print a warning and emit an empty index-rows section rather than failing the whole run; the agent can still implement from specs alone, just without code-location hints.
- **Code file in Code Map doesn't exist** — noted as `planned, not yet present`, not an error.

## Performance Considerations

One `git diff --name-status` call, one `git diff` per unique code file (batchable into a single `git diff <base> -- <file1> <file2> ...` to keep it to one git invocation for the code-state section). Slug extraction is a single `grep -hoE` per spec file. Index parsing is one `awk` pass. The whole bundle is produced in seconds for any realistic project size. The single-pass constraint (`FR-implement-single-pass-context`) is structural, not just aspirational: the script is one process, not a loop of agent calls.

## Security Considerations

The script runs `git diff` and reads files under the spec tree and `index.md`. It writes nothing. No user-controlled input reaches a shell expansion unsanitized — the base ref is passed through `git rev-parse --verify` before use, and file paths come from git's own output, not from user arguments. The positional feature/slug is matched against the filesystem and `grep` patterns only; it is never passed to a shell.

## Implementation Plan

Ordered steps. Each unlocks the next.

1. **Write `scripts/implement-context.sh`** — the context producer. This is the core; without it nothing else is testable. Implement arg parsing, base resolution, spec-scope derivation, slug extraction, index lookup, code-map extraction, current-code-state, and deterministic bundle assembly. Add a `--check` mode that prints the resolved base + in-scope slug set without the full bundle, for fast testing.
2. **Write `pdeq-rules/commands/pdeq-implement.md`** — the command prompt that shells out to the script and instructs the agent. Depends on the script's stdout contract being fixed (step 1).
3. **Materialize into `.claude/commands/` and `.pi/prompts/`** — run the existing installer sync (or `scripts/sync-symlinks.sh`) so the command appears in Claude and Pi. No installer code changes.
4. **Run the engineering/QA loop** — execute the QA test plan against the script and command, fix failures, iterate to green.
5. **Re-run `audit-traceability.sh`** — confirm the new markers repopulate the index `Code` column for the implement FRs.

## Code Map

Authoritative planned code locations for every functional requirement this spec covers.

| Slug | Planned location | Status |
|---|---|---|
| FR-implement-command | pdeq-rules/commands/pdeq-implement.md:1 | planned |
| FR-implement-no-arg-default | scripts/implement-context.sh | planned |
| FR-implement-spec-diff-scope | scripts/implement-context.sh | planned |
| FR-implement-default-base | scripts/implement-context.sh | planned |
| FR-implement-base-options | scripts/implement-context.sh | planned |
| FR-implement-fallback-scope | scripts/implement-context.sh | planned |
| FR-implement-empty-scope | scripts/implement-context.sh | planned |
| FR-implement-single-pass-context | scripts/implement-context.sh | planned |
| FR-implement-changed-specs | scripts/implement-context.sh | planned |
| FR-implement-slug-inventory | scripts/implement-context.sh | planned |
| FR-implement-index-rows | scripts/implement-context.sh | planned |
| FR-implement-code-map | scripts/implement-context.sh | planned |
| FR-implement-current-code | scripts/implement-context.sh | planned |
| FR-implement-implements-requirements | pdeq-rules/commands/pdeq-implement.md | planned |
| FR-implement-runs-loop | pdeq-rules/commands/pdeq-implement.md | planned |
| FR-implement-audit-done-check | pdeq-rules/commands/pdeq-implement.md | planned |
| FR-implement-context-ephemeral | pdeq-rules/commands/pdeq-implement.md; scripts/implement-context.sh | planned |
