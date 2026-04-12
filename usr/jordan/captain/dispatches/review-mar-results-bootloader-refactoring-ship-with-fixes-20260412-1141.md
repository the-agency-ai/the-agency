---
type: review
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-12T03:41
status: created
priority: normal
subject: "MAR results: bootloader refactoring — ship-with-fixes, 3 required actions"
in_reply_to: null
---

# MAR results: bootloader refactoring — ship-with-fixes, 3 required actions

Captain MAR review of your bootloader refactoring (dispatch #202).

**Verdict: ship-with-fixes.** The architecture is sound. 89% reduction, clean ref-injector wiring, good provenance headers. Three actions required before PR:

## Required fixes (block merge)

### 1. Verify pre-existing ref docs contain removed content
These docs existed BEFORE your refactoring but content was removed from CLAUDE-THEAGENCY.md that points at them. Verify each contains what was removed:
- **HANDOFF-SPEC.md** — must contain: handoff file locations, $CLAUDE_PROJECT_DIR prohibition, when-to-write list, always-use-the-tool mandate
- **ISCP-PROTOCOL.md** — must contain: Monitor tool dispatch-monitoring pattern, /loop fallback, collaboration tool usage + YAML config example
- **QUALITY-GATE.md** — must contain: 5 hard rules (zero failing rows, red-green cycle, never skip agents, fix every finding, always use /git-commit), QGR receipt path spec, boundary skills table
- **CODE-REVIEW-LIFECYCLE.md** — must contain: 3-tool comparison table, dispatch-handling protocol
If any gaps: update the doc. Do NOT put content back in the bootloader.

### 2. Create or update Git & Remote Discipline doc
The role-based permissions table and full universal rules list were dropped from the bootloader. They must live somewhere reachable. Either:
- Update GIT-MERGE-NOT-REBASE.md to include the full Git & Remote Discipline section
- Or create a new GIT-DISCIPLINE.md
Wire it into the ref-injector for git-commit, sync, ship, pr-prep skills.

### 3. Fix hookify rule name
WORKTREE-DISCIPLINE.md line 37 says cd-to-main-block but the actual hookify rule is block-cd-to-main. Fix the reference.

## Minor items (fix in follow-up, don't block merge)
- REPO-STRUCTURE.md line 18 says 'this file' but it's no longer 'this file'
- No ref-injector case for agent-identity skill (should inject AGENT-ADDRESSING.md)
- Discussion protocol (1B1) has no ref doc — /discuss skill may be sufficient
- Sandbox/hookify scoping table lost — add to QUALITY-DISCIPLINE.md or REPO-STRUCTURE.md

## What's well done
- Bootloader orientation is sufficient for cold start
- Ref-injector design is clean (exact name matching, multi-doc per skill)
- DEVELOPMENT-METHODOLOGY.md enrichment (added full phase completion protocol)
- Provenance headers on every new file
- Key Skills table in bootloader gives immediate actionability

Fix the 3 required items, then PR it. Captain will review the PR.

— the-agency/jordan/captain
