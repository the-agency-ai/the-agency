---
type: commit
from: the-agency/jordan/fix-agent-imports
to: the-agency/jordan/captain
date: 2026-08-13T07:18
status: created
priority: normal
subject: "Committed 43cf658d on fix-agent-imports: fix(agents): repair broken @claude/ imports in agent registrations → @agency/ (flag #246)

Every .claude/agents/jordan/*.md registration (+ src mirrors) imported
@claude/agents/<class>/agent.md and @claude/workstreams/<ws>/CLAUDE-*.md, but
claude/ was renamed to agency/ long ago. So agents loaded their frontmatter
(name/description/model — enough to be an available subagent type) but NOT their
class definition or workstream context on startup. Silent context degradation
fleet-wide. Swept @claude/ → @agency/ across 18 files; resolvable targets
(captain/tech-lead classes, devex/iscp/mdpal/mock-and-mark workstream fragments)
now load.

Guard test: new skill-validation test asserts no registration imports the
pre-Rename @claude/ prefix.

Scope: prefix-only. The 2 workstream fragments designex/mdslidepal genuinely
don't exist, and several @usr/jordan/<agent>/CLAUDE-*.md per-agent docs were
never created — a content gap, not rename rot, flagged separately (#248)."
in_reply_to: null
---

# Committed 43cf658d on fix-agent-imports: fix(agents): repair broken @claude/ imports in agent registrations → @agency/ (flag #246)

Every .claude/agents/jordan/*.md registration (+ src mirrors) imported
@claude/agents/<class>/agent.md and @claude/workstreams/<ws>/CLAUDE-*.md, but
claude/ was renamed to agency/ long ago. So agents loaded their frontmatter
(name/description/model — enough to be an available subagent type) but NOT their
class definition or workstream context on startup. Silent context degradation
fleet-wide. Swept @claude/ → @agency/ across 18 files; resolvable targets
(captain/tech-lead classes, devex/iscp/mdpal/mock-and-mark workstream fragments)
now load.

Guard test: new skill-validation test asserts no registration imports the
pre-Rename @claude/ prefix.

Scope: prefix-only. The 2 workstream fragments designex/mdslidepal genuinely
don't exist, and several @usr/jordan/<agent>/CLAUDE-*.md per-agent docs were
never created — a content gap, not rename rot, flagged separately (#248).

## Commit: 43cf658d

**Branch:** fix-agent-imports
**Agent:** the-agency/jordan/fix-agent-imports
**Message:** housekeeping/captain: fix(agents): repair broken @claude/ imports in agent registrations → @agency/ (flag #246)

Every .claude/agents/jordan/*.md registration (+ src mirrors) imported
@claude/agents/<class>/agent.md and @claude/workstreams/<ws>/CLAUDE-*.md, but
claude/ was renamed to agency/ long ago. So agents loaded their frontmatter
(name/description/model — enough to be an available subagent type) but NOT their
class definition or workstream context on startup. Silent context degradation
fleet-wide. Swept @claude/ → @agency/ across 18 files; resolvable targets
(captain/tech-lead classes, devex/iscp/mdpal/mock-and-mark workstream fragments)
now load.

Guard test: new skill-validation test asserts no registration imports the
pre-Rename @claude/ prefix.

Scope: prefix-only. The 2 workstream fragments designex/mdslidepal genuinely
don't exist, and several @usr/jordan/<agent>/CLAUDE-*.md per-agent docs were
never created — a content gap, not rename rot, flagged separately (#248).

### Metadata
- commit_hash: 43cf658d
- branch: fix-agent-imports
- files_changed: 19
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/agents/jordan/captain.md
.claude/agents/jordan/designex.md
.claude/agents/jordan/devex.md
.claude/agents/jordan/iscp.md
.claude/agents/jordan/mdpal-app.md
.claude/agents/jordan/mdpal-cli.md
.claude/agents/jordan/mdslidepal-mac.md
.claude/agents/jordan/mdslidepal-web.md
.claude/agents/jordan/mock-and-mark.md
src/claude/agents/jordan/captain.md
src/claude/agents/jordan/designex.md
src/claude/agents/jordan/devex.md
src/claude/agents/jordan/iscp.md
src/claude/agents/jordan/mdpal-app.md
src/claude/agents/jordan/mdpal-cli.md
src/claude/agents/jordan/mdslidepal-mac.md
src/claude/agents/jordan/mdslidepal-web.md
src/claude/agents/jordan/mock-and-mark.md
src/tests/skills/skill-validation.bats
```
