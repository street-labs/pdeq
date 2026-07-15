<!-- Implements: FR-coverage-audit-block, FR-coverage-audit-code-signal, FR-coverage-audit-feature-grouping, FR-coverage-audit-status-check, FR-coverage-audit-terminal-statuses, FR-coverage-audit-escape-hatch -->

# QA Coverage Audit: $ARGUMENTS

Run the **QA Coverage Audit** (`scripts/audit-coverage.sh` / `scripts/audit-coverage.py`) against the current project: join the marker-derived Code column from the traceability index against each feature's QA Coverage Matrix, and report when a feature has realizing code but its coverage rows are non-terminal.

`$ARGUMENTS` is `[feature] [--escape]`:
- `[feature]` — **optional**. Narrow the audit to a single feature (e.g., `coverage-audit`) so a reviewer or implementor can focus on one feature's coverage status. Omit to audit the whole project.
- `[--escape]` — **optional**. Set `PDEQ_ALLOW_DRIFT=1` so blocks are demoted to warnings. Equivalent to running the script directly with the env var.

Read `product/coverage-audit.md` and `engineering/cli/coverage-audit.md` first if you need the full contract. Then follow the steps below.

---

## Phase 0 — Resolve and validate

1. Read `pdeq.json`; resolve `specsRoot` and `codeRoot` (default `.` each).
2. Confirm `scripts/audit-coverage.sh` exists at the repository root. If not, the project has not installed or updated to a pdeq version that ships this audit — stop and print a message directing the user to run `/pdeq-update`.
3. Confirm `index.md` exists and has been rewritten by the traceability audit (the Code column is populated). If the Code column is empty for all FRs, note that the traceability audit must run first.
4. If `[feature]` is given, confirm the product spec exists at `{specsRoot}/product/<feature>.md`. If not, list the available feature specs.

## Phase 1 — Run the audit

Run the audit script. The invocation depends on `$ARGUMENTS`:

- **No arguments**: `./scripts/audit-coverage.sh`
- **Feature-only**: `PDEQ_COVERAGE_FEATURE=<feature> ./scripts/audit-coverage.sh` (if the script is extended to support per-feature narrowing; otherwise run the full audit and filter the output)
- **With `--escape`**: `PDEQ_ALLOW_DRIFT=1 ./scripts/audit-coverage.sh`

## Phase 2 — Interpret the output

The audit prints tagged lines. Interpret them for the user:

| Prefix | Meaning |
|---|---|
| `CLEAR:` | All features with code have terminal coverage — no action needed. |
| `WARN:` | NFR or AC row with non-terminal coverage. Advisory — the gate does not block on these. |
| `BLOCK:` | FR row with non-terminal coverage despite realizing code. The gate blocks on these. Each block includes the feature name, platform, slug, and current status. |
| `SUPPRESS:` | Same as BLOCK but suppressed by `PDEQ_ALLOW_DRIFT=1`. |
| `FAIL:` | Fatal error (e.g., index not found). |

## Phase 3 — Report and recommend

Present the results to the user:

1. **Summary line**: "QA Coverage Audit passed" or "QA Coverage Audit found N block(s)."
2. **For each BLOCK**: list the feature, slug, and current status. Recommend updating the QA Coverage Matrix status after test execution.
3. **For WARNings**: list NFR/AC rows with non-terminal coverage. Note these are advisory.
4. **If `--escape` was used**: note that blocks were suppressed and should be resolved before removing the override.

This command is **advisory when run interactively** (it never modifies specs or code). The blocking behavior is enforced at commit time via CI or the pre-commit hook.
