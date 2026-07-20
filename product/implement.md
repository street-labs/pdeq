# Implement

## Overview

Kickoff ends with reviewed specs and a reminder to add inline markers when the feature is built — but the step that actually turns those specs into code is unowned. A user finishes a kickoff, reviews the specs, and then has to manually gather every relevant spec, find the code locations the index already maps, and hand-feed context to an implementing agent. That handoff is where momentum dies and where agents burn calls re-deriving what pdeq already knows.

The implement feature closes that gap. After specs are reviewed, the user runs a single command and the implementing agent receives a complete, ready-to-code context bundle: which specs changed, which requirements are in scope, where the code already lives, and what the current code state is. The agent then writes the code, adds the inline markers, and runs the engineering/QA loop until the traceability audit passes. Scope is derived from what changed in the spec tree, so the user does not name files or slugs in the common case.

## User Stories

- As a **builder**, I want to move from reviewed specs to implementing code in one command so that I don't manually gather spec files and code locations by hand.
- As a **builder redoing a feature with a different model**, I want to re-run implement against an explicit feature so that the agent regenerates code from the current specs without me reconstructing scope.
- As a **reviewer**, I want the implementing agent to receive the same context every time so that implementation quality does not depend on which files I remembered to paste.

## Requirements

### Command and Inputs

A single slash command drives implementation from reviewed specs.

- **Slash command** `FR-implement-command`: A `/pdeq-implement` slash command turns reviewed specs into implementing code. It accepts an optional base reference and an optional feature or slug argument.
- **No-arg default** `FR-implement-no-arg-default`: Invoked with no arguments, the command derives scope from changes to the spec tree since the default base. No file names or slugs need to be named by the user.

### Scope Derivation

Scope is driven by what changed in the spec tree, with an explicit fallback for the redo case.

- **Spec-diff scope** `FR-implement-spec-diff-scope`: The command determines which spec files are new or modified relative to a base point and treats every requirement defined in those files as in scope. Over-inclusion at the file level is preferred to missing a requirement.
- **Default base** `FR-implement-default-base`: The default base is the point where the current branch diverged from the main branch. This captures every spec change made on the branch without naming commits.
- **Base options** `FR-implement-base-options`: The user may select a different base: the current branch tip (uncommitted changes only), or an explicit reference. The main default, the current-tip option, and an explicit reference are all supported.
- **Fallback scope** `FR-implement-fallback-scope`: When the spec tree has no changes relative to the base, the user may pass a feature or slug to set scope directly. This covers the redo case where specs are unchanged but code is regenerated.
- **Empty scope exits cleanly** `FR-implement-empty-scope`: When no scope can be derived (no spec changes and no explicit feature or slug), the command reports that there is nothing to implement and exits without invoking an implementing agent.

### Context Bundle

The command produces one complete context bundle that the implementing agent consumes to write code.

- **Single-pass context** `FR-implement-single-pass-context`: The full context bundle is produced in a single invocation. The implementing agent does not gather context piece by piece.
- **Changed specs included** `FR-implement-changed-specs`: The bundle includes the current content of every spec file determined to be in scope.
- **Slug inventory included** `FR-implement-slug-inventory`: The bundle includes the complete set of requirement, non-functional, acceptance, and test-case slugs defined in the in-scope spec files.
- **Index rows included** `FR-implement-index-rows`: For every in-scope slug, the bundle includes the traceability index row linking the slug to where it is defined, where it is referenced, and what code currently realizes it.
- **Code map included** `FR-implement-code-map`: The bundle includes the engineering spec's planned code locations and implementation status for every in-scope functional requirement.
- **Current code state included** `FR-implement-current-code`: For every code location the traceability index or code map points at, the bundle includes the current state of that code relative to the base, so the implementing agent sees what already exists without reading each file separately.

### Implementation and Verification

The implementing agent acts on the bundle and runs to a verifiable done state.

- **Implements in-scope requirements** `FR-implement-implements-requirements`: The implementing agent writes code that realizes every in-scope functional requirement, following the planned locations in the code map, and adds the appropriate inline markers.
- **Runs engineering/QA loop** `FR-implement-runs-loop`: The implementing agent enters the engineering/QA iteration loop and continues until tests pass against the implementation.
- **Traceability audit as done-check** `FR-implement-audit-done-check`: The command re-runs the traceability audit so the index's code column repopulates from the new markers. A passing audit is the completion signal.

### Quality

The context bundle is stable and cheap to produce.

- **Deterministic output** `NFR-implement-determinism`: The context bundle is produced in a deterministic order. Running the command twice against the same scope and base yields the same bundle, so output is reviewable and reproducible.

### Ephemerality

The context bundle and any sequenced plan are throwaway. They never become a second spec system.

- **Context is ephemeral** `FR-implement-context-ephemeral`: The context bundle is produced for the implementing agent to consume immediately. It is not committed, not slugged, not audited, and not indexed. If a plan deserves durability, it graduates to the roadmap or a real spec.

## Non-Goals

The following are deliberately out of scope. They are listed here so future requests against this spec land against an explicit baseline.

- **No code replay.** The command does not replay, cherry-pick, or re-apply historical code diffs. Re-implementing a feature means generating code from the current specs, not reconstructing a past commit range. Git history is an input filter for scope, never the source of truth for code.
- **No stored plans.** There is no plan file, no plan index, no plan audit. The context bundle and any sequenced TODO exist only for the duration of the implementing session.
- **No spec authoring.** The command does not create or modify specs. Spec authoring is kickoff's job. Implement assumes specs are already reviewed.
- **No design spec for the command.** `/pdeq-implement` is a CLI tool with no UI surface. No design spec is authored for the command itself.

## Acceptance Criteria

- [ ] **No-arg derives scope from spec changes** `AC-implement-no-arg-scope`: Invoking `/pdeq-implement` with no arguments on a branch whose spec tree changed since the main branch point produces a context bundle covering exactly the requirements in the changed spec files.
- [ ] **Default base is branch point** `AC-implement-default-base`: With no base argument, scope covers every spec change made on the current branch since it diverged from main, and no spec changes from before that point.
- [ ] **Base option respected** `AC-implement-base-option`: Passing the current-tip base restricts scope to uncommitted spec changes only; passing an explicit reference restricts scope to spec changes since that reference.
- [ ] **Fallback scope works with unchanged specs** `AC-implement-fallback-scope`: On a branch with no spec changes, passing a feature argument produces a context bundle covering that feature's requirements and code locations.
- [ ] **Empty scope exits cleanly** `AC-implement-empty-scope`: With no spec changes and no feature or slug argument, the command reports nothing to implement and exits without invoking an implementing agent.
- [ ] **Context bundle is single-pass and complete** `AC-implement-single-pass`: The produced context bundle contains the changed specs, the slug inventory, the index rows, the code map, and the current code state in one invocation, with no follow-up context-gathering steps required.
- [ ] **Implementation adds markers and passes audit** `AC-implement-markers-audit`: After the implementing agent runs, the traceability audit passes and the index's code column reflects the new inline markers for the in-scope requirements.
- [ ] **Context is not persisted** `AC-implement-context-not-persisted`: No context bundle, plan, or sequenced TODO is written to the repository or tracked by any audit.

## Open Questions

(None — the QA-loop-scope question was resolved inline in the engineering spec: implement runs the engineering/QA loop to green in one session.)

## Dependencies

- **Reviewed specs (`product/`, `design/<platform>/`, `engineering/<platform>/`, `qa/<platform>/`):** the command's input. Implement assumes a kickoff has produced and the user has reviewed these.
- **Traceability index (`index.md`):** used to resolve in-scope slugs to their code locations.
- **Engineering code maps:** used to determine planned locations and implementation status for in-scope functional requirements.
- **Traceability audit:** run as the completion check. The audit repopulates the index's code column from the new inline markers, which is the completion signal.
