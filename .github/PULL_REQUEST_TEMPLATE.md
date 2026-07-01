<!--
pdeq accepts contributions via pull request only (issues are disabled).
Bug report? This PR should add a test that reproduces it.
-->

## What & why

<!-- One or two sentences. If this fixes a bug, describe the wrong behavior. -->

## Test

<!-- Required. Point to the test that reproduces the bug or covers the change. -->

- [ ] Adds/updates a test under `engineering/apps/cli/tests/` (or explains why none is possible)

## Spec-driven checklist

- [ ] If behavior changed, the **markdown spec was updated first** (product → design/engineering/QA), and code carries an `// Implements: <slug>` marker
- [ ] `./scripts/audit-traceability.sh --check` passes
- [ ] `./scripts/audit-lanes.sh` passes (product specs stay in-lane)
- [ ] Relevant test suite(s) pass locally

<!-- Not every PR touches specs (docs/CI/tooling); tick what applies. -->
