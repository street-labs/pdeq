---
product-hash: 1e3913b4db4bef89014a53a84ab542d96871cc6ee1f28ba6b33600682684d3e3
product-slugs: [AC-spec-structure-lane-context-loaded, AC-spec-structure-no-remap-tooling, AC-spec-structure-overlap-surfaced, AC-spec-structure-presentation-routed, AC-spec-structure-shared-neutral-flagged, AC-spec-structure-triage-announced, AC-spec-structure-update-in-place, FR-spec-structure-existing-scan, FR-spec-structure-lane-context, FR-spec-structure-manifestation-routing, FR-spec-structure-overlap-check, FR-spec-structure-shared-neutral, FR-spec-structure-triage-classification, NFR-spec-structure-harness-neutral, NFR-spec-structure-prevention-first]
---
# Structural Spec-Graph Validation — CLI Technical Spec

> Based on requirements in `../../product/spec-structure.md`
> (No design spec — feature has no UI surface. Design lane is explicitly N/A.)

## What We're Building

This feature is realized entirely in **prompt/instruction text**, not in new scripts. Its enforcement point is the moment a spec is authored, which on every harness is driven by the kickoff prompt and the coordinator/lane role files. There is deliberately no new deterministic script and no new commit-time gate — the whole point (`NFR-spec-structure-prevention-first`) is to catch structural errors *before* identifiers exist to audit.

Three edits carry the feature:

1. **The kickoff Step B decision frame** (`pdeq-rules/commands/pdeq-kickoff.md`) is rewritten from a two-way (new / update) prose choice into a three-way structural triage with an explicit routing branch and a mandatory pre-mint overlap check.
2. **Each kickoff lane step** (product, design, engineering, QA) gains a first instruction to load that lane's role file into context before authoring.
3. **The coordinator `AGENTS.md`** records the triage decision frame and the "shared specs are genuinely platform-neutral" placement rule so an agent working outside a formal `/pdeq-kickoff` invocation still has the structural rules in context.

Because the realization is prompt text, coverage markers use the `<!-- Implements: <slug> -->` form and are machine-scanned (the traceability audit indexes `.md`). The behaviors are verified by QA as checklist-style acceptance rather than by fixtures, since there is no script to exercise.

## Technical Approach

### Three-way structural triage (`FR-spec-structure-triage-classification`, `FR-spec-structure-manifestation-routing`)

Kickoff Step B ("Which existing spec does this belong to?") is replaced. The agent must classify the request as exactly one of:

1. **New feature** — genuinely new behavior belonging to no existing spec. → author a new product spec (subject to the overlap check below).
2. **Update to an existing feature** — changed behavior of an already-specified feature. → update the existing product spec in place; never create a new file (`AC-spec-structure-update-in-place`).
3. **New platform / presentation of an existing feature** — a new surface, platform, or presentation of a feature whose *behavior* is already specified. → route to `design/<platform>/<feature>.md` and `engineering/<platform>/<feature>.md` hung off the existing product spec, adding a `product/<platform>/<feature>.md` supplement **only if** the platform introduces genuinely new behavior. Do **not** create a new top-level product spec (`AC-spec-structure-presentation-routed`).

The classification is **announced to the user before authoring** (folded into the existing "Announce your triage decision" block at the end of Step C), satisfying `FR-spec-structure-triage-classification` / `AC-spec-structure-triage-announced`. The prompt calls out branch 3 as the easy-to-miss case, with the coffee-shop example (the presentation of an already-specified ordering feature that was mis-framed as a new `views` product feature) as the worked illustration.

### Scan existing specs + overlap check (`FR-spec-structure-existing-scan`, `FR-spec-structure-overlap-check`)

Before minting any new product spec, the prompt requires the agent to (a) read the existing product specs, and (b) state, in the triage announcement, whether the proposed requirements materially overlap any existing spec. If they do, the work is folded into the existing spec instead of creating a new one; a new spec proceeds only after overlap has been explicitly considered and the work confirmed distinct (`AC-spec-structure-overlap-surfaced`). This is an agent-judgment gate (no similarity script — the user chose the judgment version), but it is *mandatory and announced*, which is the difference from today's optional prose.

### Shared-spec placement rule (`FR-spec-structure-shared-neutral`)

The coordinator `AGENTS.md` and kickoff Step 1 state that a top-level product spec must describe cross-platform behavior; a shared spec specifying single-platform behavior is a **structural placement error**, not merely a style issue, and must be moved to a platform supplement (or its presentation/technical content routed to design/engineering). The *detection mechanism* for in-spec bleed is owned by lane-discipline (`../../product/lane-discipline.md` → `scripts/audit-structure.sh` content-class check); this feature only establishes the placement rule and the routing response (`AC-spec-structure-shared-neutral-flagged`). The two features meet here: lane-discipline's blocking content-class check is the deterministic backstop for the placement rule this feature states.

### Lane-context guarantee (`FR-spec-structure-lane-context`, `NFR-spec-structure-harness-neutral`)

Each lane step in `pdeq-kickoff.md` gains an explicit opening instruction: *"Read `<lane>/AGENTS.md` in full before writing anything in this lane."* Today the prompt says "take on the role per `<lane>/AGENTS.md`", which assumes the harness has surfaced that file — false on harnesses that only load the root agent file, or that load per-directory files based on cwd rather than the file about to be written (the Pi failure mode). Making the read an explicit workflow step guarantees the lane's constraints are in the authoring context regardless of harness file-loading behavior (`AC-spec-structure-lane-context-loaded`, `NFR-spec-structure-harness-neutral`). The instruction is harness-neutral: an inline agent reads the file; a subagent-spawning harness has the subagent read it. Either way the constraints are loaded before the first line is written.

### Prevention-only, no correction tooling (`NFR-spec-structure-prevention-first`, `AC-spec-structure-no-remap-tooling`)

This feature ships **no** command or mode that renames, remaps, or provisionally stages requirement identifiers. Identifier permanence (root `AGENTS.md` §Slug-Based IDs) is preserved unchanged. A structural error caught *after* identifiers have propagated is handled by the existing manual retire-and-remint convention, not by new tooling (`AC-spec-structure-no-remap-tooling`). This is a deliberate scoping decision recorded in the decision log: prevention at authoring time is the sole mechanism, on the reasoning that a strong birth gate makes late correction rare enough that tooling it is not warranted.

## Code Map

Authoritative planned code locations for every FR defined in `product/spec-structure.md`. All realizations are prompt/instruction text (`<!-- Implements: -->` markers).

| Slug | Planned location | Status |
|---|---|---|
| FR-spec-structure-triage-classification | pdeq-rules/commands/pdeq-kickoff.md | planned |
| FR-spec-structure-manifestation-routing | pdeq-rules/commands/pdeq-kickoff.md | planned |
| FR-spec-structure-existing-scan | pdeq-rules/commands/pdeq-kickoff.md | planned |
| FR-spec-structure-overlap-check | pdeq-rules/commands/pdeq-kickoff.md | planned |
| FR-spec-structure-shared-neutral | AGENTS.md | planned |
| FR-spec-structure-lane-context | pdeq-rules/commands/pdeq-kickoff.md | planned |

`NFR-spec-structure-prevention-first`, `NFR-spec-structure-harness-neutral`, and the non-goal `AC-spec-structure-no-remap-tooling` are policy/negative requirements with no positive code location; they are verified by QA (absence of remap tooling; harness-neutral checklist) rather than by a marker.
