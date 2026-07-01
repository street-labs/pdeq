# Security Policy

## Reporting a vulnerability

**Do not open a public pull request for a security issue** — and note that this repository's issue tracker is disabled.

Report vulnerabilities privately through GitHub's **[private vulnerability reporting](https://github.com/street-labs/pdeq/security/advisories/new)** (Security → Report a vulnerability). This opens a private advisory visible only to the maintainers.

Please include:

- A description of the vulnerability and its impact.
- Steps to reproduce (a minimal repro is ideal).
- Affected version(s) — see `VERSION` / the release tags.

We'll acknowledge the report, investigate, and coordinate a fix and disclosure with you.

## Scope

pdeq is a local, file-based framework (shell scripts, markdown, git). The most relevant classes of issue are: shell-injection or unsafe evaluation in `scripts/`, a pre-commit/commit-msg hook that can be tricked into destructive or unscoped writes, or a migration that writes outside its declared scope. Reports in these areas are especially welcome.
