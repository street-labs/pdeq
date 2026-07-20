---
product-hash: 0223f4ba114b1142b1bcebfe3fb7442e8a95ab6e88ee5afe555cc50eaca77f36
product-slugs: [AC-implement-base-option, AC-implement-context-not-persisted, AC-implement-default-base, AC-implement-empty-scope, AC-implement-fallback-scope, AC-implement-markers-audit, AC-implement-no-arg-scope, AC-implement-single-pass, FR-implement-audit-done-check, FR-implement-base-options, FR-implement-changed-specs, FR-implement-code-map, FR-implement-command, FR-implement-context-ephemeral, FR-implement-current-code, FR-implement-default-base, FR-implement-empty-scope, FR-implement-fallback-scope, FR-implement-implements-requirements, FR-implement-index-rows, FR-implement-no-arg-default, FR-implement-runs-loop, FR-implement-single-pass-context, FR-implement-slug-inventory, FR-implement-spec-diff-scope, NFR-implement-determinism]
---
# Implement — CLI Test Plan

> Based on requirements in `../../product/implement.md`
> Based on engineering in `../../engineering/cli/implement.md`
> (No design spec — feature has no UI surface.)

## What We're Testing

This plan verifies `scripts/implement-context.sh` end-to-end: base resolution (main default, HEAD/working, explicit ref), spec-diff scope derivation, fallback scope from a feature/slug, empty-scope exit, the single-pass context bundle's completeness and deterministic ordering, and the nothing-persisted guarantee. It also covers the command prompt's downstream behavior at the contract level: that the agent adds markers, runs the loop, and re-runs the audit as the done-check. The script is fully shell-testable with git fixtures; the command-prompt behavior is verified through an integration run that checks the observable after-effects (markers present, audit passes, no bundle artifact on disk).

## Test Strategy

### Tooling

- **Primary harness**: plain POSIX shell test scripts under `engineering/apps/cli/tests/implement/`. Matches the migrations/code-mapping harness style — `mktemp -d` fixture roots, `trap` cleanup, `assert_*` helpers from `tests/lib/assert.sh`.
- **New assertion helpers**: `assert_context_section <name>` (confirms a section header appears in the bundle), `assert_slug_in_scope <slug>`, `assert_slug_not_in_scope <slug>`, `assert_index_row_present <slug>`, `assert_code_map_row_present <slug>`, `assert_exit_with <code>`, `assert_stderr_contains <substr>`, `assert_no_bundle_artifact <dir>` (confirms nothing was written under a path).
- **Git fixture builder**: `make_implement_fixture` wraps a `git init` + an initial commit on `main` containing a baseline spec tree, then checks out a feature branch and applies spec edits so the merge-base is well-defined. Used for every test that exercises the `main` default base.
- **Bundle capture**: tests pipe `implement-context.sh` stdout to a temp file and assert against it; stderr is captured separately for diagnostic assertions.

### Env overrides used

- `PDEQ_CONFIG_PATH` — path to the fixture's `pdeq.json`.
- `NO_COLOR=1` — disables ANSI escapes for clean stderr comparison.

### Automation split

Script-behavior cases are `[auto]`. The two cases that exercise the full agent-in-the-loop path (`TC-implement-markers-audit`, `TC-implement-context-not-persisted-end-to-end`) are `[manual]` because they require a live implementing agent; their observable after-effects (markers in code, audit exit 0, no on-disk bundle) are asserted programmatically after the agent run.

---

## Fixture Catalogue

| Template | Purpose | Contents |
|---|---|---|
| `branch-with-spec-changes/` | Default-base happy path. | `main` commit with `product/widget.md` (no FRs yet); branch commit adds `FR-ex-widget-x` to it and adds `engineering/cli/widget.md` with a Code Map. merge-base = main commit. |
| `branch-no-spec-changes/` | Empty-scope and fallback cases. | `main` and branch identical spec trees; no spec diff. |
| `uncommitted-only/` | HEAD/working base. | Branch with committed baseline specs + uncommitted edits to `product/widget.md`. |
| `explicit-base/` | Explicit ref base. | Three commits on main: A (baseline), B (spec change), C (more spec change). Tests `--base <A>` scopes to changes since A only. |
| `multi-platform-feature/` | Fallback scope across platforms. | `product/auth.md` + `design/web/auth.md` + `design/mobile/auth.md` + `engineering/web/auth.md` + `qa/web/auth.md`. Fallback `auth` globs all platform variants. |
| `with-code-locations/` | Current-code-state section. | Index `Code` column points at `src/widget.ts:10`; Code Map planned location `src/widget.ts`. `src/widget.ts` exists with uncommitted changes. |
| `planned-not-present/` | Code Map points at a file that doesn't exist yet. | Code Map row `FR-ex-widget-x | src/future.ts | planned`; `src/future.ts` absent. |
| `determinism-pair/` | Two identical runs. | Same fixture, run script twice, assert byte-identical stdout. |
| `missing-main/` | No `main`, no `origin/main`. | Fixture with only a `develop` branch. Default base must error with a clear message. |
| `missing-index/` | `index.md` absent. | Spec changes present; script must warn and emit an empty index-rows section rather than fail. |
| `qa-spec-in-scope/` | TC slugs included. | Changed `qa/cli/widget.md` defining `TC-ex-widget-happy`; bundle's slug inventory must include the TC slug. |

---

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| AC-implement-no-arg-scope | TC-implement-no-arg-scope | Not started |
| AC-implement-default-base | TC-implement-default-base, TC-implement-missing-main | Not started |
| AC-implement-base-option | TC-implement-base-head, TC-implement-base-explicit, TC-implement-bad-base | Not started |
| AC-implement-fallback-scope | TC-implement-fallback-feature, TC-implement-fallback-slug, TC-implement-fallback-no-match | Not started |
| AC-implement-empty-scope | TC-implement-empty-scope | Not started |
| AC-implement-single-pass | TC-implement-single-pass, TC-implement-bundle-sections, TC-implement-slug-inventory, TC-implement-index-rows, TC-implement-code-map, TC-implement-current-code, TC-implement-current-code-absent, TC-implement-tc-included, TC-implement-missing-index | Not started |
| AC-implement-markers-audit | TC-implement-markers-audit | Not started |
| AC-implement-context-not-persisted | TC-implement-context-not-persisted, TC-implement-context-not-persisted-end-to-end | Not started |
| NFR-implement-determinism | TC-implement-determinism | Not started |

---

## Test Cases

### Scope Derivation

#### No-arg scope from spec changes `TC-implement-no-arg-scope`
- **Type**: auto
- **Covers**: `AC-implement-no-arg-scope`, `FR-implement-spec-diff-scope`, `FR-implement-no-arg-default`
- **Preconditions**: `branch-with-spec-changes/` fixture checked out on the feature branch.
- **Steps**:
  1. Run `implement-context.sh` with no arguments.
  2. Capture stdout.
- **Expected Result**: The bundle's "In-scope slugs" section contains exactly the slugs defined in the spec files changed on the branch (`FR-ex-widget-x` and any others in those files), and no slugs from the baseline-only specs. The "Changed spec files" section lists the modified spec paths.

#### Default base is the branch point `TC-implement-default-base`
- **Type**: auto
- **Covers**: `AC-implement-default-base`, `FR-implement-default-base`
- **Preconditions**: `branch-with-spec-changes/`; an additional spec change committed on `main` *before* the branch point.
- **Steps**:
  1. Run `implement-context.sh` with no arguments.
  2. Inspect the bundle's `base=` header line and the "Changed spec files" list.
- **Expected Result**: The base resolves to `git merge-base main HEAD`. The pre-branch-point spec change on main is NOT in the changed-spec list; only branch-side changes are.

#### HEAD base restricts to uncommitted `TC-implement-base-head`
- **Type**: auto
- **Covers**: `AC-implement-base-option`, `FR-implement-base-options`
- **Preconditions**: `uncommitted-only/`; branch has committed spec changes plus uncommitted edits.
- **Steps**:
  1. Run `implement-context.sh --base HEAD`.
  2. Inspect the changed-spec list.
- **Expected Result**: Only the uncommitted spec edits appear; the committed branch-side changes are excluded. `--base working` produces identical output.

#### Explicit ref base `TC-implement-base-explicit`
- **Type**: auto
- **Covers**: `AC-implement-base-option`, `FR-implement-base-options`
- **Preconditions**: `explicit-base/` with commits A, B, C on main where B and C changed specs; HEAD at C.
- **Steps**:
  1. Run `implement-context.sh --base <A>`.
  2. Inspect the changed-spec list.
- **Expected Result**: Spec changes since A (both B and C) are in scope.

#### Fallback scope by feature `TC-implement-fallback-feature`
- **Type**: auto
- **Covers**: `AC-implement-fallback-scope`, `FR-implement-fallback-scope`
- **Preconditions**: `branch-no-spec-changes/` + `multi-platform-feature/` specs present.
- **Steps**:
  1. Run `implement-context.sh auth` (no spec diff exists).
  2. Inspect the bundle.
- **Expected Result**: The in-scope spec set is `product/auth.md` plus every `design/*/auth.md`, `engineering/*/auth.md`, `qa/*/auth.md` found by glob. All slugs defined in those files are in scope.

#### Fallback scope by slug `TC-implement-fallback-slug`
- **Type**: auto
- **Covers**: `AC-implement-fallback-scope`, `FR-implement-fallback-scope`
- **Preconditions**: as above.
- **Steps**:
  1. Run `implement-context.sh FR-ex-auth-email-login` (no spec diff).
  2. Inspect the bundle.
- **Expected Result**: The script locates the product spec defining `FR-ex-auth-email-login`, resolves its feature (`auth`), and produces the same in-scope set as `TC-implement-fallback-feature`.

#### Empty scope exits cleanly `TC-implement-empty-scope`
- **Type**: auto
- **Covers**: `AC-implement-empty-scope`, `FR-implement-empty-scope`
- **Preconditions**: `branch-no-spec-changes/`, no positional argument.
- **Steps**:
  1. Run `implement-context.sh` with no arguments.
  2. Capture exit code and stderr.
- **Expected Result**: Exit code 0. stderr contains a human-readable "nothing to implement" message naming the base. stdout is empty. No implementing agent is invoked.

### Context Bundle Completeness

#### Single-pass bundle has every section `TC-implement-single-pass`
- **Type**: auto
- **Covers**: `AC-implement-single-pass`, `FR-implement-single-pass-context`
- **Preconditions**: `branch-with-spec-changes/` + `with-code-locations/`.
- **Steps**:
  1. Run `implement-context.sh` once, capture stdout to a single file.
  2. Assert the file contains all six section headers in order: "Changed spec files", "In-scope slugs", "Spec contents", "Index rows", "Code map", "Current code state".
- **Expected Result**: All sections present in the fixed order. No follow-up invocation is needed to produce any section.

#### Spec contents included `TC-implement-bundle-sections`
- **Type**: auto
- **Covers**: `FR-implement-changed-specs`, `AC-implement-single-pass`
- **Preconditions**: `branch-with-spec-changes/`.
- **Steps**:
  1. Run the script, capture stdout.
  2. Assert the "Spec contents" section contains the full current content of each in-scope spec file, not just the diff.
- **Expected Result**: Each changed spec file's full current content appears under its path header.

#### Slug inventory complete and sorted `TC-implement-slug-inventory`
- **Type**: auto
- **Covers**: `FR-implement-slug-inventory`
- **Preconditions**: `branch-with-spec-changes/`.
- **Steps**:
  1. Run the script, extract the "In-scope slugs" section.
  2. Compare to the deduplicated, byte-sorted set of `(FR|NFR|AC|TC)-` slugs found by grep in the in-scope spec files.
- **Expected Result**: The two sets are identical and the bundle's ordering is ascending byte order.

#### Index rows present for in-scope slugs `TC-implement-index-rows`
- **Type**: auto
- **Covers**: `FR-implement-index-rows`
- **Preconditions**: `branch-with-spec-changes/` with `index.md` populated for the in-scope slugs.
- **Steps**:
  1. Run the script, inspect the "Index rows" section.
  2. For each in-scope slug, assert its index row (Defined In, Referenced In, Code) appears.
- **Expected Result**: Every in-scope slug has its full index row in the bundle.

#### Code map rows present `TC-implement-code-map`
- **Type**: auto
- **Covers**: `FR-implement-code-map`
- **Preconditions**: `branch-with-spec-changes/` with an engineering spec containing a `## Code Map` table.
- **Steps**:
  1. Run the script, inspect the "Code map" section.
  2. For each in-scope FR, assert its Code Map row (Planned location, Status) appears.
- **Expected Result**: Every in-scope FR has its Code Map row. Non-FR slugs (NFR/AC/TC) do not appear in this section.

#### Current code state included `TC-implement-current-code`
- **Type**: auto
- **Covers**: `FR-implement-current-code`, `AC-implement-single-pass`
- **Preconditions**: `with-code-locations/` (index Code column and Code Map both point at `src/widget.ts`, which has uncommitted changes).
- **Steps**:
  1. Run the script, inspect the "Current code state" section.
  2. Assert a `git diff` block for `src/widget.ts` is present.
- **Expected Result**: The current state of every code file the index or Code Map points at appears. Files are deduplicated (one block per file, not one per index entry).

#### Planned-but-absent code noted `TC-implement-current-code-absent`
- **Type**: auto
- **Covers**: `FR-implement-current-code`
- **Preconditions**: `planned-not-present/`.
- **Steps**:
  1. Run the script, inspect the "Current code state" section.
- **Expected Result**: The absent file is noted as `planned, not yet present` rather than producing a git error.

#### TC slugs included in inventory `TC-implement-tc-included`
- **Type**: auto
- **Covers**: `FR-implement-slug-inventory`
- **Preconditions**: `qa-spec-in-scope/`.
- **Steps**:
  1. Run the script, inspect the "In-scope slugs" section.
- **Expected Result**: The `TC-` slug defined in the changed QA spec appears in the inventory.

### Determinism

#### Identical runs produce identical output `TC-implement-determinism`
- **Type**: auto
- **Covers**: `NFR-implement-determinism`
- **Preconditions**: `determinism-pair/`.
- **Steps**:
  1. Run `implement-context.sh` twice with the same arguments, capturing each stdout.
  2. `diff` the two captures.
- **Expected Result**: The diff is empty. Ordering, slug set, and content are byte-identical.

### Agent Loop and Persistence

#### Markers added and audit passes `TC-implement-markers-audit`
- **Type**: manual
- **Covers**: `AC-implement-markers-audit`, `FR-implement-implements-requirements`, `FR-implement-runs-loop`, `FR-implement-audit-done-check`
- **Preconditions**: A real pdeq project with a reviewed spec for a small throwaway feature (e.g. a single-FR `product/greeter.md` with a matching engineering spec and Code Map). No code exists yet.
- **Steps**:
  1. Run `/pdeq-implement` (no args, so the greeter spec changes are in scope).
  2. Let the implementing agent run to completion.
  3. Inspect the realized code file for a `# Implements: FR-ex-greeter-hello` marker.
  4. Run `scripts/audit-traceability.sh`.
- **Expected Result**: The code file contains the marker at the implementing unit. The audit exits 0 and the index `Code` column for the greeter FR is populated with the new location.

#### Context bundle not persisted `TC-implement-context-not-persisted`
- **Type**: auto
- **Covers**: `AC-implement-context-not-persisted`, `FR-implement-context-ephemeral`
- **Preconditions**: `branch-with-spec-changes/`.
- **Steps**:
  1. Note the fixture's file tree before running.
  2. Run `implement-context.sh` and let it complete.
  3. Re-scan the fixture tree for any new file under `.pdeq/`, `plans/`, or anywhere else.
- **Expected Result**: No new files are written. `git status` shows no change attributable to the script. The bundle exists only on stdout.

#### No bundle artifact after end-to-end run `TC-implement-context-not-persisted-end-to-end`
- **Type**: manual
- **Covers**: `AC-implement-context-not-persisted`, `FR-implement-context-ephemeral`
- **Preconditions**: as `TC-implement-markers-audit`.
- **Steps**:
  1. Run `/pdeq-implement` to completion (agent writes code, runs loop, runs audit).
  2. `git status` and scan for any plan or bundle file.
- **Expected Result**: The only new files are the realized code and marker edits. No context bundle, plan, or sequenced TODO file exists anywhere in the tree.

## Edge Cases & Error Scenarios

### Missing main branch
- **Trigger**: `missing-main/` fixture; only `develop` exists. Default base (`main`) cannot resolve, and `origin/main` is absent.
- **Expected behavior**: Exit non-zero with `implement: no main branch found; pass --base <ref>` on stderr. No bundle emitted.
- **Test case**: `TC-implement-missing-main`

### Bad base ref
- **Trigger**: `--base notaref` where `notaref` fails `git rev-parse --verify`.
- **Expected behavior**: Exit non-zero with `implement: unknown base ref 'notaref'`.
- **Test case**: `TC-implement-bad-base`

### Missing index
- **Trigger**: `missing-index/` fixture; spec changes present but `index.md` absent.
- **Expected behavior**: Script warns on stderr and emits an empty "Index rows" section; the rest of the bundle is still produced. Exit 0.
- **Test case**: `TC-implement-missing-index`

### Positional feature with no matching spec
- **Trigger**: `implement-context.sh nonexistent-feature` where no `product/nonexistent-feature.md` exists.
- **Expected behavior**: Exit non-zero with `implement: no spec found for feature 'nonexistent-feature'`. Distinct from the empty-scope exit-0 case.
- **Test case**: `TC-implement-fallback-no-match`

## Regression Considerations

- **Index format changes**: the parser assumes the documented `Slug | Type | Defined In | Referenced In | Code` layout. If `audit-traceability.sh` ever changes the column order, the index-rows section breaks. Mitigation: parse by header position, not by fixed column index.
- **Code Map format changes**: same risk for the `## Code Map` table. Mitigation: locate the header row and parse by header position.
- **New harness materialization**: if a future harness adapter axis changes where command files are materialized, `pdeq-rules/commands/pdeq-implement.md` remains the canonical source; the installer's existing glob picks it up. No script change needed.
- **Slug grammar extension**: if pdeq ever adds a new slug prefix beyond `FR`/`NFR`/`AC`/`TC`, the extraction regex must be updated in lockstep with `audit-traceability.sh`.
