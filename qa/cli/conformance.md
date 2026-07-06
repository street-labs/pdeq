---
product-hash: 388b024e9649caa2071e10d74599313a3e9988635ee891f5a6a7d251f60c704c
product-slugs: [AC-conformance-evidence-cited, AC-conformance-exhaustive, AC-conformance-incorrect-detected, AC-conformance-no-plumbing, AC-conformance-non-blocking, AC-conformance-platform-isolation, AC-conformance-report-shape, AC-conformance-uncertainty-marked, AC-conformance-undocumented-detected, AC-conformance-unfulfilled-behavioral, FR-conformance-actionable, FR-conformance-advisory, FR-conformance-complements, FR-conformance-evidence, FR-conformance-four-quadrant, FR-conformance-fulfilled, FR-conformance-incorrect, FR-conformance-per-platform, FR-conformance-requirement-scope, FR-conformance-seeded, FR-conformance-single-verdict, FR-conformance-summary, FR-conformance-undocumented, FR-conformance-unfulfilled, NFR-conformance-precision, NFR-conformance-uncertainty, NFR-conformance-verifiable]
---
# Platform Conformance Audit — CLI Test Plan

> Based on requirements in `../../product/conformance.md`
> Based on technical spec in `../../engineering/cli/conformance.md`
> (No design spec — feature has no UI surface.)

## What We're Testing

The conformance audit is an **advisory, agent-driven** reviewer: it reads a platform's source against that platform's specs and emits a four-quadrant report — **fulfilled**, **unfulfilled**, **incorrectly fulfilled**, and **undocumented**. Its verdicts are LLM judgments about *behavior*, not lexical facts, so — like the Lane Reviewer's Layer 2 (`qa/cli/lane-discipline.md`) — its test cases are almost entirely **scenario/fixture-based with manual verification**, not deterministic asserts.

The strategy is a single small **fixture repo** (`conformance-demo/`) whose code is deliberately seeded so that each of the four quadrants has a known-correct answer. We run `/pdeq-conform` against that fixture and a human checks that the produced report places each seeded case in the right quadrant, cites evidence, stays exhaustive, marks its uncertainty, and never blocks a commit. The anchor case — the one thing this reviewer does that the deterministic audit (`qa/cli/code-mapping.md`) cannot — is **incorrectly fulfilled**: code carrying a *valid* `// Implements:` marker that nonetheless contradicts its requirement. That case passes the deterministic audit and must be caught here.

## Test Strategy

### How these cases are executed

Because the verdicts are judgment-based, there is **no deterministic runner**. Each case is executed by:

1. Materializing the `conformance-demo/` fixture at a known git state (below).
2. Running `/pdeq-conform <platform> [--feature <feature>]` (or the equivalent `.pdeq/pdeq-rules/commands/pdeq-conform.md` workflow in a non-Claude harness) against it.
3. **Human-checking** the emitted report against the expected quadrant placement, evidence citations, and confidence markings recorded in each case.

A case "passes" when a reviewer confirms the report matches the expected outcome. There is no `assert_*` helper; the check is a human reading the four-quadrant report. Where a case is partially machine-checkable (report *shape*, section presence, non-blocking commit behavior), that portion is noted as semi-auto.

### Automation split

| Aspect | Auto/Manual |
|---|---|
| Quadrant classification of a seeded case | Manual (human confirms the verdict) |
| Report contains the summary + four labeled sections | Semi-auto (section-presence check) |
| Commit is not blocked | Semi-auto (commit exit status) |
| Every finding cites `file:line` + slug | Semi-auto (each cited path/line/slug is resolvable) + Manual (relevance) |

The split is intrinsic: presence and format are scriptable; whether a verdict is *correct* is a judgment.

---

## Fixture Catalogue

A single fixture repo, `conformance-demo/`, with **two platforms** so isolation can be tested. Platform `demo` is the platform under audit; platform `other` exists only to prove it is never surfaced.

The `demo` platform realizes one product feature, `product/orders.md`, seeded so that every quadrant has a known answer:

| Requirement (in `product/orders.md`) | Code state under `engineering/apps/demo/` | Expected quadrant |
|---|---|---|
| `FR-ex-orders-reject-negative-total` — reject an order whose total is negative | `validateTotal()` correctly rejects `total < 0`, marker present | **Fulfilled** |
| `FR-ex-orders-discount-cap` — a discount may never exceed 50% of subtotal | `applyDiscount()` carries a valid `// Implements: FR-ex-orders-discount-cap` marker but the guard is inverted / caps at 150% — contradicts the threshold | **Incorrectly fulfilled** |
| `FR-ex-orders-email-receipt` — email a receipt after checkout completes | `sendReceipt()` carries the marker but its body is an empty stub (`return; // TODO`) — no real behavior | **Unfulfilled** |
| `FR-ex-orders-round-currency` — monetary amounts are rounded to the currency's minor unit | partial/ambiguous realization: rounding happens in one path but not another; hard to judge from source alone | **Fulfilled or Incorrectly fulfilled, marked low-confidence** |
| *(no requirement)* — `applyLoyaltyPoints()` awards and redeems loyalty points, real product behavior | live, product-relevant code with no owning slug | **Undocumented** |
| *(no requirement)* — `main.ts` framework bootstrap, `generated/schema.ts`, `orders.config.json`, `orders.test.ts` test-support | scaffolding / generated / config / test code | **Not flagged** (NFR precision) |

Additional fixture variants (git states of the same repo), used by edge cases:

| Variant | Purpose | Contents |
|---|---|---|
| `demo-empty/` | Platform declared, no code yet. | `product/orders.md` present; `engineering/apps/demo/` empty or absent. |
| `demo-fully-documented/` | Every behavior owns a requirement. | The `applyLoyaltyPoints()` behavior has a matching `FR-ex-orders-loyalty-points` requirement added; nothing undocumented remains. |
| `demo-clean-commit/` | Non-blocking proof. | The full `demo` fixture with a pre-commit hook installed and a staged change; used to confirm a commit succeeds even when the audit would report findings. |

---

## Coverage Matrix

| AC | Test case(s) | Auto/Manual | Status |
|---|---|---|---|
| `AC-conformance-report-shape` | `TC-conformance-report-shape` | Semi-auto | Not started |
| `AC-conformance-incorrect-detected` | `TC-conformance-incorrect-detected` | Manual | Not started |
| `AC-conformance-undocumented-detected` | `TC-conformance-undocumented-detected` | Manual | Not started |
| `AC-conformance-unfulfilled-behavioral` | `TC-conformance-unfulfilled-behavioral` | Manual | Not started |
| `AC-conformance-exhaustive` | `TC-conformance-exhaustive` | Semi-auto | Not started |
| `AC-conformance-evidence-cited` | `TC-conformance-evidence-cited` | Semi-auto | Not started |
| `AC-conformance-non-blocking` | `TC-conformance-non-blocking` | Semi-auto | Not started |
| `AC-conformance-platform-isolation` | `TC-conformance-platform-isolation` | Manual | Not started |
| `AC-conformance-no-plumbing` | `TC-conformance-no-plumbing` | Manual | Not started |
| `AC-conformance-uncertainty-marked` | `TC-conformance-uncertainty-marked` | Manual | Not started |

Supporting cases (no direct AC — cover FR/NFR behavior):
`TC-conformance-fulfilled-genuine` (`FR-conformance-fulfilled`, `FR-conformance-four-quadrant`), `TC-conformance-summary` (`FR-conformance-summary`), `TC-conformance-actionable` (`FR-conformance-actionable`), `TC-conformance-seeded` (`FR-conformance-seeded`), `TC-conformance-scope-single-feature` (`FR-conformance-requirement-scope`), `TC-conformance-complements-deterministic` (`FR-conformance-complements`, the complementarity proof).

---

## Test Cases

All cases below run `/pdeq-conform demo` against the `conformance-demo/` fixture unless a different platform, feature scope, or variant is named. Verification is a human reading the emitted report against the **Expected Result**, except where a step is marked semi-auto.

### Report Shape & Exhaustiveness

Probes that the report is always the same four-quadrant shape and accounts for every requirement.

#### Four-quadrant report produced `TC-conformance-report-shape`
- **Type**: Integration / Manual (semi-auto on structure)
- **Covers**: `AC-conformance-report-shape`, `FR-conformance-four-quadrant`, `FR-conformance-summary`
- **Preconditions**: `conformance-demo/` fixture; audit `demo`.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Inspect the report structure.
- **Expected Result**: The report opens with a per-platform **summary** and contains all four labeled categories — *fulfilled*, *unfulfilled*, *incorrectly fulfilled*, *undocumented* — each either populated with findings or **explicitly marked empty** (never silently omitted). Structure/section-presence is machine-checkable; content is human-confirmed.

#### Conformance-at-a-glance summary `TC-conformance-summary`
- **Type**: Integration / Manual
- **Covers**: `FR-conformance-summary`
- **Preconditions**: `conformance-demo/` fixture.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Read the opening summary block.
- **Expected Result**: The summary counts requirements in each quadrant (e.g. fulfilled: 1, unfulfilled: 1, incorrectly fulfilled: 1, plus the low-confidence one; undocumented: 1) and precedes the detailed findings, so a reader can judge conformance before reading detail.

#### Every requirement gets exactly one verdict `TC-conformance-exhaustive`
- **Type**: Integration / Manual (semi-auto on completeness)
- **Covers**: `AC-conformance-exhaustive`, `FR-conformance-single-verdict`
- **Preconditions**: `conformance-demo/` fixture; audit is scoped to feature `orders`.
- **Steps**:
  1. Enumerate every `FR-ex-orders-*` slug defined in `product/orders.md`.
  2. Run `/pdeq-conform demo --feature orders`.
  3. Cross-check each defined slug against the report.
- **Expected Result**: Every requirement defined in `product/orders.md` appears in the report with **exactly one** of the three requirement verdicts (fulfilled / unfulfilled / incorrectly fulfilled) — no requirement is missing, none appears in two quadrants. The report is an exhaustive account of the requirement set, not a sample.

### Quadrant Classification

The core of the feature: each seeded case must land in the correct quadrant.

#### Genuinely fulfilled requirement `TC-conformance-fulfilled-genuine`
- **Type**: Integration / Manual
- **Covers**: `FR-conformance-fulfilled`, `FR-conformance-four-quadrant`
- **Preconditions**: `conformance-demo/`; `validateTotal()` correctly rejects negative totals and carries `// Implements: FR-ex-orders-reject-negative-total`.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Locate `FR-ex-orders-reject-negative-total` in the report.
- **Expected Result**: The requirement is reported under **fulfilled**, on the basis that the code realizes the specified behavior — not merely because a marker is present.

#### Incorrect fulfilment detected `TC-conformance-incorrect-detected`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-incorrect-detected`, `FR-conformance-incorrect`, `FR-conformance-complements`
- **Preconditions**: `conformance-demo/`; `applyDiscount()` carries a **valid** `// Implements: FR-ex-orders-discount-cap` marker but its guard is inverted / caps discounts at 150% of subtotal — directly contradicting the "never exceed 50%" threshold. The deterministic audit passes this code (marker present, slug real).
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Locate `FR-ex-orders-discount-cap` in the report.
- **Expected Result**: The requirement is reported under **incorrectly fulfilled**, and the finding **describes the divergence** (code allows up to 150% where the spec caps at 50%). This is the differentiator from the deterministic audit: a valid marker on divergent code passes the lexical check but is caught here. This is the single most important case in the plan.

#### Unfulfilled goes beyond marker presence `TC-conformance-unfulfilled-behavioral`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-unfulfilled-behavioral`, `FR-conformance-unfulfilled`
- **Preconditions**: `conformance-demo/`; `sendReceipt()` carries `// Implements: FR-ex-orders-email-receipt` but its body is an empty stub with no real behavior.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Locate `FR-ex-orders-email-receipt` in the report.
- **Expected Result**: The requirement is reported under **unfulfilled**, demonstrating the verdict is **behavioral** — a marker exists (so the deterministic coverage check is satisfied) yet no realizing behavior exists, and conformance reports it as unfulfilled anyway.

#### Undocumented behavior detected `TC-conformance-undocumented-detected`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-undocumented-detected`, `FR-conformance-undocumented`
- **Preconditions**: `conformance-demo/`; `applyLoyaltyPoints()` is live product-relevant behavior with no owning requirement slug.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Read the **undocumented** section.
- **Expected Result**: The loyalty-points behavior appears under **undocumented** with its code location, flagged as a candidate to either specify or remove. This exercises reverse traceability — the deterministic audit is requirement-driven and never inspects code no requirement points to.

#### No plumbing false positives `TC-conformance-no-plumbing`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-no-plumbing`, `NFR-conformance-precision`
- **Preconditions**: `conformance-demo/` includes `main.ts` (framework bootstrap), `generated/schema.ts` (generated), `orders.config.json` (config), and `orders.test.ts` (test-support) — none of which realize a product requirement.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Read the **undocumented** section.
- **Expected Result**: **None** of the scaffolding, generated, config, or test-support files is reported as undocumented behavior. Undocumented findings name product-relevant behavior only — incidental plumbing is high-signal-filtered out.

### Evidence, Actionability & Uncertainty

Probes the quality contract on every finding.

#### Findings cite evidence `TC-conformance-evidence-cited`
- **Type**: Integration / Manual (semi-auto on resolvability)
- **Covers**: `AC-conformance-evidence-cited`, `FR-conformance-evidence`, `NFR-conformance-verifiable`
- **Preconditions**: `conformance-demo/` (which yields non-fulfilled findings).
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. For each finding, extract the cited code location and slug/behavior.
  3. Open each cited `file:line` and confirm it exists and is relevant.
- **Expected Result**: Every finding names at least one concrete code location (`file:line`) **and** the specific requirement slug or behavior it is judged against. Every cited location resolves to a real line (semi-auto), and the line is genuinely relevant to the verdict (manual) — a reader can confirm or refute without re-deriving.

#### Recommended action per finding `TC-conformance-actionable`
- **Type**: Integration / Manual
- **Covers**: `FR-conformance-actionable`
- **Preconditions**: `conformance-demo/`.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Read each non-fulfilled finding.
- **Expected Result**: Each non-fulfilled finding (unfulfilled, incorrectly fulfilled, undocumented) states a recommended next action — e.g. fix the discount guard, implement `sendReceipt()`, add a loyalty-points requirement or remove the code. The report drives work, it does not merely describe state.

#### Uncertainty is marked `TC-conformance-uncertainty-marked`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-uncertainty-marked`, `NFR-conformance-uncertainty`
- **Preconditions**: `conformance-demo/`; `FR-ex-orders-round-currency` has an ambiguous realization (rounding present in one path, absent in another) that is hard to judge from source alone.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Locate the `FR-ex-orders-round-currency` verdict.
- **Expected Result**: The verdict for the ambiguous requirement is presented as a **marked, lower-confidence suspicion** — distinguishable from the firm verdicts on the other requirements — rather than asserted with false certainty. A reader can tell a firm verdict from a flagged suspicion.

### Scope, Seeding & Isolation

Probes that the audit is correctly scoped and grounded.

#### Per-platform isolation `TC-conformance-platform-isolation`
- **Type**: Integration / Manual
- **Covers**: `AC-conformance-platform-isolation`, `FR-conformance-per-platform`
- **Preconditions**: `conformance-demo/` contains two platforms, `demo` and `other`, each with its own requirements and code.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Scan the report for any `other`-platform requirement slug or code path.
- **Expected Result**: The report contains **only** `demo`'s requirements and code. No `other`-platform requirement or finding appears. A run for one platform never surfaces another's.

#### Grounded in existing traceability `TC-conformance-seeded`
- **Type**: Integration / Manual
- **Covers**: `FR-conformance-seeded`
- **Preconditions**: `conformance-demo/` has a populated engineering Code Map for `demo` and code-location entries in `index.md`.
- **Steps**:
  1. Run `/pdeq-conform demo`.
  2. Confirm the audit's fulfilled/unfulfilled starting points align with the Code Map and index rather than being rediscovered from scratch, then observe it reasons beyond them (e.g. reaching the *incorrectly fulfilled* verdict the Code Map alone does not encode).
- **Expected Result**: The audit begins from the existing requirement-to-code mapping (Code Map + index) and extends it to the four-quadrant verdicts — it does not ignore the maintained mapping, nor does it stop at it.

#### Narrowing to a single feature `TC-conformance-scope-single-feature`
- **Type**: Integration / Manual
- **Covers**: `FR-conformance-requirement-scope`
- **Preconditions**: `conformance-demo/` where `demo` realizes more than one feature; audit narrowed to `orders`.
- **Steps**:
  1. Run `/pdeq-conform demo --feature orders`.
- **Expected Result**: The report covers exactly the requirements from the `orders` product spec (plus any `orders` platform supplement), and does not enumerate other features' requirements — a reader can focus the review.

### Advisory, Never Gating

#### Never blocks a commit `TC-conformance-non-blocking`
- **Type**: Integration (semi-auto on exit status)
- **Covers**: `AC-conformance-non-blocking`, `FR-conformance-advisory`
- **Preconditions**: `demo-clean-commit/` variant — the full `demo` fixture (which the audit would report findings on) with the pre-commit hook installed and a staged change.
- **Steps**:
  1. Run `/pdeq-conform demo` directly and observe it completes.
  2. Attempt a `git commit` of the staged change.
- **Expected Result**: The audit completes and produces a report; the commit **succeeds** despite the fixture containing incorrectly-fulfilled, unfulfilled, and undocumented findings. Conformance never wires itself into a commit/push gate — it mirrors the Lane Reviewer's advisory precedent.

#### Complements the deterministic audit `TC-conformance-complements-deterministic`
- **Type**: Integration / Manual (the complementarity proof)
- **Covers**: `FR-conformance-complements`, `FR-conformance-incorrect`
- **Preconditions**: `conformance-demo/` with the inverted `applyDiscount()` guard (`FR-ex-orders-discount-cap`).
- **Steps**:
  1. Run the deterministic traceability audit (`scripts/audit-traceability.sh`) on the fixture.
  2. Run `/pdeq-conform demo` on the same fixture.
  3. Compare the two outputs for `FR-ex-orders-discount-cap`.
- **Expected Result**: The deterministic audit **passes** the discount guard (valid marker, real slug) and reports nothing wrong; the conformance audit reports it as **incorrectly fulfilled**. This is concrete evidence the two are complementary, not redundant — the deterministic audit remains the fast commit-time gate for marker/slug validity, conformance adds the semantic layer.

---

## Edge Cases & Error Scenarios

Adversarial and boundary conditions for a judgment-based reviewer.

### Platform declared but no code yet
- **Trigger**: Audit a platform whose product spec exists but whose `engineering/apps/<platform>/` is empty or absent (variant `demo-empty/`).
- **Expected behavior**: Every requirement lands in **unfulfilled** (no realizing behavior exists); *fulfilled*, *incorrectly fulfilled*, and *undocumented* sections are present but **explicitly empty**. The audit does not error or produce a malformed report.
- **Test case**: `TC-conformance-report-shape` (empty-code variant) / `TC-conformance-unfulfilled-behavioral`.

### Feature with zero undocumented behavior
- **Trigger**: Audit a platform where every product-relevant behavior owns a requirement (variant `demo-fully-documented/`, where loyalty points has a real `FR-ex-orders-loyalty-points`).
- **Expected behavior**: The **undocumented** section is present and **explicitly empty** ("No undocumented behavior found"), not omitted. Confirms an empty quadrant is stated, not silently dropped — reinforcing `AC-conformance-report-shape`.
- **Test case**: `TC-conformance-undocumented-detected` (negative variant).

### Unknown / unconfigured platform argument
- **Trigger**: Run `/pdeq-conform nonexistent` for a platform not declared in `pdeq.json`'s `platforms` and with no `engineering/apps/nonexistent/`.
- **Expected behavior**: The audit reports a clear "unknown platform" error and does **not** emit a spurious four-quadrant report or fabricate findings. Being advisory, it exits without blocking anything.
- **Test case**: `TC-conformance-platform-isolation` (unknown-arg variant).

### All requirements fulfilled
- **Trigger**: Audit a platform whose code correctly realizes every requirement and introduces no undocumented behavior.
- **Expected behavior**: The *fulfilled* section lists every requirement; the other three sections are present and explicitly empty; the summary reflects a fully-conformant platform. No false-positive divergences are invented.
- **Test case**: `TC-conformance-exhaustive` (all-fulfilled variant).

---

## Regression Considerations

- **Deterministic audit unchanged.** Conformance must not alter the behavior or exit status of `scripts/audit-traceability.sh`, `scripts/audit-structure.sh`, or `scripts/audit-lanes.sh`. `TC-conformance-complements-deterministic` guards that the deterministic gate keeps passing exactly what it passed before.
- **No commit-path coupling.** Because the audit is advisory, its introduction must not add any pre-commit/pre-push step. `TC-conformance-non-blocking` is the standing regression guard against accidental gating.
- **Marker/Code-Map conventions untouched.** Conformance consumes the Code Map and index (`FR-conformance-seeded`) but must not redefine markers or coverage rules owned by `product/code-mapping.md`; changes there should not require changes here beyond re-seeding the fixture.

## Open Questions

- Whether the report shape and empty-section presence can be partially `[auto]` via a lightweight report-structure linter, leaving only quadrant *correctness* manual. Deferred — classification is intrinsically judgment-based today.
- Requirement types in scope (per product Open Questions): whether verdicts cover `FR-` only or also `NFR-`/`AC-`. This plan seeds `FR-` cases; NFR/AC verdict coverage will be added once engineering settles the initial scope.
