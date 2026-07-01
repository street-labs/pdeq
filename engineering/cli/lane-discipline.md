---
product-hash: 67efc78b11e1b6bce569905fcbb511645f8bdc127e3476593ed64a1e43c44a08
product-slugs: [AC-lane-discipline-backstop-exit-status, AC-lane-discipline-backstop-nonblocking, AC-lane-discipline-default-catches-known, AC-lane-discipline-no-config-no-break, AC-lane-discipline-project-terms-applied, AC-lane-discipline-review-allows-legit, AC-lane-discipline-review-flags-structural, AC-lane-discipline-review-output-shape, AC-lane-discipline-review-suggests-terms, AC-lane-discipline-update-review-no-edit, AC-lane-discipline-update-seed-idempotent, FR-lane-discipline-backstop-at-commit, FR-lane-discipline-default-terms, FR-lane-discipline-lexical-backstop, FR-lane-discipline-project-terms, FR-lane-discipline-review-in-workflow, FR-lane-discipline-severity, FR-lane-discipline-structural-review, FR-lane-discipline-structured-output, FR-lane-discipline-taxonomy, FR-lane-discipline-term-suggestions, FR-lane-discipline-two-layer, FR-lane-discipline-update-reviews-specs, FR-lane-discipline-update-seeds-config, NFR-lane-discipline-advisory-review, NFR-lane-discipline-backcompat, NFR-lane-discipline-deterministic-backstop, NFR-lane-discipline-nonblocking-backstop]
---
# Lane Discipline Enforcement — CLI Technical Spec

> Based on requirements in `../../product/lane-discipline.md`
> (No design spec — feature has no UI surface. Design lane is explicitly N/A.)

## What We're Building

Two loosely-coupled pieces realize the two-layer model:

1. **Layer 1 — the deterministic backstop.** An extension of the existing `scripts/audit-lanes.sh`. Its four hardcoded term greps stay, but the technology-name check is fed by the *union* of a built-in default alternation and a project-supplied term list read from `pdeq.json`. No LLM, no network, same result on the same input — it remains a plain-shell audit runnable in CI and at commit time. It is additionally wired into the pre-commit pipeline as a **warn-only** step so obvious leaks surface on every commit without ever blocking one.

2. **Layer 2 — the prompt-guided lane review.** A documented review *contract* — a taxonomy, a severity vocabulary, and an output-table schema — added to the kickoff Step 4 quality batch and to the standalone Lane Reviewer role in the root `AGENTS.md`. It is executed by whichever agent runs the workflow, is non-deterministic, and never runs in the commit-time gate.

The two are deliberately independent. Layer 1 is a lexical net that a project tunes with its own vocabulary; Layer 2 reasons about structure and context and can flag bleed carrying no listed word. Neither is authoritative over the other — a clean Layer 1 run does not imply an in-lane spec, and that is stated in the docs so no one mistakes the grep for the principle.

## Technical Approach

### Layer 1 — project-tunable term list in `audit-lanes.sh`

**Config read.** Add a `read_lane_terms()` function modeled exactly on `read_exclude_patterns()` in `scripts/audit-traceability.sh` (lines 116–129): an inline `python3` invocation that loads `pdeq.json` and prints the terms, tolerant of a missing file or missing keys (prints nothing, never errors). **No `jq` dependency** — this matches the established repo convention; every other script that reads `pdeq.json` uses inline `python3` or `grep`. Honor a `PDEQ_CONFIG_PATH` override (default `$ROOT/pdeq.json`) so QA fixtures can point the audit at a fixture config, mirroring `audit-traceability.sh`.

**Config shape.** The function reads the `laneAudit` object and unions its four arrays:

```json
"laneAudit": {
  "vendors":   ["Square", "Toast"],
  "protocols": ["OAuth", "PKCE"],
  "platforms": ["CLI", "BFF"],
  "libraries": ["Vapor", "argument-parser"]
}
```

All four categories are merged into a single set of extra terms. The category split exists for **self-documentation in `pdeq.json`** (a maintainer reading the config sees why each term is listed) and to mirror the Layer-2 taxonomy; the script itself does not need per-category behavior — a term is a term to grep.

**Merge, don't replace.** The built-in `tech_terms` alternation stays as the **default**. Project terms are appended to it:

```
tech_terms="React|TypeScript|…|markdown-it"          # built-in default (unchanged)
extra=$(read_lane_terms)                               # e.g. Square|Toast|OAuth|PKCE|CLI|BFF|Vapor|argument-parser
if [ -n "$extra" ]; then tech_terms="$tech_terms|$extra"; fi
```

This guarantees `NFR-lane-discipline-backcompat` and `FR-lane-discipline-default-terms`: a project that configures nothing gets exactly today's behavior; a project that configures vendors *adds* to the shipped guard, never silences it.

**Literal-term safety.** Terms from config are treated as literal alternatives. `read_lane_terms()` regex-escapes each term (via `re.escape`) before joining with `|`, so a vendor name containing a `.` or `+` (e.g. `Prism.js`) matches literally rather than as a pattern. Terms are matched with a word-boundary scan (`\b($tech_terms)\b`).

**Scanning engine — `python3 re`, not `grep -P`.** The four term scans run through a small `pcre_scan()` shell helper that shells out to `python3 -c` with the `re` module, printing `<lineno>:<line>` for each matching line. This replaces the previous `grep -nP` calls. Rationale: `grep -P` (PCRE) is **not portable** — macOS ships BSD grep, which rejects `-P` outright (`invalid option -- P`). The old `grep -nP … 2>/dev/null || true` swallowed that error and made the audit silently no-op on macOS, where the pre-commit hook actually runs. `python3` is already a hard dependency of the pdeq audit scripts, so routing the scan through `re` makes the backstop deterministic and identical across macOS/Linux (`NFR-lane-discipline-deterministic-backstop`) with no new dependency. The patterns themselves are unchanged (`\b`, `\s`, `[0-9]+` are all `re`-compatible); only the matcher changes. Case-insensitive scans pass an `i` flag through to `re.I`.

**Expected false positives are acceptable.** Platform terms like `CLI` will match legitimately in a `cli`-platform project's specs. That is fine and intended: Layer 1 is a crude net, which is exactly why its commit-time incarnation is warn-only (`NFR-lane-discipline-nonblocking-backstop`) and why Layer 2 exists to adjudicate context.

**Markers.** Each realizing block carries a `# Implements: <slug>` marker (shell syntax). `read_lane_terms()` → `FR-lane-discipline-project-terms`; the merged default alternation → `FR-lane-discipline-default-terms`; the overall scan → `FR-lane-discipline-lexical-backstop`.

### Layer 1 — pre-commit wiring (warn-only)

Add an `-x`-guarded step to `hooks/pre-commit`, after the traceability audit and before/around the decision merge, that runs the backstop but never aborts the commit:

```sh
# Lane-discipline lexical backstop — warn-only, never blocks (NFR-lane-discipline-nonblocking-backstop).
if [ -x "$REPO/scripts/audit-lanes.sh" ]; then
  "$REPO/scripts/audit-lanes.sh" || true
fi
```

The `|| true` makes the step advisory: `audit-lanes.sh` keeps its standalone `exit 1` on violations (so on-demand and CI runs still signal failure per `AC-lane-discipline-backstop-exit-status`), but the hook swallows that non-zero so the commit proceeds (`AC-lane-discipline-backstop-nonblocking`). A missing script skips cleanly, matching the pipeline's partial-install tolerance. Realizes `FR-lane-discipline-backstop-at-commit`.

Note on the `set -e` hook: because the hook runs under `set -e`, the `|| true` is required — without it a non-zero `audit-lanes.sh` would abort the commit. This is the crux of warn-only behavior and is covered by an explicit QA case.

### Layer 2 — the review contract

The review is defined once and referenced from two host workflows. The canonical definition lives in the root `AGENTS.md` §"Quality Subagents" as a new **Lane Reviewer** role; the kickoff prompt's Step 4 references it as pass #7. The contract has three parts.

**Taxonomy (categories with examples, not a closed list)** — realizes `FR-lane-discipline-taxonomy`:

| Category | Examples |
|---|---|
| Vendor names | Square, Toast, Stripe, Auth0 |
| Protocol / algorithm names | OAuth, PKCE, JWT, CSRF, REST, gRPC, idempotency key |
| Host / platform as product | CLI, BFF, iOS, Android, web, server — when treated *as the product* rather than one manifestation |
| Library / framework names | Vapor, React, argument-parser, SwiftUI |
| Concrete surfaces | command names, flag names, exit codes, env var names, file paths, ports, redirect URIs |
| Implementation mechanisms | keychain / secret store, file permissions, background polling, thread/queue, cache |
| Testing terms | unit, E2E, XCTest, mock, stub |

The review is instructed to treat these as *starting categories* and to generalize — flag a vendor or protocol even if it is not in any example — because the point is the principle, not the list.

**Severity vocabulary** — realizes `FR-lane-discipline-severity`. Each finding gets exactly one:

- `violation` — the text prescribes implementation/platform detail as a requirement; must be reworded.
- `allowed: overview context` — a host/tech named in prose overview for orientation, not as a requirement.
- `allowed: per-host NFR constraint` — a non-functional requirement that legitimately states a constraint scoped to a specific host/platform.

The vocabulary is extensible; new `allowed: <reason>` variants may be added in this spec if usage demands. The structural-bleed reasoning (flagging a protocol-shaped requirement, or a host-as-product framing, even absent any listed word) realizes `FR-lane-discipline-structural-review`.

**Output schema** — realizes `FR-lane-discipline-structured-output`. A Markdown table, one row per finding:

| File | Line | Flagged text | Category | Severity | Suggested rewording |
|---|---|---|---|---|---|

Empty table ⇒ no findings. The table is greppable/parseable so a human or a later script can act on it.

**Term-list suggestions** — realizes `FR-lane-discipline-term-suggestions`. After the table, when the review found a lexical leak (a concrete vendor/protocol/library word) that the backstop's current `laneAudit` terms would miss, it appends a short suggested-additions block naming the category and term(s) to add to `pdeq.json`, e.g. `laneAudit.protocols += ["OAuth"]`. This lets the deterministic net improve without manual curation.

**Where it runs** — realizes `FR-lane-discipline-review-in-workflow` and, jointly with the backstop, `FR-lane-discipline-two-layer`. Two hosts:
- `pdeq-rules/commands/pdeq-kickoff.md` Step 4, as pass #7 "Lane review", alongside the reviewer and consistency passes. The mirror copy `.claude/commands/pdeq-kickoff.md` is kept byte-identical.
- Root `AGENTS.md` §"Quality Subagents" as the standalone **Lane Reviewer** role.

### Config schema

`pdeq.schema.json` gains a `laneAudit` object property (`additionalProperties: false`) with four `array`-of-`string` properties — `vendors`, `protocols`, `platforms`, `libraries` — each documented as *extending* the built-in defaults. A `laneAudit` example is added to the top-level `examples` block. Realizes, jointly with `read_lane_terms()`, `FR-lane-discipline-project-terms`.

### Update propagation — migration 0.5.0

Lane discipline ships in pdeq 0.5.0. Because `laneAudit` is optional and the defaults preserve prior behavior, the change is **non-breaking** for consumers (they stay conformant without acting). But the pdeq-repo commit-msg gate treats any MINOR bump as breaking and therefore requires a matching `migrations/0.5.0.md` to be present — and that migration is also the vehicle for the two propagation requirements.

- **Mechanical — seed the scaffold** (`FR-lane-discipline-update-seeds-config`). One idempotent `shell` block that adds an empty `laneAudit` object (all four category arrays empty) to the consumer's `pdeq.json` **only if** no `laneAudit` key is already present (grep-guarded). It never overwrites or reorders an existing `laneAudit`, satisfying `AC-lane-discipline-update-seed-idempotent`. `pdeq.json` is inside `scope: default`, so the post-run scope audit passes. Uses inline `python3` for the JSON edit (no `jq`), preserving the file's existing formatting where practical.
- **Semantic — report-only review** (`FR-lane-discipline-update-reviews-specs`). `### Files` is `product/**/*.md`; `### Prompt` runs the Lane Reviewer contract but instructs the agent to **make no edits** — emit the findings table and suggested `laneAudit` additions only. The runner's semantic summary line is `reviewed <M> files, updated <N>`; a report-only pass reports `updated 0`, which is exactly the idempotent, no-edit outcome `AC-lane-discipline-update-review-no-edit` requires. Because no spec file changes, the scope audit is trivially satisfied and re-running the migration is a clean no-op.

The migration's front-matter is `breaking: false` (consumers stay conformant without it) with `scope: default`. It carries an `<!-- Implements: -->` marker citing both propagation FRs plus `FR-migrations-idempotent` / `FR-migrations-author-written`, which is how those two FRs get their scanned coverage (the Code Map rows above point at `migrations/0.5.0.md`).

## Determinism & Precision Notes

- **Layer 1 is deterministic** (`NFR-lane-discipline-deterministic-backstop`): given the same product specs and the same `pdeq.json`, output is identical. `read_lane_terms()` sorts nothing — order in the alternation does not affect which lines match — but to keep report ordering stable it preserves config order and relies on the existing per-file line ordering of `grep -n`.
- **Layer 2 is advisory** (`NFR-lane-discipline-advisory-review`): never invoked by `hooks/pre-commit`; only by agent-run workflows. This is a documentation-enforced boundary, not a code path.
- **Crude by design:** Layer 1 cannot see structure and will both miss structural bleed and over-flag legitimate platform mentions. Both limitations are intended and are the reason Layer 2 exists and Layer 1 is warn-only at commit time.

## Code Map

Authoritative planned code locations for every FR defined in `product/lane-discipline.md`. Updated as implementation proceeds.

| Slug | Planned location | Status |
|---|---|---|
| FR-lane-discipline-two-layer | pdeq-rules/commands/pdeq-kickoff.md | implemented |
| FR-lane-discipline-lexical-backstop | scripts/audit-lanes.sh | implemented |
| FR-lane-discipline-project-terms | scripts/audit-lanes.sh:read_lane_terms | implemented |
| FR-lane-discipline-default-terms | scripts/audit-lanes.sh | implemented |
| FR-lane-discipline-structural-review | AGENTS.md | implemented |
| FR-lane-discipline-taxonomy | AGENTS.md | implemented |
| FR-lane-discipline-severity | AGENTS.md | implemented |
| FR-lane-discipline-structured-output | AGENTS.md | implemented |
| FR-lane-discipline-term-suggestions | AGENTS.md | implemented |
| FR-lane-discipline-review-in-workflow | pdeq-rules/commands/pdeq-kickoff.md | implemented |
| FR-lane-discipline-backstop-at-commit | hooks/pre-commit | planned |
| FR-lane-discipline-update-seeds-config | migrations/0.5.0.md | implemented |
| FR-lane-discipline-update-reviews-specs | migrations/0.5.0.md | implemented |

Layer-2 rows point at Markdown prompt/agent files; their inline markers use the `<!-- Implements: <slug> -->` form. Layer-1 rows point at shell and use `# Implements: <slug>`.

**Note on `FR-lane-discipline-backstop-at-commit`.** Its only realization is the warn-only step added to `hooks/pre-commit`, which carries a `# Implements:` marker. But the traceability marker scan is extension-indexed and skips extensionless files, so the hook marker is not machine-detected — the same reason the pre-existing `FR-code-mapping-audit-scan` hook marker is absent from the index Code column. The row is therefore kept `planned` (marking it `implemented` would fail phase-7 validation, which requires a *scanned* marker). Coverage is verified by QA `TC-lane-discipline-hook-warn-only` instead. The decorative hook marker is retained to document intent.
