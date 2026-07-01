# Layer 2 evidence — Lane Reviewer over the coffee-shop auth spec

This is the recorded output of running the **Lane Reviewer** contract (root
`AGENTS.md` §"Quality Subagents" → Lane Reviewer) against the seeded coffee-shop
`product/auth.md` used by `regression-coffee-auth.sh`. It is the companion to the
deterministic Layer 1 run in that script, and together they are the regression
proof for `PDEQ-qfnojetv`: **Layer 1 (no config) reports zero findings on this
spec; Layer 2 flags the bleed structurally.** Line numbers reference the seeded
`product/auth.md` in `regression-coffee-auth.sh`.

## Findings

| File | Line | Flagged text | Category | Severity | Suggested rewording |
|---|---|---|---|---|---|
| product/auth.md | 4 | "exercised from a command-line host today, before any mobile UI exists" | Host / platform as product | allowed: overview context | (keep) orientation prose, not a requirement — names the host to set context |
| product/auth.md | 10 | "authenticates the customer with Square" | Vendor names | violation | "authenticates the customer with the payment provider" |
| product/auth.md | 10 | "via an OAuth authorization code exchange" | Protocol / algorithm names | violation | "by delegating sign-in to the provider and completing the returned authorization" |
| product/auth.md | 11 | "validating a CSRF state parameter" | Protocol / algorithm names | violation | "verifying the sign-in response corresponds to the request the customer started" |
| product/auth.md | 11 | "stores the access token and refresh token" | Implementation mechanisms | violation | "keeps the customer signed in across sessions until they sign out" |
| product/auth.md | 13 | "Subsequent CLI invocations reuse the stored token" | Host / platform as product | violation | "once signed in, the customer stays signed in on that device without re-entering credentials" |
| product/auth.md | 14 | "The customer runs `coffee auth login` … `coffee auth status`" | Concrete surfaces (command names) | violation | "the customer can start sign-in and check their sign-in status" |
| product/auth.md | 18 | "A command-line host stores the tokens locally with platform-appropriate protection" | Host / platform as product | allowed: per-host NFR constraint | (keep) a non-functional, per-host storage-security constraint legitimately scoped to one host |
| product/auth.md | 22 | "exits non-zero on failure" | Concrete surfaces (exit code) | violation | "reports failure to the customer and does not sign them in" |

## Suggested `laneAudit` additions

These concrete vendor/protocol words appear in the spec and the project's current
`pdeq.json` has no `laneAudit`, so the deterministic backstop misses them. Adding
them makes Layer 1 catch the *lexical* leaks on the next commit:

```jsonc
"laneAudit": {
  "vendors":   ["Square"],
  "protocols": ["OAuth", "CSRF", "PKCE"]
}
```

(`regression-coffee-auth.sh` test 2 confirms that with `vendors:["Square"]` and
`protocols:["OAuth"]` configured, Layer 1 then flags those two lines — closing the
lexical half. The purely structural findings above — "subsequent CLI invocations",
"exits non-zero", the command surface — remain catchable only by Layer 2.)

## Why Layer 1 alone was insufficient

Run against this spec with no `laneAudit`, `audit-lanes.sh` reports
**"No lane discipline violations found"** — none of `Square`, `OAuth`,
`authorization code exchange`, `CSRF`, `CLI`, `coffee auth login`, or
`exits non-zero` is in the built-in default term list. A keyword scan cannot flag
a protocol described in words it does not know, nor a host treated as the product,
nor a command surface. That is the structural bleed the Lane Reviewer catches by
reasoning about the text — the concrete demonstration that the two layers are
complementary.
