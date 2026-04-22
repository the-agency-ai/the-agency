# REQUEST-jordan-0074: Starter Quality Cleanup

**Status:** Open
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-23
**Updated:** 2026-01-23

## Summary

Comprehensive cleanup of the-agency-starter quality issues identified by 5-agent review. Fix documentation, tool naming, crashes, and permissions before next release.

## Context

Five review subagents analyzed the-agency-starter and found 47 issues across:
- Documentation (outdated tool names, wrong paths, aspirational references)
- Tool crashes (--help handling, unbound variables)
- Configuration (missing permissions, broken hook references)
- Consistency (noun-verb naming, cross-references)

All fixes must be made in **the-agency** (source), then a clean build released to the-agency-starter.

---

## Work Items

### WI-1: Documentation Fixes (CLAUDE.md, README.md, GETTING_STARTED.md)

**Scope:** Fix all documentation issues in the-agency

| File | Issue | Fix |
|------|-------|-----|
| README.md | Says "development repository" | Update to describe starter correctly |
| CLAUDE.md | References `dispatch-collaborations`, `doc-commit` | Remove (never existed) |
| CLAUDE.md | Wrong starter packs: `nextjs/`, `react-native/`, `python/` | Update to: `nextjs-react/`, `vercel/`, `supabase/`, `git-ci/`, `tauri-app/` |
| CLAUDE.md | References `collaboration-pending` | Remove (never built) |
| All docs | `/welcome` command | Change to `/agency-welcome` |
| CONTRIBUTING.md | `pre-commit-check` | Change to `commit-precheck` |
| CONTRIBUTING.md | `welcome.md`, `tutorial.md` | Change to `agency-welcome.md`, `agency-tutorial.md` |
| GETTING_STARTED.md | 10+ wrong tool names | Fix all (see list below) |
| SECRETS.md | `services/agency-service/` | Change to `source/services/agency-service/` |
| README.md | References `requirements.txt` | Remove (no Python deps) |

**GETTING_STARTED.md tool name fixes:**
- `backup-session` → `session-backup`
- `pre-commit-check` → `commit-precheck`
- `run-unit-tests` → `test-run`
- `post-news` → `news-post`
- `read-news` → `news-read`
- `add-nit` → `nit-add`
- `capture-instruction` → `instruction-capture`
- `capture-artifact` → `artifact-capture`
- Remove `list-tools`, `show-instructions` (don't exist)

---

### WI-2: Hook and Script Naming (noun-verb consistency)

**Scope:** Rename hooks and fix references

| Current | New | Notes |
|---------|-----|-------|
| `.claude/hooks/check-messages.sh` | `.claude/hooks/messages-check.sh` | Follows noun-verb pattern |
| Reference to `read-messages` | `message-read` | In messages-check.sh |
| Reference to `collaboration-pending` | Remove | In session-start.sh (never built) |

---

### WI-3: Tool Crash Fixes

**Scope:** Fix tools that crash or misbehave

| Tool | Issue | Fix |
|------|-------|-----|
| `epic-create` | Crashes on `--help` (printf parsing) | Add help flag check before argument parsing |
| `browser` | Crashes with unbound variable | Use `${2:-}` pattern, add proper --help |
| Multiple tools | Exit 1 on --help (should be 0) | Fix help handling |

---

### WI-4: Permissions and Configuration

**Scope:** Fix settings.json and configuration files

**Add to permissions (non-destructive only):**
- `findings-consolidate`
- `findings-save`
- `log-tool-use-debug`
- `workflow-check`

**Do NOT add (require explicit permission):**
- `gh*` tools (can push/create)
- `sync` (pushes to remote)
- `release`, `starter-*` (modifies repos)
- `*-setup` tools (modifies system config)
- `install-hooks` (modifies .git)

**Fix configuration:**
- `agency-bug.md` - Fix bugs directory path
- `agency-nit.md` - Fix nits file path
- `settings.json` - Quote statusLine command path

---

### WI-5: Structure and Consistency

**Scope:** Fix directory structure issues

| Issue | Fix |
|-------|-----|
| browser agent missing KNOWLEDGE.md, WORKLOG.md | Add standard agent files |
| housekeeping workstream missing KNOWLEDGE.md | Add file |
| example-principal differs from template | Unify structure |
| principals/INDEX.md shows wrong structure | Update to match reality |

---

### WI-6: Clean Build and Release

**Scope:** Build and verify the-agency-starter

1. Run `./tools/starter-release patch --push`
2. Test fresh install: `curl -fsSL ... | bash`
3. Verify all issues resolved
4. Create GitHub release

---

## Acceptance Criteria

- [x] All documentation references correct tool names (noun-verb)
- [x] No references to non-existent tools
- [x] All `/welcome` → `/agency-welcome`
- [x] All starter pack paths correct
- [x] `epic-create --help` works (exit 0)
- [x] `browser --help` works (exit 0) → removed, replaced with research agent
- [x] Hook renamed to `messages-check.sh`
- [x] 4 non-destructive tools added to permissions
- [x] Fresh install works without errors (tested v1.3.3)
- [ ] All files pass lint/format checks

## Work Completed

### WI-1 through WI-5 (commit 2985c3a)
- Fixed all documentation issues (CLAUDE.md, README.md, SECRETS.md, CONTRIBUTING.md)
- Renamed check-messages.sh → messages-check.sh
- Fixed epic-create, browser, sprint-create --help crashes
- Added 4 non-destructive tools to permissions
- Added missing agent files for browser/research agent
- Fixed principal structure

### Browser → Research Rename (commits 5593873, 0ae5c83)
- Renamed browser agent to research agent
- Updated agent.md with research capabilities
- Research agent now handles web research, content analysis, knowledge production

### Releases
- v1.3.1 - Initial fixes
- v1.3.2 - Browser agent files
- v1.3.3 - Browser → Research rename

---

## Activity Log

### 2026-01-23 - Created
- Request created based on 5-agent review
- Identified 47 issues across documentation, tools, config, consistency
- Organized into 6 work items for parallel execution

### 2026-01-23 - WI-1 through WI-5 Complete
- 5 Task agents completed WI-1 through WI-5 in parallel
- Committed 2985c3a with all fixes
- Released v1.3.1, v1.3.2, v1.3.3

### 2026-01-23 - Browser → Research Agent
- Clarified browser agent was renamed to research agent
- Research agent for deep technical research and knowledge production
- Released v1.3.3 with final rename

### 2026-01-23 - WI-6 Verification
- Fresh install tested and verified
- VERSION: 1.3.3
- Research agent present with all files
