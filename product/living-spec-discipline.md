# Living Spec Discipline

## Overview

Pdeq specs are living documents showing the current state of features, not versioned snapshots or point-in-time plans. Yet temporal language creeps in — "MVP", "phase 1", "iteration 2", "first version" — language that treats a spec as a plan for what will happen rather than a description of what is. This undermines the living-document principle: when a spec says "phase 1 will have X, phase 2 will add Y," readers cannot tell what the current state actually is without reading git history.

The solution has two parts. First, expand the roadmap mechanism so forward-looking ideas have a proper home outside specs — including multi-phase feature plans that spec future behavior without requiring immediate implementation. Second, add audits that detect temporal/phasing language in specs and flag it for correction. Together these make it easy to do the right thing (park future plans in roadmap) and hard to do the wrong thing (leak phasing talk into living specs).

## User Stories

- As a **spec author**, I want a structured place to spec out future phases of a feature without polluting the current-state spec, so forward-looking plans have a home and the living spec stays focused on what exists now.
- As a **spec reader**, I want specs to show the current state without phasing qualifiers, so I can understand what the feature does today without needing to parse "phase 1" vs "phase 2" or consult git history to see which phase shipped.
- As a **maintainer**, I want temporal language automatically flagged in specs during review and at commit time, so phasing talk is caught before it becomes embedded in the spec graph.
- As a **person planning work**, I want to spec multiple phases or iterations of a feature in roadmap without needing to immediately implement them, so scope can be understood up front without the spec pretending the future is the present.

## Requirements

### Expanded Roadmap Structure

The roadmap mechanism gains the ability to hold forward-looking *spec content*, not just lightweight bullet lists.

- **Roadmap spec supplements** `FR-living-spec-roadmap-supplements`: A roadmap file can now include structured spec-shaped sections (requirements with slugs, acceptance criteria, even design or engineering notes) for future phases or iterations of a feature, without those sections needing to exist in the authoritative product/design/engineering specs. These are forward-looking plans, explicitly non-authoritative, and exempt from traceability audits.
- **Graduated sections move to authoritative specs** `FR-living-spec-roadmap-graduation`: When a roadmap section is ready for implementation, its content is moved (not copied) into the authoritative spec for that lane, and the roadmap section is removed. The roadmap remains the staging ground; the lane specs remain the source of truth for what is current.
- **Roadmap slugs use a reserved prefix** `FR-living-spec-roadmap-slug-prefix`: Requirements in roadmap supplements use a reserved slug prefix (e.g., `FRR-` for "future requirement roadmap", `ACR-` for "future acceptance criterion roadmap") so they are visually distinct from authoritative slugs and tooling can skip them in coverage/traceability checks.
- **Multi-phase feature planning** `FR-living-spec-multi-phase-roadmap`: A roadmap file can organize forward-looking content by phase or iteration (e.g., "V2", "Fast Follow", "Phase 2") so multi-phase work can be scoped and spec'd up front without pretending that future phases are current state.

### Temporal Language Audit

A new audit detects temporal and phasing language in authoritative specs and flags it for removal.

- **Temporal language patterns flagged** `FR-living-spec-temporal-audit-patterns`: The audit scans authoritative specs (product, design, engineering, QA — not roadmap) for temporal language patterns including: "MVP", "phase [N]", "iteration [N]", "first version", "V[N]", "initial release", "later", "eventually", "future", "upcoming", "next", and phrases like "will be added", "to be implemented", "planned for". Each match is reported with file, line, and flagged text.
- **Audit runs in multiple modes** `FR-living-spec-temporal-audit-modes`: The audit can run on-demand (via a dedicated command), as part of the kickoff quality-check step, in CI, and optionally at commit time. The commit-time mode defaults to warn-only (does not block commits) and can be configured per-project.
- **Suggested rewordings** `FR-living-spec-temporal-audit-rewording`: For each flagged instance, the audit suggests how to reword it: either move the content to roadmap (if it describes future work), or rewrite it in present tense describing current state (if the work has shipped and the language is stale).
- **Exempt roadmap and decisions log** `FR-living-spec-temporal-audit-exemptions`: The audit does not scan `roadmap/` (temporal language is expected there) or `decisions.md` / `decisions-pending.md` (historical context legitimately references past phases).

### Spec Authoring Guardrails

The kickoff workflow and spec templates actively guide authors away from temporal language.

- **Kickoff warns on temporal language** `FR-living-spec-kickoff-temporal-check`: During kickoff (Step 4, quality checks), the temporal language audit runs over newly created or updated specs, and any findings are reported before the kickoff completes. This catches phasing language at authoring time.
- **Spec template guidance** `FR-living-spec-template-guidance`: The product spec template in `product/AGENTS.md` includes a brief note in the guidelines section reminding authors that specs describe current state and that forward-looking ideas belong in roadmap, not in the spec itself.

## Non-Functional Requirements

- **Deterministic audit** `NFR-living-spec-deterministic-audit`: The temporal language audit is a deterministic keyword/pattern scan (like the lane-discipline lexical backstop), not an LLM-based review, so it is fast, reproducible, and suitable for commit-time and CI use.
- **No false-positive flood** `NFR-living-spec-low-noise`: The audit's pattern list is curated to minimize false positives. Legitimate uses of flagged words (e.g., "version" in a glossary entry defining a term, "iteration" describing an algorithm's loop) should not trigger warnings. Patterns are anchored or contextualized to catch phasing language specifically.
- **Roadmap remains lightweight by default** `NFR-living-spec-roadmap-lightweight-default`: The expanded roadmap structure (spec supplements with slugs) is opt-in. Roadmap files can still be simple bullet lists as they are today; the structured-spec mode is used only when multi-phase planning or detailed future scoping is needed.

## Acceptance Criteria

These are the testable conditions that define "done."

- [ ] **Roadmap can hold spec-shaped sections** `AC-living-spec-roadmap-spec-sections`: A roadmap file can contain a section with requirements using `FRR-`, `NFRR-`, `ACR-` slugs, and those requirements are recognized as forward-looking (not authoritative) by tooling.
- [ ] **Roadmap slugs exempt from traceability** `AC-living-spec-roadmap-slugs-exempt`: Requirements with roadmap slug prefixes (`FRR-`, `NFRR-`, `ACR-`) do not appear in `index.md` and do not trigger traceability warnings or blocks.
- [ ] **Graduated roadmap content moves to authoritative specs** `AC-living-spec-graduation-moves-content`: When a roadmap section is implemented, its requirements are renumbered with authoritative slugs (`FR-`, `NFR-`, `AC-`) and moved into the product/design/engineering spec, and the roadmap section is deleted.
- [ ] **Temporal audit detects common patterns** `AC-living-spec-temporal-patterns-detected`: The audit flags at least the following in authoritative specs: "MVP", "phase 1", "iteration 2", "V2", "initial release", "will be added", "to be implemented".
- [ ] **Temporal audit suggests fixes** `AC-living-spec-temporal-suggestions`: For each flagged instance, the audit output includes either a suggested rewording or a note to move the content to roadmap.
- [ ] **Temporal audit runs in kickoff** `AC-living-spec-temporal-in-kickoff`: The kickoff workflow (Step 4) runs the temporal audit over created/updated specs and reports findings before completion.
- [ ] **Temporal audit does not scan roadmap** `AC-living-spec-roadmap-not-scanned`: Running the temporal audit does not flag content in `roadmap/` files.
- [ ] **Spec template includes guidance** `AC-living-spec-template-has-guidance`: The product spec template in `product/AGENTS.md` includes a reminder about living-document discipline and directing future plans to roadmap.

## Open Questions

- Should the roadmap slug prefixes be `FRR-` / `NFRR-` / `ACR-` (R for roadmap), or something else (e.g., `FR-ex-future-*`, `FR-ex-v2-*` style suffix)? The double-R form is shorter and visually distinct; a suffix-based form is more greppable. Lean toward `FRR-` / `NFRR-` / `ACR-` for brevity unless there's a strong reason to use a different convention.
- Should the temporal audit block commits by default (like traceability), or default to warn-only? Lean toward warn-only initially since this is a new discipline and existing specs likely have some temporal language that would need cleanup; make it blocking per-project opt-in once the codebase is clean.

## Dependencies

- The kickoff workflow invokes the temporal audit as part of Step 4 quality checks.
- The traceability audit (`scripts/audit-traceability.sh`) is extended to recognize and skip roadmap slug prefixes.
- The lane-discipline feature provides a model for a deterministic lexical audit (keyword scan, warn-only mode, per-project config toggle); this feature follows the same pattern for temporal language.
