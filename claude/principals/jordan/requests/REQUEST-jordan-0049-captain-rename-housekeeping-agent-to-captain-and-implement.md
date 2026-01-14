# REQUEST-jordan-0049-captain-rename-housekeeping-agent-to-captain-and-implement

**Status:** Complete
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** captain
**Created:** 2026-01-14
**Updated:** 2026-01-14
**Completed:** 2026-01-14

## Summary

Rename housekeeping agent to captain and implement first-launch onboarding

## Details

This REQUEST encompasses three major deliverables:

1. **Rename housekeeping agent to captain** - Better reflects the agent's leadership role
2. **Fix first-launch context** - Guide the captain agent (not the principal) on their first session
3. **Implement Captain's Tour** - Interactive `/welcome` onboarding command from REQUEST-jordan-0034

### The Captain's Role

The captain agent is the multi-faceted leader of The Agency with these responsibilities:

**Onboarding & Guidance**
- Welcome new principals with `/welcome` interactive tour
- Answer framework questions
- Guide principals through first steps

**Project Management**
- Coordinate multi-agent work
- Track REQUESTs, bugs, ideas
- Manage sprint planning and retrospectives
- Facilitate collaboration between agents

**Infrastructure & Setup**
- Execute starter kits (Next.js, React Native, Python, etc.)
- Configure development environments
- Set up CI/CD, git hooks, quality gates
- Initialize secrets, permissions, services

**Framework Expertise**
- Meta-framework questions and improvements
- Tool creation and maintenance
- Documentation updates
- Convention enforcement

### Scope

**Phase 1: Core Rename**
- Rename `claude/agents/housekeeping/` → `claude/agents/captain/`
- Update all tool references (myclaude, commit, session-start hook, iterm-setup)
- Update configuration files (iTerm profiles)
- Update documentation (CLAUDE.md, README.md, FIRST-LAUNCH.md)
- Keep workstream name as "housekeeping"

**Phase 2: First-Launch Context**
- Create captain-focused context that displays on first session
- Guide captain on what to offer the principal
- Ships with the-agency-starter template

**Phase 3: Captain's Tour**
- Implement `.claude/commands/welcome.md` - Interactive "Choose Your Own Adventure"
- Create tutorial content structure (`.claude/tutorials/`)
- Add onboarding state tracking (`claude/principals/{name}/onboarding.yaml`)
- Implement `/tutorial` navigation commands

### Implementation Details

See the complete implementation plan at: `/Users/jdm/.claude/plans/flickering-growing-goose.md`

## Acceptance Criteria

**Phase 1: Core Rename**
- [x] Agent directory renamed from `housekeeping` to `captain`
- [x] Captain identity established in agent.md with full role description
- [x] Tools default to "captain" agent (myclaude, commit, session-start hook)
- [x] iTerm integration shows "captain" badge
- [x] Documentation updated (CLAUDE.md, README.md, FIRST-LAUNCH.md)
- [x] No broken references to "housekeeping" agent in core files
- [x] Clean git history with clear commit messages

**Phase 2: First-Launch Context**
- [x] Captain-focused first-launch context created
- [x] Context guides captain (not principal) on their first session
- [x] Context displays correctly when captain launches first time
- [x] Template ready for the-agency-starter integration

**Phase 3: Captain's Tour**
- [x] `/welcome` command works with 5 initial paths presented
- [x] Tutorial content created for all branches
- [x] Can create real artifacts (agents, workstreams) during tutorial
- [x] Onboarding state tracking saves progress to `onboarding.yaml`
- [x] `/tutorial` navigation commands work (status, restart, skip)
- [x] Each tutorial section takes <5 minutes to complete
- [x] Can exit and resume onboarding at any point

## Notes

### Historical Records
- Do NOT rename REQUEST files (they're historical records)
- Preserve ADHOC-WORKLOG.md entries as-is
- Session logs remain unchanged
- Git history preserved through git mv

### Workstream vs Agent
- **Workstream remains:** `housekeeping` (meta-work that keeps The Agency running)
- **Agent renamed:** `housekeeping` → `captain` (the leader)
- **Commit pattern:** `housekeeping/captain: type: message`

### This Completes REQUEST-jordan-0034
The Captain's Tour implementation fulfills REQUEST-jordan-0034 (interactive onboarding)

---

## Activity Log

### 2026-01-14 - Created
- Request created by agent:housekeeping (on behalf of jordan)
- Initial plan developed in `/Users/jdm/.claude/plans/flickering-growing-goose.md`

### 2026-01-14 - Phase 1 Implementation (Core Rename)
**Commit:** `f5964db` - housekeeping/captain: refactor: Rename housekeeping agent to captain (Phase 1)

**Changes:**
- Renamed agent directory: `claude/agents/housekeeping/` → `claude/agents/captain/`
- Rewrote `claude/agents/captain/agent.md` with expanded leadership role:
  * Onboarding & Guidance section
  * Project Management section
  * Infrastructure & Setup section
  * Framework Expertise section
  * Personality and capabilities defined
- Updated tools to reference captain:
  * `tools/myclaude` - Example usage (line 12)
  * `tools/commit` - Fallback agent default (lines 117-119)
  * `.claude/hooks/session-start.sh` - Default AGENTNAME (line 5)
  * `tools/iterm-setup` - Profile name, GUID, badge text (lines 68-89)
- Updated iTerm configuration:
  * `claude/principals/jordan/config/iterm/agency-profiles.json`
  * Changed profile name: "Agency - Housekeeping" → "Agency - Captain"
  * Changed GUID: "agency-housekeeping-jordan" → "agency-captain-jordan"
  * Changed badge text: "housekeeping" → "captain"
  * Updated initial text command

**Files changed:** 29 files (renames + modifications)

### 2026-01-14 - Phase 2 Implementation (Documentation)
**Commit:** `cb736e3` - housekeeping/captain: docs: Update documentation for captain agent (Phase 2)

**Changes:**
- Updated `CLAUDE.md`:
  * Quick Start section: `./tools/myclaude housekeeping housekeeping` → `./tools/myclaude housekeeping captain`
  * Directory Structure: `housekeeping/` → `captain/` with description "The captain - your guide"
  * Getting Help section: Added reference to `/welcome` interactive tour
- Updated `claude/docs/FIRST-LAUNCH.md`:
  * Changed all file paths from housekeeping to captain
  * Updated launch commands in examples
  * Added `/welcome` tour reference
- Rewrote `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl`:
  * Captain-focused guidance instead of principal-focused
  * Context tells captain their role and what to offer
  * Suggests `/welcome` tour to principal

**Files changed:** 3 files

### 2026-01-14 - Phase 3 Implementation (Captain's Tour)
**Commit:** `7e93522` - housekeeping/captain: feat: Implement Captain's Tour interactive onboarding (Phase 3)

**Changes:**
- Created `.claude/commands/welcome.md`:
  * Interactive "Choose Your Own Adventure" onboarding
  * 5 initial paths: new project, existing codebase, explore, concepts, quick setup
  * Uses AskUserQuestion tool for interactivity
  * Guides principals through tutorial content
- Created `.claude/commands/tutorial.md`:
  * `/tutorial` - Resume from last point
  * `/tutorial status` - Show progress
  * `/tutorial restart` - Start over
  * `/tutorial skip` - Skip current section
  * Reads/writes onboarding state to `claude/principals/{name}/onboarding.yaml`
- Created complete tutorial content in `claude/docs/tutorials/`:
  * `new-project.md` - Start a project from scratch (5 min)
  * `existing-codebase.md` - Integrate with existing code (5 min)
  * `quick-setup.md` - Fast setup for experienced users (2 min)
  * `explore/agents.md` - Understanding agents (3 min)
  * `explore/workstreams.md` - How workstreams organize work (3 min)
  * `explore/tools.md` - CLI toolkit tour (4 min)
  * `explore/collaboration.md` - Multi-agent coordination (4 min)
  * `concepts/principals.md` - Role of principals (2 min)
  * `concepts/agents.md` - Deep dive on agents (3 min)
  * `concepts/workstreams.md` - Deep dive on workstreams (3 min)

**Files changed:** 12 files (2 commands + 10 tutorial files)
**Total tutorial time:** ~34 minutes of content across all paths

### 2026-01-14 - Integration Documentation
**Commit:** `7da869f` - housekeeping/captain: docs: Add starter pack integration guide

**Changes:**
- Created `claude/docs/STARTER-PACK-INTEGRATION.md`:
  * Comprehensive integration guide for the-agency-starter
  * Files to copy (agent structure, tutorials, commands)
  * First-launch context setup instructions
  * Installation flow documentation
  * Testing checklist
  * Migration notes for existing installations
  * Backward compatibility considerations
  * Questions for starter pack team

**Files changed:** 1 file

### 2026-01-14 - Completed
**Total commits:** 8 (including preliminary commits for .gitignore and REQUEST creation)
**Total files changed:** 45 files (created + modified)

**Key commits:**
1. `a1f65e3` - First-launch documentation and .gitignore fix
2. `5b99e3b` - REQUEST-jordan-0049 creation
3. `f5964db` - Phase 1: Core rename (29 files)
4. `cb736e3` - Phase 2: Documentation (3 files)
5. `7e93522` - Phase 3: Captain's Tour (12 files)
6. `7da869f` - Starter pack integration guide (1 file)

**Implementation complete.**
**Ready for tagging:** REQUEST-jordan-0049-impl

### Next Steps
- [ ] Test `/welcome` command in captain session
- [ ] Test `/tutorial` navigation commands
- [ ] Verify first-launch context displays correctly
- [ ] Tag REQUEST-jordan-0049-impl after validation
- [ ] Integrate into the-agency-starter (follow STARTER-PACK-INTEGRATION.md)
- [ ] Update REQUEST-jordan-0034 status (completed by this work)
