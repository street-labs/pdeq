# Glossary

This file defines shared vocabulary for the project. All agents must use consistent terminology. Before introducing a new domain concept or term, check here first. If the term is not present, add it so all agents use the same language.

**Format for entries:**

**Term** — definition

---

## Terms

**Bootstrap chain** — The arrangement by which the pdeq repository manages its own specs using a pinned previous-stable pdeq version rather than the in-development version. Lets pdeq evolve itself using its own tooling without chicken-and-egg risk.

**Breaking change** — A change to pdeq that requires consumer projects to run a migration to stay in conformance. Additive or internal-only changes are not breaking; changes to slug formats, required config keys, required file layouts, or other consumer-visible contracts are. Two operational senses coexist: **lineage-breaking** (a MINOR/MAJOR version bump — what the migration runner and the enforcement gate act on) and **consumer-breaking** (the consumer must run the migration to stay conformant — recorded in a migration's `breaking:` frontmatter). They usually coincide; when a lineage-breaking release is not consumer-breaking, it ships an [advisory migration].

**Advisory migration** — A migration whose frontmatter declares `breaking: false`. It rides a lineage-breaking (MINOR/MAJOR) release that is not consumer-breaking: its transforms are optional and idempotent (e.g. seeding an optional config scaffold, or a report-only conformance review), so a consumer who skips it — or whose semantic block only reports — stays conformant. The runner applies it exactly like any other pending migration; the flag is human-facing documentation, not a control signal. `migrations/0.5.0.md` (lane-discipline) is the first advisory migration.

**Code Map** — The section in a platform-specific engineering spec that lists planned code locations for every requirement slug the spec covers. Captures implementation intent at planning time and is kept current as files move, split, or merge during implementation.

**Inline marker** — A short comment placed at the implementation site in code that cites one or more requirement slugs (e.g. `FR-auth-email-login`) the surrounding block realizes. The authoritative link between a requirement and its implementation; lives with the code rather than in a separate mapping file.

**Lane discipline** — The practice of keeping each spec within its functional area's scope, in particular keeping product specs free of design, engineering, and platform detail so they remain a portable, platform-neutral baseline. Enforced by two layers: a lexical backstop and a lane review. See `product/lane-discipline.md`.

**Lexical backstop** — The deterministic keyword audit (`scripts/audit-lanes.sh`) that scans product specs for configured red-flag terms — built-in defaults plus a project's own `laneAudit` vocabulary in `pdeq.json`. Cheap and agent-free; runs warn-only at commit time. It catches *words*, not structure, so a clean run does not by itself mean a spec is in-lane.

**Lane review / Lane Reviewer** — The agent-run quality pass (root `AGENTS.md` §Quality Subagents) that reads product specs and flags lane bleed by reasoning about the meaning and structure of the text, classifying each finding by category and severity (`violation` vs `allowed`). The principle-enforcing complement to the lexical backstop; advisory, never a commit-time gate.

**Structural bleed** — Design/engineering/platform detail that appears in a product spec through *phrasing* rather than a recognizable keyword — e.g. a requirement described as a protocol exchange without naming the protocol, or a single host treated as if it were the product. Invisible to the lexical backstop; the target of the lane review.

**In-session command availability** — The contract that any new or modified pdeq slash command shipped by a freshly-bumped pdeq version is invocable in the same coding-agent session that ran the upgrade, without requiring a session restart. Realized by the symlink sync step of `/pdeq-update` plus the harness's on-demand command-file lookup.

**Mechanical transform** — The deterministic portion of a migration. Applies the same rule to every applicable file without human judgment — for example, a rename, a move, or a rule-based rewrite. Runs before the semantic transform within a single migration.

**Migration** — A versioned, author-written transformation that brings a consumer project's specs and configuration into conformance with a newer pdeq version. One migration per pdeq version that introduces a breaking change.

**Orphan marker** — An inline marker that cites a slug not defined in any current product spec. Usually indicates either a typo in the marker or a requirement that was removed from the product spec without the code being updated. Orphan markers are rejected by the traceability audit.

**Semantic transform** — The optional judgment-based portion of a migration. A prompt block supplied with relevant file context, executed by an AI agent when per-item judgment is required and no deterministic rule can express the change. Runs after the mechanical transform within a single migration.

**Symlink sync** — The idempotent operation that reconciles a consumer project's `<git-root>/scripts/` and `<git-root>/.claude/commands/` symlinks against the current contents of the `.pdeq/` submodule: creating symlinks for newly-shipped files and (with `--prune`) removing dangling symlinks for files deleted upstream. Implemented in `scripts/sync-symlinks.sh` and called by both `init.sh` and `/pdeq-update`.

**Traceability audit** — The pre-commit pipeline (`scripts/audit-traceability.sh`) that validates the traceability index against product specs, downstream specs, and code. Reconciles slug definitions, Code Map planned paths, and inline markers; blocks commits on drift subject to the documented escape hatch.

**Pdeq command prefix** — The naming convention by which every pdeq-installed slash command begins with the `pdeq-` prefix (`/pdeq-kickoff`, `/pdeq-status`, `/pdeq-migrate`, etc.). Lets a consumer discover the full pdeq command surface by typing `/pdeq` in their slash-command palette and prevents collision with bare-verb commands a consumer's own project or other tooling may ship. See `product/cli-conventions.md` for the contract.

**Upgrade entrypoint** — The unified consumer-facing surface for getting on a newer pdeq version. Realized by the `/pdeq-update` slash command, which advances the pinned `.pdeq/` submodule reference, runs symlink sync, and chains into `/pdeq-migrate` so the recorded version catches up — all in one invocation. Distinct from `/pdeq-migrate`, which advances the recorded version against an already-bumped pin and serves as the recovery verb on partial-run failure.

**Harness** — A coding-agent runtime that loads pdeq's prose, slash commands, and skill assets and presents them to the developer. Examples at pdeq v0.4.0: Claude Code (`claude`), Codex CLI (`codex`), Pi (`pi`). Pdeq exposes its surface to multiple harnesses by materializing per-harness file views at install time over a single canonical source-of-truth in the submodule. See `product/harness-agnostic.md`.

**Harness adapter table** — The internal lookup inside `scripts/init.sh` that maps each recognized harness identifier to the per-lane agent-file name that harness reads (e.g. `CLAUDE.md` for `claude`, `AGENTS.md` for `codex`/`pi`) and the relative directory inside the consumer's project where that harness expects markdown-defined slash commands (or empty when the harness has no markdown slash-command surface). The single point of extension for adding a new harness — adding a row to the table is a one-commit change that does not alter installer logic. See `engineering/cli/harness-agnostic.md` for the v1 contents.

**Canonical agent-instructions file** — The single `AGENTS.md` file at each lane (root, `product/`, `design/`, `engineering/`, `qa/`, `roadmap/`) inside the pdeq submodule that holds the agent-orienting prose for that lane. Every per-harness file the installer materializes in a consumer project points at the canonical `AGENTS.md` for its lane — Claude via `@import`, other harnesses via symlink — so editing the canonical file propagates to every harness view. Introduced in pdeq 0.4.0 to replace the per-harness `CLAUDE.md` duplication.

**Harness materialization** — The installer step that translates a consumer's `harnesses` list into concrete files on disk. For every enabled harness, the installer creates the agent-instructions file at each lane (using the harness's filename convention) and, when the harness supports markdown slash commands, mirrors pdeq's command source files into the harness's commands directory. The step is idempotent: re-running after a `harnesses`-list edit reconciles the filesystem to match the new list, adding what is now needed and removing pdeq-managed files for harnesses that were dropped.

