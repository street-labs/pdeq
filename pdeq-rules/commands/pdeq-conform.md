<!-- Implements: FR-conformance-per-platform, FR-conformance-requirement-scope, FR-conformance-seeded, FR-conformance-four-quadrant, FR-conformance-single-verdict, FR-conformance-summary, FR-conformance-evidence, FR-conformance-actionable, FR-conformance-temporal-specs, FR-conformance-advisory, FR-conformance-complements -->

# Platform Conformance Audit: $ARGUMENTS

Run the **Conformance Reviewer** (root `AGENTS.md` §"Quality Subagents") against one platform: read that platform's source against its specs and report how well the implementation actually conforms to the requirement set. This is **advisory** — it produces a report and exits. It never blocks a commit or any other action, and it never modifies specs, `index.md`, or code.

`$ARGUMENTS` is `<platform> [feature]`:
- `<platform>` — **required**. Which platform to audit (must be one of `pdeq.json` → `platforms`).
- `[feature]` — **optional**. Narrows the audit to a single feature (`product/<feature>.md`) so a reviewer can focus. Omit to audit the whole platform.

Read `product/conformance.md` and `engineering/cli/conformance.md` first if you need the full contract. Then follow the phases below exactly.

---

## Phase 0 — Resolve and validate

<!-- Implements: FR-conformance-per-platform -->

1. Read `pdeq.json`; resolve `specsRoot` and `codeRoot` (default `.` each). Everything below is scoped under those.
2. Parse `$ARGUMENTS` into `<platform>` and optional `[feature]`.
3. **Validate `<platform>` against `pdeq.json` → `platforms`.** If it is missing or unknown, **stop** and print the valid platform list. Never audit a tree the user did not name — this is the first guarantee behind per-platform isolation.
4. If `[feature]` is given, confirm `{specsRoot}/product/<feature>.md` exists. If not, stop and list the available feature specs.

Scope every read below to this platform only: `{specsRoot}/{product,engineering,qa}/…` for its features and `{codeRoot}` entries belonging to this platform. Do not surface another platform's requirements or code.

## Phase 1 — SEED from existing traceability

<!-- Implements: FR-conformance-seeded, FR-conformance-requirement-scope -->

Assemble the grounding set **before reading any code**. Do not rediscover the requirement→code mapping from scratch — start from what pdeq already maintains:

1. **Enumerate the requirement set.** Collect every `FR-`, `NFR-`, and `AC-` slug defined in the platform's product spec(s) — `{specsRoot}/product/<feature>.md` (and any `product/<platform>/<feature>.md` supplement). If `[feature]` was given, restrict to that feature's spec. **This is the exhaustive denominator: every `FR-` here must receive a verdict.**
2. **Read the engineering Code Map(s).** From `{specsRoot}/engineering/<platform>/<feature>.md` → the `## Code Map` table: the planned/implemented code location per slug.
3. **Read the `Code` column of `index.md`.** The marker-derived `file:line` locations per slug.

(2) and (3) give the *known* requirement→code map. Treat it as a **starting point, not ground truth** — the whole reason this audit exists is that a Code Map row can say `implemented` while the code diverges, and the deterministic audit will not notice.

## Phase 2 — READ the code + evaluate spec temporal compliance

<!-- Implements: FR-conformance-evidence, FR-conformance-temporal-specs -->

For each seeded location, open the cited file at the cited line and read the realizing unit. Then read the platform's source tree under `{codeRoot}` broadly enough to (a) confirm each requirement's behavior in context and (b) surface behavior no requirement points at (the reverse-traceability sweep). If `[feature]` narrowed the scope, read the code for that feature's slugs plus its neighborhood; otherwise read the whole platform's source.

Every verdict you reach must be backed by a concrete `file:line` you actually read — a finding a reader cannot check against the source is not acceptable.

**While reading each spec file** (product specs from Phase 1, plus any engineering/design/QA specs you open), evaluate whether the prose is **temporal** — describing plans, future work, setup, or becoming rather than present state. The deterministic `scripts/audit-temporal.sh` catches known patterns by grep; your job here is the semantic complement: catch temporal framing the grep list would miss. Look for:

- Novel planning verbs not in the pattern list ("prepares", "lays the foundation", "readies")
- Domain-specific setup phrasing ("creates the scaffolding for X", "converts the legacy path")
- Spec meta-language that alludes to timing (before-after narratives, implicit ordering)
- Any prose that frames a feature as becoming rather than being

For each violation found, record the `file:line`, the offending prose excerpt, and a suggested present-tense rewrite. These go into the *Spec Temporal Violations* section of the report.

## Phase 3 — REASON to verdicts

<!-- Implements: FR-conformance-four-quadrant, FR-conformance-fulfilled, FR-conformance-unfulfilled, FR-conformance-incorrect, FR-conformance-single-verdict, FR-conformance-undocumented -->

Assign **every in-scope `FR-` slug exactly one** of three verdicts, judged on **behavior**, not marker presence:

- **Fulfilled** — the code realizes the specified behavior. A present marker is necessary evidence, not sufficient justification.
- **Unfulfilled** — no realization, or one too incomplete to satisfy the spec, *even if a marker cites the slug*.
- **Incorrectly fulfilled** — code attempts the requirement but diverges (inverted condition, missing case, contradicted threshold, forbidden behavior). This is the drift a valid marker hides from `audit-traceability.sh`.

`NFR-`/`AC-` slugs are **best-effort**: render a verdict only when the source plainly bears on them; otherwise mark them *not assessed from source*. Keep the exhaustiveness invariant firm over `FR-` only.

Then **sweep for undocumented behavior**: product-relevant behavior in the code that no in-scope requirement describes. **Exclude incidental plumbing** — framework scaffolding, generated files, configuration, build glue, test-support code are never undocumented findings. Only logic a requirement *could* meaningfully describe is eligible.

For every finding, decide a **confidence**: `high` (unambiguous code backs the verdict), `medium`, or `low` (rests on inference about intent — a marked suspicion, not an assertion).

## Phase 4 — EMIT the report

<!-- Implements: FR-conformance-summary, FR-conformance-actionable -->

Output the report and stop. Do not write any file; do not stage anything; do not touch `index.md` or specs.

### Summary first

Open with a header naming the platform (and feature, if narrowed), then a count table:

```
# Conformance Report — platform: <platform>[  (feature: <feature>)]

| Quadrant              | Count |
|-----------------------|-------|
| Fulfilled             | <n>   |
| Unfulfilled           | <n>   |
| Incorrectly fulfilled | <n>   |
| Undocumented          | <n>   |
| Spec temporal violations | <n>   |   ← separate dimension (not part of requirements in scope)
| Requirements in scope | <n>   |   ← fulfilled + unfulfilled + incorrect (the exhaustive FR denominator)
```

`Requirements in scope` **must equal** the count of `FR-` slugs enumerated in Phase 1 and the sum of the three requirement verdicts. `Undocumented` is counted separately (it is a property of code, not of the requirement set).

### Then five sections, in this fixed order

Each section is either a findings table or an explicit empty line (e.g. `_No incorrectly-fulfilled requirements found._`) — **never omitted**, so the report shape is stable.

**Fulfilled / Unfulfilled / Incorrectly Fulfilled** — one row per requirement:

| Slug | Code location(s) | Verdict rationale / divergence | Recommended action | Confidence |
|---|---|---|---|---|

- **Code location(s)**: at least one concrete `file:line` (`; `-separated for several). An unfulfilled requirement with no realizing code cites the location the Code Map *claims* (to show the marker-vs-behavior gap) or `— (no realizing code found)`.
- **Recommended action**: `—` is allowed for fulfilled rows; every non-fulfilled row must state one (fix code / correct or clarify spec / add requirement / remove behavior).
- **Confidence**: `high` / `medium` / `low`.

**Undocumented** — one row per undocumented behavior; the Slug column is `—`:

| Slug | Code location(s) | Behavior observed | Recommended action | Confidence |
|---|---|---|---|---|

Recommended action here is the reverse-traceability choice: *specify it as a requirement* or *remove the dead behavior*.

**Spec Temporal Violations** (`FR-conformance-temporal-specs`, `AC-conformance-temporal-flagged`). One row per temporal/planning phrasing found in spec prose — catching framing the deterministic `scripts/audit-temporal.sh` grep would miss:

| Slug | File:line | Offending prose | Suggested rewrite | Confidence |
|---|---|---|---|---|

- **File:line** — exact location of the temporal prose.
- **Offending prose** — the sentence or clause, truncated to ~100 chars.
- **Suggested rewrite** — a present-tense version stating what *is*.
- **Confidence** — `high` for unambiguous temporal framing (creation verbs, before-after narratives); down-rank borderline prose.

This section is always present (populated or empty). Its count is **not** part of `Requirements in scope` — it is a separate spec-health dimension.

---

## Guarantees to honor

<!-- Implements: FR-conformance-advisory, FR-conformance-complements -->

- **Advisory, never gating.** Producing this report changes nothing. It is not part of any hook and must never block a commit.
- **Complements, never replaces** `scripts/audit-traceability.sh`. You *read* its outputs (the `Code` column, the Code Maps) but never modify them, re-implement marker scanning, or change the coverage gate. The deterministic audit stays the authoritative commit-time gate for marker presence and slug validity; this report adds the semantic layer it is deliberately not built to provide.
- **Per-platform isolation.** One run reports only the named platform's requirements and code.
- **Honest uncertainty.** When you are not sure, say so with a `low`/`medium` confidence marker rather than asserting a firm verdict.
