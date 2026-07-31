# Traceability Index

This file maps every requirement slug to all files that define or reference it. It is the single source of truth for requirement traceability across the project.

**Slug types:**
- `FR-` — Functional requirements (defined in `product/`)
- `NFR-` — Non-functional requirements (defined in `product/`)
- `AC-` — Acceptance criteria (defined in `product/`)
- `TC-` — Test cases (defined in `qa/`)

**Agent rule:** Every agent must update this file when they create or reference a slug. This is not optional.

**Validation:** The `scripts/audit-traceability.sh` script validates this index. It will report errors if a slug is defined but missing from the index, referenced but not defined, or if a file path listed here does not exist. Run it manually at any time: `./scripts/audit-traceability.sh`

---

## Index

| Slug | Type | Defined In | Referenced In | Code |
|------|------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------|
| FR-migrations-version-field | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, pdeq.schema.json, VERSION | scripts/init.sh:574 |
| FR-migrations-version-readable | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:82, scripts/migrate.sh:95 |
| FR-migrations-absent-version | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | scripts/migrate.sh:82 |
| FR-migrations-one-per-version | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:110 |
| FR-migrations-ordered | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:110 |
| FR-migrations-mechanical-block | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:155 |
| FR-migrations-semantic-block | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:155 |
| FR-migrations-order-within | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-author-written | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | migrations/0.10.0.md:8, migrations/0.11.0.md:10, migrations/0.11.0.md:8, migrations/0.12.0.md:8, migrations/0.13.0.md:8, migrations/0.4.0.md:8, migrations/0.5.0.md:8, migrations/0.6.0.md:8, migrations/0.7.0.md:8, migrations/0.8.0.md:8, migrations/0.9.0.md:8, migrations/TEMPLATE.md:8 |
| FR-migrations-explicit-run | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-pending-detection | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:110 |
| FR-migrations-ordered-application | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-version-bump | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:219 |
| FR-migrations-nonbreaking-advance | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:301 |
| FR-migrations-noop-when-current | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:110 |
| FR-migrations-dry-run | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-idempotent | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | migrations/0.10.0.md:8, migrations/0.11.0.md:10, migrations/0.11.0.md:8, migrations/0.12.0.md:8, migrations/0.13.0.md:8, migrations/0.4.0.md:8, migrations/0.5.0.md:8, migrations/0.6.0.md:8, migrations/0.7.0.md:8, migrations/0.8.0.md:8, migrations/0.9.0.md:8, migrations/TEMPLATE.md:8 |
| FR-migrations-scoped-writes | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:354 |
| FR-migrations-breaking-gate | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | scripts/audit-migrations.sh:45 |
| FR-migrations-no-false-positive | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | scripts/audit-migrations.sh:45 |
| FR-migrations-lineage-integrity | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:272 |
| FR-migrations-bootstrap-chain | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| FR-migrations-self-migration | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-atomic-bump | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:219 |
| FR-migrations-failure-report | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| FR-migrations-recoverable-partial | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | scripts/migrate.sh:219 |
| FR-migrations-unknown-version | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:272 |
| FR-migrations-missing-file-refused | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh | scripts/migrate.sh:301 |
| FR-migrations-update-command | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| FR-migrations-update-bumps-pin | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| FR-migrations-update-chains | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| FR-migrations-update-in-session | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1, scripts/sync-symlinks.sh:122 |
| FR-migrations-update-noop | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| FR-migrations-update-bump-failure | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| FR-migrations-update-dry-run | FR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-update.md:1 |
| NFR-migrations-idempotency | NFR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| NFR-migrations-determinism | NFR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| NFR-migrations-scope-minimalism | NFR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| NFR-migrations-enforcement-precision | NFR | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-noop-when-current | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-ordered-apply | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-no-bump-on-failure | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-dry-run-accurate | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-gate-blocks | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-gate-allows-nonbreaking | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-semantic-context | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-idempotent-rerun | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-absent-reported | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-lineage-refused | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-scope-respected | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-self-migration-runs | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-nonbreaking-advance | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-missing-file-refused | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md, scripts/migrate.sh |  |
| AC-migrations-update-end-to-end | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-update-noop | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-update-in-session | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-update-bump-failure | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-update-dry-run | AC | product/migrations.md | design/cli/migrations.md, engineering/cli/migrations.md, qa/cli/migrations.md |  |
| TC-migrations-status-line-printed | TC | qa/cli/migrations.md |  |  |
| TC-migrations-status-line-at-latest | TC | qa/cli/migrations.md |  |  |
| TC-migrations-version-field-read | TC | qa/cli/migrations.md |  |  |
| TC-migrations-absent-version-state | TC | qa/cli/migrations.md |  |  |
| TC-migrations-absent-version-no-writes | TC | qa/cli/migrations.md |  |  |
| TC-migrations-newer-recorded-refused | TC | qa/cli/migrations.md |  |  |
| TC-migrations-foreign-lineage-refused | TC | qa/cli/migrations.md |  |  |
| TC-migrations-noop-at-latest | TC | qa/cli/migrations.md |  |  |
| TC-migrations-noop-no-writes | TC | qa/cli/migrations.md |  |  |
| TC-migrations-pending-detection-single | TC | qa/cli/migrations.md |  |  |
| TC-migrations-pending-detection-multi | TC | qa/cli/migrations.md |  |  |
| TC-migrations-pending-detection-none | TC | qa/cli/migrations.md |  |  |
| TC-migrations-multi-order | TC | qa/cli/migrations.md |  |  |
| TC-migrations-ordered-pending-list | TC | qa/cli/migrations.md |  |  |
| TC-migrations-version-bump-success | TC | qa/cli/migrations.md |  |  |
| TC-migrations-dry-run-no-writes | TC | qa/cli/migrations.md |  |  |
| TC-migrations-dry-run-output-shape | TC | qa/cli/migrations.md |  |  |
| TC-migrations-dry-run-semantic-skipped | TC | qa/cli/migrations.md |  |  |
| TC-migrations-dry-run-matches-real-run | TC | qa/cli/migrations.md |  |  |
| TC-migrations-dry-run-file-list-exhaustive | TC | qa/cli/migrations.md |  |  |
| TC-migrations-rerun-is-noop | TC | qa/cli/migrations.md |  |  |
| TC-migrations-mechanical-idempotent | TC | qa/cli/migrations.md |  |  |
| TC-migrations-semantic-idempotent | TC | qa/cli/migrations.md |  |  |
| TC-migrations-non-breaking-no-file | TC | qa/cli/migrations.md |  |  |
| TC-migrations-one-file-per-version | TC | qa/cli/migrations.md |  |  |
| TC-migrations-file-required | TC | qa/cli/migrations.md |  |  |
| TC-migrations-no-auto-trigger | TC | qa/cli/migrations.md |  |  |
| TC-migrations-mechanical-runs | TC | qa/cli/migrations.md |  |  |
| TC-migrations-mechanical-absent-marker | TC | qa/cli/migrations.md |  |  |
| TC-migrations-semantic-runs | TC | qa/cli/migrations.md |  |  |
| TC-migrations-semantic-absent-marker | TC | qa/cli/migrations.md |  |  |
| TC-migrations-mechanical-before-semantic | TC | qa/cli/migrations.md |  |  |
| TC-migrations-atomic-bump-on-mechanical-fail | TC | qa/cli/migrations.md |  |  |
| TC-migrations-atomic-bump-on-semantic-fail | TC | qa/cli/migrations.md |  |  |
| TC-migrations-failure-report-names-migration | TC | qa/cli/migrations.md |  |  |
| TC-migrations-failure-report-names-block | TC | qa/cli/migrations.md |  |  |
| TC-migrations-failure-report-recovery-steps | TC | qa/cli/migrations.md |  |  |
| TC-migrations-partial-recoverable-state | TC | qa/cli/migrations.md |  |  |
| TC-migrations-resume-after-fix | TC | qa/cli/migrations.md |  |  |
| TC-migrations-no-skip-gaps | TC | qa/cli/migrations.md |  |  |
| TC-migrations-scope-default-enforced | TC | qa/cli/migrations.md |  |  |
| TC-migrations-scope-broader-declared | TC | qa/cli/migrations.md |  |  |
| TC-migrations-scope-semantic-context-confined | TC | qa/cli/migrations.md |  |  |
| TC-migrations-semantic-context-receives-files | TC | qa/cli/migrations.md |  |  |
| TC-migrations-untouched-files-unchanged | TC | qa/cli/migrations.md |  |  |
| TC-migrations-gate-blocks-missing-file | TC | qa/cli/migrations.md |  |  |
| TC-migrations-gate-passes-with-file | TC | qa/cli/migrations.md |  |  |
| TC-migrations-gate-docs-only | TC | qa/cli/migrations.md |  |  |
| TC-migrations-gate-nonframework | TC | qa/cli/migrations.md |  |  |
| TC-migrations-gate-trailer-override | TC | qa/cli/migrations.md |  |  |
| TC-migrations-self-migration-same-command | TC | qa/cli/migrations.md |  |  |
| TC-migrations-self-migration-advances-version | TC | qa/cli/migrations.md |  |  |
| TC-migrations-output-glyphs | TC | qa/cli/migrations.md |  |  |
| TC-migrations-determinism-two-runs | TC | qa/cli/migrations.md |  |  |
| TC-migrations-unknown-format-error | TC | qa/cli/migrations.md |  |  |
| TC-migrations-grep-friendly | TC | qa/cli/migrations.md |  |  |
| TC-migrations-nonbreaking-advance | TC | qa/cli/migrations.md |  |  |
| TC-migrations-missing-file-refused | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-happy | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-noop-current | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-nonbreaking-only | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-in-session-new-command | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-bump-failure-network | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-dry-run | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-self-host-refuses | TC | qa/cli/migrations.md |  |  |
| TC-migrations-update-symlink-prune | TC | qa/cli/migrations.md |  |  |
| FR-code-mapping-marker-presence | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:184 |
| FR-code-mapping-marker-multi | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:180 |
| FR-code-mapping-marker-scope | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:597 |
| FR-code-mapping-marker-language | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:180 |
| FR-code-mapping-marker-slug-reference | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:579 |
| FR-code-mapping-marker-retirement-blocks | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:580 |
| FR-code-mapping-planned-paths | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:267 |
| FR-code-mapping-planned-paths-living | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:267 |
| FR-code-mapping-planned-paths-per-platform | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:625 |
| FR-code-mapping-acknowledged-unimplemented | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:677 |
| FR-code-mapping-audit-scan | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:144, scripts/audit-traceability.sh:184, scripts/init.sh:667 |
| FR-code-mapping-audit-validates-slug | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:580, scripts/audit-traceability.sh:73 |
| FR-code-mapping-audit-validates-path | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:625 |
| FR-code-mapping-audit-coverage | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:678 |
| FR-code-mapping-audit-coverage-blocks | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:678 |
| FR-code-mapping-audit-coverage-grace | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:306, scripts/audit-traceability.sh:678 |
| FR-code-mapping-audit-escape-hatch | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:707 |
| FR-code-mapping-audit-qa-status-evidence | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:452 |
| FR-code-mapping-index-code-locations | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:332 |
| FR-code-mapping-index-populated | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:332, scripts/audit-traceability.sh:739 |
| FR-code-mapping-index-removes-stale | FR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:334 |
| NFR-code-mapping-audit-speed | NFR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| NFR-code-mapping-precision | NFR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:179 |
| NFR-code-mapping-review-cost | NFR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| NFR-code-mapping-determinism | NFR | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-orphan-marker-rejected | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-retirement-blocks | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-stale-planned-path-rejected | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-uncovered-warns | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-uncovered-blocks | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-acknowledged-unimplemented | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-multi-slug-counted | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-marker-scope-enforced | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md | scripts/audit-traceability.sh:597 |
| AC-code-mapping-marker-syntax-per-type | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-planned-paths-living | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-index-reflects-markers | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-index-drops-removed | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-index-stage-preserves-unstaged | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-escape-hatch | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-qa-pass-without-evidence-rejected | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-near-match-rejected | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-audit-speed | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| AC-code-mapping-deterministic-output | AC | product/code-mapping.md | engineering/cli/code-mapping.md, qa/cli/code-mapping.md |  |
| TC-code-mapping-marker-matches | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-multi-slug | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-syntax-table | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-close-token-required | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-scan-finds-markers | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-near-match-ignored | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-nested-comment-known-limit | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-single-line-marker | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-orphan-blocks | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-retirement-blocks | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-scope-flagged | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-code-map-parses | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-code-map-malformed | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-stale-path-blocks | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-unimplemented-exempt | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-coverage-reported | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-grace-warns | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-grace-expires | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-shallow-clone-warns | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-index-populated | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-index-auto-stage | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-index-check-mode-fails | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-index-removes-stale | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-per-platform-index | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-override-demotes | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-override-reports-suppressed | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-audit-under-2s | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-deterministic-two-runs | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-exclusion-respected | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-selfhost-includes | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-consumer-excludes-pdeq | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-scope-on-function-passes | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-grep-fallback-correctness | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-skip-index-rewrite | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-grace-default-5 | TC | qa/cli/code-mapping.md |  |  |
| TC-code-mapping-implemented-status-no-marker | TC | qa/cli/code-mapping.md |  |  |
| FR-visualize-command | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-input-design-spec | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-single-file | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-browser-viewable | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-auto-open | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-output-path | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-gitignored | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-regenerable | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-single-mode | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| FR-visualize-platform-scope | FR | product/visualize.md |  | pdeq-rules/commands/pdeq-visualize.md:1 |
| AC-visualize-renders | AC | product/visualize.md |  |  |
| AC-visualize-gitignored | AC | product/visualize.md |  |  |
| AC-visualize-self-contained | AC | product/visualize.md |  |  |
| AC-visualize-missing-spec | AC | product/visualize.md |  |  |
| AC-visualize-rerun-overwrites | AC | product/visualize.md |  |  |
| FR-cli-naming-prefix | FR | product/cli-conventions.md | migrations/0.3.0.md | migrations/0.3.0.md:8 |
| FR-cli-naming-rename-existing | FR | product/cli-conventions.md | migrations/0.3.0.md | migrations/0.3.0.md:8 |
| FR-cli-naming-discoverable | FR | product/cli-conventions.md |  |  |
| FR-cli-naming-no-collision | FR | product/cli-conventions.md |  |  |
| AC-cli-naming-listing | AC | product/cli-conventions.md |  |  |
| AC-cli-naming-no-bare-name | AC | product/cli-conventions.md |  |  |
| AC-cli-naming-migration-carries | AC | product/cli-conventions.md |  |  |
| FR-harness-agnostic-config | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:129, scripts/init.sh:632, scripts/lib/harness.sh:77 |
| FR-harness-agnostic-v1-harness-set | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/lib/harness.sh:28 |
| FR-harness-agnostic-multiple-per-install | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-unknown-rejected | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:138, scripts/lib/harness.sh:28 |
| FR-harness-agnostic-canonical-agents-file | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-content-portable | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-no-import-in-canonical | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-per-harness-install | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:152, scripts/init.sh:437, scripts/init.sh:457 |
| FR-harness-agnostic-claude-import | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | CLAUDE.md:1, scripts/init.sh:153, scripts/lib/harness.sh:65 |
| FR-harness-agnostic-symlink-include | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:154, scripts/lib/harness.sh:65 |
| FR-harness-agnostic-commands-per-harness | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:191, scripts/init.sh:507, scripts/lib/harness.sh:50 |
| FR-harness-agnostic-commands-source-path | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-bootstrap-inline | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | pdeq-rules/commands/pdeq-bootstrap.md:3 |
| FR-harness-agnostic-no-subagent-files | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | pdeq-rules/commands/pdeq-bootstrap.md:3 |
| FR-harness-agnostic-skill-claude-pi | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-migration | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | migrations/0.4.0.md:8 |
| FR-harness-agnostic-hard-cutover | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | migrations/0.4.0.md:8 |
| FR-harness-agnostic-migration-default-harness | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | migrations/0.4.0.md:8 |
| FR-harness-agnostic-migration-idempotent | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | migrations/0.4.0.md:8 |
| FR-harness-agnostic-migration-removes-subagents | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | migrations/0.4.0.md:8 |
| FR-harness-agnostic-harness-change-reinstall | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| FR-harness-agnostic-removed-harness-cleaned | FR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:226, scripts/init.sh:296, scripts/init.sh:513 |
| NFR-harness-agnostic-no-new-deps | NFR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| NFR-harness-agnostic-installer-reporting | NFR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:155 |
| NFR-harness-agnostic-symlink-portability | NFR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md | scripts/init.sh:192 |
| NFR-harness-agnostic-docs-multi-harness | NFR | product/harness-agnostic.md | engineering/cli/harness-agnostic.md |  |
| AC-harness-agnostic-default-claude | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-codex-install | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-pi-install | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-multi-install | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-unknown-init | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-unknown-schema | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-codex-no-commands | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-pi-commands | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-pi-skill | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-bootstrap-no-subagent | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-migration-end-to-end | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-migration-idempotent | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-migration-warns-customized | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-no-new-deps | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-remove-harness | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-installer-output | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| AC-harness-agnostic-self-host-migrates | AC | product/harness-agnostic.md | engineering/cli/harness-agnostic.md, qa/cli/harness-agnostic.md |  |
| TC-harness-agnostic-default-claude-resolved | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-codex-install-files | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-codex-symlink-content | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-pi-install-files | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-pi-symlink-content | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-multi-install-both-files | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-multi-install-canonical-edit-propagates | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-init-unknown-rejected | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-schema-unknown-rejected | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-codex-no-commands-dir | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-pi-commands-dir | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-pi-skill | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-bootstrap-no-subagent-files | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-bootstrap-prompts-inlined | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-migrate-cutover | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-migrate-bumps-version | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-migrate-rerun-noop | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-migrate-customized-subagent-warn | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-install-no-extra-toolchain | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-remove-harness-cleanup | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-remove-harness-preserves-authored | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-remove-claude-preserves-instructions | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-installer-names-harness-per-line | TC | qa/cli/harness-agnostic.md |  |  |
| TC-harness-agnostic-self-host-migrate-clean | TC | qa/cli/harness-agnostic.md |  |  |
| AC-lane-discipline-backstop-exit-status | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-backstop-nonblocking | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-default-catches-known | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-no-config-no-break | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-project-terms-applied | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-review-allows-legit | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-review-flags-structural | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-review-output-shape | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-review-suggests-terms | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| FR-lane-discipline-backstop-at-commit | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| FR-lane-discipline-default-terms | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-lanes.sh:56 |
| FR-lane-discipline-lexical-backstop | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-lanes.sh:56, scripts/lib/lane-scan.sh:56 |
| FR-lane-discipline-project-terms | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, pdeq.schema.json, qa/cli/lane-discipline.md | scripts/lib/lane-scan.sh:18 |
| FR-lane-discipline-review-in-workflow | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | pdeq-rules/commands/pdeq-kickoff.md:174 |
| FR-lane-discipline-severity | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | AGENTS.md:460 |
| FR-lane-discipline-structural-review | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | AGENTS.md:460 |
| FR-lane-discipline-structured-output | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | AGENTS.md:460 |
| FR-lane-discipline-taxonomy | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | AGENTS.md:460 |
| FR-lane-discipline-term-suggestions | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | AGENTS.md:460 |
| FR-lane-discipline-two-layer | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | pdeq-rules/commands/pdeq-kickoff.md:174 |
| NFR-lane-discipline-advisory-review | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| NFR-lane-discipline-backcompat | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| NFR-lane-discipline-deterministic-backstop | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| NFR-lane-discipline-nonblocking-backstop | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| TC-lane-discipline-defaults-fire | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-extend-not-replace | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-hook-warn-only | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-literal-escape | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-no-config-clean | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-no-pcre-grep | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-project-terms-fire | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-review-allows | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-review-structural | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-review-suggests | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-review-table | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-standalone-exit1 | TC | qa/cli/lane-discipline.md |  |  |
| FR-lane-discipline-update-seeds-config | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | migrations/0.5.0.md:8 |
| FR-lane-discipline-update-reviews-specs | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | migrations/0.5.0.md:8 |
| AC-lane-discipline-update-seed-idempotent | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-update-review-no-edit | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| TC-lane-discipline-update-seed-idempotent | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-update-review-no-edit | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-slug-not-flagged | TC | qa/cli/lane-discipline.md |  |  |
| FR-lane-guides-config | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md, pdeq.schema.json |  |
| FR-lane-guides-distinct-from-standing | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-framework-surfaces | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-harness-agnostic | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-installer-no-stub | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-installer-validates | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-missing-non-fatal | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-paths-relative-to-specsroot | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md, pdeq.schema.json |  |
| FR-lane-guides-per-lane-context | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-project-local | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-reinstall-reconciles | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-status-reports | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| FR-lane-guides-unknown-lane-rejected | FR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md, pdeq.schema.json |  |
| NFR-lane-guides-cheap-read | NFR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| NFR-lane-guides-no-new-deps | NFR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| NFR-lane-guides-survives-template-update | NFR | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-agent-reads | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-installer-no-stub | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-installer-warns | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-reinstall-reconciles | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-schema-accepts | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-schema-rejects-unknown | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-status-reports | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| AC-lane-guides-symlink-harness | AC | product/lane-guides.md | engineering/cli/lane-guides.md, qa/cli/lane-guides.md |  |
| TC-lane-guides-schema-accepts-valid | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-schema-accepts-omitted | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-schema-rejects-unknown-lane | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-schema-rejects-absolute-path | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-installer-warns-missing | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-installer-silent-present | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-installer-no-stub | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-framework-prose-present | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-agent-reads-conformance | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-symlink-harness-no-submodule-edit | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-status-reports-table | TC | qa/cli/lane-guides.md |  |  |
| TC-lane-guides-reinstall-add-then-remove | TC | qa/cli/lane-guides.md |  |  |
| FR-migrations-advisory-class | FR | product/migrations.md | engineering/cli/migrations.md, qa/cli/migrations.md | pdeq-rules/commands/pdeq-migrate.md:1 |
| AC-migrations-advisory-applied | AC | product/migrations.md | engineering/cli/migrations.md, qa/cli/migrations.md |  |
| AC-migrations-advisory-conformant | AC | product/migrations.md | engineering/cli/migrations.md, qa/cli/migrations.md |  |
| TC-migrations-advisory-applied | TC | qa/cli/migrations.md |  |  |
| TC-migrations-advisory-conformant | TC | qa/cli/migrations.md |  |  |
| AC-lane-discipline-content-clean-passes | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-content-construction-blocks | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-content-incidental-passes | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-content-platform-blocks | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-content-presentation-blocks | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-downstream-design-blocks | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-downstream-eng-blocks | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-escape-hatch-demotes | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| FR-lane-discipline-blocking-at-commit | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| FR-lane-discipline-blocking-enforcement | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-structure.sh:45 |
| FR-lane-discipline-blocking-escape-hatch | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-structure.sh:45 |
| FR-lane-discipline-content-class-check | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-structure.sh:57 |
| FR-lane-discipline-content-class-precision | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/lib/lane-scan.sh:56 |
| FR-lane-discipline-downstream-scan | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/audit-structure.sh:133 |
| NFR-lane-discipline-blocking-precision | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| NFR-lane-discipline-cross-lane-consistency | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-spec-structure-lane-context-loaded | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-no-remap-tooling | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-overlap-surfaced | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-presentation-routed | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-shared-neutral-flagged | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-triage-announced | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| AC-spec-structure-update-in-place | AC | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| FR-spec-structure-existing-scan | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md | pdeq-rules/commands/pdeq-kickoff.md:26 |
| FR-spec-structure-lane-context | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md | pdeq-rules/commands/pdeq-kickoff.md:81 |
| FR-spec-structure-manifestation-routing | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| FR-spec-structure-overlap-check | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| FR-spec-structure-shared-neutral | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md | AGENTS.md:118 |
| FR-spec-structure-triage-classification | FR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md | pdeq-rules/commands/pdeq-kickoff.md:26 |
| NFR-spec-structure-harness-neutral | NFR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| NFR-spec-structure-prevention-first | NFR | product/spec-structure.md | engineering/cli/spec-structure.md, qa/cli/spec-structure.md |  |
| TC-lane-discipline-content-clean | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-content-construction | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-content-incidental | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-content-platform | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-content-presentation | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-downstream-design | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-downstream-eng | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-escape-hatch | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-structure-hook-blocks | TC | qa/cli/lane-discipline.md |  |  |
| TC-spec-structure-lane-context | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-no-remap-tooling | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-overlap-surfaced | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-presentation-routed | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-shared-neutral | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-triage-announced | TC | qa/cli/spec-structure.md |  |  |
| TC-spec-structure-update-in-place | TC | qa/cli/spec-structure.md |  |  |
| FR-lane-discipline-exclude-terms | FR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md | scripts/lib/lane-scan.sh:56 |
| NFR-lane-discipline-exclude-surgical | NFR | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-exclude-passes | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-exclude-surgical | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| AC-lane-discipline-exclude-optional | AC | product/lane-discipline.md | engineering/cli/lane-discipline.md, qa/cli/lane-discipline.md |  |
| TC-lane-discipline-exclude-passes | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-exclude-surgical | TC | qa/cli/lane-discipline.md |  |  |
| TC-lane-discipline-exclude-optional | TC | qa/cli/lane-discipline.md |  |  |
| FR-conformance-actionable | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:73 |
| FR-conformance-advisory | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:132 |
| FR-conformance-complements | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:132 |
| FR-conformance-evidence | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:40 |
| FR-conformance-four-quadrant | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:57 |
| FR-conformance-fulfilled | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:57 |
| FR-conformance-incorrect | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:57 |
| FR-conformance-per-platform | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:17 |
| FR-conformance-requirement-scope | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:28 |
| FR-conformance-seeded | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:28 |
| FR-conformance-single-verdict | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:57 |
| FR-conformance-summary | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:73 |
| FR-conformance-temporal-specs | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:1, pdeq-rules/commands/pdeq-conform.md:40 |
| FR-conformance-undocumented | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:57 |
| FR-conformance-unfulfilled | FR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md | AGENTS.md:497, pdeq-rules/commands/pdeq-conform.md:57 |
| NFR-conformance-precision | NFR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| NFR-conformance-uncertainty | NFR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| NFR-conformance-verifiable | NFR | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-evidence-cited | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-exhaustive | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-incorrect-detected | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-no-plumbing | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-non-blocking | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-platform-isolation | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-report-shape | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-temporal-flagged | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-uncertainty-marked | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-undocumented-detected | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| AC-conformance-unfulfilled-behavioral | AC | product/conformance.md | engineering/cli/conformance.md, qa/cli/conformance.md |  |
| TC-conformance-actionable | TC | qa/cli/conformance.md |  |  |
| TC-conformance-complements-deterministic | TC | qa/cli/conformance.md |  |  |
| TC-conformance-evidence-cited | TC | qa/cli/conformance.md |  |  |
| TC-conformance-exhaustive | TC | qa/cli/conformance.md |  |  |
| TC-conformance-fulfilled-genuine | TC | qa/cli/conformance.md |  |  |
| TC-conformance-incorrect-detected | TC | qa/cli/conformance.md |  |  |
| TC-conformance-no-plumbing | TC | qa/cli/conformance.md |  |  |
| TC-conformance-non-blocking | TC | qa/cli/conformance.md |  |  |
| TC-conformance-platform-isolation | TC | qa/cli/conformance.md |  |  |
| TC-conformance-report-shape | TC | qa/cli/conformance.md |  |  |
| TC-conformance-scope-single-feature | TC | qa/cli/conformance.md |  |  |
| TC-conformance-seeded | TC | qa/cli/conformance.md |  |  |
| TC-conformance-summary | TC | qa/cli/conformance.md |  |  |
| TC-conformance-uncertainty-marked | TC | qa/cli/conformance.md |  |  |
| TC-conformance-undocumented-detected | TC | qa/cli/conformance.md |  |  |
| TC-conformance-unfulfilled-behavioral | TC | qa/cli/conformance.md |  |  |
| FR-living-spec-roadmap-supplements | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | roadmap/AGENTS.md:57 |
| FR-living-spec-roadmap-graduation | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | roadmap/AGENTS.md:95 |
| FR-living-spec-roadmap-slug-prefix | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | scripts/audit-traceability.sh:534, scripts/audit-traceability.sh:549, scripts/audit-traceability.sh:583 |
| FR-living-spec-multi-phase-roadmap | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | roadmap/AGENTS.md:57 |
| FR-living-spec-temporal-audit-patterns | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | scripts/audit-temporal.sh:2, scripts/audit-temporal.sh:27 |
| FR-living-spec-temporal-audit-modes | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | scripts/audit-temporal.sh:2 |
| FR-living-spec-temporal-audit-rewording | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | scripts/audit-temporal.sh:265 |
| FR-living-spec-temporal-audit-exemptions | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md | scripts/audit-temporal.sh:12 |
| FR-living-spec-kickoff-temporal-check | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| FR-living-spec-template-guidance | FR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| NFR-living-spec-deterministic-audit | NFR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| NFR-living-spec-low-noise | NFR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| NFR-living-spec-roadmap-lightweight-default | NFR | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-roadmap-spec-sections | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-roadmap-slugs-exempt | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-graduation-moves-content | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-temporal-patterns-detected | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-temporal-suggestions | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-temporal-in-kickoff | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-roadmap-not-scanned | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-template-has-guidance | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-exclude-removes-patterns | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-include-adds-patterns | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| AC-living-spec-patterns-full-replacement | AC | product/living-spec-discipline.md | engineering/cli/living-spec-discipline.md, qa/cli/living-spec-discipline.md |  |
| TC-living-spec-roadmap-frr-recognized | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-roadmap-slugs-no-warn | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-graduation-renumber | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-mvp-detected | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-phase-detected | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-v2-detected | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-future-detected | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-suggestion-format | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-kickoff-runs-audit | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-roadmap-exempt-scan | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-decisions-exempt | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-template-reminder | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-code-fence-flagged | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-config-fallback | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-check-mode-exit | TC | qa/cli/living-spec-discipline.md |  |  |
| TC-living-spec-staged-mode | TC | qa/cli/living-spec-discipline.md |  |  |
| FR-coverage-audit-code-signal | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:33 |
| FR-coverage-audit-feature-grouping | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:159 |
| FR-coverage-audit-status-check | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:159 |
| FR-coverage-audit-block | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:159 |
| FR-coverage-audit-terminal-statuses | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:159 |
| FR-coverage-audit-prose-skip | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | scripts/audit-coverage.py:78 |
| FR-coverage-audit-nfr-ac-best-effort | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | scripts/audit-coverage.py:159 |
| FR-coverage-audit-escape-hatch | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | pdeq-rules/commands/pdeq-coverage.md:1, scripts/audit-coverage.py:159 |
| FR-coverage-audit-reuse-parser | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | scripts/audit-coverage.py:78 |
| FR-coverage-audit-independent | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | .github/workflows/ci.yml:27, scripts/audit-coverage.sh:2 |
| FR-coverage-audit-reads-index | FR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md | scripts/audit-coverage.py:33 |
| NFR-coverage-audit-speed | NFR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| NFR-coverage-audit-determinism | NFR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| NFR-coverage-audit-precision | NFR | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-code-exists-no-coverage | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-code-exists-coverage-done | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-no-code-passes | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-prose-skipped | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-nfr-warns | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-escape-hatch | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-speed | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-deterministic-output | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| AC-coverage-audit-non-fr-ignored | AC | product/coverage-audit.md | engineering/cli/coverage-audit.md, qa/cli/coverage-audit.md |  |
| TC-coverage-audit-code-column-used | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-feature-grouping | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-code-exists-not-started | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-code-exists-pass | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-code-exists-fail | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-mixed-status | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-prose-row-skipped | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-nfr-warn | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-ac-warn | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-escape-hatch-active | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-escape-hatch-names-suppressed | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-qa-parser-shared | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-runs-independently | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-index-unchanged | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-missing-qa-file | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-malformed-index | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-multiple-platforms | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-under-2s | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-deterministic-two-runs | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-no-code-passes | TC | qa/cli/coverage-audit.md |  |  |
| TC-coverage-audit-non-fr-ignored | TC | qa/cli/coverage-audit.md |  |  |
| FR-project-orientation-file | FR | product/project-orientation.md | engineering/cli/project-orientation.md | scripts/init.sh:534, scripts/seed-project-md.sh:78 |
| FR-project-orientation-living | FR | product/project-orientation.md | engineering/cli/project-orientation.md | AGENTS.md:528 |
| FR-project-orientation-standing-spec | FR | product/project-orientation.md | engineering/cli/project-orientation.md | AGENTS.md:528 |
| FR-project-orientation-standing-manifest | FR | product/project-orientation.md | engineering/cli/project-orientation.md | pdeq-rules/commands/pdeq-kickoff.md:179 |
| FR-project-orientation-session-read | FR | product/project-orientation.md | engineering/cli/project-orientation.md | AGENTS.md:528 |
| FR-project-orientation-kickoff-maintains | FR | product/project-orientation.md | engineering/cli/project-orientation.md | pdeq-rules/commands/pdeq-kickoff.md:179 |
| FR-project-orientation-status-surfaces | FR | product/project-orientation.md | engineering/cli/project-orientation.md | pdeq-rules/commands/pdeq-status.md:36 |
| FR-project-orientation-migration-seeds | FR | product/project-orientation.md | engineering/cli/project-orientation.md | scripts/seed-project-md.sh:78 |
| FR-project-orientation-migration-pares | FR | product/project-orientation.md | engineering/cli/project-orientation.md | migrations/0.12.0.md:8 |
| NFR-project-orientation-no-new-folder | NFR | product/project-orientation.md | engineering/cli/project-orientation.md |  |
| NFR-project-orientation-cheap-read | NFR | product/project-orientation.md | engineering/cli/project-orientation.md |  |
| NFR-project-orientation-llm-maintained | NFR | product/project-orientation.md | engineering/cli/project-orientation.md | AGENTS.md:528 |
| AC-project-orientation-fresh-install | AC | product/project-orientation.md | engineering/cli/project-orientation.md | scripts/init.sh:534 |
| AC-project-orientation-migration-idempotent | AC | product/project-orientation.md | engineering/cli/project-orientation.md |  |
| AC-project-orientation-manifest-resolves | AC | product/project-orientation.md | engineering/cli/project-orientation.md |  |
| AC-project-orientation-kickoff-adds | AC | product/project-orientation.md | engineering/cli/project-orientation.md | pdeq-rules/commands/pdeq-kickoff.md:179 |
| AC-project-orientation-migration-consolidates | AC | product/project-orientation.md | engineering/cli/project-orientation.md |  |
| FR-implement-command | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | pdeq-rules/commands/pdeq-implement.md:1 |
| FR-implement-no-arg-default | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:200 |
| FR-implement-spec-diff-scope | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:139 |
| FR-implement-default-base | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:102 |
| FR-implement-base-options | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:102 |
| FR-implement-fallback-scope | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:159 |
| FR-implement-empty-scope | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:208 |
| FR-implement-single-pass-context | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:278 |
| FR-implement-changed-specs | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:278 |
| FR-implement-slug-inventory | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:214 |
| FR-implement-index-rows | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:236 |
| FR-implement-code-map | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:236 |
| FR-implement-current-code | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:239 |
| FR-implement-implements-requirements | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | pdeq-rules/commands/pdeq-implement.md:1 |
| FR-implement-runs-loop | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | pdeq-rules/commands/pdeq-implement.md:1 |
| FR-implement-audit-done-check | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | pdeq-rules/commands/pdeq-implement.md:1 |
| FR-implement-context-ephemeral | FR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | pdeq-rules/commands/pdeq-implement.md:1, scripts/implement-context.sh:278 |
| NFR-implement-determinism | NFR | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md | scripts/implement-context.sh:278 |
| AC-implement-no-arg-scope | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-default-base | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-base-option | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-fallback-scope | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-empty-scope | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-single-pass | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-markers-audit | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
| AC-implement-context-not-persisted | AC | product/implement.md | engineering/cli/implement.md, qa/cli/implement.md |  |
