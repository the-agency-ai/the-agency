---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/devex
filed_by: jordan
date_filed: 2026-04-19
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/345
github_issue_number: 345
status: open
---

# test-monitor: mid-run critical-failure abort (v2 follow-on from PVR #180 Q5)

**Filed:** 2026-04-19T15:15:48Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#345](https://github.com/the-agency-ai/the-agency/issues/345)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

## Scope

Follow-on to PVR #180 (test-monitor) Q5 resolution. The v1 PVR decides mid-run interruption on critical failure is **out of scope** — runs complete, cascade noise is tolerable, agent reads results and decides.

This issue captures the two candidate mechanisms that were considered but deferred, so we don't lose the thinking when pain surfaces.

## Motivating scenarios

- Foundational test fails (e.g., BATS can't load helpers) → all subsequent tests report the same root cause as separate failures. Signal-to-noise collapses.
- Environment bug causes 200+ cascading identical failures. Agent reads 200 dispatches when 1 would do.
- Long-running suite (XCTest, large vitest run) where the first 30s of failures already tell the full story.

## Deferred options

### Option B — Agent-side `TaskStop` pattern

Document in A&D / reference doc: when the agent sees a failure pattern it classifies as foundational (e.g., the first N `FAIL` lines share a common root, or a specific \`[TEST ERROR]\` line fires), it MAY invoke \`TaskStop\` on the test-monitor task to abort the run.

- **Pros:** No tool change; agent decides based on context. Free capability (TaskStop already exists).
- **Cons:** Agent-specific heuristics; no shared convention for what 'foundational' means; doesn't work for programmatic consumers like \`/quality-gate\` that don't reason about failure semantics.

### Option C — Tool-side `--abort-on-foundational` flag

Add \`test-monitor --abort-on-foundational\` (or similar). Test-monitor classifies the failure pattern and sends SIGTERM to its child subprocess when a critical pattern is detected.

- **Pros:** Declarative, framework-aware, usable by automation (\`/quality-gate\`).
- **Cons:** 'Foundational' classification is framework-specific and error-prone (BATS has no concept; vitest has \`bail\`; XCTest doesn't). Needs per-framework heuristic or explicit user config.

## Recommended v2 approach

**Leverage native framework support where it exists:**
- **vitest** ships \`--bail\` — test-monitor adapter already has context, can pass through when appropriate.
- **BATS** has no native bail; would need a wrapper or config-driven \`abort_on\` pattern list.
- **XCTest** has no native bail; same.

Suggested: \`testing.suites.<name>.abort_on_critical: true | false | <pattern-list>\` in \`agency.yaml\`, with test-monitor consulting it per run.

## When to act

Revisit when:
- A real run produces >100 cascaded failures and the noise cost is concrete
- \`/quality-gate\` Step 8 latency is dominated by waiting for known-doomed runs
- An adopter files a bug about Monitor firehose from runaway failure cascades

Until then: deferred.

## Related

- PVR: \`claude/workstreams/devex/test-monitor-pvr-20260417.md\` — Q5 resolution
- Workstream: devex (author: the-agency/jordan/devex)

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-19:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/345
