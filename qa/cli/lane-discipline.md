---
product-hash: 67efc78b11e1b6bce569905fcbb511645f8bdc127e3476593ed64a1e43c44a08
product-slugs: [AC-lane-discipline-backstop-exit-status, AC-lane-discipline-backstop-nonblocking, AC-lane-discipline-default-catches-known, AC-lane-discipline-no-config-no-break, AC-lane-discipline-project-terms-applied, AC-lane-discipline-review-allows-legit, AC-lane-discipline-review-flags-structural, AC-lane-discipline-review-output-shape, AC-lane-discipline-review-suggests-terms, AC-lane-discipline-update-review-no-edit, AC-lane-discipline-update-seed-idempotent, FR-lane-discipline-backstop-at-commit, FR-lane-discipline-default-terms, FR-lane-discipline-lexical-backstop, FR-lane-discipline-project-terms, FR-lane-discipline-review-in-workflow, FR-lane-discipline-severity, FR-lane-discipline-structural-review, FR-lane-discipline-structured-output, FR-lane-discipline-taxonomy, FR-lane-discipline-term-suggestions, FR-lane-discipline-two-layer, FR-lane-discipline-update-reviews-specs, FR-lane-discipline-update-seeds-config, NFR-lane-discipline-advisory-review, NFR-lane-discipline-backcompat, NFR-lane-discipline-deterministic-backstop, NFR-lane-discipline-nonblocking-backstop]
---
# Lane Discipline Enforcement — CLI Test Plan

> Based on requirements in `../../product/lane-discipline.md`
> Based on engineering in `../../engineering/cli/lane-discipline.md`
> (No design spec — feature has no UI surface.)

## What We're Testing

Two layers, verified differently:

- **Layer 1 (deterministic backstop)** is fully shell-testable and `[auto]`. Tests exercise `scripts/audit-lanes.sh` against fixture repos: built-in defaults still catch known bleed; project `laneAudit` terms are flagged; a missing / term-less config runs clean; project terms *extend* rather than replace defaults; literal terms are escaped; exit status is 1 on findings standalone but the pre-commit hook demotes it to warn-only.
- **Layer 2 (prompt-guided review)** is agent-run and non-deterministic, so its cases are `[manual]` / semi-auto: an agent runs the Lane Reviewer contract against a seeded fixture and a human confirms the structured output flagged the structural bleed, allowed the legitimate mentions, and suggested term additions. The coffee-shop auth fixture is the anchor regression: Layer 2 must catch what Layer 1's defaults miss.

## Test Strategy

### Tooling

- **Layer 1 harness**: POSIX shell test scripts under `engineering/apps/cli/tests/lane-discipline/`, matching the `qa/cli/code-mapping.md` fixture style — `mktemp -d` fixture roots that are `git init`'d (the audit derives its root from `git rev-parse --show-toplevel`), `trap` cleanup, `assert_*` helpers.
- **New assertion helpers**: `assert_lanes_exit <code>`, `assert_lanes_flags <relpath:lineno>` (asserts a warning line for that location appears), `assert_lanes_clean` (asserts the ✓ no-violations line), `assert_lanes_no_flag <term>` (asserts no warning line contains `<term>`).
- **PCRE availability**: the audit scans via `python3 re` (not `grep -P`), so tests require only `python3` — no GNU-grep dependency, and they pass identically on macOS and Linux. A test asserts the audit does **not** silently no-op when only BSD grep is present.
- **Layer 2 harness**: manual/semi-auto. The reviewer prompt (root `AGENTS.md` §Quality Subagents → Lane Reviewer) is run by an agent against a fixture product spec; the produced table is checked by hand (or by a lightweight table-shape assertion) against the expected findings recorded below.

### Env overrides used

- `PDEQ_CONFIG_PATH` — points the audit at the fixture's `pdeq.json` (default `<root>/pdeq.json`).

### Automation split

Layer 1 cases are `[auto]`. Layer 2 cases are `[manual]` (agent-run + human confirmation). The split is intrinsic: a deterministic grep is scriptable; structural judgement is not.

---

## Fixture Catalogue

| Template | Purpose | Contents |
|---|---|---|
| `defaults-only/` | Built-in defaults still fire; project terms absent. | `pdeq.json` with no `laneAudit`; `product/x.md` naming `React` and `240px` on separate lines. |
| `project-terms/` | Project vocabulary flagged. | `pdeq.json` with `laneAudit.vendors:["Square"]`, `laneAudit.protocols:["OAuth"]`; `product/x.md` naming `Square` and `OAuth` on lines with **no** default term. |
| `no-config/` | Safety when config absent. | No `pdeq.json` at all; `product/x.md` naming `React`. |
| `extend-not-replace/` | Project terms add to, don't shadow, defaults. | `pdeq.json` with `laneAudit.vendors:["Square"]`; `product/x.md` naming both `React` (default) and `Square` (project) on separate lines. |
| `literal-escape/` | Config terms are literal, not regex. | `laneAudit.libraries:["Prism.js"]`; `product/x.md` containing `PrismXjs` (must NOT match). |
| `coffee-auth-bleed/` | **Layer 2 regression.** Product spec with vendor/protocol/host bleed. | `product/auth.md` seeded with Square, OAuth, "authorization code exchange", "coffee auth login", "exits non-zero", "subsequent CLI invocations", plus one legitimate overview host mention and one per-host NFR. `pdeq.json` with **no** `laneAudit` (so Layer 1 defaults miss it). |

---

## Coverage Matrix

| AC | Test case(s) | Layer | Auto/Manual | Status |
|---|---|---|---|---|
| AC-lane-discipline-default-catches-known | TC-lane-discipline-defaults-fire | 1 | auto | Not started |
| AC-lane-discipline-project-terms-applied | TC-lane-discipline-project-terms-fire | 1 | auto | Not started |
| AC-lane-discipline-no-config-no-break | TC-lane-discipline-no-config-clean | 1 | auto | Not started |
| AC-lane-discipline-backstop-nonblocking | TC-lane-discipline-hook-warn-only | 1 | auto | Not started |
| AC-lane-discipline-backstop-exit-status | TC-lane-discipline-standalone-exit1 | 1 | auto | Not started |
| AC-lane-discipline-review-flags-structural | TC-lane-discipline-review-structural | 2 | manual | Not started |
| AC-lane-discipline-review-allows-legit | TC-lane-discipline-review-allows | 2 | manual | Not started |
| AC-lane-discipline-review-output-shape | TC-lane-discipline-review-table | 2 | manual | Not started |
| AC-lane-discipline-review-suggests-terms | TC-lane-discipline-review-suggests | 2 | manual | Not started |
| AC-lane-discipline-update-seed-idempotent | TC-lane-discipline-update-seed-idempotent | — | auto | Not started |
| AC-lane-discipline-update-review-no-edit | TC-lane-discipline-update-review-no-edit | — | manual | Not started |

Supporting cases (no direct AC, cover FR/NFR behavior): `TC-lane-discipline-extend-not-replace` (FR-lane-discipline-default-terms), `TC-lane-discipline-literal-escape` (FR-lane-discipline-project-terms precision), `TC-lane-discipline-no-pcre-grep` (NFR-lane-discipline-deterministic-backstop), `TC-lane-discipline-slug-not-flagged` (FR-lane-discipline-lexical-backstop precision — slug identifiers are excluded).

---

## Layer 1 Test Cases (auto)

### TC-lane-discipline-defaults-fire
> Covers `AC-lane-discipline-default-catches-known`.
Fixture `defaults-only/`. Run `audit-lanes.sh`.
- **Expect**: exit 1; a warning line for the `React` line and the `240px` line.

### TC-lane-discipline-project-terms-fire
> Covers `AC-lane-discipline-project-terms-applied`.
Fixture `project-terms/` (Square/OAuth on default-free lines). Run `audit-lanes.sh`.
- **Expect**: exit 1; warning lines for both the `Square` line and the `OAuth` line — proving terms not in the defaults are flagged because they are configured.

### TC-lane-discipline-no-config-clean
> Covers `AC-lane-discipline-no-config-no-break`.
Fixture `no-config/` (no `pdeq.json`). Run `audit-lanes.sh`.
- **Expect**: no `python` traceback on stderr; result identical to what the defaults alone produce (the `React` line is flagged; exit 1). A variant with a clean spec exits 0.

### TC-lane-discipline-extend-not-replace
> Covers `FR-lane-discipline-default-terms`.
Fixture `extend-not-replace/`. Run `audit-lanes.sh`.
- **Expect**: BOTH the default term (`React`) and the project term (`Square`) are flagged — configuring `laneAudit` never silences the shipped defaults.

### TC-lane-discipline-literal-escape
> Covers `FR-lane-discipline-project-terms` precision.
Fixture `literal-escape/` (`Prism.js` configured, `PrismXjs` in spec). Run `audit-lanes.sh`.
- **Expect**: no warning for the `PrismXjs` line — the `.` in the configured term is matched literally, not as a wildcard.

### TC-lane-discipline-no-pcre-grep
> Covers `NFR-lane-discipline-deterministic-backstop`.
Run `audit-lanes.sh` in an environment whose `grep` is BSD grep (no `-P`). Fixture `defaults-only/`.
- **Expect**: the audit still flags `React`/`240px` (it scans via `python3 re`, not `grep -P`), proving it does not silently no-op on macOS.

### TC-lane-discipline-standalone-exit1
> Covers `AC-lane-discipline-backstop-exit-status`.
Fixture `defaults-only/`. Run `audit-lanes.sh` directly (not via the hook).
- **Expect**: exit status 1, so CI can gate on it.

### TC-lane-discipline-slug-not-flagged
> Covers `FR-lane-discipline-lexical-backstop` precision (slug identifiers excluded).
Fixture whose product spec has a requirement line carrying a slug that embeds a red-flag term (e.g. `` `FR-ex-browser-thing` ``) with clean prose. A second fixture line has the same slug **and** the term in prose (`opens in a browser`).
- **Expect**: the slug-only line is not flagged (the slug token is stripped before matching); the line with the term in prose IS flagged (stripping is surgical — only the slug token is removed). Proves a project's own slug never self-trips while real prose bleed on the same line still catches.

### TC-lane-discipline-hook-warn-only
> Covers `AC-lane-discipline-backstop-nonblocking`, `FR-lane-discipline-backstop-at-commit`.
Fixture with `hooks/pre-commit` installed and a staged product spec containing default bleed. Attempt a commit.
- **Expect**: the commit **succeeds**; the lane warning is printed; the traceability audit still runs and still blocks on its own failures (verifying the `|| true` is scoped to the lane step only).

---

## Layer 2 Test Cases (manual / semi-auto)

All Layer 2 cases run the Lane Reviewer contract against fixture `coffee-auth-bleed/` and inspect the produced table.

### TC-lane-discipline-review-structural
> Covers `AC-lane-discipline-review-flags-structural`.
- **Expect**: the table flags as `violation` — "authorization code exchange" (protocol/algorithm, no word "OAuth" needed), "coffee auth login" (concrete command surface), "exits non-zero" (exit code), and "subsequent CLI invocations" (host-as-product) — i.e. structural bleed the Layer 1 defaults do not match.

### TC-lane-discipline-review-allows
> Covers `AC-lane-discipline-review-allows-legit`.
- **Expect**: the single overview host mention is severity `allowed: overview context`; the per-host constraint stated in an NFR is `allowed: per-host NFR constraint` — not counted as violations.

### TC-lane-discipline-review-table
> Covers `AC-lane-discipline-review-output-shape`.
- **Expect**: output is a Markdown table with columns File · Line · Flagged text · Category · Severity · Suggested rewording; every row has all six cells; empty ⇒ no findings.

### TC-lane-discipline-review-suggests
> Covers `AC-lane-discipline-review-suggests-terms`.
- **Expect**: because `Square`/`OAuth` appear and are not in this fixture's (absent) `laneAudit`, the reviewer appends a suggested-additions note naming the category and term(s) to add to `pdeq.json` (e.g. `laneAudit.vendors += ["Square"]`, `laneAudit.protocols += ["OAuth"]`).

### Regression assertion (the complementarity proof)
Running Layer 1 (`audit-lanes.sh` with default config) on `coffee-auth-bleed/` flags at most the incidental default-term matches and **misses** the structural bleed above; running Layer 2 flags all of it. This is the concrete evidence that the two layers are complementary, not redundant — recorded in `PDEQ-qfnojetv`.

---

## Update Propagation Test Cases (migration 0.5.0)

### TC-lane-discipline-update-seed-idempotent (auto)
> Covers `AC-lane-discipline-update-seed-idempotent`.
Run the `migrations/0.5.0.md` Mechanical block against three fixture `pdeq.json` files: (a) no `laneAudit` key, (b) an already-populated `laneAudit`, (c) already-seeded empty scaffold. Run it **twice** against each.
- **Expect**: (a) an empty `laneAudit` scaffold is added once; a second run makes no further change. (b) the populated `laneAudit` is left byte-for-byte unchanged. (c) the empty scaffold is left unchanged. No duplication in any case; valid JSON after every run.

### TC-lane-discipline-update-review-no-edit (manual)
> Covers `AC-lane-discipline-update-review-no-edit`.
Run the `migrations/0.5.0.md` Semantic pass over a fixture `product/` tree containing bleed.
- **Expect**: the pass emits the Lane Reviewer findings table and suggested `laneAudit` additions, the runner reports `reviewed <M> files, updated 0`, and every product spec file is byte-for-byte identical before and after (verify with a checksum/`git diff`).

## Open Questions

- Whether to add a lightweight table-shape linter so `TC-lane-discipline-review-table` can be partially `[auto]`. Deferred — the review is intrinsically manual today.
