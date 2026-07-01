# Changelog

All notable changes to pdeq are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and pdeq follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). A MINOR/MAJOR
(lineage-breaking) release ships a matching migration under `migrations/<version>.md`;
run `/pdeq-migrate` (or `/pdeq-update`) to advance a project.

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

[0.5.0]: https://github.com/street-labs/pdeq/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/street-labs/pdeq/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/street-labs/pdeq/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/street-labs/pdeq/releases/tag/v0.2.0
