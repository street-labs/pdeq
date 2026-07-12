---
product-hash: 256193cc07e7b5870b081d2ba69f0069333030f516ad94f5b6a4a6e525f6e66d
product-slugs: [AC-living-spec-graduation-moves-content, AC-living-spec-roadmap-not-scanned, AC-living-spec-roadmap-slugs-exempt, AC-living-spec-roadmap-spec-sections, AC-living-spec-template-has-guidance, AC-living-spec-temporal-in-kickoff, AC-living-spec-temporal-patterns-detected, AC-living-spec-temporal-suggestions, FR-living-spec-kickoff-temporal-check, FR-living-spec-multi-phase-roadmap, FR-living-spec-roadmap-graduation, FR-living-spec-roadmap-slug-prefix, FR-living-spec-roadmap-supplements, FR-living-spec-template-guidance, FR-living-spec-temporal-audit-exemptions, FR-living-spec-temporal-audit-modes, FR-living-spec-temporal-audit-patterns, FR-living-spec-temporal-audit-rewording, NFR-living-spec-deterministic-audit, NFR-living-spec-low-noise, NFR-living-spec-roadmap-lightweight-default]
---
# Living Spec Discipline — Test Plan

> Based on requirements in `../../product/living-spec-discipline.md`
> Based on technical spec in `../../engineering/cli/living-spec-discipline.md`

## What We're Testing

The temporal language audit script (`scripts/audit-temporal.sh`) and its integration into the kickoff workflow, plus the roadmap slug exemption in the traceability audit. Testing verifies that the audit correctly detects all configured patterns, suggests appropriate fixes, respects exemptions, and integrates cleanly into the commit and kickoff workflows without false positives or missed violations.

## Coverage Matrix

| Requirement | Test Cases | Status |
|---|---|---|
| `AC-living-spec-roadmap-spec-sections` | `TC-living-spec-roadmap-frr-recognized` | Not started |
| `AC-living-spec-roadmap-slugs-exempt` | `TC-living-spec-roadmap-slugs-no-warn` | Not started |
| `AC-living-spec-graduation-moves-content` | `TC-living-spec-graduation-renumber` | Not started |
| `AC-living-spec-temporal-patterns-detected` | `TC-living-spec-mvp-detected`, `TC-living-spec-phase-detected`, `TC-living-spec-v2-detected`, `TC-living-spec-future-detected` | Not started |
| `AC-living-spec-temporal-suggestions` | `TC-living-spec-suggestion-format` | Not started |
| `AC-living-spec-temporal-in-kickoff` | `TC-living-spec-kickoff-runs-audit` | Not started |
| `AC-living-spec-roadmap-not-scanned` | `TC-living-spec-roadmap-exempt-scan` | Not started |
| `AC-living-spec-template-has-guidance` | `TC-living-spec-template-reminder` | Not started |

## Test Cases

### Roadmap Spec Supplements

Tests that roadmap can hold spec-shaped content with reserved slug prefixes and that those slugs are exempt from traceability.

#### Roadmap FRR slugs recognized `TC-living-spec-roadmap-frr-recognized`
- **Type**: Integration
- **Covers**: `AC-living-spec-roadmap-spec-sections`, `FR-living-spec-roadmap-supplements`, `FR-living-spec-roadmap-slug-prefix`
- **Preconditions**: Create a test roadmap file `roadmap/test-feature.md` with content like:
  ```markdown
  ## V2
  - **Future requirement** `FRR-test-future-login`: Users will authenticate via OAuth.
  - **Performance goal** `NFRR-test-future-perf`: Response time under 200ms.
  
  ## Acceptance Criteria
  - [ ] **OAuth flow works** `ACR-test-oauth-flow`: OAuth login succeeds.
  ```
- **Steps**:
  1. Run `grep -r 'FRR-\|NFRR-\|ACR-' roadmap/test-feature.md`
  2. Verify the slugs are found
  3. Run `./scripts/audit-traceability.sh`
  4. Check that no orphan-slug warnings appear for `FRR-`, `NFRR-`, `ACR-` slugs
- **Expected Result**: The roadmap slugs are visible in the file, but the traceability audit does not warn about them being undefined or missing from `index.md`.

#### Roadmap slugs exempt from traceability warnings `TC-living-spec-roadmap-slugs-no-warn`
- **Type**: Unit
- **Covers**: `AC-living-spec-roadmap-slugs-exempt`, `FR-living-spec-roadmap-slug-prefix`
- **Preconditions**: Same test roadmap file as above, plus a design spec that references `FRR-test-future-login`
- **Steps**:
  1. Add a reference to `FRR-test-future-login` in a design spec
  2. Run `./scripts/audit-traceability.sh`
  3. Check stderr for orphan warnings
- **Expected Result**: No warning about `FRR-test-future-login` being orphaned or undefined. The traceability audit skips all `FRR-`/`NFRR-`/`ACR-` prefixes.

#### Graduated roadmap content renumbered `TC-living-spec-graduation-renumber`
- **Type**: Manual
- **Covers**: `AC-living-spec-graduation-moves-content`, `FR-living-spec-roadmap-graduation`
- **Preconditions**: A roadmap file with `FRR-ex-test-x` and matching product spec `product/ex-test.md`
- **Steps**:
  1. Copy the requirement text from `FRR-ex-test-x` in roadmap
  2. Add it to `product/ex-test.md` with a new slug `FR-ex-test-x`
  3. Delete the `FRR-ex-test-x` entry from the roadmap
  4. Run `./scripts/audit-traceability.sh`
- **Expected Result**: The new `FR-ex-test-x` is recognized as authoritative; the old `FRR-` slug no longer appears anywhere. The graduation happened cleanly.

### Temporal Language Detection

Tests that the audit script correctly identifies temporal and phasing language patterns.

#### MVP pattern detected `TC-living-spec-mvp-detected`
- **Type**: Unit
- **Covers**: `AC-living-spec-temporal-patterns-detected`, `FR-living-spec-temporal-audit-patterns`
- **Preconditions**: Create a test product spec `product/test-temporal.md` with the line: "The MVP will include email login."
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check the output for a finding referencing `product/test-temporal.md` and the word "MVP"
- **Expected Result**: The audit reports `product/test-temporal.md:<line>: MVP [suggested fix: ...]`

#### Phase pattern detected `TC-living-spec-phase-detected`
- **Type**: Unit
- **Covers**: `AC-living-spec-temporal-patterns-detected`, `FR-living-spec-temporal-audit-patterns`
- **Preconditions**: Add the line "Phase 1 includes basic auth." to `product/test-temporal.md`
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check for a finding with "phase 1"
- **Expected Result**: The audit flags the line containing "Phase 1".

#### Version pattern detected `TC-living-spec-v2-detected`
- **Type**: Unit
- **Covers**: `AC-living-spec-temporal-patterns-detected`, `FR-living-spec-temporal-audit-patterns`
- **Preconditions**: Add "V2 will add OAuth support." to `product/test-temporal.md`
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check for a finding with "V2"
- **Expected Result**: The audit flags "V2".

#### Future/planned language detected `TC-living-spec-future-detected`
- **Type**: Unit
- **Covers**: `AC-living-spec-temporal-patterns-detected`, `FR-living-spec-temporal-audit-patterns`
- **Preconditions**: Add "This will be implemented later." to `product/test-temporal.md`
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check for findings with "will be implemented" and "later"
- **Expected Result**: Both phrases are flagged.

#### Suggested rewording format `TC-living-spec-suggestion-format`
- **Type**: Integration
- **Covers**: `AC-living-spec-temporal-suggestions`, `FR-living-spec-temporal-audit-rewording`
- **Preconditions**: `product/test-temporal.md` with "Phase 1: basic login."
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Read the output line for this finding
  3. Verify it includes a suggested fix (e.g., "[Move to roadmap with FRR- slugs, or rewrite as 'Basic login is supported']")
- **Expected Result**: Each finding includes a `[suggested fix: ...]` or similar guidance.

### Audit Modes and Integration

Tests for on-demand, CI, and kickoff integration modes.

#### Kickoff runs temporal audit `TC-living-spec-kickoff-runs-audit`
- **Type**: Integration
- **Covers**: `AC-living-spec-temporal-in-kickoff`, `FR-living-spec-kickoff-temporal-check`
- **Preconditions**: A kickoff workflow that creates a new product spec
- **Steps**:
  1. Run `/pdeq-kickoff` for a new feature, ensuring the generated product spec contains "MVP" or another temporal keyword
  2. Observe the Step 4 quality-check output
  3. Check if the temporal audit findings are reported
- **Expected Result**: The kickoff Step 4 output includes a "Temporal language audit" section with findings (if any temporal language is present).

#### Roadmap directory exempt from temporal audit `TC-living-spec-roadmap-exempt-scan`
- **Type**: Unit
- **Covers**: `AC-living-spec-roadmap-not-scanned`, `FR-living-spec-temporal-audit-exemptions`
- **Preconditions**: `roadmap/test-feature.md` with "V2 will add X" (legitimate roadmap content)
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check that `roadmap/test-feature.md` is not listed in findings
- **Expected Result**: No findings from `roadmap/` directory. The audit only scans `product/`, `design/`, `engineering/`, `qa/`.

#### Decisions log exempt from temporal audit `TC-living-spec-decisions-exempt`
- **Type**: Unit
- **Covers**: `FR-living-spec-temporal-audit-exemptions`
- **Preconditions**: `decisions.md` with a historical entry mentioning "phase 1 shipped in Q2"
- **Steps**:
  1. Run `./scripts/audit-temporal.sh`
  2. Check findings
- **Expected Result**: `decisions.md` is not scanned; no findings reported from it.

### Template Guidance

#### Product template includes living-spec reminder `TC-living-spec-template-reminder`
- **Type**: Manual
- **Covers**: `AC-living-spec-template-has-guidance`, `FR-living-spec-template-guidance`
- **Preconditions**: None
- **Steps**:
  1. Read `product/AGENTS.md`
  2. Find the "Guidelines" section
  3. Check for a note reminding authors to use present tense and park future plans in roadmap
- **Expected Result**: The template guidelines include text like "Specs describe current state; forward-looking ideas belong in roadmap, not in the spec."

### Edge Cases & Error Scenarios

#### Pattern in code fence not flagged as high priority
- **Trigger**: A product spec includes a code fence or literal block with "MVP" in an example.
- **Expected behavior**: The audit still flags it (per the engineering spec: "specs should not embed temporal language even in examples"), but the suggestion is to reword the example or use `FR-ex-` slugs instead.
- **Test case**: `TC-living-spec-code-fence-flagged`

#### Malformed pdeq.json temporalAudit config
- **Trigger**: `pdeq.json` exists but `temporalAudit.patterns` is not an array.
- **Expected behavior**: The audit warns about the malformed config and falls back to default patterns.
- **Test case**: `TC-living-spec-config-fallback`

#### Check mode exits non-zero on findings
- **Trigger**: Run `./scripts/audit-temporal.sh --check` when temporal language exists.
- **Expected behavior**: Exit code 1.
- **Test case**: `TC-living-spec-check-mode-exit`

#### Staged mode scans only staged files
- **Trigger**: Run `./scripts/audit-temporal.sh --staged` with temporal language in an unstaged file.
- **Expected behavior**: The unstaged file is not scanned; no findings from it.
- **Test case**: `TC-living-spec-staged-mode`

## Regression Considerations

- **Traceability audit must still work**: Extending `audit-traceability.sh` to skip roadmap slugs should not break existing slug validation. Run the full traceability suite after the change.
- **Kickoff workflow must still complete**: Adding the temporal audit to Step 4 should not break the kickoff flow if no findings are present, or if findings are present but non-blocking.
- **Existing specs may have temporal language**: The initial run of the temporal audit on an existing pdeq project will likely find many violations. This is expected. The audit defaults to warn-only (does not block commits) until the project is cleaned up.
