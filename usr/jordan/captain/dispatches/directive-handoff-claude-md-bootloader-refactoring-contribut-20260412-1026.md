---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-12T02:26
status: created
priority: normal
subject: "HANDOFF: CLAUDE.md bootloader refactoring + contribution model rollout + CI rework — needed before Monday"
in_reply_to: null
---

# HANDOFF: CLAUDE.md bootloader refactoring + contribution model rollout + CI rework — needed before Monday

Captain to DevEx. This is a multi-task handoff for Saturday April 12. Captain and principal are focused on workshop course materials today. You run point on the following, captain reviews at each boundary.

## Priority 1: CLAUDE.md Bootloader Refactoring (NEW — hyper warp)

Seed: claude/workstreams/agency/seeds/seed-claude-md-bootloader-refactoring-20260412.md

READ THE SEED FIRST. It has the full plan.

Summary: Refactor claude/CLAUDE-THEAGENCY.md from a ~4000-word monolith into a ~200-300 word bootloader. Move all protocol details (QG, MAR, Valueflow, ISCP, git rules, etc.) into skills, reference docs, and ref-injector mappings. The mechanisms to do this already exist — hookify blocks violations, skills are discoverable via /, ref-injector provides context on demand. We just haven't used them to slim down the monolith.

Execution:
1. PVR (30 min)
2. A&D — for each section, verify skill + ref doc + ref-injector mapping exist. Create what is missing. (1 hr)
3. Plan (30 min)
4. Implement — mechanical extraction + skill creation + ref-injector updates + bootloader rewrite (2-3 hrs)
5. MAR — high-stakes review to verify nothing critical was lost (1 hr)
6. QG + PR

Autonomous triage on MAR findings. Only Collaborative items surface to captain.

## Priority 2: Contribution Model Rollout Tasks

These are pending items from the contribution-model three-ring rollout:

1. Send monofolk transition dispatch — Ring 2 / PR-only policy
   - Seed: claude/workstreams/agency/seeds/seed-contribution-model-three-rings-20260411.md
   - Dispatch to monofolk/captain explaining Ring 2 transition
2. Rework CI — new smoke-ubuntu + fork-pr-full-qg + sister-project-pr-gate workflows
   - Seed: same as above
   - Delete legacy tests.yml, create three new workflows
3. Move skill-validation and tool tests into commit-precheck
   - The root cause fix for the broken-window problem
4. Build claude/tools/ci-monitor — replaces email notifications
   - Monitor tool pattern (dispatch-monitor, changelog-monitor)
5. Create .claude/skills/monitor-ci/SKILL.md
6. Document how to disable GitHub email notifications (for jordan)
7. Document branch protection setup for main (to wire AFTER monofolk is informed)
8. Create CODE_OF_CONDUCT.md at repo root (Contributor Covenant 2.1)
9. Final commit + PR for the contribution model rollout (D36-R3)

Order: CLAUDE.md bootloader first (it affects everything), then contribution model items in the order above.

## Context you need

- Contribution model reference: claude/docs/CONTRIBUTION-MODEL.md (already written)
- CONTRIBUTING.md: already written at repo root
- PR template: .github/PULL_REQUEST_TEMPLATE.md (already written)
- agency.yaml: updated with full principal identity (email, github, platforms)
- Transcript: usr/jordan/captain/transcripts/contribution-model-three-rings-20260411.md

## Constraints

- Ship as PRs (always PR, never direct to main for framework changes)
- Captain reviews at each boundary (dispatch when you have something for review)
- Autonomous triage on MAR findings
- Needed before Monday workshop (13 April 2026)

— the-agency/jordan/captain
