# Project Orientation

## Overview

A pdeq project has framework rules (how pdeq works) but no lightweight description of *itself* — what the project is, what platforms it runs on, what tech stack it chose, and which cross-cutting specs every builder must respect regardless of feature. A fresh agent session implementing a feature reads the framework rules but has no entry point that says "this project is X, on platform Y, and here are the standing specs you must not violate." Meanwhile cross-cutting concerns — a style guide, an architecture baseline, a security baseline — are not features, so they have no structurally correct home: they get shoe-horned into a fake feature file, dumped into the framework agent file, or simply never specified.

Project orientation closes both gaps with one authored, living file — `project.md` at the specs root — and a first-class concept of a **standing spec**: a spec that applies project-wide rather than to a single feature. `project.md` is the skinny: what the project is, its platforms and stack, a manifest of its standing specs, and how to operate within it. It is read at the start of every implementation session and kept current as the project evolves, so future sessions orient in seconds and respect the conventions the project has already decided.

## User Stories

- As a **fresh agent session**, I want a single short file that tells me what this project is and which standing specs I must respect, so I can implement a feature without unknowingly violating a project-wide convention.
- As a **project maintainer**, I want a structurally correct home for cross-cutting specs (style guide, architecture baseline, security baseline) that apply to every feature, so they are not forced into a fake feature file or left unspecified.
- As a **project maintainer**, I want the orientation file to stay current automatically as the project evolves, so it does not silently rot into a stale snapshot that misleads new sessions.
- As a **migrator of an existing pdeq project**, I want a migration that seeds the orientation file and pares accumulated project-specific clutter out of the framework agent file, so conflicting or duplicate guidance is consolidated into one place.

## Requirements

### The orientation file

- **Orientation file exists at the specs root** `FR-project-orientation-file`: Every pdeq project has a `project.md` at its specs root. It is a living, authored document with these sections: **What this is** (2-4 sentences of project identity), **Platforms** (the platforms this project targets), **Tech stack** (the engineering choices the project made), **Standing specs** (a manifest of cross-cutting specs every builder must respect), and **How to operate** (short pointers to the kickoff flow, the markdown-first cardinal rule, where decisions live, and how to run audits). Sections are authored prose except the Standing specs manifest, which is a maintained table.
- **Orientation file is living** `FR-project-orientation-living`: `project.md` reflects the current state of the project, not a point-in-time snapshot. When the project identity, platforms, or tech stack change materially, the authored sections are updated in place. When a standing spec is added or retired, the manifest is updated in the same change set.

### Standing specs

- **Standing spec concept** `FR-project-orientation-standing-spec`: A **standing spec** is a spec that applies project-wide rather than to a single feature — for example a style guide, an architecture baseline, a security baseline, or API conventions. A standing spec lives in its correct lane (a style guide is engineering; a security baseline's "what" is product non-functional requirements and its "how" is engineering) and is marked in its YAML frontmatter with `standing: true` and a `governs:` one-line description, so tooling and kickoff can distinguish it from a feature spec.
- **Standing specs manifest** `FR-project-orientation-standing-manifest`: `project.md`'s Standing specs section is a table listing every standing spec: its human-readable name, its lane and path, and the one-line `governs:` description. The manifest is the authoritative inventory of cross-cutting specs a builder must respect. Every path in the manifest must resolve to an existing file; every standing spec in the project must appear in the manifest.

### Session orientation

- **Sessions read the orientation file** `FR-project-orientation-session-read`: At the start of any implementation session, the coordinator reads `project.md` and respects every standing spec it lists before doing feature work. This is the always-on orientation path; it does not require an explicit command.

### Maintenance as the project evolves

- **Kickoff maintains the manifest** `FR-project-orientation-kickoff-maintains`: When `/pdeq-kickoff` mints a spec marked `standing: true`, it adds a row to `project.md`'s Standing specs table in the same kickoff. When a standing spec is retired, kickoff removes its row. Authored sections (identity, platforms, stack, how to operate) are updated by the coordinator when the underlying facts change, not by a mechanical transform.
- **Status surfaces orientation** `FR-project-orientation-status-surfaces`: `/pdeq-status` reports whether `project.md` exists and lists the standing specs in its manifest, so a maintainer can see at a glance whether the project is oriented and which cross-cutting specs are in force.

### Migration

- **Migration seeds the orientation file** `FR-project-orientation-migration-seeds`: A migration creates `project.md` for projects that lack one. For a fresh project, the authored sections are seeded from project configuration and repository signals. For an existing project, the migration also performs a semantic pass (below). The mechanical creation is idempotent: re-running against a project that already has `project.md` is a no-op.
- **Migration pares accumulated project-specific content** `FR-project-orientation-migration-pares`: For existing projects, the migration's semantic pass scans the framework agent file (and any harness-specific override file such as a CLAUDE.md wrapper) for project-specific content that has organically accumulated — project identity, stack notes, conventions, or guidance that duplicates or conflicts with what now belongs in `project.md` or a standing spec. It moves identity/stack/standing-convention content into `project.md`, and pares the framework file back to framework rules, flagging duplicates and conflicts for human review rather than silently deleting them.

## Non-Functional Requirements

- **No new top-level folder** `NFR-project-orientation-no-new-folder`: `project.md` sits at the specs root alongside `index.md` and `glossary.md`. Standing specs live in their existing lane folders. No new top-level directory is introduced.
- **Orientation read is cheap** `NFR-project-orientation-cheap-read`: `project.md` is short enough that reading it at session start adds negligible overhead — a few paragraphs and a short table, not a comprehensive document. Comprehensive detail lives in the standing specs it points at.
- **Maintenance is LLM-driven, not mechanically generated** `NFR-project-orientation-llm-maintained`: The authored sections of `project.md` are maintained by the agent during sessions as the project changes, not regenerated from a deterministic scan. The standing-specs manifest is the one structured, cross-checkable part; the rest is prose a human or agent keeps current.

## Acceptance Criteria

These are the testable conditions that define "done."

- [ ] **Fresh install creates project.md** `AC-project-orientation-fresh-install`: Running `init.sh` on a new project creates `project.md` at the specs root with the required sections.
- [ ] **Migration is idempotent** `AC-project-orientation-migration-idempotent`: Re-running the project-orientation migration against a project that already has `project.md` makes no changes.
- [ ] **Manifest paths resolve** `AC-project-orientation-manifest-resolves`: Every file path listed in `project.md`'s Standing specs table points to an existing file, and every spec in the project marked `standing: true` appears in the table.
- [ ] **Kickoff adds standing specs to the manifest** `AC-project-orientation-kickoff-adds`: After `/pdeq-kickoff` mints a spec with `standing: true`, `project.md`'s Standing specs table contains a row for it.
- [ ] **Migration consolidates accumulated content** `AC-project-orientation-migration-consolidates`: After the migration's semantic pass on an existing project, project-specific content that belonged in `project.md` or a standing spec has been moved there, and the framework agent file no longer contains the duplicates; conflicts are flagged for review rather than silently dropped.
