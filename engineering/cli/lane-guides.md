---
product-hash: 702ebccbedc4866a1c385c6460af91e99a71f599934f7ef3170431963ce5d40f
product-slugs: [AC-lane-guides-agent-reads, AC-lane-guides-installer-no-stub, AC-lane-guides-installer-warns, AC-lane-guides-reinstall-reconciles, AC-lane-guides-schema-accepts, AC-lane-guides-schema-rejects-unknown, AC-lane-guides-status-reports, AC-lane-guides-symlink-harness, FR-lane-guides-config, FR-lane-guides-distinct-from-standing, FR-lane-guides-framework-surfaces, FR-lane-guides-harness-agnostic, FR-lane-guides-installer-no-stub, FR-lane-guides-installer-validates, FR-lane-guides-missing-non-fatal, FR-lane-guides-paths-relative-to-specsroot, FR-lane-guides-per-lane-context, FR-lane-guides-project-local, FR-lane-guides-reinstall-reconciles, FR-lane-guides-status-reports, FR-lane-guides-unknown-lane-rejected, NFR-lane-guides-cheap-read, NFR-lane-guides-no-new-deps, NFR-lane-guides-survives-template-update]
---
# Lane Guides — Technical Spec

> Based on requirements in `../../product/lane-guides.md`

## What We're Building

A config-driven, harness-agnostic mechanism for a consumer project to attach a per-lane "guide" file of skills/architecture/guidelines that the lane agent reads before authoring specs in that lane. The consumer declares the guides in `pdeq.json` under a new `laneGuides` object (lane id → path relative to `specsRoot`); the installer validates the paths and warns on misses; the framework's canonical agent instructions tell each lane agent to read its guide when configured; `/pdeq-status` reports the configured guides and their resolve status.

The key design decision is where the "read your guide" rule lives: in the **canonical framework `AGENTS.md` templates** (root coordinator + each lane), not in consumer-appended prose. This is what makes the feature harness-agnostic — symlink harnesses (Codex, Pi) have no append slot below the import, so the only way to reach them is to bake the rule into the shared template they already load. The consumer never edits the submodule; project-specific content lives in the guide files they author and commit.

The rejected alternative was extending the standing-specs manifest to be lane-scoped. Standing specs are project-wide constraints surfaced once at session start; lane guides are lane-scoped context surfaced at authoring time, and they must close the Codex/Pi append asymmetry that standing specs do not address. Folding the two would overload one concept; keeping them orthogonal (a file may be both) is cheaper and clearer.

## Technical Approach

Four tracks, roughly in order:

1. **Schema** — add a `laneGuides` object to `pdeq.schema.json` keyed by lane id, values relative paths. Reject unknown lane keys and absolute paths.
2. **Framework prose** — add a short "Lane guides" section to the root `AGENTS.md` and each lane's `AGENTS.md` (`product/`, `design/`, `engineering/`, `qa/`, `roadmap/`) instructing the agent to read its configured guide before authoring in that lane. These are canonical template edits in the self-host repo.
3. **Installer validation** — add a validation pass to `scripts/init.sh` that reads `laneGuides`, resolves each path against `specsRoot`, warns on miss, and reports in the install log. No file creation.
4. **Status surfacing** — extend the `pdeq-status` command prompt to read `laneGuides` and print a per-lane table (lane, path, resolves?).

## Data Model

No persistent runtime data. The single state surface is:

- **`pdeq.json` `laneGuides` field** — a JSON object mapping lane identifier (`product` | `design` | `engineering` | `qa` | `roadmap`) to a file path string relative to `specsRoot`. Validated by `pdeq.schema.json`. Read by `scripts/init.sh` (validation) and the `pdeq-status` command (reporting). Omitting the field or a key means no guide for that lane.

## API / Interface Design

No external API. The interface is the config field plus two consumer-facing surfaces:

- **`pdeq.json` `laneGuides`** — consumer-authored, version-controlled.
- **Installer log lines** — `validate <lane> guide: <path> (ok | MISSING)` per configured entry.
- **`/pdeq-status` Lane Guides table** — lane, path, resolve status.

## Component Architecture

### Schema (`pdeq.schema.json`)

Add a top-level `laneGuides` property:

```json
"laneGuides": {
  "type": "object",
  "description": "Per-lane guide files... map lane id to path relative to specsRoot.",
  "additionalProperties": false,
  "properties": {
    "product": { "type": "string", "description": "..." },
    "design": { "type": "string" },
    "engineering": { "type": "string" },
    "qa": { "type": "string" },
    "roadmap": { "type": "string" }
  },
  "patternProperties": { "^[a-z]+$": { "type": "string" } }
}
```

`additionalProperties: false` with explicit per-lane properties rejects unknown lane keys (`AC-lane-guides-schema-rejects-unknown`). Absolute-path rejection is enforced by a `pattern` forbidding a leading `/` on each value (pattern: `^[^/].*$`), or by an install-time check; schema-level is preferred so it is caught at validation, not at install.

### Installer (`scripts/init.sh`)

A new validation function sourced or inlined after harness materialization. It reads `laneGuides` from the config (reuse the same JSON-parse approach the harness resolver uses — a small `grep`/`tr` extraction or a `python3 -c` one-liner, consistent with the existing no-new-deps floor). For each entry:

1. Resolve `<specsRoot>/<path>`.
2. If the file exists: report `ok`.
3. If missing: print a warning naming the lane and path; do not fail, do not create the file.

This is idempotent by construction: re-running re-validates. Removing a key from `laneGuides` stops validation for that lane; the authored file is never touched by the installer.

### Framework prose (canonical `AGENTS.md` templates)

Because the self-host repo's framework files live at the repo root (selfHost), the canonical templates are `AGENTS.md` (root), `product/AGENTS.md`, `design/AGENTS.md`, `engineering/AGENTS.md`, `qa/AGENTS.md`, `roadmap/AGENTS.md`. Each gains a short section:

> **Lane guides.** Before writing specs in this lane, check `pdeq.json` for a `laneGuides` entry keyed to this lane. If present and the path resolves, read that file first — it holds this project's lane-specific skills, architecture, or guidelines. If absent or missing, proceed without it.

The root `AGENTS.md` adds the cross-lane version (the coordinator reads a delegate's guide when delegating). This is framework behavior, not project content, so it propagates to every harness through the normal template load (Claude `@import`, Codex/Pi symlink) with no consumer append.

### `/pdeq-status` (`pdeq-rules/commands/pdeq-status.md`)

Add a step that reads `laneGuides` from `pdeq.json` and prints:

```
### Lane Guides
| Lane | Path | Resolves |
|---|---|---|
| qa | qa/snapshot-testing.md | yes |
| engineering | engineering/architecture.md | no — flagged |
```

If `laneGuides` is absent, report "none configured."

## State Management

Stateless. The config is read fresh each time the installer or status command runs. No cached guide state.

## Error Handling

- **Unknown lane key** — rejected at schema validation (fail fast, before install).
- **Absolute path** — rejected at schema validation.
- **Missing guide file at install** — warning, non-fatal. The consumer stages the file later.
- **Missing guide file mid-session** — the agent notes it and proceeds (`FR-lane-guides-missing-non-fatal`). Surfacing this as a status gap, not a hard stop, matches the standing-spec manifest's "flag unresolved path" pattern.

## Performance Considerations

One file existence check per configured guide at install/status time. Negligible. The agent read is one file open before authoring — `NFR-lane-guides-cheap-read`.

## Security Considerations

Guide paths are relative to `specsRoot` and resolved within the project tree. Absolute paths are rejected. No path is executed or parsed as code; guides are markdown read as context. No elevation beyond reading a committed project file.

## Implementation Plan

1. **Schema** — add `laneGuides` to `pdeq.schema.json` with per-lane properties and absolute-path rejection. Unlocks installer + status work.
2. **Installer validation** — add the `_validate_lane_guides` pass to `scripts/init.sh` after harness materialization, with warn-on-miss and per-entry logging. Unlocks the install-time ACs.
3. **Framework prose** — add the "Lane guides" section to the six canonical `AGENTS.md` templates. Unlocks the agent-reads behavior and the harness-agnostic AC.
4. **Status command** — extend `pdeq-rules/commands/pdeq-status.md` with the Lane Guides table step.
5. **Tests** — extend `scripts/test-harness-agnostic.sh` (or a new `scripts/test-lane-guides.sh`) with the schema-accepts/rejects, installer-warns/no-stub, and status-reports cases.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-lane-guides-config | pdeq.schema.json | planned |
| FR-lane-guides-unknown-lane-rejected | pdeq.schema.json | planned |
| FR-lane-guides-paths-relative-to-specsroot | pdeq.schema.json | planned |
| FR-lane-guides-per-lane-context | AGENTS.md (root + lane templates) | planned |
| FR-lane-guides-project-local | scripts/init.sh | planned |
| FR-lane-guides-distinct-from-standing | AGENTS.md (root) | planned |
| FR-lane-guides-framework-surfaces | AGENTS.md (root + lane templates) | planned |
| FR-lane-guides-harness-agnostic | AGENTS.md (root + lane templates) | planned |
| FR-lane-guides-missing-non-fatal | AGENTS.md (lane templates); scripts/init.sh | planned |
| FR-lane-guides-installer-validates | scripts/init.sh | planned |
| FR-lane-guides-installer-no-stub | scripts/init.sh | planned |
| FR-lane-guides-reinstall-reconciles | scripts/init.sh | planned |
| FR-lane-guides-status-reports | pdeq-rules/commands/pdeq-status.md | planned |
| NFR-lane-guides-no-new-deps | scripts/init.sh | planned |
| NFR-lane-guides-cheap-read | AGENTS.md (lane templates) | planned |
| NFR-lane-guides-survives-template-update | AGENTS.md (root + lane templates) | planned |
