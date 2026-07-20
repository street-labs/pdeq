# Contributing to pdeq

Thanks for your interest in pdeq. A few things make contributing here different from a typical repo — please read this first.

## Pull requests only — no issues

**This project does not use the issue tracker** (it's disabled). All contributions, including bug reports, come in as pull requests.

- **Found a bug?** Open a PR that adds a **test reproducing it** — a failing test in the relevant suite under `engineering/apps/cli/tests/`. That's the minimum; a PR that also fixes the bug (turning the test green) is even better. A reproducing test is worth far more than a prose description, and it never goes stale.
- **Want a feature or change?** Open a PR with the spec change and code (see the spec-driven flow below). Small, focused PRs review fastest.

Every PR ships with a test. If a change can't be covered by an automated test, say why in the PR description.

## Markdown first, code second

pdeq is **spec-driven**: the markdown specs are the source of truth, and code is derived from them. Changes flow **markdown → code**, never the reverse. Before changing behavior:

1. Update the **product** spec (`product/<feature>.md`) if the *what* changed.
2. Update the **design**, **engineering**, and **QA** specs (`<lane>/<platform>/<feature>.md`) as needed.
3. **Then** update the code to match, with an `// Implements: <slug>` marker (or the language-appropriate form) at the implementing unit.
4. Update the traceability index and add/adjust tests.

The full rules live in [`AGENTS.md`](AGENTS.md) (§The Cardinal Rule, §Requirement ↔ Code Mapping, §Stay In Your Lane). A PR that changes code without the corresponding spec change will be asked to add it.

## Running the checks locally

Everything runs with just `bash`, `python3`, and `git` — no extra toolchain. These are the same checks CI runs:

```bash
# Traceability: slugs ↔ index ↔ markers reconcile (strict / CI mode)
./scripts/audit-traceability.sh --check

# Lane discipline: product specs stay free of design/engineering bleed
./scripts/audit-lanes.sh

# Test suites
./engineering/apps/cli/tests/migrations/run-all.sh
./engineering/apps/cli/tests/code-mapping/run-all.sh
./engineering/apps/cli/tests/lane-discipline/regression-coffee-auth.sh
```

A pre-commit hook (installed by `scripts/init.sh`) runs the traceability audit, the lane backstop (warn-only), and merges pending decision-log entries. If you didn't install via `init.sh`, run the audits manually before pushing.

## Conventions worth knowing

- **Slugs are permanent.** `FR-`/`NFR-`/`AC-`/`TC-` identifiers are never renamed or reused. Use the reserved `-ex-` prefix (`FR-ex-…`) for examples in prose so the audit ignores them.
- **Decisions** go in `decisions-pending.md` during a change (the pre-commit hook merges them into `decisions.md`), never directly into `decisions.md`.
- **Breaking (MINOR/MAJOR) releases** ship a migration under `migrations/<version>.md`; the enforcement gate blocks a version bump that lacks one. See `product/migrations.md`.

## Releasing

Releases are tagged `v<VERSION>` (e.g. `v0.13.0`) on `main`, following [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The release commit bumps `VERSION`, `pdeq.json` (`pdeqVersion`), the `CHANGELOG.md` entry, and — for a MINOR/MAJOR (lineage-breaking) release — ships `migrations/<version>.md`. The commit-message gate (`scripts/audit-migrations.sh`) blocks a breaking bump that has no matching migration, so author the migration first.

**Release steps** (run after the version-bump PR is merged to `main`):

1. `git checkout main && git pull --ff-only origin main` — land the bump.
2. Confirm `cat VERSION` matches the version you're releasing.
3. Cut and push the annotated tag, then verify it landed:
   ```bash
   scripts/release.sh 0.13.0        # tag at HEAD, push, verify via ls-remote
   # or, by hand:
   # git tag -a v0.13.0 -m "pdeq 0.13.0: <one-line summary>"
   # git push origin v0.13.0
   # git ls-remote --tags origin | grep v0.13.0
   ```
4. Confirm the `git ls-remote` line dereferences to the release commit's SHA.

The tag is the release marker — consumers pin the `.pdeq` submodule to it, and `git ls-remote --tags` / release-notes tooling read from it. A version bump merged without its tag (the `v0.13.0` gap) leaves consumers seeing the bump with no resolvable release point, so don't skip step 3.

`scripts/release.sh <version>` is bash (no extra toolchain — `just` is not a repo dependency). It asserts `VERSION` matches, tags HEAD, pushes, and verifies the remote in one step.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
