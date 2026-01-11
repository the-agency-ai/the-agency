# REQUEST-jordan-0038-housekeeping-common-slash-commands

**Status:** Open
**Priority:** High
**Requested By:** jordan
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-11

## Summary

Common slash commands for frequent operations (/bug, /idea, /request, etc.)

## Details

Create a set of slash commands for common operations that principals frequently need. These should be quick, low-friction ways to capture information and trigger actions without breaking flow.

### Example Use Case

User is working with an agent and encounters an issue:
```
/bug We need to ensure that every non-destructive tool in tools/ is in our permissions
```

This should:
1. Capture the bug description
2. Default to the current agent's queue (the agent you're talking to)
3. Allow override to different agent/workstream
4. Provide confirmation

## Command Structure: `/agency {subcommand}`

All Agency commands live under a single `/agency` namespace for discoverability and consistency.

### Quick Captures

| Command | Purpose | Default Target |
|---------|---------|----------------|
| `/agency bug` | Report a bug quickly | Current agent's queue |
| `/agency idea` | Capture an idea | Idea service |
| `/agency request` | Create a REQUEST | Housekeeping queue |
| `/agency nit` | Flag a minor issue | Nit queue |
| `/agency note` | Add a note to current work | Current agent's worklog |

### Navigation/Context

| Command | Purpose |
|---------|---------|
| `/agency status` | Show current work status |
| `/agency queue` | Show agent's work queue |
| `/agency requests` | List open REQUESTs |
| `/agency news` | Read recent news |

### Actions

| Command | Purpose |
|---------|---------|
| `/agency commit` | Commit current work |
| `/agency sync` | Push with pre-commit checks |
| `/agency review` | Request code review |

### Meta

| Command | Purpose |
|---------|---------|
| `/agency help` | Show available commands |
| `/agency version` | Show Agency version |

### Shorthand Aliases

For the most common commands, we could also support direct shortcuts:
- `/bug` → `/agency bug`
- `/idea` → `/agency idea`
- `/request` → `/agency request`

## Command Behavior

### /agency bug [description]
```
/agency bug The docbench tool doesn't handle files with spaces
```

**Flow:**
1. Parse description from command
2. If no description, prompt for one
3. Show current agent context: "Assigning to: housekeeping (override with --agent=X)"
4. Create bug in Bug Service
5. Optionally add to agent's work queue
6. Confirm: "Bug BUG-0042 created, assigned to housekeeping"

**Options:**
- `--agent=NAME` - Override target agent
- `--priority=high|normal|low` - Set priority
- `--workstream=NAME` - Override workstream

### /agency idea [description]
```
/agency idea Add voice input for capturing ideas hands-free
```

**Flow:**
1. Capture idea in Idea Service
2. Tag with current context (workstream, agent)
3. Confirm: "Idea captured: IDEA-0015"

### /agency request [summary]
```
/agency request Implement voice input for idea capture
```

**Flow:**
1. Create REQUEST file from template
2. Assign to housekeeping by default
3. Open in editor for details
4. Confirm: "REQUEST-jordan-0039 created"

## Implementation Approach

### Option A: Claude Code Custom Commands
Use `.claude/commands/` directory:
- `.claude/commands/bug.md` - /bug command
- `.claude/commands/idea.md` - /idea command
- etc.

Each command file contains instructions for the agent to execute.

### Option B: Skill System
Extend the existing skill system to handle these as skills.

### Option C: Hybrid
- Simple captures (bug, idea, nit) → Claude Code commands
- Complex actions (commit, sync, review) → Skills or tools

## Permissions Issue (Related)

User noted: Every non-destructive tool in `tools/` should be pre-approved in permissions.

**Action Items:**
1. Audit all tools in `tools/` directory
2. Categorize as destructive vs non-destructive
3. Add non-destructive tools to `.claude/settings.local.json` permissions
4. Document which tools are auto-approved

### Non-Destructive Tools (should be pre-approved):
- `./tools/agency-bench` - launches app
- `./tools/docbench` - opens documents
- `./tools/bench` - launches app
- `./tools/read-news` - reads news
- `./tools/welcomeback` - session restore
- `./tools/check-project-deps` - checks deps
- `./tools/run-unit-tests` - runs tests (read-only)
- etc.

### Destructive Tools (require confirmation):
- `./tools/sync` - pushes to git
- `./tools/commit` - creates commits
- `./tools/release` - creates releases
- `./tools/create-*` - creates files
- etc.

## Deliverables

- [ ] `/agency` command framework (dispatcher)
- [ ] `/agency bug` subcommand
- [ ] `/agency idea` subcommand
- [ ] `/agency request` subcommand
- [ ] `/agency nit` subcommand
- [ ] `/agency note` subcommand
- [ ] `/agency status` subcommand
- [ ] `/agency queue` subcommand
- [ ] `/agency help` subcommand
- [ ] Shorthand aliases (/bug, /idea, /request)
- [ ] Audit and update tool permissions
- [ ] Documentation for available commands

## Acceptance Criteria

- [ ] Can quickly report a bug with `/bug description`
- [ ] Bug defaults to current agent's queue
- [ ] Can override target with `--agent=X`
- [ ] All non-destructive tools are pre-approved
- [ ] Commands work consistently across agents

## Notes

This is about reducing friction for common operations. The goal is to stay in flow while still capturing important information.

Key principle: **Don't break the user's flow**

---

## Activity Log

### 2026-01-11 - Created
- Request created by jordan
- Identified core slash commands needed
- Noted permissions issue for non-destructive tools
