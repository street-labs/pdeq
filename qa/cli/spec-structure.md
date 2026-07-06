---
product-hash: 1e3913b4db4bef89014a53a84ab542d96871cc6ee1f28ba6b33600682684d3e3
product-slugs: [AC-spec-structure-lane-context-loaded, AC-spec-structure-no-remap-tooling, AC-spec-structure-overlap-surfaced, AC-spec-structure-presentation-routed, AC-spec-structure-shared-neutral-flagged, AC-spec-structure-triage-announced, AC-spec-structure-update-in-place, FR-spec-structure-existing-scan, FR-spec-structure-lane-context, FR-spec-structure-manifestation-routing, FR-spec-structure-overlap-check, FR-spec-structure-shared-neutral, FR-spec-structure-triage-classification, NFR-spec-structure-harness-neutral, NFR-spec-structure-prevention-first]
---
# Structural Spec-Graph Validation — CLI Test Plan

> Based on requirements in `../../product/spec-structure.md`
> Based on engineering in `../../engineering/cli/spec-structure.md`
> (No design spec — feature has no UI surface.)

## What We're Testing

This feature is prompt/instruction text, so most cases are **`[manual]`** checklist verifications: run `/pdeq-kickoff` (or its harness-neutral prose equivalent) against a seeded fixture request and confirm the agent's announced behavior matches the acceptance criterion. Two cases are **`[auto]`**: the shared-spec placement rule shares a deterministic backstop with lane-discipline (`audit-structure.sh`), and the prevention-only non-goal is a grep-assertable absence of remap tooling.

The anchor regression is the **coffee-shop case**: a request that is the presentation of an already-specified feature must be classified as branch 3 (new presentation of an existing feature) and routed to design/engineering under the existing product spec — *not* minted as a new top-level product spec.

## Test Strategy

- **Manual harness**: a fixture pdeq project with a pre-existing `product/ordering.md` (behavior already specified) and a seeded kickoff request ("add the visual ordering screens"). An agent runs the kickoff prompt; a human checks the announced triage classification and the resulting file set against the expected outcome.
- **Auto harness**: shell assertions. `TC-spec-structure-no-remap-tooling` greps the command surface; `TC-spec-structure-shared-neutral` reuses the lane-discipline `audit-structure.sh` fixture harness.
- **Harness-neutral check** (`NFR-spec-structure-harness-neutral`): the lane-context and triage cases are run once with a subagent-capable harness and once with an inline-only harness (or simulated by starting the agent at repo root with only the root agent file loaded) to confirm the behavior does not depend on automatic per-lane file loading.

## Coverage Matrix

| AC | Test case | Auto/Manual | Status |
|---|---|---|---|
| AC-spec-structure-triage-announced | TC-spec-structure-triage-announced | manual | Not started |
| AC-spec-structure-update-in-place | TC-spec-structure-update-in-place | manual | Not started |
| AC-spec-structure-presentation-routed | TC-spec-structure-presentation-routed | manual | Not started |
| AC-spec-structure-overlap-surfaced | TC-spec-structure-overlap-surfaced | manual | Not started |
| AC-spec-structure-shared-neutral-flagged | TC-spec-structure-shared-neutral | auto | Not started |
| AC-spec-structure-lane-context-loaded | TC-spec-structure-lane-context | manual | Not started |
| AC-spec-structure-no-remap-tooling | TC-spec-structure-no-remap-tooling | auto | Not started |

## Test Cases

### TC-spec-structure-triage-announced (manual)
> Covers `AC-spec-structure-triage-announced`, `FR-spec-structure-triage-classification`.
Seed any kickoff request. Run the kickoff prompt.
- **Expect**: before authoring any spec, the agent announces exactly one of the three classifications (new feature / update to existing / new presentation of an existing feature) with a one-line justification.

### TC-spec-structure-update-in-place (manual)
> Covers `AC-spec-structure-update-in-place`.
Fixture has `product/ordering.md`. Seed a request that changes ordering behavior ("orders should support scheduled pickup").
- **Expect**: the agent classifies this as an *update*, edits `product/ordering.md` in place, and creates **no** new product spec file.

### TC-spec-structure-presentation-routed (manual) — coffee-shop regression
> Covers `AC-spec-structure-presentation-routed`, `FR-spec-structure-manifestation-routing`.
Fixture has `product/ordering.md` (behavior specified, no GUI). Seed "build the ordering screens" for a `gui` platform.
- **Expect**: the agent classifies this as a *new presentation of an existing feature*, produces `design/gui/ordering.md` and `engineering/gui/ordering.md` referencing the existing `product/ordering.md`, adds a `product/gui/ordering.md` supplement **only if** genuinely new behavior is introduced, and does **not** create a new top-level product spec (e.g. no `product/views.md`). This is the exact failure the feature exists to prevent.

### TC-spec-structure-overlap-surfaced (manual)
> Covers `AC-spec-structure-overlap-surfaced`, `FR-spec-structure-overlap-check`, `FR-spec-structure-existing-scan`.
Fixture has `product/ordering.md` covering retrieve-menu/build-cart/submit. Seed a request whose requirements re-specify build-cart under a new name.
- **Expect**: before minting anything, the agent reads existing product specs, names the overlap with `product/ordering.md`, and folds the work into it rather than creating a second spec; a new spec would proceed only after explicitly confirming distinctness.

### TC-spec-structure-shared-neutral (auto)
> Covers `AC-spec-structure-shared-neutral-flagged`, `FR-spec-structure-shared-neutral`.
Reuses the lane-discipline `content-platform/` fixture (a top-level product spec specifying single-platform behavior). Run `audit-structure.sh`.
- **Expect**: exit 1 — the mis-placed shared spec is flagged by the deterministic content-class backstop. (This AC's *routing* response is verified by the manual cases; its *detection* is the shared auto backstop, cross-referenced to `../../qa/cli/lane-discipline.md` → `TC-lane-discipline-content-platform`.)

### TC-spec-structure-lane-context (manual / harness-neutral)
> Covers `AC-spec-structure-lane-context-loaded`, `FR-spec-structure-lane-context`, `NFR-spec-structure-harness-neutral`.
Run a kickoff on a harness that loads only the root agent file (or start the agent at repo root). Observe the design lane step.
- **Expect**: the agent explicitly reads `design/AGENTS.md` before writing the design spec, verifiable in its actions/transcript — the lane constraints are loaded regardless of whether the harness auto-surfaced the file. Repeat on a subagent-capable harness: same guarantee.

### TC-spec-structure-no-remap-tooling (auto)
> Covers `AC-spec-structure-no-remap-tooling`, `NFR-spec-structure-prevention-first`.
Grep the command surface (`pdeq-rules/commands/`, `.claude/commands/`) and script directory.
- **Expect**: no command or script that renames/remaps/provisionally-stages requirement slugs (e.g. no `pdeq-remap`, no `--rename-slug`). The prevention-only stance ships no correction tooling.

## Open Questions

- Whether the manual triage cases can be partially automated with a scripted transcript assertion once a headless kickoff-replay harness exists. Deferred — the triage judgment is intrinsically agent-run today.
