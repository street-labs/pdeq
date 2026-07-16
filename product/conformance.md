# Platform Conformance Audit

## Overview

Pdeq's deterministic traceability audit answers "does every requirement have a marker, and does every marker cite a real slug?" — a fast, lexical, commit-blocking check. It cannot answer the harder questions a reviewer actually cares about: does the code *behave* the way the requirement says, is a requirement only *pretending* to be implemented, and is there behavior in the code that no requirement describes at all? The conformance audit fills that gap. It is an **advisory** review that reasons about a platform's source against that platform's specs and reports how well the implementation actually conforms to the requirement set.

Run for a single platform, it produces a four-quadrant picture: requirements that are genuinely **fulfilled**, requirements that are **unfulfilled** (no real behavior behind them, even if a marker exists), requirements that are **incorrectly fulfilled** (code that diverges from what the spec says), and **undocumented** behavior (code doing something no requirement asked for). It is the semantic counterpart to the deterministic audit — it never blocks a commit; it hands a human or agent a prioritized, evidence-backed list of where implementation and intent have drifted apart. It joins the Reviewer, Consistency Checker, and Lane Reviewer as the fourth pdeq quality reviewer.

## User Stories

- As a **reviewing agent or maintainer**, I want to see which requirements a platform actually fulfills — not just which ones have a marker — so that I can trust the implementation matches intent before I sign off.
- As a **maintainer inheriting a codebase**, I want a per-platform report of where code diverges from its spec so that I can find the risky drift without reading every file against every requirement by hand.
- As a **maintainer**, I want behavior that exists in code but is described by no requirement surfaced as *undocumented* so that I can decide to either specify it or remove it, closing the reverse-traceability gap.
- As a **product owner**, I want a conformance-at-a-glance summary per platform so that I can judge how complete and correct a platform's implementation is against its stated requirements.
- As a **maintainer**, I want this review to be advisory and never block a commit so that a judgment-based, occasionally-uncertain check never becomes a merge gate.

## Requirements

### The Conformance Report

The audit's output is a per-platform report that classifies the relationship between the platform's requirements and its code.

- **Four-quadrant classification** `FR-conformance-four-quadrant`: The report classifies the requirement-to-code relationship into four categories: **fulfilled**, **unfulfilled**, **incorrectly fulfilled** (each a verdict on a requirement), and **undocumented** (behavior in code with no owning requirement).
- **Fulfilled requirements** `FR-conformance-fulfilled`: A requirement is reported as *fulfilled* when the platform's code realizes the behavior the requirement specifies. This is a judgment about behavior, not merely the presence of a marker.
- **Unfulfilled requirements** `FR-conformance-unfulfilled`: A requirement is reported as *unfulfilled* when the platform's code contains no realization of it, or a realization too incomplete to satisfy the specified behavior — even if an inline marker cites the requirement. This sharpens the deterministic coverage check, which is satisfied by marker presence alone.
- **Incorrectly fulfilled requirements** `FR-conformance-incorrect`: A requirement is reported as *incorrectly fulfilled* when code exists that claims or attempts to realize it but diverges from the specified behavior — wrong condition, missing case, contradicted threshold, or behavior the spec forbids. This is the drift the deterministic audit cannot see, because a valid marker on divergent code still passes it.
- **Undocumented behavior** `FR-conformance-undocumented`: The report identifies behavior realized in the platform's code that no requirement in scope describes, as candidates to either specify or remove. This is reverse traceability: the deterministic audit is requirement-driven and never looks at code that no requirement points to.
- **Spec temporal compliance** `FR-conformance-temporal-specs`: Beyond evaluating whether code matches requirements, the conformance reviewer evaluates whether spec prose itself is temporal — describing plans, future work, or setup rather than present state. This is the semantic complement to the deterministic temporal audit (`scripts/audit-temporal.sh`), which can only match known patterns; the conformance reviewer can identify temporal framing that a grep list would miss (e.g., novel planning verbs, domain-specific setup language). Findings are reported in a separate *Spec Temporal Violations* section.
- **One verdict per requirement** `FR-conformance-single-verdict`: Every requirement in scope receives exactly one of the three requirement verdicts (fulfilled / unfulfilled / incorrectly fulfilled), so the report is an exhaustive account of the requirement set, not a sampling.
- **Evidence per finding** `FR-conformance-evidence`: Every finding cites the concrete evidence behind it — the code location(s) it concerns and the specific requirement or behavior it is judged against — so a reader can confirm or refute the verdict without re-deriving it.
- **Recommended action per finding** `FR-conformance-actionable`: Each non-fulfilled finding states a recommended next action (e.g., fix the code, correct or clarify the spec, add a missing requirement, or remove dead behavior), so the report drives work rather than just describing state.
- **Conformance summary** `FR-conformance-summary`: The report opens with a per-platform summary that counts requirements in each quadrant, giving conformance-at-a-glance before the detailed findings.

### Scope and Invocation

The audit is always scoped to one platform and grounded in the project's existing traceability.

- **Per-platform invocation** `FR-conformance-per-platform`: The audit is invoked for a named platform and audits that platform's code against that platform's specs. A run for one platform does not report another platform's requirements or code.
- **Requirement set in scope** `FR-conformance-requirement-scope`: The requirements audited for a platform are those defined in the product spec(s) the platform realizes, including any platform-specific supplements. The audit may be narrowed to a single feature so a reader can focus a review.
- **Grounded in existing traceability** `FR-conformance-seeded`: The audit begins from the requirement-to-code mapping the project already maintains (the engineering Code Map and the traceability index) as its starting point, rather than rediscovering the mapping from nothing. It then reasons beyond that mapping to reach the four-quadrant verdicts.

### Advisory, Never Gating

The audit is a review, not a gate.

- **Never blocks** `FR-conformance-advisory`: The conformance audit never blocks a commit, a push, or any other action. It produces a report; acting on it is a human or agent decision. This mirrors the Lane Reviewer, whose judgment-based findings are likewise advisory.
- **Complements the deterministic audit** `FR-conformance-complements`: The conformance audit supplements, and does not replace, the deterministic coverage check. The deterministic audit remains the authoritative, fast, commit-time gate for marker presence and slug validity; the conformance audit adds the semantic layer the deterministic one is deliberately not built to provide.

### Non-Functional Requirements

- **Verifiable findings** `NFR-conformance-verifiable`: Every finding is traceable to a concrete code location and a specific requirement or behavior, so a reviewer can independently confirm or refute it. A finding a reader cannot check against the source is not acceptable output.
- **Signal over noise** `NFR-conformance-precision`: The report distinguishes genuine divergence from acceptable variation and keeps findings high-signal. In particular, framework scaffolding, generated files, configuration, build glue, and test-support code are not reported as *undocumented behavior* — undocumented findings name product-relevant behavior, not incidental plumbing.
- **Honest about uncertainty** `NFR-conformance-uncertainty`: Because the verdicts are judgment-based, the audit marks findings it is not confident about as such rather than asserting them with false certainty. A reader can tell a firm verdict from a flagged suspicion.

## Acceptance Criteria

These cover the observable outcomes QA verifies directly.

- [ ] **Four-quadrant report produced** `AC-conformance-report-shape`: Running the audit for a platform yields a report containing the per-platform summary and the four categories (fulfilled, unfulfilled, incorrectly fulfilled, undocumented), each either populated with findings or explicitly empty.
- [ ] **Incorrect fulfilment detected** `AC-conformance-incorrect-detected`: For a requirement whose code demonstrably contradicts the specified behavior (e.g., an inverted condition or a violated threshold), the audit reports it as *incorrectly fulfilled* and describes the divergence — even though the code carries a valid marker and passes the deterministic audit.
- [ ] **Undocumented behavior detected** `AC-conformance-undocumented-detected`: For a piece of product-relevant behavior realized in code that no requirement in scope describes, the audit reports it under *undocumented* with its code location.
- [ ] **Spec temporal violations flagged** `AC-conformance-temporal-flagged`: For a spec that uses temporal framing the deterministic audit would not catch (novel planning language, domain-specific setup phrasing), the conformance reviewer flags each violation with the specific prose, the file:line, and a suggested present-tense rewrite.
- [ ] **Unfulfilled goes beyond marker presence** `AC-conformance-unfulfilled-behavioral`: A requirement that carries an inline marker but has no real realizing behavior is reported as *unfulfilled*, demonstrating the check is behavioral rather than marker-presence-based.
- [ ] **Every requirement gets a verdict** `AC-conformance-exhaustive`: For a feature under audit, every requirement defined in its product spec appears in the report with exactly one requirement verdict.
- [ ] **Findings cite evidence** `AC-conformance-evidence-cited`: Every reported finding names at least one concrete code location and the requirement or behavior it is judged against.
- [ ] **Never blocks a commit** `AC-conformance-non-blocking`: Invoking the audit — and committing in a repository where the audit would report findings — completes without the audit blocking either action.
- [ ] **Per-platform isolation** `AC-conformance-platform-isolation`: An audit run for one platform reports only that platform's requirements and code, and does not surface findings belonging to another platform.
- [ ] **No plumbing false positives** `AC-conformance-no-plumbing`: Framework scaffolding, generated files, configuration, and test-support code are not reported as undocumented behavior.
- [ ] **Uncertainty is marked** `AC-conformance-uncertainty-marked`: A finding the audit is not confident about is presented as a marked, lower-confidence suspicion rather than as a firm verdict.

## Open Questions

- **Requirement types in scope.** Whether the requirement verdicts cover `FR-` only, or also `NFR-` and `AC-`. NFRs (e.g., latency thresholds) and ACs are harder to judge from source alone; a first cut may scope verdicts to `FR-` and treat `NFR-`/`AC-` as best-effort. Engineering/QA to settle the initial scope.
- **Depth vs. cost.** Whether a run reads the whole platform's source every time or can be narrowed (by feature, or to changed files) to keep a review fast. The per-feature narrowing in `FR-conformance-requirement-scope` is the first lever; a changed-files mode is a possible follow-up.
- **Persistence of findings.** Whether conformance findings are ever recorded/tracked over time (e.g., an accepted-divergence list, like `laneAudit.exclude` for lane bleed) or always produced fresh and ephemeral. Deferred; v1 assumes fresh, ephemeral reports.
- **Confidence presentation.** The concrete form of the confidence signal (`NFR-conformance-uncertainty`) — a per-finding label, a separate low-confidence section, or similar — is a downstream concern.

## Dependencies

- **Requirement ↔ Code Mapping (`product/code-mapping.md`):** the conformance audit consumes the mapping that feature maintains — the engineering **Code Map** and the traceability index's code locations — as its grounding (`FR-conformance-seeded`), and is explicitly the semantic complement to that feature's deterministic coverage check (`FR-conformance-complements`). It does not redefine markers, the Code Map, or the coverage gate.
- **CLI conventions (`product/cli-conventions.md`):** the per-platform invocation is surfaced as a `pdeq-`prefixed command, per the command-naming contract.
- **Quality-subagent pattern (root `AGENTS.md` §"Quality Subagents"):** the audit joins the Reviewer, Consistency Checker, and Lane Reviewer as an advisory quality reviewer, and follows the Lane Reviewer's advisory (never-gating) precedent.
- **Glossary:** defines the terms *Conformance audit*, *Four-quadrant conformance*, and *Undocumented behavior (reverse traceability)*. See `../glossary.md`.
