---
standing: true
governs: how to triage and place specs so the graph stays internally consistent
---

# Structural Spec-Graph Validation

## Overview

Pdeq's existing audits verify that the spec graph is *internally consistent* — every requirement slug resolves, every downstream reference is defined, every requirement has a code location. They do not verify that the spec graph is *structurally correct*: that a shared spec is actually shared, that a new spec is not a duplicate of one that already exists, that a piece of work landed in the right lane, or that the constraints of a lane were in force when its spec was written.

The gap is not hypothetical. A single piece of work — the presentation of an already-specified feature — was framed at kickoff as a brand-new product feature. It produced a new top-level product spec that duplicated an existing spec's requirements, declared itself platform-neutral while specifying single-platform behavior, and leaked engineering detail into the product lane. Every consistency check passed, so the mistake survived a full kickoff, an entire epic of implementation work, and many commits before a human caught it in review. By then its identifiers had propagated across the index, downstream specs, and code, making the correction expensive.

This feature adds *structural correctness* enforcement at the moment specs are born — the cheapest possible point to catch these errors, before any identifier propagates. It has three parts. A **structural triage gate** forces every kickoff to classify what it is doing before authoring, and in particular to recognize when work is a new presentation of an existing feature rather than a new feature. A **duplication check** compares proposed new requirements against existing specs before a new spec is minted. A **lane-context guarantee** ensures the constraints of a lane are actually loaded into the authoring agent's context before it writes in that lane, on every harness — not merely referenced by a file the harness may or may not have loaded.

The organizing principle is **prevention, not correction**. Structural errors are caught before identifiers are stamped downstream, where permanence would otherwise make them costly to unwind. There is deliberately no tooling to rename or remap established identifiers and no provisional-identifier state; the sole mechanism is catching the error at birth.

## User Stories

- As a **person kicking off a feature**, I want the kickoff to state up front whether it is creating a new feature, updating an existing one, or adding a new presentation of an existing feature, so that work is not accidentally framed as a new feature when it is really a new platform or design on top of one that already exists.
- As a **product spec author**, I want the kickoff to check a proposed new spec against the specs that already exist before creating it, so that I do not mint a second spec that re-specifies requirements another spec already owns.
- As a **maintainer**, I want a shared product spec that actually describes single-platform behavior to be recognized as mis-placed, so that platform-specific work is routed to a platform supplement or to the design and engineering lanes instead of polluting the shared baseline.
- As an **authoring agent on any harness**, I want the constraints of the lane I am writing in to be loaded into my working context before I write, so that a lane's rules are in force at authoring time even on a harness that does not automatically load per-lane role files.
- As a **maintainer**, I want structural errors caught before identifiers propagate, so that a correction never requires unwinding permanent identifiers that have already spread across the index, downstream specs, and code.

## Requirements

### Structural Triage at Kickoff

Every kickoff classifies the shape of the work before any spec is authored, and announces that classification.

- **Three-way classification** `FR-spec-structure-triage-classification`: Before authoring any spec, a kickoff must classify the request as exactly one of: a **new feature**, an **update to an existing feature**, or a **new platform or presentation of an existing feature**. The classification is announced before authoring begins so a human can correct a mis-framing at the cheapest possible moment.
- **Recognize a new presentation of an existing feature** `FR-spec-structure-manifestation-routing`: When the work is a new platform, surface, or presentation of a feature whose behavior is already specified — rather than genuinely new behavior — it is routed to the design and engineering lanes (and, only if the platform introduces new behavior, a platform-specific product supplement) hung off the existing product spec. It does not create a new top-level product spec. This is the classification that is easiest to get wrong, because presentation work superficially resembles a new feature.
- **Scan existing specs before creating one** `FR-spec-structure-existing-scan`: Before creating any new product spec, the kickoff must read the existing product specs to determine whether the request belongs in one of them. A new spec file is created only when the request is genuinely distinct from every existing spec.

### Duplication Prevention

A new product spec is not created when its requirements already live in an existing spec.

- **Overlap check** `FR-spec-structure-overlap-check`: Before a new product spec is minted, its proposed requirements are compared against the requirements of existing product specs, and any material overlap is surfaced. When the overlap shows the work belongs in an existing spec, that spec is updated instead of creating a new one. A new spec proceeds only after overlap has been considered and the work is confirmed distinct.

### Correct Placement

A shared spec must genuinely be shared; single-platform content is a placement error.

- **Shared specs are genuinely platform-neutral** `FR-spec-structure-shared-neutral`: A top-level (shared) product spec must describe behavior that holds across platforms. A shared spec that specifies behavior existing on only one platform is mis-placed: the platform-specific behavior belongs in a platform supplement, and any presentation or technical specifics belong in the design or engineering lanes. The mechanism that detects in-spec bleed is owned by the lane-discipline feature (see `lane-discipline.md`); this requirement states that mis-placement is a structural error, not merely a stylistic one.

### Lane-Context Guarantee

The constraints of a lane are loaded before writing in that lane, on every harness.

- **Load the lane's role before authoring** `FR-spec-structure-lane-context`: Before authoring or modifying a spec in a lane, the agent must load that lane's role definition — the charter and constraints that govern what the lane may and may not specify — into its working context. This holds regardless of whether the harness automatically surfaces per-lane role files; the guarantee is that the lane's constraints are in force at the moment of writing, not merely present somewhere on disk.

## Non-Functional Requirements

- **Prevention over correction** `NFR-spec-structure-prevention-first`: Structural correctness is enforced by catching errors at authoring time, before identifiers propagate to the index, downstream specs, or code. It is an explicit non-goal to provide tooling that renames or remaps established identifiers, or a provisional-identifier state that can be freely renamed before it is stamped downstream. Identifier permanence is preserved; the sole mechanism for keeping structural errors cheap is preventing them at birth.
- **Harness-neutral guarantees** `NFR-spec-structure-harness-neutral`: The triage, overlap, and lane-context behaviors hold on every supported harness, including harnesses that do not automatically load per-lane role files and harnesses that do not spawn per-lane subagents. The behaviors are properties of the workflow, not of any one harness's file-loading or subagent mechanism.

## Acceptance Criteria

These are the testable conditions that define "done." QA writes test cases against these.

- [ ] **Triage classification is announced** `AC-spec-structure-triage-announced`: A kickoff announces which of the three classifications — new feature, update to existing, or new presentation of an existing feature — applies to the request before it authors any spec.
- [ ] **An update modifies the existing spec** `AC-spec-structure-update-in-place`: A request that changes the behavior of an already-specified feature updates the existing product spec rather than creating a new spec file.
- [ ] **A new presentation routes under the existing spec** `AC-spec-structure-presentation-routed`: A request that is a new platform or presentation of an existing feature produces design and engineering specs hung off the existing product spec and does not create a new top-level product spec.
- [ ] **Overlap is surfaced before minting** `AC-spec-structure-overlap-surfaced`: A request whose proposed requirements materially overlap an existing product spec has that overlap surfaced, and the work is folded into the existing spec, before any new spec is created.
- [ ] **A mis-placed shared spec is flagged** `AC-spec-structure-shared-neutral-flagged`: A top-level product spec that specifies behavior existing on only one platform is flagged as mis-placed rather than accepted as a shared baseline.
- [ ] **The lane role is loaded before authoring** `AC-spec-structure-lane-context-loaded`: Authoring or modifying a spec in a lane is preceded by loading that lane's role definition into the authoring context, verifiably and independently of whether the harness auto-loads it.
- [ ] **No identifier-remap tooling exists** `AC-spec-structure-no-remap-tooling`: The feature ships no command or mode that renames, remaps, or provisionally stages requirement identifiers; a structural error caught after identifiers have propagated is handled by the existing manual retire-and-remint convention, not by new tooling.

## Open Questions

- None currently. The prevention-only stance (no remap tooling, no provisional-identifier state) is a settled decision recorded in the decision log; if experience shows late-caught structural errors are common enough to warrant a tooled correction path, that would be a future feature, scoped separately.

## Dependencies

- The kickoff workflow hosts the structural triage gate, the overlap check, and the lane-context guarantee as steps in its flow.
- The lane-discipline feature (`lane-discipline.md`) owns the deterministic mechanism that detects design, engineering, and platform bleed within a spec; this feature states that such bleed and mis-placement are *structural* errors and routes work to the correct lane, but it does not re-specify the detection mechanism.
- Per-lane role definitions (the charters that govern each lane) are the artifacts the lane-context guarantee loads before authoring.
