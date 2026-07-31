# Roadmap

This folder holds **forward-looking notes** for features — fast follows, V2 ideas, future directions — that are **not yet scoped** for implementation.

Roadmap entries are intentionally lightweight. They are not specs. Their job is to park ideas so product/design/engineering/QA specs stay focused on what exists today, and so future `/pdeq-kickoff` runs have a starting point.

## What Goes Here

- Fast follows for features currently being built.
- V2 / V3 / "someday" ideas for existing features.
- Cross-cutting vision that spans multiple features (in `_overview.md`).

## What Does NOT Go Here

- Requirements that are actively being built — those belong in `../product/<feature>.md`.
- Design mockups, architecture plans, or test cases — those belong in their respective folders once scoped.
- Bug fixes or small corrections — those update the existing spec directly.

## File Layout

- `<feature>.md` — one file per feature. Use the same filename as the product spec it extends (or will eventually become).
- `_overview.md` — optional, for multi-feature or cross-cutting vision.

## File Structure

```markdown
# [Feature Name] — Roadmap

Short prose intro. Where is this feature headed? What's the longer-term vision?

See current state in [../product/[feature].md](../product/[feature].md).

## Fast Follow

Ideas queued up for immediately after the current scope ships.

- **[Readable Label]** — one-line description. Brief rationale if non-obvious.
- **[Readable Label]** — ...

## V2

Larger additions or reshapes that require their own kickoff.

- **[Readable Label]** — ...

## Later

Speculative / aspirational. May or may not happen.

- **[Readable Label]** — ...
```

Horizon sections (**Fast Follow**, **V2**, **Later**) are a suggestion — use whatever names make sense for the feature. Could also be **V1 → V2 → V3**, **Phase 1 → Phase 2**, etc.

## Roadmap Spec Supplements (Optional)

<!-- Implements: FR-living-spec-roadmap-supplements, FR-living-spec-multi-phase-roadmap -->
For multi-phase or detailed forward-looking planning, a roadmap file can include **spec-shaped sections** with requirements using reserved slug prefixes. This is opt-in — most roadmap files stay lightweight bullet lists. Use structured supplements only when you need to spec out multiple phases or iterations of a feature in detail before any phase is ready for implementation.

### Reserved Roadmap Slug Prefixes

- **`FRR-<feature>-<slug>`** — Future Functional Requirement (Roadmap)
- **`NFRR-<feature>-<slug>`** — Future Non-Functional Requirement (Roadmap)
- **`ACR-<feature>-<slug>`** — Future Acceptance Criterion (Roadmap)

These are explicitly **non-authoritative** and exempt from traceability audits. Use the same `<feature>` name as the eventual product spec.

### Structure

Organize by phase/iteration (e.g., "V2", "Fast Follow", "Phase 2"):

```markdown
# [Feature Name] — Roadmap

...

## V2

Requirements for the second phase, not yet scheduled for implementation.

- **[Readable Label]** `FRR-<feature>-<slug>`: Requirement description
- **[Performance goal]** `NFRR-<feature>-<slug>`: Non-functional requirement

### Acceptance Criteria

- [ ] **[Test condition]** `ACR-<feature>-<slug>`: Testable criterion

## Phase 3

- **[Future idea]** `FRR-<feature>-<other-slug>`: ...
```

### Graduation Flow

<!-- Implements: FR-living-spec-roadmap-graduation -->
When a roadmap section is ready for implementation:

1. **Renumber slugs**: `FRR-` → `FR-`, `NFRR-` → `NFR-`, `ACR-` → `AC-`
2. **Move content** into the authoritative product spec (`../product/<feature>.md`)
3. **Delete the roadmap section**. Delete the file if empty.

The roadmap remains the staging ground; product specs remain the source of truth for what is current.

## Rules

- **Lightweight by default.** Roadmap files are simple bullet lists unless you opt into spec supplements for multi-phase planning.
- **Roadmap slugs (`FRR-`, `NFRR-`, `ACR-`) never become authoritative until graduated.** They are exempt from traceability audits and do not appear in `../index.md`.
- **No lane discipline.** Roadmap entries can hand-wave across product/design/engineering/QA concerns. Detail comes later at kickoff.
- **Not tracked in `../index.md`.** Roadmap is not authoritative.
- **Not audited by the pre-commit traceability hook.**
- **Not platform-scoped at the folder level.** If an idea is platform-specific, mention platform inline. Do not create `roadmap/<platform>/` subfolders.
- **Keep entries short.** One or two bullets per idea. If an idea needs a page of detail, it's ready for `/pdeq-kickoff`.

## Graduation Flow

When a roadmap item is ready for implementation:

1. Run `/pdeq-kickoff` on that item. The kickoff flow reads the roadmap entry for context, then creates a proper product spec (with slugs), design spec, engineering spec, and QA test plan.
2. Remove the graduated item from `<feature>.md`. Delete the file if empty.

## Path Resolution

At the start of each session, check for a `pdeq.json` config file:

1. Look in `../pdeq.json` (parent of this `roadmap/` folder).
2. If not found, check `../../pdeq.json`.

If `pdeq.json` is found, apply:

- **`specsRoot`**: Directory containing `product/`, `design/`, `engineering/`, `qa/`, `roadmap/`. Cross-folder references (e.g., `../product/<feature>.md`) are relative to `specsRoot`.
- **`nested.label`**: If present, you are working on the `{label}` component. Scope roadmap entries to this component.

If `pdeq.json` is absent, assume defaults: sibling folders at `../`.

## Lane Guides

<!-- Implements: FR-lane-guides-framework-surfaces, FR-lane-guides-harness-agnostic, FR-lane-guides-missing-non-fatal, NFR-lane-guides-cheap-read -->

Before writing specs in this lane, check `pdeq.json` for a `laneGuides` entry keyed to `roadmap`. If present and the path resolves (relative to `specsRoot`), read that file first — it holds this project's lane-specific skills, architecture, or guidelines for roadmap work. If `laneGuides` is absent, the `roadmap` key is missing, or the configured path does not resolve, proceed without a guide — a missing guide is non-fatal.
