---
standing: true
governs: keeping product specs platform-neutral; the two-layer enforcement model
---

# Lane Discipline Enforcement

## Overview

Pdeq keeps product specs free of design and engineering detail: product describes *what* a feature does and *why*, agnostic of platform and technical implementation, while *how it looks* and *how it's built* live in the design and engineering lanes. This separation is what lets a single product spec serve as the shared baseline for every platform. When implementation detail bleeds into a product spec, that baseline stops being portable and the lane boundary erodes.

Today the only mechanical guard is a deterministic audit that scans product specs for a fixed list of technology keywords. A keyword list catches the words it knows and nothing else: it misses any vendor, protocol, or platform no one thought to list, and — more fundamentally — it cannot see *structural* bleed, where a requirement reads as implementation-shaped without naming any listed word ("authorization code exchange" is OAuth-shaped without the word OAuth; "subsequent invocations" is host-specific without any flagged term). A grep also cannot tell a real violation from a legitimate mention — an overview sentence that names a host for context, or a per-host constraint stated in a non-functional requirement, are both allowed.

This feature enforces the lane *principle* rather than a fixed word list, through complementary layers. A **deterministic lexical backstop** keeps the cheap, no-judgment keyword scan but makes its term list project-tunable, so each project can name its own vendors, protocols, and platforms without editing shared framework files. A **prompt-guided lane review** run by an agent reasons about structural bleed the keyword scan cannot see, classifies each finding by category and severity so it can distinguish a true violation from an allowed mention, and reports its findings in a structured, actionable form. The two layers are complementary, not redundant: the backstop is a fast deterministic net for obvious lexical leaks; the review is the real principle enforcement.

Alongside the noisy, warn-only keyword backstop, a higher-precision **deterministic content-class check** targets a small set of *structural* content classes rather than an open-ended keyword list — presentation and interaction detail, technical and construction detail, and treating one platform as if it were the product. Because it is precise enough to distinguish these classes from ordinary prose (skipping quoted code and permanent identifier tokens), it is trusted to **block** a commit rather than merely warn, with a documented escape hatch for the rare false positive. This same deterministic checking extends **beyond product specs to the downstream lanes** — a design spec is checked for engineering-lane content, an engineering spec for product-lane content — so bleed is caught wherever it lands, not only in product. Together these turn lane discipline from an advisory net around one lane into an enforced boundary around every lane.

## User Stories

- As a **product spec author**, I want a review that flags implementation and platform bleed by reasoning about the text, not just matching words, so that my spec stays a portable baseline even when it names things no keyword list anticipated.
- As a **pdeq maintainer of many projects**, I want each project to supply its own vendor, protocol, and platform terms without editing the shared framework, so that the deterministic guard is meaningful for that project's domain.
- As a **reviewing agent**, I want each flagged item classified by category and severity — a real violation versus an allowed contextual mention — so that I can act on the genuine problems without drowning in false positives.
- As a **commit-time gate**, I want the deterministic backstop to run automatically on every commit without ever blocking it, so that obvious leaks are surfaced early while a heuristic scan never wedges a legitimate change.
- As a **framework that improves over time**, I want the agent review to suggest term-list additions for the lexical leaks it found, so that the deterministic net grows smarter without manual curation.
- As a **maintainer who has been burned by bleed surviving into implementation**, I want the highest-confidence, structural lane violations to *block* a commit rather than only warn, so that a spec carrying presentation, construction, or platform-as-product detail cannot silently reach the codebase.
- As a **design or engineering spec author**, I want the deterministic check to run on my lane too — flagging engineering detail in a design spec, or product behavior redefined in an engineering spec — so that lane discipline protects every lane, not just product.
- As an **author hitting a rare false positive**, I want a documented, single-commit escape hatch that demotes the block to a warning and names what it suppressed, so that a heuristic mistake never permanently wedges a legitimate change.
- As a **maintainer of a project whose domain legitimately includes a default red-flag term** — a code-review tool that names the languages it supports, or a desktop app that must state the operating systems it runs on — I want to declare those terms in-lane for my project so they stop blocking, without rewording correct specs or reaching for the escape hatch on every commit.

## Requirements

### Two-Layer Model

Lane enforcement is layered: a deterministic lexical backstop and a prompt-guided structural review, each covering what the other cannot.

- **Two complementary layers** `FR-lane-discipline-two-layer`: Lane enforcement is provided by two layers — a deterministic lexical backstop that runs with no agent involvement, and a prompt-guided lane review run by an agent. Neither replaces the other: the backstop catches obvious lexical leaks cheaply; the review enforces the underlying principle by reasoning about structure and context.

### Deterministic Lexical Backstop

A no-judgment scan flags configured red-flag terms in product specs. It is the cheap, always-on net.

- **Lexical scan** `FR-lane-discipline-lexical-backstop`: A deterministic audit scans product specs for a configured set of red-flag terms (technology names, vendors, protocols, platform names, and similar) and reports every match with its file and location. The scan requires no agent and produces the same result on the same input every time.
- **Project-tunable terms** `FR-lane-discipline-project-terms`: A project can supply its own red-flag terms — its vendors, protocols, platforms, and libraries — that the backstop scans for, without editing files shared across projects. This lets the backstop be meaningful for a project's own domain rather than only the terms the framework happened to ship.
- **Default terms** `FR-lane-discipline-default-terms`: When a project supplies no terms of its own, a sensible built-in default set applies. Project-supplied terms extend the defaults rather than replacing them, so configuring a project's own vendors never silences the shipped guard.
- **Excludable domain terms** `FR-lane-discipline-exclude-terms`: A project can declare a set of **domain-legitimate terms** that the deterministic checks skip — vocabulary that is genuinely part of the project's product (a platform it must run on, a language it supports, a first-class domain noun) and therefore not lane bleed for that project. An excluded term is removed from matching everywhere the deterministic checks run — both the lexical backstop and the blocking content and downstream checks — so it neither warns nor blocks. Exclusion never affects the advisory lane review, which continues to reason about context. This is the counterpart to project-tunable terms: tunable terms *add* red flags a project cares about; excluded terms *remove* defaults a project has judged in-lane. It is the supported alternative to rewording a correct spec or repeatedly using the per-commit escape hatch.

### Blocking Structural Content Check

A higher-precision deterministic check targets structural content classes and is trusted to block a commit, complementing the noisy warn-only keyword backstop.

- **Content-class detection** `FR-lane-discipline-content-class-check`: A deterministic check flags a small, named set of *content classes* that do not belong in a shared product spec: presentation and interaction detail (naming concrete visual elements or user gestures), technical and construction detail (naming how the feature is built — its components, targets, or dependencies), and platform-as-product framing (specifying behavior that treats one platform as if it were the whole product). The classes are defined structurally, so the check generalizes beyond any fixed keyword list.
- **Blocking enforcement** `FR-lane-discipline-blocking-enforcement`: When the content-class check finds a violation, it blocks the commit rather than merely warning. This is deliberately stronger than the lexical backstop, which stays warn-only: the content-class check is scoped to high-confidence structural classes and ignores incidental matches (see false-positive handling), so a block reflects a real lane violation.
- **Escape hatch** `FR-lane-discipline-blocking-escape-hatch`: A documented, single-commit escape hatch demotes the block to a warning, so a rare false positive never permanently wedges a legitimate change. When the escape hatch is used, the check still reports what it found and names the conditions it suppressed, so the suppression is visible rather than silent.
- **Incidental-match handling** `FR-lane-discipline-content-class-precision`: The content-class check does not flag text where a class term appears incidentally rather than as a requirement — quoted or fenced code, and permanent identifier tokens (requirement and test slugs) — so that legitimate examples and identifiers do not trip a blocking check. This precision is what justifies blocking rather than warning.

### Downstream Lane Scanning

Deterministic bleed detection is not limited to product specs; each downstream lane is checked for content that belongs to another lane.

- **Downstream scan** `FR-lane-discipline-downstream-scan`: The deterministic checks extend beyond product specs to the downstream lanes. A design spec is scanned for engineering-lane content (how it is built — components, algorithms, interface contracts); an engineering spec is scanned for product-lane content (redefining *what* the feature does rather than *how* it is built). Bleed detected downstream is enforced at the same strength as the product content-class check, so a lane boundary is protected wherever specs are written.

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
- **Backstop at commit time** `FR-lane-discipline-backstop-at-commit`: The deterministic lexical backstop runs automatically as part of the commit-time checks in addition to being runnable on demand, so obvious lexical leaks are surfaced without waiting for an agent review.
- **Blocking checks at commit time** `FR-lane-discipline-blocking-at-commit`: The content-class check and the downstream lane scan run automatically as part of the commit-time checks and, unlike the lexical backstop, block the commit on a violation (subject to the escape hatch). They are also runnable on demand and in continuous integration, where they signal failure through their exit status.

### Update Propagation

When an existing project adopts a version of the framework that includes lane discipline, the two layers should reach that project without hand-wiring.

- **Update seeds the term list** `FR-lane-discipline-update-seeds-config`: When a project updates to a framework version that introduces lane discipline, the update seeds an empty project-term scaffold into the project configuration if none is present, so the tunable term list is discoverable and ready to populate. Seeding never overwrites or duplicates an existing term list.
- **Update reviews existing specs** `FR-lane-discipline-update-reviews-specs`: The same update runs the lane review over the project's existing product specs and reports its findings, so a project adopting lane discipline learns where its current specs already carry bleed. The update's review is report-only — it reports findings and suggested term additions and does not modify any spec.

## Non-Functional Requirements

- **Deterministic and agent-free backstop** `NFR-lane-discipline-deterministic-backstop`: The lexical backstop is fully deterministic and runs with no agent or network dependency, so it is usable in continuous-integration and commit-time contexts where no agent is available.
- **Advisory review** `NFR-lane-discipline-advisory-review`: The prompt-guided review is advisory. Because it is non-deterministic, it never runs as a blocking commit-time gate; its output informs humans and downstream tooling.
- **Non-blocking lexical backstop** `NFR-lane-discipline-nonblocking-backstop`: When the deterministic *lexical* backstop (the open-ended keyword scan) runs at commit time, it reports findings as warnings and never blocks the commit, reflecting that a heuristic keyword scan can produce false positives that must not wedge a legitimate change. The lexical backstop still signals failure through its exit status when run on demand or in continuous integration. This warn-only stance applies to the keyword scan specifically; it does not extend to the content-class check or downstream scan, which are scoped precisely enough to block.
- **Blocking check is precise and recoverable** `NFR-lane-discipline-blocking-precision`: The content-class check and downstream scan are scoped to high-confidence structural classes and skip incidental matches (quoted code, permanent identifier tokens), so that blocking reflects a genuine lane violation and not prose noise. Because no heuristic is perfect, a single-commit escape hatch is always available and, when used, names the conditions it suppressed so the suppression is auditable rather than silent.
- **Consistent enforcement across lanes** `NFR-lane-discipline-cross-lane-consistency`: The deterministic content checks apply the same enforcement strength wherever a lane boundary exists — product, design, and engineering — rather than protecting only the product lane, so no lane is a privileged place to hide bleed.
- **Exclusion is surgical and optional** `NFR-lane-discipline-exclude-surgical`: Excluding a term removes only that exact term from matching; a line that also contains a non-excluded flagged term still flags on the remaining term, so exclusion cannot be used to blanket-silence a line. A project that declares no exclusions behaves exactly as before — exclusion is purely additive configuration.
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
- [ ] **Presentation detail in product blocks** `AC-lane-discipline-content-presentation-blocks`: A commit touching a shared product spec that names a concrete visual element or user gesture (presentation-and-interaction content class) is blocked by the content-class check.
- [ ] **Construction detail in product blocks** `AC-lane-discipline-content-construction-blocks`: A commit touching a shared product spec that names how the feature is built — a component, build target, or dependency (technical-and-construction content class) — is blocked.
- [ ] **Platform-as-product framing blocks** `AC-lane-discipline-content-platform-blocks`: A commit touching a shared product spec that specifies behavior treating one platform as if it were the whole product is blocked.
- [ ] **Clean product spec passes** `AC-lane-discipline-content-clean-passes`: A commit touching a shared product spec written in platform-neutral, behavior-only language passes the content-class check without a block.
- [ ] **Engineering detail in design blocks** `AC-lane-discipline-downstream-design-blocks`: A commit touching a design spec that specifies engineering-lane content (how it is built — components, algorithms, or interface contracts) is blocked by the downstream scan.
- [ ] **Product redefinition in engineering blocks** `AC-lane-discipline-downstream-eng-blocks`: A commit touching an engineering spec that redefines what the feature does (product-lane content) rather than how it is built is blocked by the downstream scan.
- [ ] **Escape hatch demotes and names** `AC-lane-discipline-escape-hatch-demotes`: With the escape hatch engaged, a commit that would otherwise be blocked by the content-class check or downstream scan succeeds, and the suppressed conditions are named in the output rather than silently ignored.
- [ ] **Incidental matches do not trip the block** `AC-lane-discipline-content-incidental-passes`: A shared product spec in which a content-class term appears only inside quoted or fenced code, or inside a permanent identifier token (a requirement or test slug), is not blocked by the content-class check.
- [ ] **Excluded term does not block** `AC-lane-discipline-exclude-passes`: With a term declared in the project's exclusion list, a spec whose only flagged content on a line is that term is neither warned nor blocked by the deterministic checks.
- [ ] **Exclusion is surgical** `AC-lane-discipline-exclude-surgical`: A line containing both an excluded term and a non-excluded flagged term is still flagged on the non-excluded term — exclusion removes only the named term, not the whole line.
- [ ] **No exclusion changes nothing** `AC-lane-discipline-exclude-optional`: A project with no exclusion list produces exactly the same deterministic results it would produce without the feature present.

## Open Questions

- None currently. The severity vocabulary (violation vs allowed-with-reason) and the taxonomy category set are defined in the engineering spec's review contract; if usage shows additional severities are needed, they are added there.

## Dependencies

- The kickoff and reviewer workflows (`/pdeq-kickoff` and the standalone reviewer pass) host the prompt-guided review as an additional quality check.
- The commit-time check pipeline hosts the deterministic backstop as a warn-only step.
- Per-project configuration (the mechanism projects already use for path and platform settings) carries the project-supplied term list.
