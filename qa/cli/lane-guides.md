---
product-hash: 702ebccbedc4866a1c385c6460af91e99a71f599934f7ef3170431963ce5d40f
product-slugs: [AC-lane-guides-agent-reads, AC-lane-guides-installer-no-stub, AC-lane-guides-installer-warns, AC-lane-guides-reinstall-reconciles, AC-lane-guides-schema-accepts, AC-lane-guides-schema-rejects-unknown, AC-lane-guides-status-reports, AC-lane-guides-symlink-harness, FR-lane-guides-config, FR-lane-guides-distinct-from-standing, FR-lane-guides-framework-surfaces, FR-lane-guides-harness-agnostic, FR-lane-guides-installer-no-stub, FR-lane-guides-installer-validates, FR-lane-guides-missing-non-fatal, FR-lane-guides-paths-relative-to-specsroot, FR-lane-guides-per-lane-context, FR-lane-guides-project-local, FR-lane-guides-reinstall-reconciles, FR-lane-guides-status-reports, FR-lane-guides-unknown-lane-rejected, NFR-lane-guides-cheap-read, NFR-lane-guides-no-new-deps, NFR-lane-guides-survives-template-update]
---
# Lane Guides — Test Plan

> Based on requirements in `../../product/lane-guides.md`
> Based on technical spec in `../../engineering/cli/lane-guides.md`

## What We're Testing

The `laneGuides` config field and its support across the installer, the framework agent templates, and `/pdeq-status`: schema acceptance and rejection of unknown lane keys / absolute paths, installer path validation (warn on miss, never stub), harness-agnostic surfacing on a symlink harness with no submodule edits, status reporting, and idempotent re-install reconciliation. All cases run against the `cli` platform — pdeq's schema, installer, and status command.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-lane-guides-schema-accepts` | `TC-lane-guides-schema-accepts-valid`, `TC-lane-guides-schema-accepts-omitted` | Not started |
| `AC-lane-guides-schema-rejects-unknown` | `TC-lane-guides-schema-rejects-unknown-lane`, `TC-lane-guides-schema-rejects-absolute-path` | Not started |
| `AC-lane-guides-installer-warns` | `TC-lane-guides-installer-warns-missing`, `TC-lane-guides-installer-silent-present` | Not started |
| `AC-lane-guides-installer-no-stub` | `TC-lane-guides-installer-no-stub` | Not started |
| `AC-lane-guides-agent-reads` | `TC-lane-guides-framework-prose-present`, `TC-lane-guides-agent-reads-conformance` | Not started |
| `AC-lane-guides-symlink-harness` | `TC-lane-guides-symlink-harness-no-submodule-edit` | Not started |
| `AC-lane-guides-status-reports` | `TC-lane-guides-status-reports-table` | Not started |
| `AC-lane-guides-reinstall-reconciles` | `TC-lane-guides-reinstall-add-then-remove` | Not started |

## Test Cases

Test cases are grouped by scenario. Each runs against a temporary directory with a pdeq install pinned at the version under test, mirroring the harness used by `scripts/test-harness-agnostic.sh`.

### Schema Validation

Verifies the `pdeq.json` `laneGuides` field is accepted when well-formed and rejected when it carries an unknown lane key or an absolute path.

#### Schema accepts valid laneGuides `TC-lane-guides-schema-accepts-valid`
- **Type**: Unit
- **Covers**: `AC-lane-guides-schema-accepts`, `FR-lane-guides-config`, `FR-lane-guides-paths-relative-to-specsroot`
- **Preconditions**: `pdeq.schema.json` with the `laneGuides` property added.
- **Steps**:
  1. Create a `pdeq.json` with `"laneGuides": { "qa": "qa/snapshot-testing.md", "engineering": "engineering/architecture.md" }`.
  2. Validate against `pdeq.schema.json` (e.g. `python3 -c` with `jsonschema`, or the project's existing schema validation helper).
- **Expected Result**: Validation passes with no errors.

#### Schema accepts omitted laneGuides `TC-lane-guides-schema-accepts-omitted`
- **Type**: Unit
- **Covers**: `AC-lane-guides-schema-accepts`, `FR-lane-guides-config`
- **Preconditions**: `pdeq.schema.json` with `laneGuides`.
- **Steps**:
  1. Create a `pdeq.json` with no `laneGuides` field.
  2. Validate against the schema.
- **Expected Result**: Validation passes; the field is optional in its entirety.

#### Schema rejects unknown lane key `TC-lane-guides-schema-rejects-unknown-lane`
- **Type**: Unit
- **Covers**: `AC-lane-guides-schema-rejects-unknown`, `FR-lane-guides-unknown-lane-rejected`
- **Preconditions**: `pdeq.schema.json` with `laneGuides` using `additionalProperties: false` and explicit per-lane properties.
- **Steps**:
  1. Create a `pdeq.json` with `"laneGuides": { "deploy": "deploy/guide.md" }`.
  2. Validate against the schema.
- **Expected Result**: Validation fails with a message naming `deploy` as an unexpected property and listing the recognized lane keys.

#### Schema rejects absolute path `TC-lane-guides-schema-rejects-absolute-path`
- **Type**: Unit
- **Covers**: `AC-lane-guides-schema-rejects-unknown`, `FR-lane-guides-paths-relative-to-specsroot`
- **Preconditions**: `pdeq.schema.json` with the absolute-path rejection pattern on `laneGuides` values.
- **Steps**:
  1. Create a `pdeq.json` with `"laneGuides": { "qa": "/etc/passwd" }`.
  2. Validate against the schema.
- **Expected Result**: Validation fails with a message naming the offending path.

### Installer Validation

Verifies the installer warns on a missing guide path, stays silent when present, and never creates a stub file.

#### Installer warns on missing guide `TC-lane-guides-installer-warns-missing`
- **Type**: Integration
- **Covers**: `AC-lane-guides-installer-warns`, `FR-lane-guides-installer-validates`, `FR-lane-guides-missing-non-fatal`
- **Preconditions**: A temp consumer project with `pdeq.json` containing `"laneGuides": { "qa": "qa/no-such-file.md" }`; the path does not exist on disk.
- **Steps**:
  1. Run `scripts/init.sh` (or the validation pass directly) against the temp project.
  2. Capture the installer output.
- **Expected Result**: Output contains a warning naming the `qa` lane and `qa/no-such-file.md`; the install exits 0 (non-fatal).

#### Installer silent when guide present `TC-lane-guides-installer-silent-present`
- **Type**: Integration
- **Covers**: `AC-lane-guides-installer-warns`, `FR-lane-guides-installer-validates`
- **Preconditions**: A temp consumer project with `pdeq.json` containing `"laneGuides": { "qa": "qa/guide.md" }` and `qa/guide.md` present.
- **Steps**:
  1. Run `scripts/init.sh` against the temp project.
  2. Capture the installer output.
- **Expected Result**: No missing-path warning for the `qa` entry; the install exits 0.

#### Installer does not stub a missing guide `TC-lane-guides-installer-no-stub`
- **Type**: Integration
- **Covers**: `AC-lane-guides-installer-no-stub`, `FR-lane-guides-installer-no-stub`
- **Preconditions**: A temp consumer project with `pdeq.json` containing `"laneGuides": { "engineering": "engineering/arch.md" }`; the path does not exist.
- **Steps**:
  1. Run `scripts/init.sh` against the temp project.
  2. Check whether `engineering/arch.md` was created.
- **Expected Result**: `engineering/arch.md` does not exist after install. The installer only validates; it never creates guide content.

### Framework Surfacing

Verifies the "read your guide" rule is present in the canonical templates and behaves as a framework rule, not consumer-appended prose.

#### Framework prose present in lane templates `TC-lane-guides-framework-prose-present`
- **Type**: Unit (static check)
- **Covers**: `AC-lane-guides-agent-reads`, `FR-lane-guides-framework-surfaces`, `FR-lane-guides-harness-agnostic`
- **Preconditions**: The canonical `AGENTS.md` templates (root, `product/`, `design/`, `engineering/`, `qa/`, `roadmap/`).
- **Steps**:
  1. Grep each canonical lane `AGENTS.md` for a `laneGuides` / "Lane guides" section.
- **Expected Result**: Each lane template contains the read-your-guide instruction referencing `pdeq.json` `laneGuides`.

#### Agent reads configured guide (conformance) `TC-lane-guides-agent-reads-conformance`
- **Type**: Manual / Conformance
- **Covers**: `AC-lane-guides-agent-reads`, `FR-lane-guides-framework-surfaces`, `FR-lane-guides-missing-non-fatal`
- **Preconditions**: A project with `laneGuides.qa` configured and present.
- **Steps**:
  1. Run `/pdeq-conform cli lane-guides` (or a manual lane-review pass) and confirm the QA agent context references the configured guide before authoring.
- **Expected Result**: The lane agent reads the guide when authoring in that lane; if the path is missing, the agent notes it and proceeds without blocking.

### Symlink-Harness Isolation

Verifies a Codex/Pi (symlink) project surfaces a lane guide without editing the `.pdeq` submodule.

#### Symlink harness needs no submodule edit `TC-lane-guides-symlink-harness-no-submodule-edit`
- **Type**: Integration
- **Covers**: `AC-lane-guides-symlink-harness`, `FR-lane-guides-harness-agnostic`, `FR-lane-guides-project-local`, `NFR-lane-guides-survives-template-update`
- **Preconditions**: A temp consumer project initialized with `harnesses: ["pi"]` (symlink materialization); `pdeq.json` with `"laneGuides": { "qa": "qa/snapshot-testing.md" }`; `qa/snapshot-testing.md` authored in the parent repo.
- **Steps**:
  1. Run `scripts/init.sh`.
  2. `git -C .pdeq status` on the submodule.
  3. Simulate a fresh checkout: remove the submodule working-tree changes (if any) and re-run init.
- **Expected Result**: The `.pdeq` submodule has no uncommitted changes attributable to lane guides. The guide file is committed in the parent repo and survives the fresh-checkout simulation. The framework read-your-guide rule reaches the Pi agent via the symlinked template, unmodified.

### Status Reporting

Verifies `/pdeq-status` reports configured lane guides and their resolve status.

#### Status reports lane guides table `TC-lane-guides-status-reports-table`
- **Type**: Integration
- **Covers**: `AC-lane-guides-status-reports`, `FR-lane-guides-status-reports`
- **Preconditions**: A project with `laneGuides` containing one resolving and one non-resolving entry.
- **Steps**:
  1. Run `/pdeq-status`.
  2. Inspect the output for a Lane Guides section.
- **Expected Result**: Output contains a table listing each configured lane with its path and a resolve status (yes / no). A project with no `laneGuides` reports "none configured."

### Re-install Reconciliation

Verifies editing `laneGuides` and re-running the installer reconciles without error and never deletes authored files.

#### Re-install add then remove `TC-lane-guides-reinstall-add-then-remove`
- **Type**: Integration
- **Covers**: `AC-lane-guides-reinstall-reconciles`, `FR-lane-guides-reinstall-reconciles`
- **Preconditions**: A temp consumer project with no `laneGuides`.
- **Steps**:
  1. Add `"laneGuides": { "qa": "qa/guide.md" }`, create the file, re-run init. Confirm no warning for `qa`.
  2. Remove the `qa` key, re-run init. Confirm no `qa` validation runs.
  3. Check `qa/guide.md` still exists on disk.
- **Expected Result**: Step 1 silent on `qa`; step 2 no `qa` validation; step 3 the authored file is untouched.

## Edge Cases & Error Scenarios

### Empty laneGuides object
- **Trigger**: `"laneGuides": {}`.
- **Expected behavior**: Schema accepts it (no guides configured); installer validates nothing; status reports "none configured."
- **Test case**: `TC-lane-guides-schema-accepts-valid` covers the empty-object case implicitly; add an explicit assertion.

### Guide path is a directory, not a file
- **Trigger**: A `laneGuides` value resolves to a directory.
- **Expected behavior**: Installer warns (the `[ -f ]` check fails for a directory); non-fatal.
- **Test case**: `TC-lane-guides-installer-warns-missing` extension — assert a directory path also warns.

### Guide path escapes specsRoot via `..`
- **Trigger**: `"laneGuides": { "qa": "../outside.md" }`.
- **Expected behavior**: Schema permits relative `..` paths (they are relative to specsRoot); installer resolves and validates existence. Allowed: a nested install may point at a guide above `specsRoot` (e.g. a package-root architecture doc). See `engineering/cli/lane-guides.md` §Security Considerations for the threat model. No separate test case — covered by the installer's general path-resolution behavior.

## Regression Considerations

- **Existing harness-agnostic install tests** — `scripts/test-harness-agnostic.sh` must still pass unchanged; the new validation pass is additive and runs after harness materialization.
- **Schema additions** — adding `laneGuides` to `pdeq.schema.json` must not reject existing consumer `pdeq.json` files that omit it (optional field).
- **`/pdeq-status` output** — existing consumers' status output gains a new section; no existing section is removed or reordered.
- **Canonical template edits** — adding the "Lane guides" section to lane `AGENTS.md` files must not alter existing section content; the lane-discipline lexical backstop must still pass on those templates (they are not product specs, but the edit should introduce no flagged terms).
