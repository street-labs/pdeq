# PDEQ

## What this is
PDEQ is a spec-driven workflow for coding agents. It gives any project four structured lanes — Product, Design, Engineering, QA — where markdown specs are the source of truth and code is derived from them. Every requirement is traceable from its product spec to the test that verifies it, and a pre-commit hook keeps specs and code in sync. It is driven through an agent (Claude Code, Codex CLI, or Pi) with slash commands like `/pdeq-kickoff`.

## Platforms
- `cli` — pdeq itself: shell scripts, slash commands, hooks, and agent prompts that install into consumer projects via a git submodule.

## Tech stack
Bash (POSIX-compatible, `set -euo pipefail`) for all scripts and the installer; Python 3 for the heavier audit logic (`audit-coverage.py`). No Node, no compiled binaries — the install dependency floor is bash + git + python3. Specs and agent prompts are markdown. Ripgrep is recommended but optional. Pdeq ships as a git submodule at `.pdeq` in consumer projects; this repo is the self-host source that manages its own specs with a pinned previous-stable version (the "bootstrap chain").

## Standing specs
Cross-cutting specs every builder MUST respect, regardless of feature.

| Spec | Lane / Path | Governs |
|---|---|---|
| CLI conventions | product/cli-conventions.md | the pdeq- command prefix and naming rules every shipped command follows |
| Spec structure | product/spec-structure.md | how to triage and place specs so the graph stays internally consistent |
| Lane discipline | product/lane-discipline.md | keeping product specs platform-neutral; the two-layer enforcement model |
| Living spec discipline | product/living-spec-discipline.md | specs describe current state; future plans live in roadmap; temporal language audit |
| Code mapping | product/code-mapping.md | inline Implements: markers and the requirement-to-code link |
| Migrations | product/migrations.md | the version-upgrade contract between pdeq and consumer projects |
| Conformance | product/conformance.md | the semantic code-vs-spec review contract |
| Harness-agnostic | product/harness-agnostic.md | how pdeq installs and behaves identically across Claude Code, Codex CLI, and Pi |

## How to operate
- **Build a feature:** `/pdeq-kickoff <description>` → product → design → engineering → QA, one lane at a time.
- **Cardinal rule:** markdown first, code second. Change the spec, then change the code — never the reverse.
- **Decisions:** append to `decisions-pending.md` during a session; the pre-commit hook merges it into `decisions.md` at commit time. Never edit `decisions.md` directly mid-session.
- **Traceability:** every requirement slug (`FR-`/`NFR-`/`AC-`) is tracked in `index.md`. Update it when you create or reference a slug. Run `./scripts/audit-traceability.sh` to verify.
- **Audits:** `./scripts/audit-traceability.sh`, `./scripts/audit-lanes.sh`, `./scripts/audit-structure.sh`, `./scripts/audit-temporal.sh`, `./scripts/audit-coverage.sh`. The pre-commit hook runs the blocking ones automatically; `PDEQ_ALLOW_DRIFT=1` demotes blocks to warnings.
- **Updating pdeq itself:** this is the self-host repo. It manages its own specs with a pinned previous-stable pdeq version (bootstrap chain). Bump `.pdeq` via `/pdeq-update`, then `/pdeq-migrate`.
