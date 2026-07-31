# Project Status Dashboard

Scan all four functional folders, the `roadmap/` folder, and the traceability index to build a status report.

## Step 1: Inventory Features

Scan `product/` for all feature spec files (excluding AGENTS.md and CLAUDE.md). Each file represents a feature. Collect the filenames.

Also scan `roadmap/` (excluding AGENTS.md, CLAUDE.md, and `_overview.md`) for feature files with pending forward-looking ideas. A roadmap entry may reference a shipped feature (fast follow / V2 backlog) or an unshipped feature (pre-kickoff vision).

## Step 2: Check Coverage Per Feature

For each feature found in `product/`, check whether a corresponding file exists in:
- `design/` (same filename)
- `engineering/` (same filename)
- `qa/` (same filename)
- `roadmap/` (same filename — optional, indicates pending future work)

## Step 3: Slug Coverage

For each feature, count:
- How many slugs are defined in the product spec (FR-*, NFR-*, AC-*)
- How many of those slugs appear in the design spec
- How many appear in the engineering spec
- How many have test cases in the QA spec
- How many are in `index.md`

Roadmap files are not slug-tracked — skip slug counting for them.

## Step 4: Run Audit

Run `./scripts/audit-traceability.sh` and capture the results.

## Step 4b: Project Orientation

<!-- Implements: FR-project-orientation-status-surfaces -->
Read `project.md` at the specs root. Report:
- Whether `project.md` exists.
- If it exists: the **What this is** one-liner (first sentence), the **Platforms** list, and the **Standing specs** table (name + path for each row).
- If any standing-spec path in the table does not resolve to a file, flag it as a gap.
- If `project.md` does not exist, note that the project is not yet oriented and that the project-orientation migration will seed it.

## Step 4c: Lane Guides

<!-- Implements: FR-lane-guides-status-reports -->

Read `pdeq.json` for a `laneGuides` object. If absent, report "none configured." If present, for each lane key (`product`, `design`, `engineering`, `qa`, `roadmap`) → path (relative to `specsRoot`), resolve the path against `specsRoot` and record whether the file exists. Paths that do not resolve are flagged as gaps (non-fatal — the installer also warns on these at install time).

## Step 5: Present Dashboard

```
## Project Status

### Feature Coverage

| Feature | Product | Design | Engineering | QA | Index | Roadmap |
|---|---|---|---|---|---|---|
| auth | ✓ (8 slugs) | ✓ (8/8) | ✓ (6/8) | ✓ (7/8) | 8/8 | 3 items |
| onboarding | ✓ (5 slugs) | ✗ missing | ✗ missing | ✗ missing | 3/5 | — |

### Roadmap (unshipped)

Features with roadmap entries but no product spec yet (pre-kickoff vision):
- [List: roadmap/<feature>.md — one-line summary]

### Summary
- X features defined
- Y fully covered (all four stages)
- Z partially covered
- R features with roadmap entries
- N traceability issues

### Gaps
- [List specific missing specs or uncovered slugs]

### Audit Results
[Output from audit-traceability.sh]

### Orientation
- project.md: <exists? one-liner of what the project is>
- Platforms: <list>
- Standing specs: <table or none>

### Lane Guides
| Lane | Path | Resolves |
|---|---|---|
| qa | qa/snapshot-testing.md | yes |
| engineering | engineering/architecture.md | no — flagged |

If `laneGuides` is absent or empty, report "none configured" here.
```

If there are no features yet, just say the project is empty and ready for its first `/pdeq-kickoff`.
