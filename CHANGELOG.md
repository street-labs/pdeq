# Changelog

All notable changes to pdeq are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and pdeq follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). A MINOR/MAJOR
(lineage-breaking) release ships a matching migration under `migrations/<version>.md`;
run `/pdeq-migrate` (or `/pdeq-update`) to advance a project.

## [0.15.0] — 2026-09-28

### Added
- **Jev-assisted lane-audit triage.** Opt-in automated classification of lexical-backstop findings: with `laneAudit.jevTriage: true` in `pdeq.json` and the `jev` judgment CLI installed, each flagged line is additionally classified as a violation or an allowed mention. High-confidence allowed answers are demoted to labeled notes; triage can only demote, never hide. Off by default — a project that does nothing keeps the exact pre-0.15.0 deterministic, no-network audit behavior.
- **Conformance alignment pre-screen** (`scripts/alignment-check.sh`) — cheap per-slice drift check pairing each indexed requirement with the code its traceability mapping cites, classified aligned/drift by one `jev --json choice` call per slice. Acts only on confident answers; a doubtful or unavailable service leaves the slice unassessed. Escalated drift names the feature whose full `/pdeq-conform` review to run. Invocation is the opt-in — no hook or default audit ever calls the judgment service.
- Advisory migration `migrations/0.15.0.md` (`breaking: false`) — mechanically a no-op; the features are opt-in configuration or opt-in invocation.

## [0.14.0] — 2026-09-28

### Added
- **Lane guides.** A config-driven, harness-agnostic way to attach a per-lane guide file (skills, architecture, guidelines) that the lane agent reads before authoring specs. Declared in `pdeq.json` under `laneGuides` (lane id → path relative to `specsRoot`); the installer validates paths and warns on misses; `/pdeq-status` reports configured guides and their resolve status. Distinct from standing specs (project-wide, surfaced at session start) — lane guides are lane-scoped and surfaced at authoring time; a single file may be both.
- Advisory migration `migrations/0.14.0.md` (`breaking: false`) — scans a consumer's existing lane-specific content (appended prose in lane agent override files, standalone non-spec lane docs, lane-scoped standing specs) and consolidates it into declarative `<lane>/GUIDE.md` files; a project with no lane-specific content sees a no-op.

## [0.13.0] — 2026-09-28

### Added
- **Implement command.** `/pdeq-implement` plus `scripts/implement-context.sh`: turns reviewed specs into implementing code in one step. Scope is derived from spec-tree changes relative to a base branch; the traceability index says where the code is; the context bundle is produced by one script invocation and is ephemeral (never committed). After implementation and marker annotation, the traceability audit is the done-check.
- Advisory migration `migrations/0.13.0.md` (`breaking: false`) — the script, command, and 22-case test suite install on submodule bump; the only semantic step wires the implement suite into consumer CI alongside the existing pdeq suites.

## [0.12.0] — 2026-07-19

### Added
- **Project orientation.** Every pdeq project gets a `project.md` at its specs root: the skinny on what the project is, its platforms and tech stack, the **standing specs** every builder must respect, and how to operate within it. A *standing spec* is a cross-cutting spec (style guide, architecture baseline, security baseline) marked `standing: true` in its frontmatter; `project.md`'s Standing specs table is the manifest. The coordinator reads `project.md` at the start of every implementation session.
- `scripts/seed-project-md.sh` — idempotent skeleton seeder for `project.md`, installed automatically on submodule bump.
- Advisory migration `migrations/0.12.0.md` (`breaking: false`) seeds `project.md` and offers a semantic pass consolidating project-specific clutter out of the framework agent file.

### Changed
- Reviewer stamps `standing: true` frontmatter and `governs:` on standing specs; `decisions.md` boilerplate fixed.

## [0.11.0] — 2026-07-15

### Added
- **QA Coverage Audit** (`scripts/audit-coverage.sh` + `scripts/audit-coverage.py`) — joins the marker-derived Code column from the traceability index against each feature's QA Coverage Matrix and blocks commits when a feature has realizing code but its coverage rows are non-terminal. The inverse of the requirement↔code mapping: where the traceability audit blocks on "code doesn't exist yet," this blocks on "QA hasn't been run yet."
- `scripts/lib/qa-matrix.sh` — shared QA parser extracted from `audit-traceability.sh`.
- `pdeq-rules/commands/pdeq-coverage.md` — slash command for interactive coverage checks.
- Advisory migration `migrations/0.11.0.md` (`breaking: false`); scripts install on submodule bump but do not run automatically — consumers opt in via CI/pre-commit.

## [0.10.0] — 2026-07-12

### Added
- **Living spec discipline.** Specs describe the current state of features, not versioned plans or phased roadmaps. `scripts/audit-temporal.sh` detects temporal language ("MVP", "phase 1", "V2", "iteration 2") and **blocks at commit time by default**. Projects opt out via `temporalAudit.blockCommit: false` in `pdeq.json`, or tune with `temporalAudit.exclude`/`temporalAudit.include`.
- **Roadmap spec supplements** — optional forward-looking content in `roadmap/` with reserved slug prefixes (`FRR-`, `NFRR-`, `ACR-`) for multi-phase planning, exempt from traceability.
- Breaking migration `migrations/0.10.0.md`: consumers must clean up temporal language or opt out.

### Changed
- `scripts/audit-traceability.sh` skips roadmap slug prefixes.
- `pdeq-rules/commands/pdeq-kickoff.md` runs the temporal audit in Step 4.

## [0.5.0] — 2026-07-01

### Added
- **Two-layer lane discipline.** A deterministic lexical backstop (`scripts/audit-lanes.sh`) reads a project's own `laneAudit` terms from `pdeq.json` (vendors/protocols/platforms/libraries), extending built-in defaults, and runs warn-only in pre-commit. A prompt-guided **Lane Reviewer** (root `AGENTS.md`; `/pdeq-kickoff` Step 4) reasons about structural bleed a keyword scan can't see, classifying findings by category and severity.
- **Advisory (non-breaking) migration class** in `product/migrations.md`. `migrations/0.5.0.md` is the first: `breaking: false`, seeds a `laneAudit` scaffold and runs a report-only lane review over existing product specs.

### Changed
- `audit-lanes.sh` scans via `python3 re` instead of `grep -P` — portable across macOS/Linux (the old `grep -P` silently no-op'd on macOS) — and ignores requirement-slug identifiers so a project's own slugs never self-trip the audit.
- Cleared pre-existing lane bleed in pdeq's own product specs.

## [0.4.0] — 2026-05-18

### Changed
- Harness-agnostic file layout: `CLAUDE.md` → `AGENTS.md` as the canonical agent-instructions file at each lane, slash-command source moved under `pdeq-rules/commands/`, bootstrap subagent files folded inline. Adds multi-harness install support (Claude Code, Codex CLI, Pi).

## [0.3.0] — 2026-05-18

### Changed
- Renamed all pdeq slash commands to the `pdeq-` prefix (`/pdeq-kickoff`, `/pdeq-migrate`, …) for namespace clarity.

## [0.2.0] — 2026-05-18

### Added
- `pdeqVersion` field in `pdeq.json` and the migrations feature — the on-ramp from pre-migrations projects.

[0.15.0]: https://github.com/street-labs/pdeq/compare/ab6d056...v0.15.0
[0.14.0]: https://github.com/street-labs/pdeq/compare/v0.12.0...ab6d056
[0.13.0]: https://github.com/street-labs/pdeq/compare/v0.12.0...0d27295
[0.12.0]: https://github.com/street-labs/pdeq/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/street-labs/pdeq/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/street-labs/pdeq/compare/v0.9.0...v0.10.0
[0.5.0]: https://github.com/street-labs/pdeq/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/street-labs/pdeq/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/street-labs/pdeq/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/street-labs/pdeq/releases/tag/v0.2.0
