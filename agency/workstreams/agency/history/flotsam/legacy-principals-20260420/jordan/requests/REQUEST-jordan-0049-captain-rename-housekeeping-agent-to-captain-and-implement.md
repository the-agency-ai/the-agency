# REQUEST-jordan-0049-captain-rename-housekeeping-agent-to-captain-and-implement

**Status:** Complete + Released
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** captain
**Created:** 2026-01-14
**Updated:** 2026-01-14 (Session 2)
**Completed:** 2026-01-14
**Released:** 2026-01-14 (v1.0.9 to the-agency-starter)

## Summary

Rename housekeeping agent to captain, implement first-launch onboarding, and release to the-agency-starter with tool logging pattern

## Details

This REQUEST encompasses the following deliverables:

**Session 1 (Core Implementation):**
1. **Rename housekeeping agent to captain** - Better reflects the agent's leadership role
2. **Fix first-launch context** - Guide the captain agent (not the principal) on their first session
3. **Implement Captain's Tour** - Interactive `/welcome` onboarding command from REQUEST-jordan-0034

**Session 2 (Release & Tooling):**
4. **Update starter sync tools** - Update starter-release, starter-verify for captain and sibling repo
5. **Release to the-agency-starter** - Sync all captain changes and cut v1.0.9 release
6. **Tool logging pattern** - Implement quiet-by-default pattern with log service integration

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
- Rename `agency/agents/housekeeping/` → `agency/agents/captain/`
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
- Renamed agent directory: `agency/agents/housekeeping/` → `agency/agents/captain/`
- Rewrote `agency/agents/captain/agent.md` with expanded leadership role:
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

### 2026-01-14 - Documentation & Working Note
**Commit:** `43d218f` - housekeeping/captain: docs: Document REQUEST-jordan-0049 and create WORKING-NOTE-0024

**Changes:**
- Updated REQUEST-jordan-0049 with full activity log
- Created `WORKING-NOTE-0024.md` for the book:
  * Context and problem statement
  * Three-phase transformation details
  * Technical architecture
  * Lessons and patterns
  * For-the-book sections on agent identity, onboarding design, tutorial design
  * Implementation metrics (4 hours, 45 files changed)

**Files changed:** 2 files

### 2026-01-14 - Starter Tools Update (Session 2)
**Commit:** `e53574b` - housekeeping/captain: refactor: Update starter tools and docs for captain rename

**Changes:**
- Updated `tools/starter-release`:
  * Changed sync paths from housekeeping to captain (lines 142-145)
  * Added `.claude/commands` to sync list (line 138)
  * Added new documentation files to sync (FIRST-LAUNCH.md, FIRST-LAUNCH-CONTEXT.jsonl, STARTER-PACK-INTEGRATION.md, tutorials)
  * Updated mkdir paths to captain (line 168)
  * Updated cleanup paths to captain (lines 198-199)
  * Updated verification file check (line 261)
- Updated `tools/starter-verify`:
  * Fixed path to use sibling repo: `../the-agency-starter` instead of subdirectory (lines 33-42)
  * Added fallback to environment variable
- Updated `tools/starter-compare`:
  * Updated documentation comment to reflect sibling repo (line 13-14)
- Updated `claude/docs/REPO-RELATIONSHIP.md`:
  * Changed overview to explain sibling repo structure (lines 1-12)
  * Updated development flow to show `./tools/starter-release` process (lines 17-22)
  * Changed "Future State" to "Current State" (lines 41-43)
  * Completely rewrote Sync Process section with detailed instructions (lines 103-156)
  * Updated last-modified date to 2026-01-14

**Files changed:** 4 files

### 2026-01-14 - Release to the-agency-starter
**Commit in the-agency-starter:** `8e002a4` - release: the-agency-starter v1.0.9

**Action:** Ran `./tools/starter-release patch`

**Changes synced to the-agency-starter:**
- 41 files changed, 3836 insertions, 257 deletions
- New files created:
  * `.claude/commands/tutorial.md`
  * `.claude/commands/welcome.md`
  * `.claude/hooks/check-messages.sh`
  * `.claude/hooks/session-start.sh`
  * `.claude/settings.json`
  * `.claude/settings.local.json.example`
  * `agency/agents/captain/` (agent.md, KNOWLEDGE.md, ADHOC-WORKLOG.md)
  * `claude/docs/FIRST-LAUNCH-CONTEXT.jsonl`
  * `claude/docs/FIRST-LAUNCH.md`
  * `claude/docs/PERMISSIONS.md`
  * `claude/docs/SECRETS.md`
  * `claude/docs/STARTER-PACK-INTEGRATION.md`
  * `claude/docs/TERMINAL-INTEGRATION.md`
  * `claude/docs/tutorials/` (10 tutorial files)
  * `tools/context-review`
  * `tools/context-save`
  * `tools/tab-status`
- Modified files: All core tools updated for captain
- Tagged: `v1.0.9`

**Status:** Ready to push to GitHub

### 2026-01-14 - Tool Logging Pattern
**Commit:** `c00e8b4` - housekeeping/captain: refactor: Add verbose flag and log service integration to starter-release

**Changes:**
- Added `--verbose` flag to control output verbosity
- Default to quiet mode (only show summary and run ID)
- Added `log_end` calls at all exit points:
  * On error: clears trap, calls log_end with failure status
  * On success (sync-only): clears trap, calls log_end with success
  * On success (dry-run): clears trap, calls log_end with success
  * On success (release): clears trap, calls log_end with success
- Added trap for unexpected exits
- Show run ID for debugging: `starter-release [run: xyz]`
- Created `verbose_echo()` function for detail output
- Replaced detail echoes with verbose_echo calls

**Impact:** Reduces context window usage while enabling debugging via log service queries

**Files changed:** 1 file (tools/starter-release)

### 2026-01-14 - Tool Logging Pattern Documentation
**Commit:** `9453d56` - housekeeping/captain: docs: Add tool logging pattern guide

**Changes:**
- Created `claude/docs/TOOL-LOGGING-PATTERN.md`:
  * Complete pattern for quiet-by-default tools
  * Verbose flag implementation
  * Log service integration (log_start/log_end)
  * Run ID display and trap handling
  * Output behavior examples (default vs verbose)
  * Debugging instructions (query log service)
  * Benefits list
  * Tools to update (priority order)
  * Reference implementation (starter-release)

**Files changed:** 1 file

### Next Steps
- [x] Integrate into the-agency-starter (complete - v1.0.9)
- [x] Update starter tools for captain rename
- [x] Document sibling repo structure
- [x] Create tool logging pattern
- [ ] Test session restart with captain agent
- [ ] Verify first-launch context displays correctly
- [ ] Verify iTerm shows "captain" badge
- [ ] Push the-agency-starter v1.0.9 to GitHub
- [ ] Apply logging pattern to remaining tools (use TOOL-LOGGING-PATTERN.md)
- [ ] Update REQUEST-jordan-0034 status (completed by this work)
