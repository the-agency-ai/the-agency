---
boundary: phase-complete
phase: "5"
slug: "post-init-enhancements"
date: 2026-04-02 08:56
commit: pending
plan: monofolk-dispatch-incorporation
---

# Quality Gate Report — Monofolk Phase 5: Post-Init Enhancements

## Issues Found

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| — | — | No issues found | — |

## Phase 5 Sub-Items

| Item | Plan Requirement | Status |
|------|-----------------|--------|
| 5.1: Pluggable ref skills (preview, deploy, crawl-sites) | Create with provider-dispatch pattern | Created: 3 new skills |
| 5.2: workstream-create | Skill already exists | Verified present |
| 5.3: Boundary skill verification | Verify skills at boundary commands | Created: `skill-verify` tool, wired into quality-gate |
| 5.4: settings-merge | Tool already exists | Verified present |
| 5.5: Web content retrieval tools | Automated fallback tool | Created: `web-fetch` tool |

## New Artifacts

### Skills Created (3)
- `.claude/skills/preview/SKILL.md` — provider-dispatch to `preview-{provider}` tools
- `.claude/skills/deploy/SKILL.md` — provider-dispatch to `deploy-{provider}` tools
- `.claude/skills/crawl-sites/SKILL.md` — provider-dispatch to `crawl-{provider}` tools

### Tools Created (2)
- `agency/tools/skill-verify` — validates all skills have SKILL.md with allowed-tools frontmatter
- `agency/tools/web-fetch` — curl-based fetch with JS-heavy site detection and Playwright fallback guidance

### Config Updated
- `agency/config/agency.yaml` — added `preview`, `deploy`, `crawl` provider sections
- `.claude/settings.json` — added permissions for new tools (crawl-*, deploy-*, preview-*, settings-merge, skill-verify, web-fetch)
- `.claude/skills/quality-gate/SKILL.md` — added skill-verify precondition check (Step 0.2)

## Accountability

| Check | Result |
|-------|--------|
| skill-verify (40 skills) | All pass |
| Monofolk residue in new skills | Zero |
| Frontmatter (allowed-tools) on all new skills | Present |
| bash -n on new tools | Pass |
| jq validation (settings.json) | Valid |
| BATS tests (git-operations: 52) | All pass |
| BATS tests (config: 14) | All pass |
| BATS tests (findings: 25) | All pass |
| BATS tests (handoff-types: 8) | All pass |
| BATS tests (agency-init: 12) | All pass |

## Checks

- [x] 3 new provider-dispatch skills created (preview, deploy, crawl-sites)
- [x] All follow agency.yaml provider pattern (matches secret command pattern)
- [x] skill-verify tool validates all 40 skills
- [x] skill-verify wired into quality-gate Step 0.2 precondition
- [x] web-fetch tool with curl + JS-detection + Playwright fallback
- [x] agency.yaml updated with 3 new provider sections
- [x] settings.json permissions added for all new tools
- [x] Zero monofolk residue in new artifacts
- [x] All BATS tests pass
- [x] All shell syntax valid
