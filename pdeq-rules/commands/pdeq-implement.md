<!-- Implements: FR-implement-command, FR-implement-implements-requirements, FR-implement-runs-loop, FR-implement-audit-done-check, FR-implement-context-ephemeral -->
# Implement: $ARGUMENTS

Turn reviewed specs into implementing code. `/pdeq-kickoff` wrote the specs and the user reviewed them; this command produces a complete context bundle and drives the implementing agent through writing code, adding inline markers, running the engineering/QA loop, and re-running the traceability audit as the done-check.

`$ARGUMENTS` is optional:

| Form | Meaning |
|---|---|
| _(empty)_ | Derive scope from spec-tree changes since the default base (`git merge-base main HEAD`). The normal path after a kickoff on a branch. |
| `--base main\|HEAD\|<ref>` | Select a different base. `main` (default) = branch point. `HEAD` / `working` = uncommitted spec changes only. `<ref>` = explicit git reference. |
| `<feature>` or `<slug>` | Fallback scope when the spec tree has no changes (the redo case). Resolves the in-scope spec set from the feature name or a slug's defining product spec. |

`--base` and a positional `feature`/`slug` may be combined.

---

## Step 1 — Produce the context bundle

Run the context producer. It joins git spec-diff scope against the traceability index and emits one complete, deterministically-ordered bundle to stdout in a single pass.

```sh
./scripts/implement-context.sh $ARGUMENTS
```

If the script exits 0 with empty stdout, it printed a "nothing to implement" message to stderr — report that to the user and stop. Do not invoke an implementing agent.

If the script exits non-zero, report the stderr message and stop.

Otherwise, the stdout is your context bundle. Read it once. It contains, in fixed order:

1. **Changed spec files** — which specs are new or modified vs the base.
2. **In-scope slugs** — every `FR-`/`NFR-`/`AC-`/`TC-` defined in those specs (file-level over-inclusion; `TC-` included because QA specs are in scope).
3. **Spec contents** — the full current content of each in-scope spec file.
4. **Index rows** — for each in-scope slug, its traceability index row (Defined In, Referenced In, Code).
5. **Code map** — for each in-scope `FR-`, the engineering spec's planned location and status (`planned`/`implemented`/`unimplemented`).
6. **Current code state** — for every code file the index or Code Map points at, `git diff` vs the base (or `planned, not yet present`).

Do not gather any additional context with toolcalls. The bundle is complete and single-pass by design.

---

## Step 2 — Implement every in-scope FR

For every in-scope `FR-` per the Code Map, write the realizing code at the planned location:

1. Read the product spec, engineering spec, and (if present) the design spec for the requirement from the bundle's Spec contents section.
2. Write the code that realizes the requirement's behavior. Follow the engineering spec's technical approach and the Code Map's planned locations.
3. Add the language-appropriate inline marker at the smallest enclosing named unit (function, method, or block) that realizes the requirement:
   - C-family (`.ts`, `.js`, `.go`, `.swift`, etc.): `// Implements: FR-<feature>-<slug>`
   - Shell / scripting (`.sh`, `.py`, etc.): `# Implements: FR-<feature>-<slug>`
   - SQL: `-- Implements: FR-<feature>-<slug>`
   - HTML / Markdown: `<!-- Implements: FR-<feature>-<slug> -->`
   - Block-comment only (`.css`, etc.): `/* Implements: FR-<feature>-<slug> */`
   - Multi-slug: `// Implements: FR-x, FR-y` (single source line).
4. Update the Code Map row's Status from `planned` to `implemented` in the engineering spec.

If a requirement is deliberately deferred, set its Code Map Status to `unimplemented` (this exempts it from coverage warnings). Do not leave a `planned` row with no code and no `unimplemented` marker.

**Cardinal rule:** markdown first, code second. If during implementation you discover the spec is wrong or incomplete, update the spec first, then write the code to match. Never back-fill a spec from code.

---

## Step 3 — Run the engineering/QA loop

Enter the engineering/QA iteration loop and run to green:

1. Run the project's automated tests (per the QA test plan in the bundle).
2. For each failing test (`TC-` slug), document observed vs expected behavior.
3. Investigate the root cause. If the fix changes architecture or behavior, update the relevant markdown spec first (cardinal rule), then fix the code.
4. Re-run the tests. Loop until all pass.

If the project has no automated test infrastructure, execute the manual test cases from the QA test plan and verify each acceptance criterion by inspection. Report any failures and fix them before proceeding.

---

## Step 4 — Re-run the traceability audit (done-check)

```sh
./scripts/audit-traceability.sh
```

The audit scans for the inline markers you added and repopulates the `Code` column in `index.md` from them. A passing audit (exit 0) is the completion signal — it means every in-scope `FR-` with a marker now has its code location recorded, and the index is in sync with the code.

If the audit reports issues:
- **Uncovered requirements** — a `FR-` with no marker. Add the marker or mark it `unimplemented` in the Code Map.
- **Orphan markers** — a marker citing a slug not defined in any product spec. Remove the marker or correct the slug.
- **Stale Code Map paths** — a Code Map row pointing at a file that doesn't exist. Update the Code Map.

Fix and re-run until the audit passes.

---

## Step 5 — Summary

Present a summary to the user:
- Which `FR-`s were implemented (slug + file).
- Which files were created or modified.
- Test results (pass/fail count).
- Traceability audit result (pass/fail).
- Any specs that were updated during implementation (and why).

---

## Constraints

- **The context bundle is ephemeral.** Do not write it to disk. Do not commit it. Do not create a plan file, a TODO file, or any artifact derived from the bundle. If a plan deserves durability, it graduates to `roadmap/` or a real spec — but that is a separate decision, not this command's job.
- **Do not modify specs unless the spec was wrong.** Implement writes code; it does not author new requirements. The only spec edits allowed during implement are corrections discovered during implementation (cardinal rule: markdown first, code second) and Code Map status updates.
- **Do not replay historical code.** Re-implementing a feature means generating code from the current specs, not reconstructing a past commit range. Git history is a scope filter, never the source of truth for code.
