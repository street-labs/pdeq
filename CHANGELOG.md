# Changelog

All notable changes to pdeq are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and pdeq follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). A MINOR/MAJOR
(lineage-breaking) release ships a matching migration under `migrations/<version>.md`;
run `/pdeq-migrate` (or `/pdeq-update`) to advance a project.

## [0.14.0] — 2026-08-01

### Added
- **Lane guides.** A config-driven, harness-agnostic way to attach a per-lane "guide" file of skills, architecture, or guidelines that the lane agent reads before authoring in that lane. A consumer declares guides in `pdeq.json` under a `laneGuides` object (lane id → path relative to `specsRoot`); the installer validates each path and warns on a miss; `/pdeq-status` reports configured guides and their resolve status. Lane guides are distinct from standing specs (project-wide) — they are lane-scoped, surfaced at authoring time, and a single file may be both. Because the rule lives in the canonical framework template, it reaches every harness through the normal template load with no consumer append.
- `scripts/test-lane-guides.sh` — installer-validation and status test suite.
- Advisory migration `migrations/0.14.0.md` (`breaking: false`) — scans a project for existing lane-specific content (append-slot prose in project-owned lane override files, standalone non-spec lane docs, lane-scoped standing specs) and consolidates it into declarative `laneGuides` files.

### Changed
- **Release runbook.** Documented the release procedure in `CONTRIBUTING.md` §Releasing and added `scripts/release.sh` — the mechanical tagger that asserts `VERSION` matches, refuses a dirty tree, refuses to tag off `origin/main`, cuts an annotated `v<version>` tag, pushes it, and verifies via `ls-remote`. Closes the "bumped but never tagged" gap.

## [0.13.0] — 2026-07-20

### Added
- **Implement command.** `/pdeq-implement` and `scripts/implement-context.sh` turn reviewed specs into implementing code in one step: joins git spec-diff scope against the traceability index, emits one deterministically-ordered context bundle to the implementing agent, which writes code, adds inline markers, runs the engineering/QA loop, and re-runs the traceability audit as the done-check.
- `engineering/apps/cli/tests/implement/` — 22-case shell test suite (runs in CI, no consumer action needed).
- Advisory migration `migrations/0.13.0.md` (`breaking: false`); the new script, command, and test suite install automatically on submodule bump. No consumer spec or config changes required.

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

[0.12.0]: https://github.com/street-labs/pdeq/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/street-labs/pdeq/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/street-labs/pdeq/compare/v0.9.0...v0.10.0
[0.5.0]: https://github.com/street-labs/pdeq/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/street-labs/pdeq/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/street-labs/pdeq/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/street-labs/pdeq/releases/tag/v0.2.0
