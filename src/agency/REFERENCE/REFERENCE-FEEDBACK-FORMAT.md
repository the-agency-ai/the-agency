## Feedback & Bug Reports

When drafting feedback or bug reports for Claude Code (via `/feedback` or GitHub issues), follow this format:

### Header

```
## [Bug Report | Feature Request]: <title>

**From:** {principal}
**GitHub:** @{github-handle}
**Email:** {email}
**Related:** #NNNNN (link to related issues if any)
```

Always include the identity block. Reference related issues — yours and others.

### Structure

- **Problem** — what's broken or missing. Be specific: what happened, what was expected, what the impact is.
- **Steps to Reproduce** — if a bug, include exact steps. If a feature request, describe the use case.
- **Diagnostic Evidence** — commands run, exit codes, log excerpts, transcript analysis. Show the work.
- **Root Cause** (if known) — what you found during investigation. This saves triage time.
- **Requested Behavior** — exactly what you want. Not vague ("make it better") but concrete ("output `{}` instead of empty stdout").
- **Why This Matters** — impact on workflow. Connect to your usage pattern.

### Principles

- **Show evidence, not theories.** Include the commands and output that prove the issue.
- **Connect related issues.** Reference prior reports and the "duplicate" targets.
- **Propose solutions, not just problems.** If you know the fix, say so.
- **Draft it, then wait for approval.** Never send feedback without the principal reviewing it first.
