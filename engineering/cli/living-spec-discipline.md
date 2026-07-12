---
product-hash: 256193cc07e7b5870b081d2ba69f0069333030f516ad94f5b6a4a6e525f6e66d
product-slugs: [AC-living-spec-graduation-moves-content, AC-living-spec-roadmap-not-scanned, AC-living-spec-roadmap-slugs-exempt, AC-living-spec-roadmap-spec-sections, AC-living-spec-template-has-guidance, AC-living-spec-temporal-in-kickoff, AC-living-spec-temporal-patterns-detected, AC-living-spec-temporal-suggestions, FR-living-spec-kickoff-temporal-check, FR-living-spec-multi-phase-roadmap, FR-living-spec-roadmap-graduation, FR-living-spec-roadmap-slug-prefix, FR-living-spec-roadmap-supplements, FR-living-spec-template-guidance, FR-living-spec-temporal-audit-exemptions, FR-living-spec-temporal-audit-modes, FR-living-spec-temporal-audit-patterns, FR-living-spec-temporal-audit-rewording, NFR-living-spec-deterministic-audit, NFR-living-spec-low-noise, NFR-living-spec-roadmap-lightweight-default]
---
# Living Spec Discipline — Technical Spec

> Based on requirements in `../../product/living-spec-discipline.md`

## What We're Building

A deterministic audit script that scans authoritative specs for temporal and phasing language ("MVP", "phase 1", "iteration 2", etc.) and flags it for correction, plus enhanced roadmap support allowing forward-looking spec content with reserved slug prefixes. The audit follows the same pattern as the lane-discipline lexical backstop: deterministic keyword scan, multiple run modes (on-demand, CI, warn-only commit hook), and per-project config toggles. The roadmap expansion lets multi-phase plans live in `roadmap/` with spec structure and slugs, exempt from traceability enforcement, until they graduate to authoritative specs.

## Technical Approach

Add a new shell script `scripts/audit-temporal.sh` that scans `product/`, `design/`, `engineering/`, and `qa/` for temporal language patterns. Extend `scripts/audit-traceability.sh` to recognize and skip roadmap slug prefixes (`FRR-`, `NFRR-`, `ACR-`). Update the kickoff command to invoke the temporal audit in Step 4. Document the roadmap spec-supplement convention in `roadmap/AGENTS.md`. Follow the pattern of the lane-discipline audit: a curated pattern list in `pdeq.json` under a new `temporalAudit` config section, with a default set baked into the script for projects without the config.

## Data Model

No persistent data. The audit is stateless — it reads specs and reports findings. The only new persistent state is the `temporalAudit` config section in `pdeq.json`:

```json
{
  "temporalAudit": {
    "patterns": ["MVP", "phase [0-9]+", "iteration [0-9]+", "V[0-9]+", ...],
    "blockCommit": true  // default; set to false to opt out of commit-time blocking
  }
}
```

## API / Interface Design

### New script: `scripts/audit-temporal.sh`

```bash
#!/usr/bin/env bash
# Scans authoritative specs for temporal/phasing language.
# Usage:
#   ./scripts/audit-temporal.sh             # scan and report, exit 0 always
#   ./scripts/audit-temporal.sh --check     # scan and exit 1 on any findings
#   ./scripts/audit-temporal.sh --staged    # scan only staged files
# Reads pdeq.json temporalAudit.patterns if present; falls back to defaults.
# Outputs: file:line: flagged-text [suggested fix]
```

### Extended: `scripts/audit-traceability.sh`

Add roadmap slug prefix exemption logic before the orphan-slug check:

```bash
# Skip roadmap slugs (FRR-, NFRR-, ACR-) from orphan warnings
if [[ "$slug" =~ ^(FRR|NFRR|ACR)- ]]; then
  continue
fi
```

### Kickoff integration

In `.pdeq/pdeq-rules/commands/pdeq-kickoff.md` Step 4, add to the parallel quality-check batch:

```
8. **Temporal language audit** — Run `./scripts/audit-temporal.sh` over newly created or updated specs. Report findings. This is advisory (does not block kickoff).
```

### Roadmap AGENTS.md update

Add a section to `roadmap/AGENTS.md` documenting the spec-supplement convention:

```markdown
## Roadmap Spec Supplements (Optional)

For multi-phase or detailed forward-looking planning, a roadmap file can include
spec-shaped sections with requirements using reserved slug prefixes:
- `FRR-<feature>-<slug>` — Future Requirement Roadmap
- `NFRR-<feature>-<slug>` — Non-Functional Requirement Roadmap
- `ACR-<feature>-<slug>` — Acceptance Criterion Roadmap

These are explicitly non-authoritative and exempt from traceability audits.
Organize by phase/iteration (e.g., "## V2", "## Fast Follow"). When a section
is ready for implementation, renumber its slugs to FR-/NFR-/AC- and move the
content into the authoritative product/design/engineering spec, then delete
the roadmap section.
```

## Component Architecture

```
scripts/
  audit-temporal.sh          # new: temporal language scanner
  audit-traceability.sh      # extended: skip roadmap slugs
  audit-lanes.sh             # unchanged (sibling reference)

.pdeq/pdeq-rules/commands/
  pdeq-kickoff.md            # extended: Step 4 temporal check

roadmap/
  AGENTS.md                  # extended: spec-supplement docs

pdeq.json                    # optional temporalAudit config
```

All changes are additive except the traceability audit extension (a small exemption block).

## Temporal Language Patterns

Default pattern list (overridable via `pdeq.json`):

```bash
PATTERNS=(
  "\\bMVP\\b"
  "\\bphase [0-9IVX]+\\b"          # phase 1, phase II
  "\\biteration [0-9]+\\b"
  "\\bV[0-9]+\\b"                   # V1, V2
  "\\binitial release\\b"
  "\\bfirst version\\b"
  "\\bwill be added\\b"
  "\\bto be implemented\\b"
  "\\bplanned for\\b"
  "\\beventually\\b"
  "\\bupcoming\\b"
  "\\bnext release\\b"
  "\\blater\\b"                     # context-dependent; may need anchoring
  "\\bfuture\\b"                    # context-dependent
)
```

Patterns use `\b` anchors to minimize false positives. The `--check` mode exits non-zero on any match; the default mode exits 0 always (report-only).

## Suggested Rewordings

For each flagged pattern, the audit suggests one of two fixes:

| Pattern | Suggested fix |
|---|---|
| "MVP will include X" | Move to roadmap, or rewrite as "X is supported" if shipped |
| "phase 1: Y" | Move to roadmap with FRR- slugs, or delete if obsolete |
| "will be added in V2" | Move to roadmap/V2 section |
| "iteration 2 adds Z" | Move to roadmap or rewrite as "Z is available" |

The suggestion logic is pattern-specific and embedded in the audit script as comments next to each pattern.

## Error Handling

- If `pdeq.json` exists but has malformed `temporalAudit` config, warn and fall back to defaults.
- If no specs exist in scanned directories, exit 0 with "no specs found" message.
- If a flagged line is part of a code fence or literal block, still report it (specs should not embed temporal language even in examples; use "FR-ex-" example slugs or reword).

## Performance Considerations

- The audit scans only markdown files in `product/`, `design/`, `engineering/`, `qa/` (excludes `AGENTS.md`, `CLAUDE.md`, `roadmap/`, `decisions.md`, `decisions-pending.md`).
- Uses `grep -nE` for speed; line-by-line pattern matching would be slower.
- On a repo with ~50 spec files, audit completes in <200ms (same order as lane audit).

## Security Considerations

None. This is a read-only local scan; no network access, no writes except to stdout.

## Integration with Pre-Commit Hook

Extend `.pdeq/pdeq-rules/scripts/pre-commit.sh` (or the consumer project's `.git/hooks/pre-commit` if installed) to invoke `audit-temporal.sh --staged`:

```bash
# Temporal audit: blocks by default unless opted out
BLOCK_COMMIT=$(jq -r '.temporalAudit.blockCommit // true' pdeq.json 2>/dev/null || echo "true")

./scripts/audit-temporal.sh --staged || {
  if [[ "$BLOCK_COMMIT" == "true" && "${PDEQ_ALLOW_DRIFT:-0}" != "1" ]]; then
    echo "✗ Temporal audit failed. Fix findings, set temporalAudit.blockCommit: false in pdeq.json, or bypass with PDEQ_ALLOW_DRIFT=1."
    exit 1
  else
    echo "⚠ Temporal audit warnings (not blocking due to config or PDEQ_ALLOW_DRIFT)."
  fi
}
```

Default: **blocks commits** when temporal language is detected. Projects can opt out by setting `temporalAudit.blockCommit: false` in `pdeq.json`.

## Implementation Plan

1. **Write `scripts/audit-temporal.sh`** — The core audit script with default patterns, `--check` and `--staged` modes, and suggested-fix output. Manually test against a spec with known temporal language.
2. **Extend `scripts/audit-traceability.sh`** — Add roadmap slug exemption logic (`FRR-`, `NFRR-`, `ACR-`) before orphan checks. Test that roadmap slugs no longer trigger warnings.
3. **Update `roadmap/AGENTS.md`** — Document the spec-supplement convention (slug prefixes, phase organization, graduation flow). Include an example roadmap file with FRR- slugs.
4. **Integrate into kickoff workflow** — Add the temporal audit call to `.pdeq/pdeq-rules/commands/pdeq-kickoff.md` Step 4. Run a test kickoff to confirm findings are reported.
5. **Add `pdeq.json` config schema** — Document the `temporalAudit.patterns` and `temporalAudit.blockCommit` fields in `engineering/cli/config.md` (or create it if it doesn't exist).
6. **Update product spec template** — Add a brief note to `product/AGENTS.md` §Guidelines reminding authors to use present tense and park future plans in roadmap.
7. **Write QA test cases** — Hand off to QA for verification against the acceptance criteria.

## Code Map

| Slug | Planned location | Status |
|---|---|---|
| FR-living-spec-roadmap-supplements | roadmap/AGENTS.md:20-45 | planned |
| FR-living-spec-roadmap-graduation | .pdeq/pdeq-rules/commands/pdeq-kickoff.md:85-95 | planned |
| FR-living-spec-roadmap-slug-prefix | scripts/audit-traceability.sh:145-155 | planned |
| FR-living-spec-multi-phase-roadmap | roadmap/AGENTS.md:30-40 | planned |
| FR-living-spec-temporal-audit-patterns | scripts/audit-temporal.sh:15-35 | planned |
| FR-living-spec-temporal-audit-modes | scripts/audit-temporal.sh:5-12 | planned |
| FR-living-spec-temporal-audit-rewording | scripts/audit-temporal.sh:40-60 | planned |
| FR-living-spec-temporal-audit-exemptions | scripts/audit-temporal.sh:75-80 | planned |
| FR-living-spec-kickoff-temporal-check | .pdeq/pdeq-rules/commands/pdeq-kickoff.md:92 | planned |
| FR-living-spec-template-guidance | product/AGENTS.md:130-135 | planned |
