# REQUEST-jordan-0067: Tool Run Telemetry and Reporting

**Status:** Open
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Workstream:** housekeeping
**Created:** 2026-01-18
**Updated:** 2026-01-18

## Summary

Build a comprehensive tool run telemetry system to capture execution data locally and (optionally) from adopters to improve tooling quality.

## Problem Statement

Currently:
- Tools have logging infrastructure (`_log-helper`) but it's **not working in practice**
- Only 5-6 tool runs logged despite hundreds of actual executions
- No visibility into tool usage patterns, failures, or performance
- No way for adopters to opt-in to sharing anonymized usage data

## Goals

### Primary Goal: Tool Efficiency Optimization

**Identify opportunities to create `./tools/` wrappers that reduce context and token usage.**

Every raw Bash/Read/Write/Grep call consumes context window. By analyzing tool run patterns, we can:

1. **Identify repetitive sequences** - "Claude always runs X then Y then Z" → create `./tools/xyz`
2. **Find verbose operations** - Commands that return too much output → create focused tools
3. **Detect common workflows** - Multi-step patterns → single tool with concise output
4. **Reduce token waste** - Replace chatty commands with efficient alternatives

**Example opportunities:**
- `git status && git diff && git log` → `./tools/git-summary` (one concise output)
- Multiple `grep` calls → `./tools/search-code` (structured results)
- `find + cat + grep` chains → `./tools/find-in-files` (direct answers)
- Repeated file reads → `./tools/context-gather` (batched, summarized)

### Secondary Goals

1. **Fix local logging** - Every tool run should be captured
2. **Rich execution data** - Args, duration, exit codes, errors
3. **Pattern detection** - What sequences appear frequently?
4. **Error analysis** - What fails, why, how to prevent?
5. **Opt-in remote reporting** - Adopters can share anonymized data
6. **Continuous improvement** - Learn from agent behavior to improve CLAUDE.md, prompts, and workflows

### Learning from Agent Behavior

Every tool call is a decision Claude made. By capturing all runs, we build a dataset of:
- What Claude tries (successful patterns)
- What fails (anti-patterns to document)
- What's inefficient (optimization opportunities)
- How agents actually work (vs. how we think they work)

This feeds back into:
- **CLAUDE.md updates** - Add rules based on observed mistakes
- **Prompt improvements** - Better guidance based on real behavior
- **Training examples** - Real-world effective vs. ineffective tool use
- **Framework improvements** - The Agency gets better from usage data

## Investigation: Why Logging Isn't Working

**Symptoms:**
- `log_start` returns empty run ID in tools
- Direct curl to API works fine
- Parsing works in isolated bash tests
- `[run: none]` shown in tool output

**Hypotheses to test:**
1. Shell environment differences (zsh vs bash?)
2. Sourcing timing (log_start called before service ready?)
3. Network issues (curl timeout too short?)
4. Response parsing issue in specific shell context

---

## Phased Implementation

### Phase A: Fix Local Logging

**Goal:** Every tool run is captured in the local database.

**Deliverables:**
- [ ] Root cause identified and documented
- [ ] `_log-helper` fixed to work reliably
- [ ] All tools verified to log correctly
- [ ] Test coverage for logging

**Investigation tasks:**
1. Add debug logging to `_log-helper` (permanent, behind flag)
2. Test in zsh vs bash
3. Test with different curl timeouts
4. Check if agency-service is always running when tools execute

### Phase B: Enhanced Data Capture

**Goal:** Capture rich execution context.

**Deliverables:**
- [ ] Capture command arguments (sanitized)
- [ ] Capture execution duration
- [ ] Capture stdout/stderr size
- [ ] Capture working directory
- [ ] Capture git context (branch, dirty status)
- [ ] Schema migration for new fields

**Schema additions:**
```sql
ALTER TABLE tool_runs ADD COLUMN duration_ms INTEGER;
ALTER TABLE tool_runs ADD COLUMN args_hash TEXT;  -- Hash for privacy
ALTER TABLE tool_runs ADD COLUMN git_branch TEXT;
ALTER TABLE tool_runs ADD COLUMN git_dirty BOOLEAN;
ALTER TABLE tool_runs ADD COLUMN cwd_hash TEXT;  -- Hash for privacy
ALTER TABLE tool_runs ADD COLUMN error_message TEXT;
```

### Phase C: Local Analytics & Tool Opportunity Detection

**Goal:** Analyze tool usage to identify wrapper tool opportunities.

**Deliverables:**
- [ ] `./tools/agency-service log stats` - Basic statistics
- [ ] `./tools/agency-service log sequences` - **Detect repeated command sequences**
- [ ] `./tools/agency-service log verbose` - **Find high-output commands**
- [ ] `./tools/agency-service log opportunities` - **Suggest new tools to create**

**Key Analysis: Sequence Detection**
```
Common Sequences (Last 7 days)
═══════════════════════════════════════════════════
Sequence: git status → git diff → git log -5
  Occurrences: 47
  Avg tokens: ~2,400
  Suggestion: ./tools/git-summary

Sequence: grep -r "pattern" → Read file → Read file → Read file
  Occurrences: 31
  Avg tokens: ~5,200
  Suggestion: ./tools/search-and-read

Sequence: ls → cat package.json → cat tsconfig.json
  Occurrences: 28
  Avg tokens: ~1,800
  Suggestion: ./tools/project-info
```

**Key Analysis: Verbose Command Detection**
```
High-Output Commands (Last 7 days)
═══════════════════════════════════════════════════
Command: npm test (avg 15,000 chars output)
  Suggestion: ./tools/test-run --summary (already exists!)

Command: git log (avg 8,000 chars output)
  Suggestion: ./tools/git-recent --concise

Command: find . -name "*.ts" (avg 3,000 chars output)
  Suggestion: ./tools/find-files --format=compact
```

**Key Analysis: Tool Opportunity Report**
```
Tool Opportunities
═══════════════════════════════════════════════════
Priority 1: ./tools/git-summary
  - Combines: git status, git diff --stat, git log -5 --oneline
  - Estimated savings: 1,500 tokens/use × 47 uses = 70,500 tokens
  - Implementation: Simple bash wrapper

Priority 2: ./tools/search-and-read
  - Combines: grep search + targeted file reads
  - Estimated savings: 3,000 tokens/use × 31 uses = 93,000 tokens
  - Implementation: Returns only matching lines with context

Priority 3: ./tools/project-context
  - Combines: package.json, tsconfig.json, key config reads
  - Estimated savings: 800 tokens/use × 28 uses = 22,400 tokens
  - Implementation: Single structured output
```

### Phase D: Opt-In Remote Reporting

**Goal:** Allow adopters to share anonymized usage data.

**Deliverables:**
- [ ] Opt-in mechanism (explicit consent required)
- [ ] Privacy controls (what data is shared)
- [ ] Anonymization (no PII, hashed identifiers)
- [ ] Collection endpoint (The Agency backend)
- [ ] Aggregated analytics dashboard

**Opt-in flow:**
```bash
# User explicitly enables telemetry
./tools/agency-config telemetry enable

# Configuration stored in ~/.agency/config.yaml
telemetry:
  enabled: true
  anonymize: true
  share_args: false  # Never share actual arguments
  share_errors: true # Share error messages (sanitized)
```

**Data shared (anonymized):**
```json
{
  "installation_id": "sha256:abc123...",  // Hash of machine ID
  "tool": "commit",
  "tool_version": "1.1.0",
  "agency_version": "1.3.0",
  "status": "success",
  "duration_ms": 1234,
  "os": "darwin",
  "shell": "zsh",
  "timestamp": "2026-01-18T12:00:00Z"
}
```

**Never shared:**
- Actual file paths
- Command arguments
- User names
- Repository names
- Code content
- Secrets

---

## Acceptance Criteria

### Phase A
- [ ] All tool runs logged locally
- [ ] Root cause documented
- [ ] No `[run: none]` in tool output

### Phase B
- [ ] Duration captured for all runs
- [ ] Git context captured
- [ ] Error messages captured (sanitized)

### Phase C
- [ ] `log stats` shows meaningful data
- [ ] `log failures` helps debug issues
- [ ] `log trends` shows patterns

### Phase D
- [ ] Opt-in is explicit (never automatic)
- [ ] Privacy controls documented
- [ ] Anonymization verified
- [ ] Users can opt-out anytime

---

## Development Cycle

### Phase A: Implementation
- [ ] Code complete
- [ ] Tests written
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0067-phaseA-impl`

### Phase A: Code Review + Security Review
- [ ] 2+ code review subagents spawned
- [ ] 1+ security review subagent spawned
- [ ] Findings consolidated
- [ ] Changes applied
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0067-phaseA-review`

### Phase A: Test Review
- [ ] 2+ test review subagents spawned
- [ ] Findings consolidated
- [ ] Test changes applied
- [ ] Local tests passing (GREEN)
- [ ] Committed
- [ ] Tagged: `REQUEST-jordan-0067-phaseA-tests`

*(Repeat for Phase B, C, D)*

### Complete
- [ ] Tagged: `REQUEST-jordan-0067-complete`

---

## Phase E: Claude Code Bash Capture

**Goal:** Capture every bash command executed during Claude Code sessions.

**Why this matters:**
- Hundreds of bash commands per session
- Rich data on what Claude does, what fails, what succeeds
- Patterns in command usage
- Error analysis for improvement

**Implementation options:**

1. **Claude Code Hooks** (Preferred)
   ```json
   // .claude/settings.json
   {
     "hooks": {
       "PostToolUse": [{
         "matcher": { "tool": "Bash" },
         "command": "./tools/log-bash-run \"$TOOL_INPUT\" \"$TOOL_OUTPUT\" \"$EXIT_CODE\""
       }]
     }
   }
   ```

2. **Bash wrapper** (Fallback)
   - Replace `/bin/bash` with wrapper that logs
   - Complex, invasive

**Data to capture:**
- Command (sanitized - no secrets)
- Exit code
- Duration
- Working directory (hashed)
- Session ID (from myclaude)
- Timestamp

**Schema:**
```sql
CREATE TABLE bash_runs (
  id INTEGER PRIMARY KEY,
  session_id TEXT,
  command_hash TEXT,  -- SHA256 of command for grouping
  command_preview TEXT,  -- First 100 chars, sanitized
  exit_code INTEGER,
  duration_ms INTEGER,
  cwd_hash TEXT,
  timestamp TEXT,
  agent TEXT,
  workstream TEXT
);
```

**Analytics enabled:**
- "What commands fail most often?"
- "What's the average session doing?"
- "Which patterns lead to errors?"
- "How long do builds take?"

---

## Privacy Considerations

**Critical:** Remote telemetry must be:
1. **Opt-in only** - Never enabled by default
2. **Transparent** - Users see exactly what's shared
3. **Anonymized** - No PII, hashed identifiers
4. **Minimal** - Only what's needed for improvement
5. **Revocable** - Easy to disable at any time

---

## Activity Log

### 2026-01-18 - Created
- Request created by jordan
- Identified that current logging isn't working (only 5-6 runs logged)
- Direct API tests work, suggesting environment/sourcing issue
