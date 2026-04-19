---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-08
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/56
github_issue_number: 56
status: open
---

# agency update does not propagate new top-level YAML sections from agency.yaml

**Filed:** 2026-04-08T12:45:36Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#56](https://github.com/the-agency-ai/the-agency/issues/56)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

## Problem

`agency update` does not propagate new top-level YAML sections from the upstream `agency/config/agency.yaml` to downstream adopters. New config sections added in framework releases are invisible to existing installations; only the framework metadata (`updated_at`, `source_commit`) is bumped.

This is a real gap in the update path. A downstream adopter who runs `agency update` regularly will never receive new optional config schemas like `issues:`, `preview:`, `deploy:`, `crawl:`, `testing:`, and so on — even though the framework code that consumes those sections DOES land. The tools fall back to their hardcoded defaults instead of the adopter's opt-in config, and the adopter has no visible signal that new sections exist.

## Steps to Reproduce

1. Install the-agency in a project at framework commit `A`.
2. In the upstream framework, add a new top-level section to `agency/config/agency.yaml` at commit `B` (e.g., add `issues: { provider: "github", github: { target_repo: "owner/repo" } }`).
3. Merge `B` to main.
4. Run `agency update` in the downstream project.
5. Inspect `agency/config/agency.yaml` in the downstream.

**Expected:** the new `issues:` section appears in the downstream agency.yaml (with a commented-out hint that says "new section added by framework update X — review and customize").

**Actual:** the `issues:` section is missing. Only the `framework.updated_at` and `framework.source_commit` fields are changed.

## Diagnostic Evidence (2026-04-08 test)

Ran `agency update` on `~/code/presence-detect` (installed 2026-04-03 from commit `4d6f6683`). Source commit was `6cac2fa9` (Day 33 R2 merged into the-agency main, 5 days of framework evolution).

```
$ agency update
From:    2.0.0 (4d6f6683)
To:      2.0.0 (6cac2fa9)
Changes: +1085 ~66 -1
```

Verification that framework files propagated correctly:
- `agency/tools/agency-issue` → present ✅
- `agency/tools/release-plan` → present ✅
- `agency/tools/iscp-check` v1.1.0 → present ✅
- `agency/hookify/hookify.block-raw-rebase.md` → present ✅
- `agency/hookify/hookify.block-reset-to-origin.md` → present ✅
- `claude/docs/GIT-MERGE-NOT-REBASE.md` → present ✅
- `agency/CLAUDE-THEAGENCY.md` → updated ✅
- `.claude/skills/agency-issue/SKILL.md` → present ✅

But:

```
$ wc -l ~/code/presence-detect/agency/config/agency.yaml agency/config/agency.yaml
      43 /Users/jdm/code/presence-detect/agency/config/agency.yaml
     128 agency/config/agency.yaml
     171 total
```

**85 lines of config schema never propagated.** Checking specific sections:

```
$ grep -E "^(issues|preview|deploy|crawl|testing):" ~/code/presence-detect/agency/config/agency.yaml
(no output — none of these sections exist downstream)
```

The diff against prior HEAD of agency.yaml in presence-detect:

```diff
- framework.updated_at: "2026-04-03T13:06:30+00:00"
- framework.source_commit: "4d6f6683d12065dceafbeb5afef006f4c845b698"
+ framework.updated_at: "2026-04-08T12:34:57+00:00"
+ framework.source_commit: "6cac2fa9e7e293d415e397606f678f371b9c6f8a"
```

**Two lines changed.** The entire new-sections delta is lost.

## Root Cause (preliminary)

`agency/tools/lib/_agency-init` handles agency.yaml management. For existing installations, it only updates the `framework.*` metadata block (the "updated_at" and "source_commit" fields) and leaves the rest of the file untouched. This is the correct default — overwriting the whole file would destroy user customizations to existing sections.

But the correct behavior is a **three-way merge**, not a metadata-only update:

- **Preserve user-customized values** in existing sections (what it does today)
- **Add new top-level sections** from source that don't exist in target (what's missing)
- **Flag removed upstream sections** as orphaned for user review (what's missing)
- **Never silently modify** user values in existing sections without a migration note

The `settings-merge` tool already does this kind of additive merge for `.claude/settings.json` (it does an array union for permissions). The same pattern needs to apply to agency.yaml section additions.

## Requested Behavior

When `agency update` encounters a top-level YAML section in source that does not exist in target:

1. **Add the section** with all its default values
2. **Prepend a comment** that says something like `# Added by framework update on YYYY-MM-DD from commit SHA — review and customize as needed.`
3. **Report in the update summary** which new sections were added, so the adopter knows to review them
4. **Never modify** existing sections with user values

The implementation should live in `agency/tools/lib/_agency-init` or a new helper like `_yaml-merge`, and should be idempotent (re-running update doesn't re-add or duplicate sections).

## Why This Matters

This gap means every new optional config schema we ship in the framework requires downstream adopters to manually patch their agency.yaml to opt in. The tools that consume those sections fall back to hardcoded defaults instead — which means:

- `issues:` section → `agency-issue` tool defaults to `the-agency-ai/the-agency` instead of the adopter's chosen repo
- `preview:` / `deploy:` sections → Preview/deploy providers default instead of adopter's choice
- `crawl:` section → Crawl provider can't be overridden
- `testing:` section → Test runner never knows about adopter's custom suites

We hit this during the 2026-04-08 agency-update test on a real downstream project. The update succeeded in every other dimension (1085 files propagated, 66 updated, hookify rules activated, merge-not-rebase discipline applied, all verify checks pass), but the YAML schema migration gap was immediately visible on the first update.

## Related

- Found during: 2026-04-08 agency-update test on `~/code/presence-detect` (installed 2026-04-03 at commit 4d6f6683, updated to commit 6cac2fa9 in this session)
- Related tool: `agency/tools/lib/_agency-init`
- Related pattern: `settings-merge` does the right thing for `.claude/settings.json`
- Sibling pattern: the Claude Code `settings.json` merge logic that unions arrays rather than overwriting
- Local report: `usr/jordan/reports/report-agency-issue-*-20260408.md` (written by the filing)

## Acceptance

- New sections added to upstream `agency.yaml` appear in downstream `agency.yaml` after `agency update`
- Existing sections in downstream are never modified
- Added sections carry a comment identifying the update that brought them in
- Summary of `agency update` reports new sections added
- Idempotent: re-running update does not duplicate or re-add

## Note

This issue will be fixed tomorrow. The bug was caught today during the first real agency-update test from the-agency R2. The principal chose to file it now (dogfooding `agency-issue` itself) and patch it tomorrow morning as the first real use of the bug-report → fix → close cycle.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-08:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/56
