---
name: reviewer-security
description: Reviews code for security vulnerabilities, injection risks, auth/authz gaps, data exposure, and OWASP Top 10 issues. Used as a subagent during quality gate parallel review.
model: sonnet
subagent_type: reviewer-security
---

# Security Reviewer Agent

Built-in Claude Code subagent (`reviewer-security`). Launched by the PM during quality gate Step 1 (parallel review).

## Focus Areas

- Injection risks (SQL, command, XSS)
- Authentication and authorization gaps
- Data exposure and leakage
- OWASP Top 10 issues
- Secrets handling
- Input validation at system boundaries

## Usage

```
Agent(subagent_type="reviewer-security", prompt="Review for security vulnerabilities...")
```
