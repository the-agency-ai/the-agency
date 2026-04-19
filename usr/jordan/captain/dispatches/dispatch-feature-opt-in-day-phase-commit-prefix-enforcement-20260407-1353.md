---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:53
status: created
priority: normal
subject: "FEATURE: opt-in Day/Phase commit prefix enforcement"
in_reply_to: null
---

# FEATURE: opt-in Day/Phase commit prefix enforcement

## Background

We just documented the Day-PR release pattern (in README-THEAGENCY.md). Part of that pattern is that commits lead with `Day N:` or `Phase X.Y:` slug. Today it's prose convention — agents follow it inconsistently.

Jordan wants mechanical enforcement, but **opt-in at the project level**. Projects can enable it if they follow the day-counting convention, or leave it off if they don't.

## What To Build

### 1. Config option in agency.yaml

Add a section for commit conventions:

```yaml
commits:
  require_day_prefix: false  # default: false — opt-in
  # When true, commit-precheck rejects commits whose first line
  # doesn't match: ^(Day \d+|Phase \d+(\.\d+|\.M\d+)?|Merge ):
```

Default is `false` so enabling it is deliberate per project.

### 2. commit-precheck check

Add a check to `agency/tools/commit-precheck`:

- Read `commits.require_day_prefix` from `agency/config/agency.yaml`
- If true, validate the commit message first line against the regex
- Allow: `Day N:`, `Phase X.Y:`, `Phase X.MN:`, `Merge ` (any merge commit)
- Block with actionable message if doesn't match, showing:
  - The failing first line
  - The expected patterns
  - How to fix (rewrite the message)

Block message should be pedagogical — this is a *helper*, not a gotcha.

### 3. Documentation update

Update the Day-PR Release Pattern section in README-THEAGENCY.md to note the opt-in mechanism. Something like:

> Projects can enable mechanical enforcement of the Day/Phase prefix by setting `commits.require_day_prefix: true` in `agency/config/agency.yaml`. Defaults to off.

And reference it in README-ENFORCEMENT.md under the commit-precheck section.

## Edge Cases

- **Merge commits** — allow unconditionally (they start with `Merge`)
- **Multi-line commit messages** — only check the first line
- **Amending commits** — same check applies
- **Revert commits** — `Revert "Day 32: foo"` — should pass (it starts with Revert but contains Day 32)
  - Decision: allow `^Revert ` unconditionally OR require the revert to preserve the original prefix
  - Recommendation: allow `^Revert ` unconditionally (simpler, less likely to fight git)

## Plan Mode (per #111)

Investigate:
- How does commit-precheck currently read config? Is there a shared config loader in `_log-helper` or similar?
- What other feature flags exist in agency.yaml today? Match their style.
- Is there a test harness for commit-precheck? Add tests for the new check.
- How does this interact with /git-safe-commit (which wraps commit-precheck)?

Present a plan before implementing. This is your 6th dispatch (#109, #110, #111, #114, #118, #120, this one). Plan mode required.

## Reference

- Day-PR pattern doc: agency/README-THEAGENCY.md — 'The Day-PR Release Pattern' section
- commit-precheck: agency/tools/commit-precheck
- Similar SPEC patterns: preview.provider, deploy.provider, secrets.provider in agency.yaml
