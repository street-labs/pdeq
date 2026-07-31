# Lane Guides

## Overview

Pdeq ships a generic agent-instructions template per lane (`product/AGENTS.md`, `engineering/AGENTS.md`, etc.) inside the framework. A consumer project often has lane-specific knowledge the generic template cannot carry — an engineering architecture baseline, a QA testing strategy, a design system reference, a product domain cheat-sheet. Today the only per-lane customization surface is asymmetric: Claude consumers can append prose below the `@import` in their `CLAUDE.md`, but Codex and Pi consumers get a symlink straight to the shared template with no append slot, so any project-specific content written into the lane agent file lands in the submodule's working tree and reverts on a fresh checkout.

Lane guides close that gap. A consumer declares a per-lane guide file in `pdeq.json`, authors the content in a project-local file the parent repo tracks, and the framework surfaces it to the lane agent as context the agent reads before writing specs in that lane. The mechanism is harness-agnostic (it does not depend on editing the symlinked template), declarative (driven by config, not by hand-editing framework files), and distinct from standing specs (which are project-wide; lane guides are lane-scoped).

## User Stories

- As a **consumer-project maintainer on Codex or Pi**, I want to attach architecture and guideline docs to each lane so my lane agents know my project's conventions when writing specs, without editing the shared framework template.
- As a **consumer-project maintainer on Claude**, I want a declarative, config-driven per-lane guide so my customizations survive re-running the installer and are visible to tooling, rather than living as freeform prose appended below an import.
- As a **lane agent writing a spec**, I want the project's lane-specific guidelines loaded into my context before I author, so I follow the project's conventions instead of only the generic template.
- As a **project maintainer**, I want lane guides reported by `/pdeq-status` and validated by the installer, so I can see which lanes have custom context and catch a broken path at install time, not mid-session.
- As a **maintainer of a project with both standing specs and lane guides**, I want the two concepts to coexist without forcing a choice, so a file can be a project-wide standing spec and a lane guide at the same time when that makes sense.

## Requirements

### The lane guide concept

A lane guide is a consumer-authored markdown document of skills, architecture, or guidelines that applies to one lane's spec-writing work. It is not a feature spec; it is context the lane agent reads before authoring in that lane.

- **Lane guide is per-lane context** `FR-lane-guides-per-lane-context`: A lane guide is scoped to exactly one lane (`product`, `design`, `engineering`, `qa`, or `roadmap`). It holds skills, architecture, conventions, or guidelines the agent working in that lane should know when writing specs. It is not a requirements spec and carries no `FR-`/`NFR-`/`AC-` slugs of its own.
- **Lane guide is project-local and tracked** `FR-lane-guides-project-local`: A lane guide file lives in the consumer's project (typically inside its lane folder under `specsRoot`), is committed to the parent repo, and is never written into the `.pdeq` submodule. This guarantees it survives fresh checkouts and is not shared with the generic framework template.
- **Distinction from standing specs** `FR-lane-guides-distinct-from-standing`: A standing spec is project-wide — every builder respects it regardless of lane. A lane guide is lane-scoped — only the agent working in that lane reads it. The two are orthogonal: a single file may be both a standing spec (listed in `project.md`'s manifest, read at session start) and a lane guide (configured in `laneGuides`, read when the lane agent authors), or just one of the two. The concepts do not collapse into each other.

### Configuration

The consumer declares lane guides in the project config so the declaration is declarative, version-controlled, and consumable by the installer and status tooling.

- **Lane guides declared in config** `FR-lane-guides-config`: A consumer project records its lane guides in `pdeq.json` as a `laneGuides` object mapping a lane identifier (`product`, `design`, `engineering`, `qa`, `roadmap`) to a file path relative to `specsRoot`. Omitting the field or a lane key means that lane has no guide. The map is optional in its entirety.
- **Unknown lane key rejected** `FR-lane-guides-unknown-lane-rejected`: A `laneGuides` key that is not a recognized lane identifier is rejected by schema validation with a message naming the offending key and the recognized set, so a typo does not silently attach a guide to the wrong lane or no lane.
- **Paths relative to specsRoot** `FR-lane-guides-paths-relative-to-specsroot`: Every guide path in `laneGuides` is interpreted relative to `specsRoot` (the directory containing the lane folders), the same base used for all spec paths. Absolute paths are rejected by schema validation.

### Surfacing to the lane agent

The framework makes the lane agent aware of its guide at authoring time, on every harness, without requiring the consumer to edit the shared template.

- **Framework surfaces lane guides** `FR-lane-guides-framework-surfaces`: The framework tells a lane agent to read its lane's guide file before writing specs in that lane when one is configured. The surfacing is framework-provided behavior, not something the consumer must wire up per project, so a consumer who declares a guide gets it surfaced without authoring or editing any agent-instruction file.
- **Surfacing is harness-agnostic** `FR-lane-guides-harness-agnostic`: The read-your-guide rule works identically on every supported harness. No harness depends on the consumer editing a framework file or submodule to surface a guide. A project on a harness with no per-file append slot gets the same per-lane customization as one with an append slot.
- **Missing guide is non-fatal** `FR-lane-guides-missing-non-fatal`: If a configured guide path does not resolve at the moment a lane agent reads it, the agent notes the missing path and proceeds without the guide, rather than blocking spec authoring. The installer catches broken paths earlier (see below), so a missing path mid-session signals drift, not a hard stop.

### Installer and tooling support

- **Installer validates guide paths** `FR-lane-guides-installer-validates`: When the installer runs, it reads `laneGuides` and checks each configured path resolves to an existing file. A path that does not resolve produces a warning naming the lane and path; the install does not fail, so a consumer can stage a guide file after install. The validation result is included in the installer's per-step output.
- **Installer does not create guide files** `FR-lane-guides-installer-no-stub`: The installer never creates, scaffolds, or modifies a lane guide file. Guide content is consumer-authored; the installer only validates and surfaces. This keeps the installer out of the content business and avoids shipping empty stubs.
- **Re-install reconciles** `FR-lane-guides-reinstall-reconciles`: Editing `laneGuides` (adding, removing, or repointing a lane) and re-running the installer's validation step reconciles without error. Removing a lane key stops the installer from validating that path; the previously-authored guide file is left untouched on disk.
- **Status reports lane guides** `FR-lane-guides-status-reports`: `/pdeq-status` reports which lanes have a guide configured, the path each points at, and whether the path currently resolves. This gives a maintainer an at-a-glance view of per-lane customization alongside the standing-specs manifest.

## Non-Functional Requirements

- **No new install dependencies** `NFR-lane-guides-no-new-deps`: The feature adds no install dependency. Path validation is plain bash test (`[ -f ]`); schema validation extends the existing JSON schema. The install dependency floor stays `git + bash + python3`.
- **Guide read is cheap** `NFR-lane-guides-cheap-read`: Reading a lane guide adds negligible overhead at authoring time — it is one file read before spec work begins, not a scan. Guides are expected to be short context documents; comprehensive detail lives in the specs they inform.
- **Surfacing survives template updates** `NFR-lane-guides-survives-template-update`: Because the read-your-guide rule lives in the canonical framework template (not in consumer-appended prose), bumping the `.pdeq` submodule and re-running the installer preserves the behavior without the consumer re-appending anything. A symlink-harness consumer never edits the template.

## Acceptance Criteria

These cover the observable outcomes QA will test directly.

- [ ] **Schema accepts laneGuides** `AC-lane-guides-schema-accepts`: A `pdeq.json` with a `laneGuides` object mapping valid lane identifiers to relative file paths passes schema validation. Omitting `laneGuides` also passes.
- [ ] **Unknown lane key rejected by schema** `AC-lane-guides-schema-rejects-unknown`: A `pdeq.json` whose `laneGuides` has a key other than `product`/`design`/`engineering`/`qa`/`roadmap` fails schema validation with a message naming the offending key.
- [ ] **Installer validates and warns** `AC-lane-guides-installer-warns`: Running the installer with a `laneGuides` entry whose path does not exist prints a warning naming the lane and path, and the install completes successfully. An entry whose path exists prints no warning.
- [ ] **Installer does not stub** `AC-lane-guides-installer-no-stub`: After running the installer with a configured `laneGuides` entry pointing at a non-existent path, no file is created at that path.
- [ ] **Lane agent reads configured guide** `AC-lane-guides-agent-reads`: When a lane has a guide configured and the file exists, the lane agent reads it before authoring a spec in that lane. (Documentation/behavior-tested via the agent instructions and a conformance check.)
- [ ] **Works on symlink harness** `AC-lane-guides-symlink-harness`: A project on `harnesses: ["pi"]` (symlink materialization, no append slot) can configure and surface a lane guide without editing any file inside `.pdeq`. The guide file is committed in the parent repo and survives a fresh checkout.
- [ ] **Status reports guides** `AC-lane-guides-status-reports`: `/pdeq-status` lists each configured lane guide with its lane, path, and resolve status.
- [ ] **Reconciles on re-install** `AC-lane-guides-reinstall-reconciles`: Adding a `laneGuides` entry and re-running the installer's validation step warns on the new path if missing and is silent if present; removing an entry stops validation for that lane and leaves the authored file on disk.

## Open Questions

- **Surfacing location (framework template edit scope).** The read-your-guide rule must reach the lane agent on every harness without consumer template edits. The exact surface (one rule in the root coordinator instructions vs a section in each lane's instructions) is an engineering decision; the product requirement is only that the rule reaches the lane agent on every harness without consumer template edits.
- **Should `/pdeq-kickoff` prompt for a lane guide?** When kicking off a feature that will touch a lane with no guide configured, kickoff could note "no lane guide configured for <lane>" so the maintainer is aware the lane has no custom context. This is a nice-to-have, not a v1 requirement; parked here for a decision.
- **Guide file naming convention.** No prescribed filename is required (the config carries the path), but a convention recommendation (e.g. `<lane>/GUIDE.md` or `<lane>/guide.md`) would aid consistency. Left to engineering/docs; not a requirement.

## Dependencies

- **Config schema (`pdeq.schema.json`):** gains a `laneGuides` object field mapping lane identifiers to relative paths.
- **Harness-agnostic install (`product/harness-agnostic.md`):** lane guides build on the existing per-harness materialization. They do not change the import-vs-symlink mechanism; they add a parallel, config-driven customization surface that works regardless of it.
- **Project orientation (`product/project-orientation.md`):** lane guides are distinct from standing specs but coexist with them. `/pdeq-status` surfaces both; `project.md`'s standing-specs manifest is unchanged by this feature.
- **Glossary:** defines the term *Lane guide*. See `../glossary.md`.
