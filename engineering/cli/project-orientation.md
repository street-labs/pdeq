---
product-hash: 51085e32fe45ec86d78c2f7e8e880c991de07caf95b1c80e3f826be775aa10a5
product-slugs: [AC-project-orientation-fresh-install, AC-project-orientation-kickoff-adds, AC-project-orientation-manifest-resolves, AC-project-orientation-migration-consolidates, AC-project-orientation-migration-idempotent, FR-project-orientation-file, FR-project-orientation-kickoff-maintains, FR-project-orientation-living, FR-project-orientation-migration-pares, FR-project-orientation-migration-seeds, FR-project-orientation-session-read, FR-project-orientation-standing-manifest, FR-project-orientation-standing-spec, FR-project-orientation-status-surfaces, NFR-project-orientation-cheap-read, NFR-project-orientation-llm-maintained, NFR-project-orientation-no-new-folder]
---

# Project Orientation — CLI Technical Spec

> Based on requirements in `../../product/project-orientation.md`

## What We're Building

Project orientation adds one authored file (`project.md` at the specs root) and one new spec concept (the **standing spec**) so a fresh agent session can orient itself in seconds and so cross-cutting concerns have a structurally correct home. The moving parts are small and deliberately close to existing pdeq machinery:

- `project.md` is a living, mostly-authored document. Its only structured part is the **Standing specs** table — a manifest of the project's cross-cutting specs.
- A **standing spec** is any spec marked `standing: true` (+ `governs:`) in its YAML frontmatter. It lives in its correct lane; it is just not feature-scoped.
- The coordinator agent file gains a session-start directive: read `project.md`, respect its standing specs. (`FR-project-orientation-session-read`)
- `/pdeq-kickoff` gains one responsibility: when it mints a `standing: true` spec, add a row to the manifest. (`FR-project-orientation-kickoff-maintains`)
- `/pdeq-status` gains one line: whether `project.md` exists and which standing specs are in force. (`FR-project-orientation-status-surfaces`)
- `scripts/init.sh` copies a `project.md` template on fresh install. (`FR-project-orientation-file`, `AC-project-orientation-fresh-install`)
- A migration (`migrations/<version>.md`) creates `project.md` for existing projects and runs a semantic pass that consolidates project-specific clutter out of the framework agent file. (`FR-project-orientation-migration-seeds`, `FR-project-orientation-migration-pares`)

No new top-level folder, no new audit script in v1, no generated index. The manifest is the one cross-checkable structure; everything else is prose an agent keeps current. (`NFR-project-orientation-no-new-folder`, `NFR-project-orientation-llm-maintained`)

## Technical Approach

### `project.md` shape and location

`project.md` lives at the specs root (the directory containing `product/`, `design/`, etc. — i.e. `specsRoot` from `pdeq.json`, default `.`). It has exactly these sections, in order:

```markdown
# <Project Name>

## What this is
2-4 sentences. What the product does, who it's for.

## Platforms
The platforms this project targets (mirrors pdeq.json, human-readable).

## Tech stack
One paragraph or short list. The engineering choices the project made.

## Standing specs
Cross-cutting specs every builder MUST respect, regardless of feature.

| Spec | Lane / Path | Governs |
|---|---|---|
| Style guide | engineering/cli/style-guide.md | naming, file layout, error handling |
| Architecture baseline | engineering/cli/architecture.md | layering, dependency direction |

## How to operate
Short pointer list: kickoff flow, the markdown-first cardinal rule, where decisions live, how to run audits.
```

The Standing specs table is the manifest. Columns: human-readable name, lane-relative path (resolved against the specs root), and the `governs:` one-liner copied from each standing spec's frontmatter. (`FR-project-orientation-file`, `FR-project-orientation-standing-manifest`)

### Standing spec frontmatter

A standing spec is marked in its YAML frontmatter:

```yaml
---
standing: true
governs: naming, file layout, error handling
product-hash: ...
product-slugs: [...]
---
```

`standing: true` is the signal kickoff uses to decide whether to add a manifest row. `governs:` is a short human-readable phrase copied into the manifest's third column. A standing spec otherwise follows all the same rules as a feature spec: it lives in its correct lane, carries slugs, is traceable, and is stamped with `product-hash`/`product-slugs` from its upstream product spec (a standing product spec stamps from itself is not applicable — a standing engineering/QA spec stamps from the product spec that defines its "what", which may itself be a standing product spec). (`FR-project-orientation-standing-spec`)

### Session-start directive (coordinator agent file)

The root `AGENTS.md` gains a short "Project Orientation" section stating: at the start of any implementation session, read `project.md` at the specs root before feature work; respect every standing spec it lists. This is the always-on path and requires no command. The directive is framework text shipped to all consumers via the existing agent-file materialization. (`FR-project-orientation-session-read`)

### Kickoff maintenance

`pdeq-rules/commands/pdeq-kickoff.md` gains one step in its post-processing batch (Step 4): after minting specs, if any spec created or updated in this kickoff carries `standing: true`, ensure `project.md` exists and add (or refresh) its row in the Standing specs table — copying `governs:` from the spec's frontmatter and using the spec's lane-relative path. If a standing spec was retired in this kickoff, remove its row. Authored sections are not touched by this step. (`FR-project-orientation-kickoff-maintains`, `AC-project-orientation-kickoff-adds`)

### Status surface

`pdeq-rules/commands/pdeq-status.md` gains one block in its dashboard: report whether `project.md` exists at the specs root, and if so list the standing specs from its manifest (name + path). This gives a maintainer a one-glance orientation check. (`FR-project-orientation-status-surfaces`)

### Fresh install

`scripts/init.sh` Step 7 (template copy) adds `project.md` to the `for tmpl in` loop, copying the pdeq repo's `project.md` template into the consumer's specs root when absent (idempotent skip if present). The template is a skeleton with the five section headings and placeholder prose, plus an empty Standing specs table. (`FR-project-orientation-file`, `AC-project-orientation-fresh-install`)

### Migration

`migrations/<version>.md` ships the project-orientation feature to existing projects.

**Mechanical block** (idempotent): if `project.md` does not exist at the specs root, copy the template from the pdeq install. Re-running is a no-op when the file exists. (`FR-project-orientation-migration-seeds`, `AC-project-orientation-migration-idempotent`)

**Semantic block**: the agent is given the framework agent file (`AGENTS.md`, or the symlink target) and any harness-specific override file (e.g. `CLAUDE.md` wrapper) as context, plus the newly-created `project.md`. The prompt instructs it to:

1. Seed `project.md`'s authored sections (What this is, Platforms, Tech stack, How to operate) from `pdeq.json`, the project README, and detected stack signals — only where the section is still placeholder. Leave already-authored content alone.
2. Scan the framework agent file and override file for project-specific content that has organically accumulated: project identity, stack notes, conventions, or guidance that duplicates or conflicts with what now belongs in `project.md` or a standing spec.
3. Move identity/stack/standing-convention content into `project.md`'s authored sections. Where the content is a cross-cutting convention worth keeping as a spec, note it as a candidate standing spec (do not mint one unprompted — flag it).
4. Pare the framework file back to framework rules. Where a removal would discard a conflict or duplicate that a human should adjudicate, flag it explicitly rather than silently dropping it.
5. Make no change to files that are already clean. Silence means conformant. End with `updated N of M files`.

The semantic pass is judgment work — deciding what is "project-specific accumulation" vs "legitimate framework rule" is not a deterministic transform. That is why it lives in the migration's Semantic block rather than its Mechanical block. (`FR-project-orientation-migration-pares`, `AC-project-orientation-migration-consolidates`)

## Runtime Constraints

- No new runtime dependency. Everything mechanical is bash in the `init.sh`/`migrate.sh` style. The semantic pass runs in the agent context like every other pdeq semantic migration block.
- `project.md` is not parsed by the traceability audit in v1. The manifest is human- and agent-maintained; a deterministic cross-check audit is a deliberate fast-follow, not a v1 gate. This keeps the change small and avoids wiring a new check into the pre-commit hook.
- Standing specs are full specs and are traceable like any other. The `standing: true` flag does not exempt them from lane discipline, the temporal audit, or the traceability audit; it only marks them as project-wide rather than feature-scoped.

## Code Map

Authoritative code locations for every FR defined in `product/project-orientation.md`. NFRs (cheap-read, no-new-folder, llm-maintained) are cross-cutting properties rather than one-line implementations, so they are not listed here — the same convention used by `engineering/cli/coverage-audit.md`.

| Slug | Planned location | Status |
|---|---|---|
| FR-project-orientation-file | scripts/seed-project-md.sh; scripts/init.sh | implemented |
| FR-project-orientation-living | AGENTS.md | implemented |
| FR-project-orientation-standing-spec | AGENTS.md | implemented |
| FR-project-orientation-standing-manifest | project.md; pdeq-rules/commands/pdeq-kickoff.md | implemented |
| FR-project-orientation-session-read | AGENTS.md | implemented |
| FR-project-orientation-kickoff-maintains | pdeq-rules/commands/pdeq-kickoff.md | implemented |
| FR-project-orientation-status-surfaces | pdeq-rules/commands/pdeq-status.md | implemented |
| FR-project-orientation-migration-seeds | scripts/seed-project-md.sh; migrations/0.12.0.md | implemented |
| FR-project-orientation-migration-pares | migrations/0.12.0.md | implemented |
