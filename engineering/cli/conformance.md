---
product-hash: 388b024e9649caa2071e10d74599313a3e9988635ee891f5a6a7d251f60c704c
product-slugs: [AC-conformance-evidence-cited, AC-conformance-exhaustive, AC-conformance-incorrect-detected, AC-conformance-no-plumbing, AC-conformance-non-blocking, AC-conformance-platform-isolation, AC-conformance-report-shape, AC-conformance-uncertainty-marked, AC-conformance-undocumented-detected, AC-conformance-unfulfilled-behavioral, FR-conformance-actionable, FR-conformance-advisory, FR-conformance-complements, FR-conformance-evidence, FR-conformance-four-quadrant, FR-conformance-fulfilled, FR-conformance-incorrect, FR-conformance-per-platform, FR-conformance-requirement-scope, FR-conformance-seeded, FR-conformance-single-verdict, FR-conformance-summary, FR-conformance-undocumented, FR-conformance-unfulfilled, NFR-conformance-precision, NFR-conformance-uncertainty, NFR-conformance-verifiable]
---
# Platform Conformance Audit — CLI Technical Spec

> Based on requirements in `../../product/conformance.md`
> (No design spec — this feature has no UI surface. Design lane is explicitly N/A.)

## What We're Building

The conformance audit is realized as **agent prose, not a shell script** — the same construction pattern as `/pdeq-bootstrap` and the Lane Reviewer, and the deliberate opposite of `scripts/audit-traceability.sh`. There is nothing to grep here: the four verdicts (`FR-conformance-fulfilled`, `FR-conformance-unfulfilled`, `FR-conformance-incorrect`) and the reverse-traceability scan (`FR-conformance-undocumented`) are judgments about whether code *behaves* the way a requirement says, which no lexical scanner can produce. So the feature ships as two Markdown artifacts that instruct whichever agent runs pdeq to perform the review: (a) a new **Conformance Reviewer** role documented in the root `AGENTS.md` §"Quality Subagents" — the fourth advisory reviewer alongside the Reviewer, Consistency Checker, and Lane Reviewer — and (b) a new slash-command prompt file `pdeq-rules/commands/pdeq-conform.md` implementing `/pdeq-conform <platform> [feature]`, which encodes the step-by-step workflow the reviewer follows.

The design is shaped by two decisions. First, **it is grounded, not greenfield** (`FR-conformance-seeded`): the review does not rediscover the requirement→code mapping from a blank slate. It starts from the mapping pdeq already maintains — the engineering **Code Map** tables and the `Code` column of `index.md`, both owned by the Requirement ↔ Code Mapping feature — reads the code those cite, then reasons *beyond* the mapping to reach verdicts and to notice behavior the mapping never points at. Second, **it is advisory and never wired into a hook** (`FR-conformance-advisory`): it is the semantic complement to the deterministic coverage gate, never a replacement for it (`FR-conformance-complements`). This follows the Lane Reviewer precedent exactly — a judgment-based, occasionally-uncertain check must never become a merge gate, so unlike `audit-traceability.sh` and `audit-structure.sh` there is no `hooks/pre-commit` step for it and no exit-code contract to honor.

## Technical Approach

### Realization as two prose artifacts

| Artifact | Kind | Role |
|---|---|---|
| Root `AGENTS.md` §"Quality Subagents" → **Conformance Reviewer** | Markdown role definition | Canonical statement of *what* the review produces — the four-quadrant model, verdict definitions, evidence/action/confidence requirements, and the advisory contract. This is the reusable definition a maintainer invokes on its own. |
| `pdeq-rules/commands/pdeq-conform.md` | Markdown command prompt | The invocable driver — `/pdeq-conform <platform> [feature]` — that resolves the platform, seeds from traceability, reads code, reasons to verdicts, and emits the report. It references the reviewer role rather than restating it. |

The reviewer role holds the *contract*; the command holds the *workflow*. This mirrors the Lane Reviewer, whose contract lives in `AGENTS.md` and whose invocation is Step 4 of `/pdeq-kickoff`. The command file is the standalone invocation the Lane Reviewer does not (yet) have.

**No installer change is required.** New command source files under `pdeq-rules/commands/` are materialized per-harness by the existing `scripts/init.sh` harness machinery (the same path that already materializes `pdeq-bootstrap.md`, `pdeq-status.md`, etc. into `.claude/commands/` for Claude Code and leaves them as read-in-place prompt files for Codex/Pi). Adding `pdeq-conform.md` therefore requires only that the file exist; it is picked up automatically, and Claude Code exposes `/pdeq-conform` after the next `init.sh` run. This realizes the per-platform invocation surface for `FR-conformance-per-platform` without any new plumbing.

### Harness-neutral delegation

The Conformance Reviewer runs **inline or as a spawned subagent depending on the harness**, with identical output either way — the same posture every other pdeq quality role takes (see the analyzer/generator roles in `/pdeq-bootstrap`). In a harness that supports named subagents (Claude Code), the command may delegate the read-and-reason work to a subtask that operates over the platform's source tree; in a harness that does not (Codex CLI, Pi at v1), the same agent plays the reviewer role inline. The workflow is written to be independent of that choice: it names the inputs it reads and the report it emits, not the execution mechanism. This is a documentation-enforced boundary, not a code path.

### The workflow: SEED → READ → REASON → EMIT

`/pdeq-conform <platform> [feature]` encodes four phases. The `<platform>` argument is required; the `[feature]` argument is optional and narrows scope (see §Scope resolution).

**Phase 0 — Resolve and validate the platform.** Read `pdeq.json`; resolve `specsRoot`/`codeRoot`. Validate `<platform>` against the `platforms` array. An unknown platform is a hard stop with the list of valid platforms — the audit never silently audits the wrong tree, which is the first guarantee behind `AC-conformance-platform-isolation`. Everything downstream is scoped to `{specsRoot}/{product,engineering}/…` and `{codeRoot}` entries belonging to this platform only (`FR-conformance-per-platform`).

**Phase 1 — SEED from existing traceability** (`FR-conformance-seeded`). Assemble the grounding set before reading any code:
1. Enumerate the platform's requirement set (`FR-conformance-requirement-scope`): the `FR-`/`NFR-`/`AC-` slugs defined in every `product/<feature>.md` the platform realizes, plus any `product/<platform>/<feature>.md` supplement. This is the exhaustive denominator — every requirement here must receive a verdict (`FR-conformance-single-verdict`, `AC-conformance-exhaustive`).
2. Read each platform engineering spec's `## Code Map` table → the planned/implemented code location per `FR-` slug.
3. Read the `Code` column of `index.md` → the marker-derived `file:line` locations per slug.
Together (2) and (3) give the known requirement→code map. The reviewer treats it as a *starting point*, not ground truth — the whole point is that a Code Map row can say `implemented` while the code diverges, and the deterministic audit will not notice.

**Phase 2 — READ the code** (`NFR-conformance-verifiable`). For each seeded location, open the cited file at the cited line and read the realizing unit. Then read the platform's source tree at `{codeRoot}` broadly enough to (a) confirm each requirement's behavior in context and (b) surface behavior no requirement points at — the reverse-traceability sweep for `FR-conformance-undocumented`. Scope of the tree read is governed by §Scope resolution.

**Phase 3 — REASON to a verdict** (`FR-conformance-four-quadrant`). Assign every in-scope requirement exactly one of three verdicts, judged on behavior rather than marker presence:
- **Fulfilled** (`FR-conformance-fulfilled`) — the code realizes the specified behavior. A present marker is necessary evidence but not sufficient justification; the judgment is about behavior.
- **Unfulfilled** (`FR-conformance-unfulfilled`) — no realization, or one too incomplete to satisfy the spec, *even if a marker cites the slug*. This is where the check sharpens the deterministic coverage gate, which a bare marker satisfies (`AC-conformance-unfulfilled-behavioral`).
- **Incorrectly fulfilled** (`FR-conformance-incorrect`) — code attempts the requirement but diverges: inverted condition, missing case, contradicted threshold, or behavior the spec forbids. This is precisely the drift a valid marker hides from `audit-traceability.sh` (`AC-conformance-incorrect-detected`).
Then sweep for **undocumented** behavior (`FR-conformance-undocumented`) — product-relevant behavior in code that no in-scope requirement describes — filtered per §Precision below (`AC-conformance-undocumented-detected`).

**Phase 4 — EMIT the report** (§Report Format). Open with the per-platform summary (`FR-conformance-summary`), then the four sections. Every finding carries evidence (`FR-conformance-evidence`), a recommended action for every non-fulfilled finding (`FR-conformance-actionable`), and a confidence marker (`NFR-conformance-uncertainty`).

### Relationship to the deterministic audit

The conformance audit **complements, never replaces** `scripts/audit-traceability.sh` (`FR-conformance-complements`). The division of labor is explicit and non-overlapping:

| Concern | Owner | Nature |
|---|---|---|
| Does every FR have a marker? Does every marker cite a real slug? Code Map path integrity, retirement, coverage grace. | `scripts/audit-traceability.sh` (deterministic coverage phase) | Fast, lexical, **commit-blocking** |
| Does the code *behave* as the requirement says? Is a marked requirement only pretending to be implemented? Is there behavior no requirement owns? | Conformance Reviewer / `/pdeq-conform` | Semantic, judgment-based, **advisory** |

The deterministic audit stays the authoritative gate for marker presence and slug validity; the conformance audit adds the semantic layer the deterministic one is deliberately not built to provide. It reads the deterministic audit's *outputs* (the `Code` column, the Code Map) but never modifies them, never re-implements marker scanning, and never changes the coverage gate's verdict.

### Advisory, never gating (`FR-conformance-advisory`)

`/pdeq-conform` is invoked on demand by a human or an agent; it produces a report and exits. It is **not** referenced by `hooks/pre-commit`, `hooks/commit-msg`, or any other gate — there is no hook step to add and none is added. Committing in a repository where the audit *would* report findings completes normally, because nothing in the commit path invokes the audit (`AC-conformance-non-blocking`). This is the identical posture the product spec draws from the Lane Reviewer: a judgment-based check with occasional false positives must never block a merge. Acting on a finding is always a human or agent decision.

## Component Architecture

Responsibility is split so the *contract* lives in one place and the *workflow* references it, avoiding the two drifting apart.

### New files

| Path | Kind | Purpose |
|---|---|---|
| `pdeq-rules/commands/pdeq-conform.md` | Markdown command prompt | Implements `/pdeq-conform <platform> [feature]`. Encodes phases 0–4. References the Conformance Reviewer role for verdict definitions and report shape rather than restating them. Carries a title line `# Platform Conformance Audit: $ARGUMENTS` and an `<!-- Implements: … -->` marker. |

### Modified files

| Path | Change |
|---|---|
| `AGENTS.md` (root) | New **Conformance Reviewer** subsection under §"Quality Subagents", after the Lane Reviewer. Defines the four-quadrant model, the three verdict definitions, the undocumented-behavior sweep, the evidence/action/confidence requirements, and the advisory contract. The existing "three quality-checking roles" framing in that section is updated to four. |
| `index.md` | New rows for this spec's `FR-`/`NFR-`/`AC-` slugs (handled by the coordinator, per the task split — not by this spec). |
| `glossary.md` | Terms *Conformance audit*, *Four-quadrant conformance*, *Undocumented behavior (reverse traceability)* (handled by the coordinator). |
| `scripts/init.sh` | **No change.** Harness materialization already discovers new files under `pdeq-rules/commands/`. Listed here only to record that it was considered and needs nothing. |
| `hooks/pre-commit` | **No change, deliberately.** The audit is advisory; wiring it into the hook would violate `FR-conformance-advisory`. |

### Harness materialization confirmation

`.claude/commands/pdeq-conform.md` is produced by `init.sh`'s existing per-harness copy step when `claude` is in `harnesses`; Codex/Pi read `pdeq-rules/commands/pdeq-conform.md` in place. Because the command participates in the same materialization path as every existing `pdeq-*` command, no installer edit is required — the file's existence is the whole integration.

## Report Format / Interface Design

The command's output is the report; there is no other interface (no exit-code contract, no machine-readable stream, no written file in v1 — see §Open-question resolutions). The layout is fixed so the report is skimmable by a human and parseable by a later script.

### Per-platform summary (`FR-conformance-summary`, `AC-conformance-report-shape`)

The report opens with a one-line header naming the platform and (if narrowed) the feature, followed by a count table — conformance-at-a-glance before any detail:

```
# Conformance Report — platform: cli  (feature: conformance)

| Quadrant              | Count |
|-----------------------|-------|
| Fulfilled             | 11    |
| Unfulfilled           | 2     |
| Incorrectly fulfilled | 1     |
| Undocumented          | 3     |
| Requirements in scope | 14    |   ← fulfilled + unfulfilled + incorrect, the exhaustive denominator
```

`Requirements in scope` equals the sum of the three requirement verdicts and is asserted to equal the count of `FR-` (plus in-scope `NFR-`/`AC-`) slugs enumerated in Phase 1 — the exhaustiveness invariant behind `AC-conformance-exhaustive`. `Undocumented` is counted separately because it is a property of code, not of the requirement set.

### The four sections

After the summary, four sections in fixed order. Each is either populated with a findings table or explicitly rendered empty (e.g. `_No incorrectly-fulfilled requirements found._`) — never omitted, so the report shape is stable (`AC-conformance-report-shape`).

**Requirement-verdict sections** — *Fulfilled*, *Unfulfilled*, *Incorrectly Fulfilled*. One row per requirement:

| Slug | Code location(s) | Verdict rationale / divergence | Recommended action | Confidence |
|---|---|---|---|---|
| `FR-conformance-seeded` | `pdeq-rules/commands/pdeq-conform.md:40` | Phase 1 reads Code Map + index as specified. | — (fulfilled) | high |
| `FR-conformance-incorrect` | `scripts/x.sh:88` | Threshold compares `>` where spec says `>=`; off-by-one at the boundary. | Fix comparison to `>=`. | high |

- **Slug** — the requirement under verdict. Fulfilled rows may set *Recommended action* to `—`; every non-fulfilled row must state one (`FR-conformance-actionable`).
- **Code location(s)** — at least one concrete `file:line` (`FR-conformance-evidence`, `NFR-conformance-verifiable`, `AC-conformance-evidence-cited`). Multiple locations separated by `; `. An unfulfilled requirement with no realizing code cites the location the Code Map *claims* (to show the marker-vs-behavior gap) or `— (no realizing code found)`.
- **Verdict rationale / divergence** — the behavior judged, stated against the specific requirement so a reader can confirm or refute without re-deriving.
- **Confidence** — see §Confidence marking.

**Undocumented section** (`FR-conformance-undocumented`, `AC-conformance-undocumented-detected`). One row per undocumented behavior; the Slug column is `—` because by definition none owns it:

| Slug | Code location(s) | Behavior observed | Recommended action | Confidence |
|---|---|---|---|---|
| — | `scripts/y.sh:120-140` | Retries network calls 3× with backoff — product-relevant, no requirement describes it. | Specify as a requirement or remove. | medium |

Recommended actions here are the reverse-traceability choices: *specify it* or *remove dead behavior* (`FR-conformance-actionable`).

### Confidence marking (`NFR-conformance-uncertainty`, `AC-conformance-uncertainty-marked`)

Every finding carries a per-finding confidence marker in a dedicated column — `high` / `medium` / `low`. A `low` (and often `medium`) finding is a marked suspicion the reader should verify, not a firm assertion; `high` is a confident verdict. This is the concrete resolution of the product spec's open "confidence presentation" question: a **per-finding column**, chosen over a separate low-confidence section so confidence travels with its evidence and the four-quadrant structure stays intact. The reviewer role instructs the agent to reserve `high` for verdicts it can point to unambiguous code for, and to down-rank anything resting on inference about intent.

## Open-Question Resolutions

The product spec leaves four questions open; engineering settles them for v1 as follows.

**(a) Requirement types in scope.** v1 scopes the three requirement verdicts to **`FR-` slugs**, which name behavior judgable from source. `NFR-` and `AC-` are handled **best-effort**: the reviewer may render a verdict when the source plainly bears on them (e.g. an `NFR-` latency budget contradicted by an obvious synchronous blocking call, or an `AC-` whose observable outcome is visible in code), and otherwise notes them as *not assessed from source* rather than forcing a verdict. This keeps `FR-conformance-single-verdict`/`AC-conformance-exhaustive` a firm guarantee over the `FR-` set — the exhaustiveness invariant is asserted over `FR-` — while not pretending to judge properties (throughput, thresholds under load) that need execution to verify.

**(b) Depth vs. cost.** Default is a **whole-platform read**: all of the platform's requirements against its full source tree. The optional `[feature]` argument narrows scope to a single feature (`FR-conformance-requirement-scope`) — it filters both the requirement set (to that `product/<feature>.md`'s slugs) and the code read (to the Code-Map/index locations for those slugs plus their neighborhood), so a reviewer can focus and keep the pass fast. A changed-files-only mode is explicitly **deferred** (noted as a possible follow-up in the product spec); v1 offers whole-platform and per-feature only.

**(c) Persistence of findings.** Findings are **ephemeral in v1** — produced fresh each run, never recorded. There is no accepted-divergence list and no `pdeq.json` state. A future mirror of `laneAudit.exclude` (an "accepted-divergence" array letting a project silence a known, deliberate divergence) is the natural extension if demand appears, but it is out of scope here; recording it would add persisted state the advisory posture does not need yet.

**(d) Confidence presentation.** Resolved as a **per-finding confidence column** (see §Confidence marking) rather than a separate section or a global label.

## Error Handling

The command is a prose workflow, so "errors" are decision points the prompt handles, not exit codes.

| Condition | Handling |
|---|---|
| `<platform>` missing | Stop; print usage and the valid `platforms` from `pdeq.json`. |
| `<platform>` not in `pdeq.json:platforms` | Hard stop naming the unknown platform and listing valid ones — never audit a different tree (`AC-conformance-platform-isolation`). |
| `[feature]` names no `product/<feature>.md` | Stop; list available feature specs for the platform. |
| A Code Map row or index `Code` entry points at a missing file | Do not fail. Record it as evidence *toward* an `unfulfilled` or `incorrectly fulfilled` verdict (the mapping claims code that is not there) and continue. |
| No product specs for the platform | Report an empty-but-well-formed report (all four sections explicitly empty, summary all zeros) rather than erroring — keeps `AC-conformance-report-shape` total. |
| Uncertain judgment | Never resolved by erroring — emitted as a `low`/`medium` confidence finding (`NFR-conformance-uncertainty`). |

Crucially, **no condition blocks a commit or any other action** — the audit has no gate to fail (`FR-conformance-advisory`, `AC-conformance-non-blocking`).

## Performance Considerations

There is no runtime budget contract as with `audit-traceability.sh` (the 2s pre-commit target) because this audit is never on the commit path. Cost is agent read time, and the two levers that govern it are the scope controls in Open-question (b): the `[feature]` narrowing bounds both the requirement set and the code read, and the SEED phase's use of the existing Code Map / index mapping (`FR-conformance-seeded`) avoids a blind full-tree rediscovery — the reviewer reads *cited* locations first and widens only as needed. Whole-platform runs on a large codebase are expected to be the expensive case; per-feature is the fast path a reviewer reaches for during focused review.

## Security Considerations

Minimal. The reviewer reads source and specs; it writes nothing in v1 (findings are ephemeral, per Open-question (c)). The `<platform>` and `[feature]` arguments are validated against `pdeq.json` before any path is resolved, so they cannot direct the read outside the configured trees. There is no command execution of the audited code — the review is by reading, not running.

## Implementation Plan

Ordered so the contract is defined before the workflow that references it.

1. **Add the Conformance Reviewer role to root `AGENTS.md`.** Rationale: the command references this contract, so it must exist first. Defines the four-quadrant model, verdict definitions, evidence/action/confidence requirements, and the advisory boundary. Update the §"Quality Subagents" intro from three roles to four. Realizes the definitional half of `FR-conformance-four-quadrant`, `FR-conformance-fulfilled`, `FR-conformance-unfulfilled`, `FR-conformance-incorrect`, `FR-conformance-undocumented`, `FR-conformance-single-verdict`, `FR-conformance-evidence`, `FR-conformance-actionable`, `FR-conformance-summary`, `FR-conformance-advisory`, `FR-conformance-complements`.
2. **Author `pdeq-rules/commands/pdeq-conform.md`.** Rationale: the invocable driver; encodes phases 0–4, the scope resolution, and the report layout, referencing the role from step 1. Realizes the invocation/workflow half of `FR-conformance-per-platform`, `FR-conformance-requirement-scope`, `FR-conformance-seeded`, and the report-emitting FRs.
3. **Verify harness materialization.** Rationale: confirm `init.sh` picks up the new command with no installer edit — run it and check `.claude/commands/pdeq-conform.md` appears. No code change expected; this is a confirmation step, not a build step.
4. **Update `glossary.md` and `index.md`** (coordinator-owned per the task split) so the new terms and slugs are registered.
5. **QA writes the conformance test plan** (`qa/cli/conformance.md`) with fixtures exercising `AC-conformance-incorrect-detected`, `AC-conformance-undocumented-detected`, `AC-conformance-unfulfilled-behavioral`, `AC-conformance-no-plumbing`, `AC-conformance-non-blocking`, and `AC-conformance-platform-isolation` against a seeded fixture repo.

Open technical questions (resolve in review or during authoring):

- **Best-effort NFR/AC verdicts** — whether to render them inline in the three verdict sections (flagged `best-effort`) or in a distinct appendix. Leaning inline with a confidence down-rank; revisit if it muddies the exhaustiveness count.
- **Undocumented-behavior granularity** — how coarse a "behavior" is (a function? a branch? a file?). Left to reviewer judgment in v1; tighten in the role definition if reports come back noisy.

## Precision — signal over noise (`NFR-conformance-precision`)

The undocumented sweep is where false positives are most likely, so the reviewer role explicitly **excludes** incidental plumbing from *undocumented* findings (`AC-conformance-no-plumbing`): framework scaffolding, generated files, configuration, build glue, and test-support code are not product-relevant behavior and are never reported as undocumented. Only product-relevant behavior — logic a requirement *could* meaningfully describe — is eligible. This mirrors the precision discipline the deterministic audits apply via their exclusion lists, but here it is a reasoning instruction to the reviewer rather than a glob filter, because "product-relevant" is a judgment no glob can make. The same signal-over-noise instruction tells the reviewer to distinguish genuine divergence from acceptable variation across all four quadrants.

## Requirements Coverage

Every slug defined in `product/conformance.md`, mapped to the section that addresses it and the QA test case(s) that verify it. FRs also appear in §Code Map with their realization locus.

| Slug | Engineering section | Verified by QA |
|---|---|---|
| FR-conformance-four-quadrant | §Workflow (Phase 3), §Report Format | TC-conformance-report-shape |
| FR-conformance-fulfilled | §Workflow (Phase 3) | TC-conformance-fulfilled-genuine |
| FR-conformance-unfulfilled | §Workflow (Phase 3) | TC-conformance-unfulfilled-behavioral |
| FR-conformance-incorrect | §Workflow (Phase 3) | TC-conformance-incorrect-detected |
| FR-conformance-undocumented | §Workflow (Phase 3), §Precision | TC-conformance-undocumented-detected |
| FR-conformance-single-verdict | §Workflow (Phase 1, Phase 3), §Report Format (summary invariant) | TC-conformance-exhaustive |
| FR-conformance-evidence | §Report Format (findings tables) | TC-conformance-evidence-cited |
| FR-conformance-actionable | §Report Format (findings tables) | TC-conformance-actionable |
| FR-conformance-summary | §Report Format (per-platform summary) | TC-conformance-report-shape |
| FR-conformance-per-platform | §Workflow (Phase 0), §Component Architecture | TC-conformance-platform-isolation |
| FR-conformance-requirement-scope | §Workflow (Phase 1), §Open-question (b) | TC-conformance-scope-single-feature |
| FR-conformance-seeded | §Workflow (Phase 1) | TC-conformance-seeded |
| FR-conformance-advisory | §Advisory never gating, §Error Handling | TC-conformance-non-blocking |
| FR-conformance-complements | §Relationship to the deterministic audit | TC-conformance-complements-deterministic |
| NFR-conformance-verifiable | §Workflow (Phase 2), §Report Format | TC-conformance-evidence-cited |
| NFR-conformance-precision | §Precision | TC-conformance-no-plumbing |
| NFR-conformance-uncertainty | §Confidence marking | TC-conformance-uncertainty-marked |
| AC-conformance-report-shape | §Report Format | TC-conformance-report-shape |
| AC-conformance-incorrect-detected | §Workflow (Phase 3) | TC-conformance-incorrect-detected |
| AC-conformance-undocumented-detected | §Workflow (Phase 3), §Precision | TC-conformance-undocumented-detected |
| AC-conformance-unfulfilled-behavioral | §Workflow (Phase 3) | TC-conformance-unfulfilled-behavioral |
| AC-conformance-exhaustive | §Report Format (summary invariant) | TC-conformance-exhaustive |
| AC-conformance-evidence-cited | §Report Format (findings tables) | TC-conformance-evidence-cited |
| AC-conformance-non-blocking | §Advisory never gating | TC-conformance-non-blocking |
| AC-conformance-platform-isolation | §Workflow (Phase 0), §Error Handling | TC-conformance-platform-isolation |
| AC-conformance-no-plumbing | §Precision | TC-conformance-no-plumbing |
| AC-conformance-uncertainty-marked | §Confidence marking | TC-conformance-uncertainty-marked |

The `TC-` slugs above are placeholders — the QA spec (`qa/cli/conformance.md`) owns their authoritative definitions.

## Code Map

Authoritative code locations for every FR defined in `product/conformance.md`. Both realizing artifacts are Markdown, so their inline markers use the `<!-- Implements: <slug> -->` form. All rows are `implemented` as of the 0.9.0 implementation — the authoritative markers live in `pdeq-rules/commands/pdeq-conform.md`, with the definitional FRs additionally marked in the root `AGENTS.md` Conformance Reviewer section.

| Slug | Planned location | Status |
|---|---|---|
| FR-conformance-four-quadrant | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-fulfilled | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-unfulfilled | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-incorrect | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-undocumented | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-single-verdict | pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-evidence | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-actionable | AGENTS.md; pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-summary | pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-per-platform | pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-requirement-scope | pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-seeded | pdeq-rules/commands/pdeq-conform.md | implemented |
| FR-conformance-advisory | AGENTS.md | implemented |
| FR-conformance-complements | AGENTS.md | implemented |

NFRs (verifiable findings, precision, uncertainty marking) are cross-cutting properties of the review contract rather than one-line realizations — not listed in the Code Map. They are verified via QA (see `../../qa/cli/conformance.md`).
