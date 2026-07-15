---
product-hash: 49fec02fe6b93a3d2160a9226d51e3631e3f6653e823092ecad9808f8e000fbe
product-slugs: [AC-coverage-audit-code-exists-coverage-done, AC-coverage-audit-code-exists-no-coverage, AC-coverage-audit-deterministic-output, AC-coverage-audit-escape-hatch, AC-coverage-audit-nfr-warns, AC-coverage-audit-no-code-passes, AC-coverage-audit-non-fr-ignored, AC-coverage-audit-prose-skipped, AC-coverage-audit-speed, FR-coverage-audit-block, FR-coverage-audit-code-signal, FR-coverage-audit-escape-hatch, FR-coverage-audit-feature-grouping, FR-coverage-audit-independent, FR-coverage-audit-nfr-ac-best-effort, FR-coverage-audit-prose-skip, FR-coverage-audit-reads-index, FR-coverage-audit-reuse-parser, FR-coverage-audit-status-check, FR-coverage-audit-terminal-statuses, NFR-coverage-audit-determinism, NFR-coverage-audit-precision, NFR-coverage-audit-speed]
---
# QA Coverage Audit — CLI Technical Spec

> Based on requirements in `../../product/coverage-audit.md`
> (No design spec — feature has no UI surface.)

## What We're Building

A standalone deterministic audit script (`scripts/audit-coverage.sh`) that detects when code has been shipped for a requirement but QA coverage has not been executed. It joins the marker-derived Code column from `index.md` against each feature's QA Coverage Matrix, and blocks commits when a feature has realizing code whose coverage rows are non-terminal. No new config, no new runtime dependency — a single shell script using python3 for the join logic, consistent with the other pdeq audit scripts.

The design is shaped by two decisions. First, **the Code column is the authoritative code-exists signal** — it is auto-rewritten by the traceability audit from inline markers in source code, so it cannot go stale. The engineering Code Map's Status field is explicitly NOT used. Second, **this is a standalone script** rather than a phase of `audit-traceability.sh`, so projects can add or remove it independently from the other audits.

## Technical Approach

### Algorithm

The script runs a single pass through the following steps:

1. **Parse index.md** — Read the traceability index. For each row with a `Defined In` column, extract:
   - The slug (e.g., `FR-coverage-audit-block`)
   - The Defined In path (e.g., `product/coverage-audit.md`)
   - The Code column (comma-separated `path:line` entries)
   - Slug prefix (FR / NFR / AC / TC)

2. **Group FRs by feature** — Group all `FR-` slugs by their Defined In path. Each unique Defined In path is one "feature". Non-FR slugs are collected separately for warning-level reporting.

3. **Filter to features with code** — For each feature, check if any of its FRs has a non-empty Code column. A feature with zero code entries is skipped.

4. **Read QA Coverage Matrix** — For each feature with code, construct the expected QA file path as `qa/<platform>/<feature>.md` where `<feature>` is the filename stem of the Defined In path (e.g., `coverage-audit` from `product/coverage-audit.md`) and `<platform>` is derived by iterating the `platforms` array from `pdeq.json`. For each platform's QA file:
   - Parse the Coverage Matrix section.
   - For each row, extract: Requirement slug, Test Cases (comma-separated TC slugs), Status.

5. **Join and evaluate** — For each Coverage Matrix row:
   - If the test-case column is empty or contains no `TC-` slug → skip (prose row).
   - If the Requirement slug is an `FR-` slug whose feature has code AND the status is non-terminal ("Not started", "In progress", "planned", empty, or unrecognized) → block (exit 1).
   - If the Requirement slug is an `NFR-` or `AC-` slug with non-terminal status → warn (no block).

6. **Report** — Print findings to stderr. Exit 0 if no blocking conditions were found.

### Reusing the existing QA parser

The script sources the existing QA Coverage Matrix parser from `scripts/audit-traceability.sh` by extracting the phase 7b parser logic into a shared helper, or by forking the parser into a sourced shell function library. The exact approach is:

- Extract the Coverage Matrix parsing regex and row-processing logic into `scripts/lib/qa-matrix.sh`, which is `source`d by both `audit-traceability.sh` and `audit-coverage.sh`.
- This avoids duplicating the parsing logic and ensures that format changes are reflected in both scripts.
- The parser emits tab-separated `requirement_slug<tab>tc_slugs<tab>status` rows on stdout.

### Determining the platform

The script reads `pdeq.json` to get the `platforms` array. For each platform, it looks for `qa/<platform>/<feature>.md`. It evaluates all platforms — a feature may have code on one platform and coverage on another, though in practice coverage and code are platform-paired.

If `pdeq.json` is absent or has no `platforms` array, the script defaults to probing `qa/*/<feature>.md` (all platform subdirectories under `qa/`).

### Feature name derivation

The feature name is the filename stem of the product spec path in the Defined In column. For example:
- `Defined In: product/coverage-audit.md` → feature name `coverage-audit`
- `Defined In: product/auth.md` → feature name `auth`
- `Defined In: product/web/auth.md` → feature name `auth` (platform supplement, same stem)

### Status vocabulary

The script recognizes these status values (case-sensitive, trimmed):
- **Terminal**: `Pass`, `Fail` — coverage has been executed.
- **Non-terminal**: Everything else — `Not started`, `In progress`, `planned`, empty string, or any unrecognized value.

### Escape hatch

The script checks `PDEQ_ALLOW_DRIFT` at startup (same as the other audits). When set to `1`:
- All blocking conditions are demoted to warnings.
- Each suppressed condition is named in the output.
- Exit code is 0.
- The output includes the line `[coverage-audit] PDEQ_ALLOW_DRIFT=1 active — coverage blocks suppressed`.

## Data Model

### Input files

| File | Purpose |
|---|---|
| `index.md` | Traceability index. Read-only. Provides the Code column (code existence signal) and the Defined In column (feature grouping). |
| `qa/<platform>/<feature>.md` | QA Coverage Matrix per feature per platform. Read-only. Provides requirement→status mapping. |
| `pdeq.json` | (Optional) Configuration. Read-only. Provides `platforms` array. |

### In-memory state

- `code_by_feature: Dict[feature_name → List[slug]]` — FRs per feature that have non-empty Code column.
- `coverage_by_feature: Dict[feature_name → List[(slug, tc_slugs, status)]]` — Coverage Matrix rows parsed per feature per platform.
- `blocking_rows: List[reason_string]` — Accumulated blocking conditions found during the join.
- `warning_rows: List[reason_string]` — Accumulated warning conditions.

## API / Interface Design

### `scripts/audit-coverage.sh`

Usage:

```bash
./scripts/audit-coverage.sh          # run coverage audit
./scripts/audit-coverage.sh --check  # run in CI mode (same behavior, explicit flag)
```

No arguments. The script reads `index.md`, `qa/`, and `pdeq.json` from the repo root automatically. It honors `PDEQ_ALLOW_DRIFT=1`.

### Environment variables

| Variable | Default | Effect |
|---|---|---|
| `PDEQ_ALLOW_DRIFT` | unset | When `1`, demotes all blocks to warnings, exit 0. |
| `PDEQ_CONFIG_PATH` | `pdeq.json` | Override path to `pdeq.json`. |
| `NO_COLOR` | unset | Suppresses ANSI color codes in output. |

### Exit codes

| Condition | Exit code | Message |
|---|---|---|
| All features with code have terminal coverage status | 0 | (no output, or summary) |
| At least one FR with code has non-terminal coverage | 1 | `✗ <feature>/<platform>: <slug> has code but coverage is <status>` |
| Missing `index.md` | 1 | `✗ index.md not found at <path>` |
| Missing `pdeq.json` (no platforms array) | 0 | `⚠ no platforms configured — no QA files checked` |
| `PDEQ_ALLOW_DRIFT=1` active | 0 | (warnings instead of blocks, override noted in output) |

## Component Architecture

### New files

| Path | Purpose |
|---|---|
| `scripts/audit-coverage.sh` | The standalone coverage audit script. Shell script using python3 for the join logic. |
| `scripts/lib/qa-matrix.sh` | Shared QA Coverage Matrix parser library, sourced by both `audit-traceability.sh` and `audit-coverage.sh`. Contains the `parse_qa_matrix` function. |

### Modified files

| Path | Change |
|---|---|
| `scripts/audit-traceability.sh` | Refactor phase 7b QA parser into `scripts/lib/qa-matrix.sh` and source it. No behavioral change. |
| `CLAUDE.md` (root) | Document the new audit script and its role alongside the existing audits. |

### Interaction with other audits

`audit-coverage.sh` is independent from `audit-traceability.sh`, `audit-lanes.sh`, and `audit-temporal.sh`. They can be composed in any order in CI or in the pre-commit hook chain. The only shared dependency is `scripts/lib/qa-matrix.sh`, which is a refactored extraction of existing logic — no circular dependency.

## State Management

The script is stateless. Every invocation re-reads `index.md`, `qa/`, and `pdeq.json` from disk. No lock files, no cache files, no state directory. Two consecutive runs on the same commit produce identical output.

## Error Handling

| Condition | Response |
|---|---|
| `index.md` not found | Exit 1 with descriptive error on stderr |
| `qa/<platform>/<feature>.md` not found | Skip that platform for that feature (no coverage file = nothing to check). Print a warning. |
| Coverage Matrix section not found in QA file | Skip that file (print a warning) |
| Coverage Matrix row missing Status column | Treat status as empty (non-terminal) |
| `pdeq.json` not found | Default to probing all `qa/*/` subdirectories |
| Malformed `index.md` row (missing columns) | Skip that row with a warning |
| `PDEQ_ALLOW_DRIFT=1` | Demote all blocks to warnings |

## Performance Considerations

### Target: sub-2-second audit

- `index.md` parsing: Python string split on `|`, O(number of rows). Negligible (index.md is typically < 200 rows).
- QA file scanning: one file read per feature per platform per invocation. Pdeq has ~10 feature specs × 1 platform = 10 QA files. Negligible.
- Coverage Matrix parsing: O(rows per file). Typically < 50 rows per file. Negligible.
- Total: well under 0.5s on the pdeq repo.

Measurement: the script includes `PDEQ_AUDIT_PROFILE=1` support (same env var the traceability audit uses) to print per-phase wall-clock timing.

### Determinism

- `index.md` rows are iterated in file order (deterministic).
- QA files are iterated in filesystem order (sorted by path to ensure determinism across platforms).
- Output is emitted in deterministic order: grouped by feature, then by file, then by row.
- Python's dictionary iteration is insertion-ordered (Python 3.7+) — the script uses sorted lists for the final report to guarantee determinism regardless of Python version.

## Security Considerations

- The script reads only; it never writes `index.md`, QA files, or `pdeq.json`.
- Paths from `index.md` and `pdeq.json` are validated against a known set of product spec paths and platform directories before being used in filesystem operations, preventing directory traversal via maliciously crafted index entries.
- `PDEQ_ALLOW_DRIFT` and other env vars are read-only and cannot inject commands.

## Implementation Plan

1. **Refactor QA parser** — Extract `parse_qa_matrix` from `scripts/audit-traceability.sh` into `scripts/lib/qa-matrix.sh`. Add source line to both scripts. No behavioral change. Rationale: shared parser prevents drift between the two audits.

2. **Implement `scripts/audit-coverage.sh`** — Write the standalone script with the full algorithm above using python3 for the join logic. Shell wrapper with sourced library. Rationale: the core deliverable.

3. **Test on pdeq repo** — Run against the pdeq repository itself to confirm it passes (pdeq has shipped code with markers but QA coverage may or may not be terminal). If it fails, note which features need coverage updated. Rationale: dogfooding.

4. **Add to CI pipeline** — Wire into the CI config alongside the other audits. Rationale: ensures coverage is checked on every PR.

## Requirements Coverage

| Slug | Engineering section | How addressed |
|---|---|---|
| FR-coverage-audit-code-signal | §Algorithm step 1: reads Code column from index.md | Code column is the marker-derived signal |
| FR-coverage-audit-feature-grouping | §Algorithm step 2: groups by Defined In path | Feature name = product spec filename stem |
| FR-coverage-audit-status-check | §Algorithm step 4–5: for each feature with code, reads QA matrix and checks status | Parser emits requirement→status rows |
| FR-coverage-audit-block | §Algorithm step 5: blocks on non-terminal FR coverage | Exit 1 with message |
| FR-coverage-audit-terminal-statuses | §Status vocabulary: Pass/Fail only | Any other value is non-terminal |
| FR-coverage-audit-prose-skip | §Algorithm step 5a: skips rows with no TC- slug | Parser skips empty TC columns |
| FR-coverage-audit-nfr-ac-best-effort | §Algorithm step 5: NFR/AC → warn only | Separate warn accumulator |
| FR-coverage-audit-escape-hatch | §Escape hatch: PDEQ_ALLOW_DRIFT=1 | Demotes to warn, names suppressed |
| FR-coverage-audit-reuse-parser | §Reusing the existing QA parser, §Implementation plan step 1 | Extracted to shared qa-matrix.sh |
| FR-coverage-audit-independent | §Component Architecture: standalone script | Not a phase of audit-traceability.sh |
| FR-coverage-audit-reads-index | §Data Model: index.md is read-only | Never writes to index.md |
| NFR-coverage-audit-speed | §Performance Considerations | Shell + python3, negligible input size |
| NFR-coverage-audit-determinism | §Determinism | Sorted iteration, no randomness |
| NFR-coverage-audit-precision | §Algorithm step 5: only FR- slugs gate | Non-FR slugs collected separately |

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-coverage-audit-code-signal | scripts/audit-coverage.py:parse_index | implemented |
| FR-coverage-audit-feature-grouping | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-status-check | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-block | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-terminal-statuses | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-prose-skip | scripts/audit-coverage.py:parse_qa_matrix | implemented |
| FR-coverage-audit-nfr-ac-best-effort | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-escape-hatch | scripts/audit-coverage.py:main | implemented |
| FR-coverage-audit-reuse-parser | scripts/lib/qa-matrix.sh | implemented |
| FR-coverage-audit-independent | scripts/audit-coverage.sh | implemented |
| FR-coverage-audit-reads-index | scripts/audit-coverage.py:parse_index | implemented |

NFRs (speed, determinism, precision) are cross-cutting properties of the whole script, not one-line implementations — not listed in the Code Map.
