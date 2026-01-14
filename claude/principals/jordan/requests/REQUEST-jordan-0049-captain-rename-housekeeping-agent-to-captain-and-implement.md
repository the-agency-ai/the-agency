# REQUEST-jordan-0049-captain-rename-housekeeping-agent-to-captain-and-implement

**Status:** Open
**Priority:** High
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** captain
**Created:** 2026-01-14
**Updated:** 2026-01-14

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
- [ ] Agent directory renamed from `housekeeping` to `captain`
- [ ] Captain identity established in agent.md with full role description
- [ ] Tools default to "captain" agent (myclaude, commit, session-start hook)
- [ ] iTerm integration shows "captain" badge
- [ ] Documentation updated (CLAUDE.md, README.md, FIRST-LAUNCH.md)
- [ ] No broken references to "housekeeping" agent in core files
- [ ] Clean git history with clear commit messages

**Phase 2: First-Launch Context**
- [ ] Captain-focused first-launch context created
- [ ] Context guides captain (not principal) on their first session
- [ ] Context displays correctly when captain launches first time
- [ ] Template ready for the-agency-starter integration

**Phase 3: Captain's Tour**
- [ ] `/welcome` command works with 5 initial paths presented
- [ ] Tutorial content created for all branches
- [ ] Can create real artifacts (agents, workstreams) during tutorial
- [ ] Onboarding state tracking saves progress to `onboarding.yaml`
- [ ] `/tutorial` navigation commands work (status, restart, skip)
- [ ] Each tutorial section takes <5 minutes to complete
- [ ] Can exit and resume onboarding at any point

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
