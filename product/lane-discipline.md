# Lane Discipline Enforcement

## Overview

Pdeq keeps product specs free of design and engineering detail: product describes *what* a feature does and *why*, agnostic of platform and technical implementation, while *how it looks* and *how it's built* live in the design and engineering lanes. This separation is what lets a single product spec serve as the shared baseline for every platform. When implementation detail bleeds into a product spec, that baseline stops being portable and the lane boundary erodes.

Today the only mechanical guard is a deterministic audit that scans product specs for a fixed list of technology keywords. A keyword list catches the words it knows and nothing else: it misses any vendor, protocol, or platform no one thought to list, and — more fundamentally — it cannot see *structural* bleed, where a requirement reads as implementation-shaped without naming any listed word ("authorization code exchange" is OAuth-shaped without the word OAuth; "subsequent invocations" is host-specific without any flagged term). A grep also cannot tell a real violation from a legitimate mention — an overview sentence that names a host for context, or a per-host constraint stated in a non-functional requirement, are both allowed.

This feature enforces the lane *principle* rather than a fixed word list, through two complementary layers. A **deterministic lexical backstop** keeps the cheap, no-judgment keyword scan but makes its term list project-tunable, so each project can name its own vendors, protocols, and platforms without editing shared framework files. A **prompt-guided lane review** run by an agent reasons about structural bleed the keyword scan cannot see, classifies each finding by category and severity so it can distinguish a true violation from an allowed mention, and reports its findings in a structured, actionable form. The two layers are complementary, not redundant: the backstop is a fast deterministic net for obvious lexical leaks; the review is the real principle enforcement.

## User Stories

- As a **product spec author**, I want a review that flags implementation and platform bleed by reasoning about the text, not just matching words, so that my spec stays a portable baseline even when it names things no keyword list anticipated.
- As a **pdeq maintainer of many projects**, I want each project to supply its own vendor, protocol, and platform terms without editing the shared framework, so that the deterministic guard is meaningful for that project's domain.
- As a **reviewing agent**, I want each flagged item classified by category and severity — a real violation versus an allowed contextual mention — so that I can act on the genuine problems without drowning in false positives.
- As a **commit-time gate**, I want the deterministic backstop to run automatically on every commit without ever blocking it, so that obvious leaks are surfaced early while a heuristic scan never wedges a legitimate change.
- As a **framework that improves over time**, I want the agent review to suggest term-list additions for the lexical leaks it found, so that the deterministic net grows smarter without manual curation.

## Requirements

### Two-Layer Model

Lane enforcement is layered: a deterministic lexical backstop and a prompt-guided structural review, each covering what the other cannot.

- **Two complementary layers** `FR-lane-discipline-two-layer`: Lane enforcement is provided by two layers — a deterministic lexical backstop that runs with no agent involvement, and a prompt-guided lane review run by an agent. Neither replaces the other: the backstop catches obvious lexical leaks cheaply; the review enforces the underlying principle by reasoning about structure and context.

### Deterministic Lexical Backstop

A no-judgment scan flags configured red-flag terms in product specs. It is the cheap, always-on net.

- **Lexical scan** `FR-lane-discipline-lexical-backstop`: A deterministic audit scans product specs for a configured set of red-flag terms (technology names, vendors, protocols, platform names, and similar) and reports every match with its file and location. The scan requires no agent and produces the same result on the same input every time.
- **Project-tunable terms** `FR-lane-discipline-project-terms`: A project can supply its own red-flag terms — its vendors, protocols, platforms, and libraries — that the backstop scans for, without editing files shared across projects. This lets the backstop be meaningful for a project's own domain rather than only the terms the framework happened to ship.
- **Default terms** `FR-lane-discipline-default-terms`: When a project supplies no terms of its own, a sensible built-in default set applies. Project-supplied terms extend the defaults rather than replacing them, so configuring a project's own vendors never silences the shipped guard.

### Prompt-Guided Lane Review

An agent-run review reasons about structural bleed the keyword scan cannot see, and classifies findings so real violations are distinguishable from allowed mentions.

- **Structural review** `FR-lane-discipline-structural-review`: An agent reviews product specs for lane bleed by reasoning about the meaning and structure of the text, not only by matching words. It flags bleed that carries no listed keyword — a requirement phrased in implementation-shaped or host-specific terms — that the lexical backstop cannot detect.
- **Red-flag taxonomy** `FR-lane-discipline-taxonomy`: The review is guided by a taxonomy of red-flag *categories* with examples — vendor names; protocol or algorithm names; host or platform names used as if they were the product; library or framework names; command surfaces, flag names, exit codes, environment variables, file paths, ports, and redirect targets; implementation mechanisms such as secret stores or background polling; and testing terms. The taxonomy is expressed as categories with examples, not a closed word list, so the review generalizes to vendors and protocols no one has listed.
- **Severity classification** `FR-lane-discipline-severity`: The review classifies each flagged item by severity rather than treating every match as a violation. It distinguishes a true lane violation from a mention that is allowed in context — for example, a host named in an overview for orientation, or a per-host constraint legitimately stated in a non-functional requirement. Allowed items are reported with the reason they are allowed.
- **Structured findings** `FR-lane-discipline-structured-output`: The review reports its findings in a structured form — for each item: the file, the location, the flagged text, its category, its severity (violation, or allowed with a stated reason), and a suggested rewording that would keep the requirement in-lane. The structure lets a human or a later script act on the findings without reparsing prose.
- **Term-list suggestions** `FR-lane-discipline-term-suggestions`: For lexical leaks it identifies, the review may additionally suggest the project term-list additions that would let the deterministic backstop catch the same leak in future, so the deterministic net improves over time without manual curation.

### Where Enforcement Runs

The two layers run in different places, matching their cost and determinism.

- **Review in the spec workflow** `FR-lane-discipline-review-in-workflow`: The prompt-guided lane review runs as part of the feature-kickoff quality checks and as part of the standalone reviewer pass, alongside the existing reviewer and consistency checks. It is not part of the commit-time gate.
- **Backstop at commit time** `FR-lane-discipline-backstop-at-commit`: The deterministic backstop runs automatically as part of the commit-time checks in addition to being runnable on demand, so obvious lexical leaks are surfaced without waiting for an agent review.

### Update Propagation

When an existing project adopts a version of the framework that includes lane discipline, the two layers should reach that project without hand-wiring.

- **Update seeds the term list** `FR-lane-discipline-update-seeds-config`: When a project updates to a framework version that introduces lane discipline, the update seeds an empty project-term scaffold into the project configuration if none is present, so the tunable term list is discoverable and ready to populate. Seeding never overwrites or duplicates an existing term list.
- **Update reviews existing specs** `FR-lane-discipline-update-reviews-specs`: The same update runs the lane review over the project's existing product specs and reports its findings, so a project adopting lane discipline learns where its current specs already carry bleed. The update's review is report-only — it reports findings and suggested term additions and does not modify any spec.

## Non-Functional Requirements

- **Deterministic and agent-free backstop** `NFR-lane-discipline-deterministic-backstop`: The lexical backstop is fully deterministic and runs with no agent or network dependency, so it is usable in continuous-integration and commit-time contexts where no agent is available.
- **Advisory review** `NFR-lane-discipline-advisory-review`: The prompt-guided review is advisory. Because it is non-deterministic, it never runs as a blocking commit-time gate; its output informs humans and downstream tooling.
- **Non-blocking backstop** `NFR-lane-discipline-nonblocking-backstop`: When the deterministic backstop runs at commit time, it reports findings as warnings and never blocks the commit, reflecting that a heuristic keyword scan can produce false positives that must not wedge a legitimate change. The backstop still signals failure through its exit status when run on demand or in continuous integration.
- **Back-compatibility** `NFR-lane-discipline-backcompat`: A project that has not configured any custom terms continues to work unchanged, using the built-in default term set. Adding the term-list configuration is optional and additive.

## Acceptance Criteria

These are the testable conditions that define "done." QA writes test cases against these.

- [ ] **Defaults still catch known bleed** `AC-lane-discipline-default-catches-known`: With no project terms configured, the backstop still flags an obvious built-in default term (e.g., a well-known framework name or a pixel value) present in a product spec.
- [ ] **Project terms are flagged** `AC-lane-discipline-project-terms-applied`: A project that configures its own vendor and protocol terms (e.g., a payment vendor and an auth protocol) has those terms flagged when they appear in a product spec, even though they are not in the built-in defaults.
- [ ] **No configuration does not break** `AC-lane-discipline-no-config-no-break`: A project with no custom term configuration runs the backstop without error and produces the same result the built-in defaults alone would produce.
- [ ] **Backstop never blocks at commit time** `AC-lane-discipline-backstop-nonblocking`: A commit that touches a product spec containing flagged bleed still succeeds; the backstop reports the finding as a warning rather than aborting the commit.
- [ ] **Backstop signals failure on demand** `AC-lane-discipline-backstop-exit-status`: Run on demand (outside the commit-time gate) against a product spec containing a flagged term, the backstop reports a non-success result, so continuous integration can act on it.
- [ ] **Review flags structural bleed** `AC-lane-discipline-review-flags-structural`: Given a product spec containing structural bleed with no listed keyword — a requirement phrased as a protocol exchange, and a host treated as the product — the review flags each as a violation, including bleed the deterministic backstop's default terms do not match.
- [ ] **Review allows legitimate mentions** `AC-lane-discipline-review-allows-legit`: Given a product spec that mentions a host in an overview for orientation and states a per-host constraint in a non-functional requirement, the review marks those mentions as allowed-with-reason rather than violations.
- [ ] **Review output is structured** `AC-lane-discipline-review-output-shape`: The review's output for each finding includes the file, location, flagged text, category, severity, and a suggested rewording, in a form a script could consume.
- [ ] **Review suggests term additions** `AC-lane-discipline-review-suggests-terms`: When the review finds a lexical leak that the backstop's current terms would miss, it suggests the term-list addition that would let the backstop catch it.
- [ ] **Update seed is idempotent** `AC-lane-discipline-update-seed-idempotent`: Running the update a second time neither duplicates the seeded term scaffold nor overwrites a term list the project has already populated.
- [ ] **Update review makes no edits** `AC-lane-discipline-update-review-no-edit`: The review the update runs over existing product specs reports its findings but leaves every spec file byte-for-byte unchanged.

## Open Questions

- None currently. The severity vocabulary (violation vs allowed-with-reason) and the taxonomy category set are defined in the engineering spec's review contract; if usage shows additional severities are needed, they are added there.

## Dependencies

- The kickoff and reviewer workflows (`/pdeq-kickoff` and the standalone reviewer pass) host the prompt-guided review as an additional quality check.
- The commit-time check pipeline hosts the deterministic backstop as a warn-only step.
- Per-project configuration (the mechanism projects already use for path and platform settings) carries the project-supplied term list.
