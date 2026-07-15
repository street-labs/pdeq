# QA Coverage Audit

## Overview

Pdeq's existing audits validate spec-graph consistency (traceability audit), lane discipline (lexical backstop), and temporal language (temporal audit). But nothing gates on whether QA coverage has actually been executed. A project can ship code for a requirement (inline markers present, index Code column populated, traceability audit green) while every QA Coverage Matrix row for that feature is still "Not started." The conformance audit (`/pdeq-conform`) is the semantic layer that judges code behavior, but it is agent-run, advisory, and never gating, so it is not run regularly.

This feature adds a cheap, deterministic audit that joins the marker-derived index Code column to the QA Coverage Matrices and gates commits when a feature has realizing code but its coverage has not been executed. It is the missing inverse of the requirement↔code mapping feature: where that feature blocks on "code doesn't exist yet," this feature blocks on "QA hasn't been run yet."

## User Stories

- As a **project maintainer**, I want CI to catch when code has been shipped for a requirement but QA has not verified it, so that untested code cannot reach production.
- As a **QA engineer**, I want a deterministic signal that tells me which features have pending testing obligations, so I can prioritize my test execution work.
- As a **reviewing agent**, I want to see that a PR includes both code changes and corresponding QA execution before approving, so that the coverage matrix is never stale.
- As a **pdeq maintainer**, I want this audit to reuse existing infrastructure (the index Code column, the QA Coverage Matrix parser) rather than duplicating parsing logic, so that the total maintenance surface stays small.

## Requirements

### Core Behavior

The audit joins the Code column of the traceability index against QA Coverage Matrices and gates on execution status.

- **Code existence signal** `FR-coverage-audit-code-signal`: The audit uses the marker-derived Code column in `index.md` (auto-rewritten by the traceability audit from inline markers) as the "code exists" signal. It does NOT use the engineering Code Map status field (`implemented`/`planned`/`unimplemented`), which is manually maintained and may go stale.
- **Feature grouping** `FR-coverage-audit-feature-grouping`: The audit groups functional requirements by feature, deriving the feature name from the product spec path listed in the index Defined In column. A "feature" is the set of FRs whose Defined In column references the same product spec file.
- **Coverage status check** `FR-coverage-audit-status-check`: For each feature that has at least one FR with a non-empty Code column, the audit reads that feature's QA Coverage Matrix (at `qa/<platform>/<feature>.md`). It reports any coverage row whose status is non-terminal ("Not started", "In progress", "planned", empty, or any value other than "Pass" or "Fail").
- **Block on untested code** `FR-coverage-audit-block`: By default, the audit blocks (exit 1) when realizing code exists for a feature and its coverage status is non-terminal. This is the primary behavior.
- **Pass/Fail considered terminal** `FR-coverage-audit-terminal-statuses`: Only "Pass" and "Fail" are terminal statuses for the purposes of this check. Any other status (including "Not started", "In progress", "planned", empty, or an unrecognized value) is treated as non-terminal.
- **Prose rows skipped** `FR-coverage-audit-prose-skip`: Coverage rows whose test-case column carries no `TC-` slug (i.e., structural coverage described in prose) are skipped, consistent with the existing rule in the traceability audit. These rows represent descriptive coverage notes rather than executable test obligations, so they are not part of the gating.
- **NFR/AC best-effort** `FR-coverage-audit-nfr-ac-best-effort`: The gate applies to functional-requirement-backed coverage (slugs with the `FR-` prefix). NFR and AC rows are checked when they appear in the Coverage Matrix but the audit does not block on uncovered NFR/AC rows — it reports them at warn level. Rationale: NFRs and ACs may not have dedicated test cases in the QA matrix; FRs always should.
- **Escape hatch** `FR-coverage-audit-escape-hatch`: The audit honors the standard `PDEQ_ALLOW_DRIFT=1` escape hatch. When set, all blocks are demoted to warnings, and the audit report names the suppressed conditions.

### Relationship to Existing Infrastructure

- **Reuses existing parser** `FR-coverage-audit-reuse-parser`: The audit reuses the QA Coverage Matrix parser already present in `scripts/audit-traceability.sh` (the phase 7b machinery that extracts status and TC slugs per row). This check is the functional inverse of phase 7b: phase 7b errors on "Pass without evidence"; this errors on "code exists but coverage not started."
- **Does not modify existing audit** `FR-coverage-audit-independent`: This is a new, standalone audit script — not a phase bolted onto `scripts/audit-traceability.sh`. It may be added independently, run in CI alongside the three existing audits, and does not modify the traceability script.
- **Reads index Code column** `FR-coverage-audit-reads-index`: The audit reads `index.md` as input to determine which FRs have realizing code. It never writes to `index.md`.

### Non-Functional Requirements

- **Audit speed** `NFR-coverage-audit-speed`: The audit completes in under two seconds on the pdeq repository, consistent with the other deterministic audits.
- **Determinism** `NFR-coverage-audit-determinism`: Two runs of the audit on the same commit produce identical output.
- **Zero false positives on non-FR slugs** `NFR-coverage-audit-precision`: The audit only gates on `FR-` slugs in the index Code column. `NFR-`, `AC-`, and `TC-` slugs in the index are never used as the "code exists" signal.

## Acceptance Criteria

- [ ] **Code exists + coverage not started blocks** `AC-coverage-audit-code-exists-no-coverage`: A project with realizing code (a non-empty Code column entry for at least one FR in a feature) and a QA Coverage Matrix with non-terminal status for that FR's coverage row exits the audit with code 1.
- [ ] **Code exists + coverage terminal passes** `AC-coverage-audit-code-exists-coverage-done`: The same project with all coverage rows for that feature moved to "Pass" or "Fail" exits with code 0.
- [ ] **No code does not block** `AC-coverage-audit-no-code-passes`: A feature with no realizing code (empty Code column for all FRs) passes the audit regardless of coverage matrix status.
- [ ] **Prose rows skipped** `AC-coverage-audit-prose-skipped`: A Coverage Matrix row whose test-case column contains no `TC-` slug is not checked against the code-exists signal and does not trigger a block or warning.
- [ ] **NFR/AC warn only** `AC-coverage-audit-nfr-warns`: An uncovered NFR or AC row in a feature's Coverage Matrix, when the feature has realizing code, produces a warning but does not block.
- [ ] **Escape hatch honored** `AC-coverage-audit-escape-hatch`: A project that would fail the audit under default settings exits with code 0 when `PDEQ_ALLOW_DRIFT=1` is set, and the output names the suppressed conditions.
- [ ] **Audit completes in under 2s** `AC-coverage-audit-speed`: Running the audit on the pdeq repository completes in under two seconds.
- [ ] **Deterministic output** `AC-coverage-audit-deterministic-output`: Two consecutive runs on the same commit produce byte-identical stderr output.
- [ ] **Non-FR slugs ignored** `AC-coverage-audit-non-fr-ignored`: An NFR or AC slug with a non-empty Code column does not trigger the code-exists check for the purpose of gating coverage (NFRs/ACs are warn-only regardless).

## Dependencies

- **Requirement ↔ Code Mapping** (`product/code-mapping.md`): This feature depends on the Code column in `index.md` being populated by the traceability audit's marker scan. Without markers and the auto-rewritten Code column, there is no code-existence signal to join against. The coverage audit does not depend on the Code Map (Status column) — only the marker-derived Code column.
- **Traceability audit**: The existing `scripts/audit-traceability.sh` maintains `index.md` and the QA Coverage Matrix parser. This feature reads both but does not modify either.
- **Audit override mechanism**: Reuses the same `PDEQ_ALLOW_DRIFT=1` escape hatch that the other pdeq audits honor.
- **QA Coverage Matrix convention**: This feature relies on Coverage Matrices following the established format in `qa/<platform>/<feature>.md` with columns for Requirement, Test Cases, and Status. Projects that deviate from this format will need the parser to accommodate their variant.
