# Kickoff: $ARGUMENTS

The user has described what they want: **$ARGUMENTS**

Follow this sequence exactly. Steps are sequential unless noted otherwise; steps marked independent may run concurrently.

**Delegation model (harness-neutral).** Each step names a functional *role* (product, design, engineering, QA) and the lane folder it works in. You take on that role inline, following the lane's `AGENTS.md`. A harness that supports spawning named subagents may delegate a role to one and run independent roles in parallel; a harness without subagents does the same work inline. The result is identical either way — the workflow does not depend on any subagent mechanism.

---

## Step 0: Triage — Decide What's Needed

Before doing anything, analyze the request and decide:

### A) Which platform(s) are in scope?

Determine the target platform(s) for this request:
- **Single-platform** — Affects only one platform. Create or update specs for that platform using the naming convention defined in AGENTS.md.
- **Cross-platform** — Affects multiple platforms. Create/update the base spec (shared behavior), then create/update platform-specific variants where behavior diverges.
- **Porting** — An existing feature being brought to a new platform. Base specs exist; create only platform-specific variants.

If the request doesn't specify a platform, ask the user. For the current project, the active platforms are listed in the "Multi-Platform Support" section of AGENTS.md.

### B) Structural triage: what shape of work is this?

<!-- Implements: FR-spec-structure-triage-classification, FR-spec-structure-existing-scan -->
**First read the existing product specs.** Read the files in `product/` (excluding AGENTS.md and CLAUDE.md) — including platform subfolders — so the classification below is grounded in what already exists, not a guess. This read is mandatory before any new product spec is minted.

Then classify the request as **exactly one** of these three shapes. Getting this right is the cheapest place to prevent a mis-shaped or duplicate spec — before any slug is minted:

1. **Update to an existing feature** — the request changes the *behavior* of a feature that already has a product spec. → **Update the existing spec file in place.** Do NOT create a new file. Specs are living documents: modifications, enhancements, and refinements go into the existing spec.

2. **New presentation of an existing feature** `<!-- Implements: FR-spec-structure-manifestation-routing -->` — the request is a new platform, surface, or presentation of a feature whose *behavior* is already specified (e.g. "build the screens for ordering" when `product/ordering.md` already specifies ordering). This is **not** new behavior, so it does **not** get a new top-level product spec. → Route it to `design/<platform>/<feature>.md` and `engineering/<platform>/<feature>.md` hung off the existing product spec, and add a `product/<platform>/<feature>.md` supplement **only if** the platform introduces genuinely new behavior. This is the classification that is easiest to get wrong — presentation work superficially looks like a new feature. *(The canonical failure: a GUI presentation of an already-specified ordering feature was mis-framed as a new `views` product feature, spawning a duplicate, platform-specific, engineering-leaking product spec that survived a full epic before review caught it.)*

3. **Genuinely new feature** — new behavior that belongs to no existing spec. → Create a new product spec, **but only after the overlap check below.**

**Overlap check (before minting any new product spec)** `<!-- Implements: FR-spec-structure-overlap-check -->`: compare the proposed requirements against the existing product specs you just read. If they materially overlap an existing spec (re-specifying requirements it already owns, even under different names), the work belongs in that spec — fold it in and treat this as an *update*, not a new spec. Proceed to a new spec only after you have explicitly considered overlap and confirmed the work is distinct. Announce the overlap finding in the triage decision (Step C).

**Placement rule** `<!-- Implements: FR-spec-structure-shared-neutral -->`: a top-level (shared) product spec must describe cross-platform behavior. If the work is single-platform in nature, it is **not** a shared product spec — it is a platform supplement plus design/engineering specs. A shared spec that specifies single-platform behavior is a structural placement error, not a style nit.

When porting to a new platform, the base spec already exists — check whether a platform-specific variant already exists too.

### B.1) Check the roadmap

Scan `roadmap/` (excluding AGENTS.md and CLAUDE.md) for an entry that matches this request. Two cases matter:

- **Request matches a roadmap item** (e.g., user says "let's do the fast-follow for auth that we noted") — Read `roadmap/<feature>.md` to pull in the captured intent before delegating to product. The roadmap entry is context, not a spec — the product agent still writes proper requirements with slugs.
- **Request matches an existing feature with a roadmap file** — Even if the user doesn't reference it, skim the roadmap for related future ideas that might inform scope decisions.

Track which roadmap item(s) this kickoff graduates. You'll remove them in Step 4.

### C) Which functional areas are actually needed?

Not every request requires all four areas. Decide which are relevant:

| Request type | Product | Design | Engineering | QA |
|---|---|---|---|---|
| New user-facing feature | Yes | Yes | Yes | Yes |
| UX/UI change to existing feature | Maybe (if requirements change) | Yes | Yes | Yes |
| Technical/performance improvement | Maybe (add NFR if needed) | No (unless UX is affected) | Yes | Yes (performance tests) |
| Bug fix | No (unless requirements were wrong) | No (unless design was wrong) | Yes | Yes |
| Refactoring / tech debt | No | No | Yes | Maybe |
| Porting existing feature to new platform | Maybe (if platform-specific reqs) | Yes (if UI differs) | Yes | Yes |

**Be honest about what's needed.** A request like "make it launch faster" is primarily an engineering concern. Product might add a brief NFR ("app should launch within Xms"), but it doesn't need a design spec. Don't create artifacts just to check boxes.

Announce your triage decision to the user before proceeding:
- **The structural classification** (Step B): update to existing / new presentation of an existing feature / genuinely new feature — with a one-line justification, and for a new spec, the overlap finding against existing product specs
- Which platform(s) are targeted
- Which spec file(s) will be created or updated (including platform-specific variants)
- Which functional areas will be involved and why
- Which functional areas are being skipped and why
- Which roadmap item(s), if any, will be graduated and removed

---

## Step 1: Product Requirements

**Only if triage determined product work is needed.**

<!-- Implements: FR-spec-structure-lane-context -->
**Read `product/AGENTS.md` in full before writing anything in this lane.** Do not rely on the harness having surfaced it — some harnesses load only the root agent file, or load per-lane files based on the working directory rather than the file about to be written. Reading it explicitly guarantees the lane's constraints are in your context at the moment you author.

Take on the product role, working in `product/`. Be explicit about whether this is a **new spec**, an **update to an existing spec**, or a **platform-specific variant**:

- **Updating an existing spec**: Tell the agent which file to update, what sections need changes, and what to add/modify. The agent should read the existing file first and make targeted edits — not rewrite the whole file.
- **New spec**: Have it create a new PRD markdown file following the template in `product/AGENTS.md`.
- **Platform-specific variant**: Tell the agent which base spec to reference and have it create a platform-specific variant file (following the naming convention in AGENTS.md) that covers only platform-specific requirements and divergences. The variant must reference the base spec and not duplicate shared requirements.

For cross-platform work, always do the base spec first, then each platform variant. The variants are independent of each other, so a subagent-capable harness may do them concurrently.

Ensure all requirement slugs follow the format: `FR-<feature>-<slug>`, `NFR-<feature>-<slug>`, `AC-<feature>-<slug>`

Before moving on, read back the product spec and verify it's complete. If the user's description was vague, the product agent should list open questions — present those to the user and resolve them before continuing.

**Do not proceed to Step 2 until this step is fully complete and verified.**

---

## Step 2: Design Spec

**Only if triage determined design work is needed. Wait for Step 1 to complete first.**

**Read `design/AGENTS.md` in full before writing anything in this lane** (see the note in Step 1 — this holds on every harness). Read the product spec from Step 1 (or the existing product spec if Step 1 was skipped). Take on the design role, working in `design/`:

- **Updating an existing spec**: Tell the agent which file to update and what changed in the product spec. The agent should make targeted updates — not rewrite.
- **New spec**: Have it create a design spec following `design/AGENTS.md`.
- **Platform-specific variant**: Tell the agent which base design spec to reference and have it create a platform-specific variant. The variant covers platform-specific UI/UX (e.g., native controls, platform conventions) and references the base spec for shared behavior.

For cross-platform work, do the base design spec first, then each platform variant (independent — may run concurrently on a subagent-capable harness).

The design spec must address every requirement and user story. Reference specific requirement slugs.

**Do not proceed to Step 3 until this step is fully complete.**

---

## Step 3: Engineering Spec + QA Test Plan (parallel)

**Wait for Step 2 to complete first (or Step 1 if design was skipped).**

These two can run **in parallel** because both depend on the same upstream inputs (product spec + design spec) and neither depends on the other at the spec level.

### Engineering Spec

**Read `engineering/AGENTS.md` in full before writing anything in this lane** (see the note in Step 1). Read the product spec and design spec (whichever exist). Take on the engineering role, working in `engineering/`:

- **Updating an existing spec**: Tell the agent which file to update, what changed upstream, and what technical approach needs revisiting.
- **New spec**: Have it create a technical spec following `engineering/AGENTS.md`.
- **Platform-specific variant**: Tell the agent which base engineering spec to reference and have it create a platform-specific variant. The variant covers platform-specific architecture (e.g., different UI frameworks, native APIs vs web APIs) and references the base spec for shared patterns.

Tell the engineering agent explicitly:

- **Populate the Code Map section.** Every platform engineering spec must include a `## Code Map` table with one row per functional requirement. If no code exists yet, use `—` for the location and Status `planned`. If a requirement is deliberately deferred, Status `unimplemented` (exempts it from coverage warnings). See the template in `engineering/AGENTS.md`.
- **Stamp `product-hash` and `product-slugs` frontmatter.** Recompute both from the current product spec every time the engineering spec is created or updated.

Do NOT write code at this stage — only the technical spec.

### QA Test Plan

**Only if triage determined QA work is needed.**

**Read `qa/AGENTS.md` in full before writing anything in this lane** (see the note in Step 1). Read the product spec and design spec. Take on the QA role, working in `qa/`:

- **Updating an existing test plan**: Tell the agent which file to update, what changed, and which test cases need adding/modifying.
- **New test plan**: Have it create a test plan following `qa/AGENTS.md`.
- **Platform-specific variant**: Tell the agent which base test plan to reference and have it create a platform-specific variant. The variant covers platform-specific test cases and tooling, and references the base plan for shared test logic.

Test cases must cover every acceptance criterion. Reference specific slugs.

**Note:** When it later comes time to *implement* (write actual code and tests), that must be sequential — engineering implements first, then QA writes/runs tests against the implementation. But at the spec-writing stage, they can work simultaneously. For cross-platform work, platform-specific engineering and QA variants can also be written in parallel.

---

## Step 4: Post-Processing + Quality Checks (independent)

**Wait for Step 3 to complete.**

These post-processing steps are independent — order among them does not matter. A subagent-capable harness may run them concurrently; otherwise do them inline in any order:

### Independent steps (any order; may run concurrently):

1. **Update traceability index** — Update `index.md` at the project root. For any new slugs, add entries linking to all referencing files. For modified slugs, update the references.

2. **Update glossary** — Review the artifacts created or modified. If any new domain terms were introduced, add them to `glossary.md`. If none were introduced, skip this.

3. **Log decisions** — If any significant decisions were made during this kickoff (technology choices, scope decisions, design patterns), append them to `decisions-pending.md` (not `decisions.md` directly — the pre-commit hook merges pending entries at commit time). If no significant decisions were made, skip this.

4. **Reviewer pass** — Read all artifacts that were created or modified and check for gaps, inconsistencies, or mismatches between them. Report any issues found.

5. **Consistency pass** — Check that terminology is consistent across all artifacts and matches `glossary.md`.

6. **Lane review (product specs only)** — If this kickoff created or updated any **product** spec, run the **Lane Reviewer** over it (see root `AGENTS.md` §"Quality Subagents" → Lane Reviewer for the full contract). Reason about design/engineering/platform bleed *structurally*, not just by keyword — flag implementation-shaped or host-as-product phrasing even when it names no obvious tech term. Classify each finding by category and severity (`violation` vs `allowed: overview context` / `allowed: per-host NFR constraint`), and report findings as the structured table (File · Line · Flagged text · Category · Severity · Suggested rewording). If you spot a concrete vendor/protocol/library word the deterministic `scripts/audit-lanes.sh` would miss, suggest the `laneAudit` term addition for `pdeq.json`. This pass is advisory; it complements — and does not replace — the deterministic backstop, which runs warn-only at commit time.
   <!-- Implements: FR-lane-discipline-review-in-workflow, FR-lane-discipline-two-layer -->

7. **Graduate roadmap items** — If this kickoff consumed any roadmap entry (per Step 0 B.1), remove the graduated item(s) from `roadmap/<feature>.md`. Delete the file entirely if no items remain.

### After the parallel batch completes:

Run `./scripts/audit-traceability.sh` to verify the index is correct. This must wait for the index update (task 1) to finish.

---

## Step 5: Summary

Present a summary to the user:
- What was **created** (new files)
- What was **updated** (existing files, with a summary of changes)
- What was **skipped** and why
- Any issues found during review or consistency checks
- Traceability audit result (pass/fail)

Then print a reminder about inline markers:

> **Next when you implement this feature:** add `// Implements: <slug>`
> markers (or the language-appropriate form — `#` for shell/Python,
> `<!-- ... -->` for Markdown, etc.) at the smallest enclosing unit
> that realizes each functional requirement. The pre-commit audit
> will pick them up and populate the `Code` column in `index.md`
> automatically. See the root `AGENTS.md` §Requirement ↔ Code Mapping
> for the full syntax table.
