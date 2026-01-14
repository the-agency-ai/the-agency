# REQUEST-jordan-0045: Tool Improvements - Logging, Telemetry, and Naming

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** Complete
**Priority:** High
**Created:** 2026-01-13

---

## Summary

Three major improvements to the tools/ directory:

1. **Logging Pattern** - Implement consistent logging via `_log-helper` across all tools
2. **Tool Telemetry** - Capture usage metrics for analytics and optimization
3. **Noun-Verb Naming** - Refactor all tools to follow `{NOUN}-{VERB}` pattern

---

## Current State Audit

### Logging Status

**Tools WITH logging (9 of 79):**
- `collaborate`
- `commit`
- `designsystem-add`
- `designsystem-validate`
- `figma-diff`
- `figma-extract`
- `myclaude`
- `sync`
- `tag`

**Tools WITHOUT logging (70):** All others

### Naming Pattern Analysis

**Single-word tools (25):** Need noun-verb conversion or are acceptable as-is
```
agentname, bench, browser, collaborate, commit, config, docbench, hello, hi,
log, myclaude, now, observe, principal, recipes, release, request, requests,
restore, secret, sync, tag, welcomeback, whoami, workstream
```

**Verb-Noun pattern (needs reversal):**
```
add-nit → nit-add
add-tool-version → tool-version-add
archive-session → session-archive
backup-session → session-backup
build-bench → bench-build
bump-version → version-bump
capture-artifact → artifact-capture
capture-instruction → instruction-capture
capture-proposal → proposal-capture
code-review → review-code (or keep as-is?)
commit-prefix → prefix-commit (or drop?)
compare-starter → starter-compare
complete-instruction → instruction-complete
complete-request → request-complete
create-agent → agent-create
create-epic → epic-create
create-principal → principal-create
create-sprint → sprint-create
create-workstream → workstream-create
find-tool → tool-find
list-artifacts → artifact-list
list-instructions → instruction-list
log-adhoc → adhoc-log
migrate-secrets → secret-migrate
new-project → project-new
new-tool → tool-new
next-version → version-next
post-news → news-post
read-messages → message-read
read-news → news-read
release-starter → starter-release
report-bug → bug-report
resolve-nit → nit-resolve
respond-collaborate → collaboration-respond
run-unit-tests → test-run (or unittest-run?)
send-message → message-send
setup-icloud → icloud-setup
setup-iterm → iterm-setup
setup-linux → linux-setup
setup-mac → mac-setup
show-instructions → instruction-show
starter-test → starter-test (already noun-verb)
starter-test-cleanup → starter-cleanup
update-artifact-index → artifact-index-update
update-instruction-index → instruction-index-update
verify-starter → starter-verify
pre-commit-check → commit-precheck (or hook-precommit?)
```

**Already Noun-Verb (good):**
```
agency-bench
agency-feedback
agency-service
designsystem-add
designsystem-validate
figma-diff
figma-extract
starter-test
```

---

## Phase 1: Logging Pattern Implementation

### Approach

Add `_log-helper` sourcing to all bash tools:

```bash
#!/bin/bash
# Tool description

# Source log helper for telemetry
source "$(dirname "$0")/_log-helper"

# ... existing setup ...

# Start logging
RUN_ID=$(log_start "tool-name" "agency-tool" "$@")

# ... tool logic ...

# End logging
log_end "$RUN_ID" "success" "$EXIT_CODE" "$OUTPUT_SIZE" "summary"
```

### Tools to Update (70)

All tools except those already using `_log-helper`.

---

## Phase 2: Tool Telemetry

### What to Capture

| Metric | Purpose |
|--------|---------|
| Tool name | Which tools are used |
| Invocation count | Usage frequency |
| Success/failure rate | Tool reliability |
| Exit codes | Error patterns |
| Execution time | Performance tracking |
| Agent/workstream context | Usage by agent |
| Arguments (sanitized) | Common usage patterns |

### Implementation

The `_log-helper` already sends to Log Service. Telemetry is captured via:
- `log_start` - Records invocation, tool, args, context
- `log_end` - Records outcome, duration, exit code

### Analytics Endpoints (if needed)

```
GET /api/log/stats/tools          # Tool usage stats
GET /api/log/stats/tools/:name    # Single tool stats
GET /api/log/stats/agents         # Usage by agent
```

---

## Phase 3: Noun-Verb Naming Convention

### Naming Rules

1. **Pattern:** `{noun}-{verb}` or `{noun}-{noun}-{verb}` for compound nouns
2. **Nouns first:** The object being acted upon
3. **Verbs last:** The action being performed
4. **Single-word exceptions:** `commit`, `sync`, `release` stay as-is (common git verbs)

### Rename Map

| Current | New | Notes |
|---------|-----|-------|
| `add-nit` | `nit-add` | |
| `add-tool-version` | `tool-version-add` | |
| `archive-session` | `session-archive` | |
| `backup-session` | `session-backup` | |
| `build-bench` | `bench-build` | |
| `bump-version` | `version-bump` | |
| `capture-artifact` | `artifact-capture` | |
| `capture-instruction` | `instruction-capture` | |
| `capture-proposal` | `proposal-capture` | |
| `compare-starter` | `starter-compare` | |
| `complete-instruction` | `instruction-complete` | |
| `complete-request` | `request-complete` | |
| `create-agent` | `agent-create` | |
| `create-epic` | `epic-create` | |
| `create-principal` | `principal-create` | |
| `create-sprint` | `sprint-create` | |
| `create-workstream` | `workstream-create` | |
| `find-tool` | `tool-find` | |
| `list-artifacts` | `artifact-list` | |
| `list-instructions` | `instruction-list` | |
| `log-adhoc` | `adhoc-log` | |
| `migrate-secrets` | `secret-migrate` | |
| `new-project` | `project-new` | |
| `new-tool` | `tool-new` | |
| `next-version` | `version-next` | |
| `post-news` | `news-post` | |
| `pre-commit-check` | `commit-precheck` | |
| `read-messages` | `message-read` | |
| `read-news` | `news-read` | |
| `release-starter` | `starter-release` | |
| `report-bug` | `bug-report` | |
| `resolve-nit` | `nit-resolve` | |
| `respond-collaborate` | `collaboration-respond` | |
| `run-unit-tests` | `test-run` | |
| `send-message` | `message-send` | |
| `setup-icloud` | `icloud-setup` | |
| `setup-iterm` | `iterm-setup` | |
| `setup-linux` | `linux-setup` | |
| `setup-mac` | `mac-setup` | |
| `show-instructions` | `instruction-show` | |
| `starter-test-cleanup` | `starter-cleanup` | |
| `update-artifact-index` | `artifact-index-update` | |
| `update-instruction-index` | `instruction-index-update` | |
| `verify-starter` | `starter-verify` | |
| `code-review` | `review-code` | Or keep? |

### Single-Word Tools - Keep As-Is

These are acceptable as single-word commands:
- `agentname`, `bench`, `browser`, `collaborate`, `commit`, `config`
- `docbench`, `hello`, `hi`, `log`, `myclaude`, `now`, `observe`
- `principal`, `recipes`, `release`, `request`, `requests`, `restore`
- `secret`, `sync`, `tag`, `welcomeback`, `whoami`, `workstream`

### Already Compliant - No Change

- `agency-bench`
- `agency-feedback`
- `agency-service`
- `designsystem-add`
- `designsystem-validate`
- `figma-diff`
- `figma-extract`
- `starter-test`

---

## Phase 4: Quiet-by-Default Rollout

### Rationale

Tools currently output verbose information to stdout which:
1. Fills up context windows and spends tokens unnecessarily
2. Makes it hard to see what actually matters (success/failure)
3. Provides no way to retrieve details when debugging failures

The quiet-by-default pattern solves this by:
- Outputting only: success/error status + run_id
- Logging verbose details to the Log Service
- Allowing retrieval via `./tools/log run get <run_id>` when needed

### Pattern Reference

See `claude/docs/TOOL-LOGGING-PATTERN.md` for the full pattern.

**Key elements:**
1. Source `_log-helper` and call `log_start` (already done for most tools)
2. Add `--verbose` flag for opt-in detail output
3. Show run_id on startup: `tool-name [run: abc-123]`
4. Use `verbose_echo`, `log_info`, `log_step` instead of raw `echo`
5. Call `log_end` at all exit points with trap for unexpected exits
6. Bump tool version (`TOOL_VERSION`) when modified

**Reference implementation:** `tools/starter-release`

### Tools Status

**COMPLETE: 66 tools now have quiet-by-default pattern**

Applied via 7 parallel subagents in commit eb32fc1:
- All tools have `VERBOSE=false` by default
- All tools support `--verbose` flag
- All tools show run_id in verbose mode
- All tools use `verbose_echo` and `log_*` functions

### Skip List (simple/special purpose)
- `_log-helper` (the helper itself)
- `hello`, `hi` (trivial greeting tools)
- `tab-status` (iTerm integration, needs visible output)

---

## Documentation Updates Required

After renaming, update:

1. **CLAUDE.md** - Tool references
2. **claude/docs/** - All documentation files
3. **README.md files** - In various directories
4. **Agent templates** - Tool references in templates
5. **Starter packs** - Any tool references
6. **Test files** - Tool invocations in tests

---

## Implementation Order

1. **Phase 1a:** Add logging to high-use tools first (10-15 tools)
2. **Phase 1b:** Add logging to remaining tools
3. **Phase 2:** Verify telemetry is captured in Log Service
4. **Phase 3a:** Rename tools (all at once to minimize confusion)
5. **Phase 3b:** Update all documentation
6. **Phase 3c:** Create compatibility aliases (optional, temporary)

---

## Success Criteria

- [x] All 78 tools use `_log-helper` for logging
- [x] Telemetry captured via Log Service (requires service running)
- [x] All tools follow noun-verb naming (44 renamed)
- [x] CLAUDE.md updated with new names
- [x] All docs updated with new names
- [x] No broken tool references (verified with grep)

---

## Work Log

### 2026-01-13

- Created REQUEST
- Audited 79 tools for logging status (9 have logging, 70 don't)
- Categorized tools by naming pattern
- Created rename map (44 tools need renaming)
- **COMPLETED: Renamed 44 tools** to noun-verb pattern using `git mv`
- **COMPLETED: Updated all internal tool references** in tool help text and documentation
- **COMPLETED: Added logging to 69 tools** (now 78/78 tools have logging)
- **COMPLETED: Updated CLAUDE.md** with new tool names
- **COMPLETED: Updated all documentation** (book drafts, proposals, agent templates, etc.)
- Removed symlinks (decided to force clean breaks and fix all references properly)
- Verified all tools work correctly

**Summary:**
- Tools renamed: 44
- Tools with logging: 78/78 (was 9/79)
- Documentation files updated: 50+

### 2026-01-14

- **COMPLETED Phase 4: Quiet-by-Default Rollout**
- Applied verbose pattern to 66 tools via 7 parallel subagents
- Added telemetry exposure: `./tools/log tools` and `./tools/log failures`
- Added log service endpoints: `/stats/tools`, `/stats/tools/:name`, `/failures`
- Committed: eb32fc1
- REQUEST marked complete

**Summary:**
- Tools with quiet-by-default: 66/66 (excluding skip list)
- Telemetry CLI commands: 2 new
- Service endpoints: 3 new

---

## Decisions

1. **`code-review`** - Keep as-is (already noun-verb: code is the noun, review is the verb)
2. **Compatibility aliases** - Decided against (would allow silent breakage, better to fix all references)
3. **Telemetry retention**:
   - Detailed logs: 90 days
   - Aggregated stats: Indefinite (for community sharing)
   - Sanitized args: 30 days
