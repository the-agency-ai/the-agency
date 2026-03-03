# The Agency

A multi-agent development framework for Claude Code.

For an overview of the system, directory structure, and getting started, see `claude/docs/PRINCIPAL-GUIDE.md`.

## Tools

**Session:** `myclaude`, `welcomeback`, `session-backup`
**Scaffolding:** `workstream-create`, `agent-create`, `epic-create`, `sprint-create`
**Messaging:** `msg` (send, broadcast, read, thread, ack)
**Dispatch:** `dispatch` (enqueue, claim, complete, fail, status), `dispatch-request`
**Collaboration (deprecated):** `collaborate`, `collaboration-respond`, `news-post`, `news-read`
**Quality:** `commit-precheck`, `test-run`, `code-review`, `review-spawn`, `install-hooks`
**Git:** `commit`, `tag`, `sync`
**GitHub:** `gh`, `gh-pr`, `gh-release`, `gh-api`

All tools are in `./tools/`. Run with `./tools/<name>`.

## Tool Output Standard

**All `./tools/*` must follow this output format to minimize context window usage.**

### stdout Format (What Claude Sees)

```
{tool-name} [run: {run-id}]
{essential-result-if-needed}
{status}
```

- **Line 1:** Tool name and run ID (for tracing to verbose logs)
- **Line 2:** Essential result only if needed (commit hash, file path, count)
- **Line 3:** Status indicator: `✓` (success) or `✗` (failure)

### Examples

```bash
# Success with essential result
commit [run: a1b2c3d4]
Committed: 9cbb97e
✓

# Success, no result needed
test-run [run: e5f6g7h8]
✓

# Failure
test-run [run: i9j0k1l2]
✗
```

### Verbose Output (Database)

Full output is captured in the database via `_log-helper`:
- stdout/stderr content
- Duration
- Exit code
- Arguments

**Investigate failures:**
```bash
./tools/agency-service log run {run-id}
```

### Why This Matters

| Location | Content | Token Impact |
|----------|---------|--------------|
| stdout (context) | 10-20 tokens | Minimal |
| Database | Full verbose output | Zero (not in context) |

Every token in stdout consumes context window. Verbose output is available when needed but doesn't waste tokens on successful runs.

## Session Context Management

**CRITICAL:** Agents must save conversational context throughout the session using `./tools/context-save`.

### When to Save Context

Save context at these key moments:

1. **Session Start** - What you're working on
2. **After Completing Subtasks** - What was accomplished
3. **Before Major Context Switch** - Switching tasks or focus
4. **When Parking Work** - Issues for later
5. **Before Long Operations** - In case session gets interrupted

### Usage Examples

```bash
# Starting work
./tools/context-save --append "Continuing REQUEST-jordan-0048 - iTerm integration"

# Completing milestone
./tools/context-save --checkpoint "Permission system redesigned - layered approach working"

# Parking an issue
./tools/context-save --park "Error handling for edge cases needs review"

# Switching tasks
./tools/context-save --checkpoint "Feature X complete, switching to bug fixes"
```

### Context Types

- `--append` - General progress note
- `--checkpoint` - Significant milestone or completion
- `--park` - Something to revisit later (shows as ⏸ PARKED on restore)

### Automatic Restoration

When you start a session, the SessionStart hook automatically displays:

```
=== PREVIOUS SESSION CONTEXT ===
✓ Permission system redesigned - layered approach working
⏸ PARKED: Error handling for edge cases needs review
• Working on iTerm integration tests
⚠ You have 3 uncommitted file(s)
=== END PREVIOUS SESSION CONTEXT ===
```

**Best Practice:** Save context proactively throughout the session, not reactively at the end.

### Greeting with Context

**When session context is restored, lead with it.** Don't give a generic greeting - acknowledge where you left off.

**Good:**
> "Welcome back! Last session we fixed the principal detection bug (committed 049f26e). You were testing the fix. How did it go?"

**Bad:**
> "Hi! I'm the captain agent. How can I help you today?"

The restored context tells you what the user was working on. Use it to provide continuity.

## Secrets

**CRITICAL: All secrets MUST use the Secret Service. NEVER commit secrets to the codebase.**

### Essential Commands

```bash
# Retrieve a secret (most common operation)
./tools/secret-vault get secret-name

# Store a new secret
./tools/secret-vault create secret-name --type=api_key --service=ServiceName

# List available secrets
./tools/secret-vault list
```

**Reference:** See `claude/docs/SECRETS.md` for complete reference (vault management, access control, audit logging, migration).

## Conventions

### Naming
- Agents: lowercase, hyphenated (`agent-manager`, `web`)
- Workstreams: lowercase (`agents`, `web`, `analytics`)
- Requests: `REQUEST-principal-XXXX-agent-summary.md`
- Artifacts: `ART-XXXX-principal-workstream-agent-date-title.md`
- Plans: `PLAN-XXXX-short-slug.md` in `claude/plans/`

### Git Commits

**With Work Item (preferred):**
```
{WORK-ITEM} - {WORKSTREAM}/{AGENT} for {PRINCIPAL}: {SHORT SUMMARY}

{body}

Stage: {impl | review | tests}
Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Without Work Item (simple commits):**
```
{WORKSTREAM}/{AGENT}: {SHORT SUMMARY}

{body}

Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Examples:**
```
REQUEST-jordan-0065 - housekeeping/captain for jordan: add Red-Green workflow docs

REQUEST-jordan-0066 - housekeeping/captain for jordan: fix path traversal vulnerability

housekeeping/captain: update README formatting
```

**Using ./tools/commit:**
```bash
# With work item
./tools/commit "add Red-Green workflow docs" --work-item REQUEST-jordan-0065 --stage impl

# Simple commit (no work item)
./tools/commit "update README formatting"
```

### API Design (Explicit Operations)
All API endpoints use explicit operation names. Do NOT rely on HTTP verb semantics.

**Pattern:**
```
POST /api/resource/create      # Create
GET  /api/resource/list        # List with filters
GET  /api/resource/get/:id     # Get single
POST /api/resource/update/:id  # Update
POST /api/resource/delete/:id  # Delete
POST /api/resource/action/:id  # Specific actions (approve, archive, etc.)
GET  /api/resource/stats       # Statistics
```

**Why explicit operations:**
- Self-documenting URLs
- Clear intent without needing to know HTTP semantics
- Easier to grep/search for operations
- Consistent across all services

**Anti-patterns (do NOT use):**
```
POST   /api/resource           # Ambiguous - is this create?
PATCH  /api/resource/:id       # Relies on verb semantics
DELETE /api/resource/:id       # Relies on verb semantics
GET    /api/resource/:id       # Ambiguous - use /get/:id
```

### Quality Gates
Pre-commit hooks enforce:
1. Code formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review checks
6. API design patterns

### Dependencies

**CRITICAL: All dependencies MUST be tracked. Never add a dependency without documenting it.**

**Turnkey Installation:** The combination of `install.sh` and `myclaude` provides a turnkey installation experience. When run, all dependencies should be auto-installed and the user should be ready to work immediately. This means:
- `myclaude` auto-installs Python dependencies (from `requirements.txt`) if missing
- `myclaude` auto-installs Bun runtime if missing
- `myclaude` auto-installs Node.js dependencies if missing
- `myclaude` auto-starts the agency-service if not running

When adding a dependency:
1. **Python** - Add to `requirements.txt` in project root
2. **Node.js** - Add to `package.json` (use `npm install --save` or `--save-dev`)
3. **System tools** - Document in README.md Prerequisites section
4. **Shell utilities** - Check availability with fallbacks or clear error messages

**Before using a dependency in code:**
- Verify it's already tracked, OR
- Add it to the appropriate manifest file first

**Error handling for optional dependencies:**
```bash
# Good - check and provide helpful error
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "Error: pyyaml not installed. Run: pip3 install pyyaml" >&2
    exit 1
fi

# Bad - let it fail cryptically
python3 -c "import yaml; ..."  # User sees "ModuleNotFoundError"
```

### Bug Fix Policy

**Fix bugs when encountered.** Don't defer bugs to "later" - they accumulate and cause confusion.

When you encounter a bug:
1. Fix it immediately if it's blocking or quick
2. Create a BUG-XXXX item if it requires significant work
3. Document the fix in the relevant KNOWLEDGE.md
4. Add tests to prevent regression

**Never ignore:**
- Cryptic error messages (improve them)
- Missing dependencies (track them)
- Test pollution (clean it up)
- Dirty working trees (commit or stash)

## Plans

**When entering plan mode, capture the prompt and final plan as a plan artifact.**

### Location & Naming

Plans are stored in `claude/plans/` with naming: `PLAN-XXXX-short-slug.md`

### Plan File Structure

```markdown
# Plan: {Title}

**Plan ID:** PLAN-{XXXX}
**Date:** {date}
**Agent:** {agent}
**Principal:** {principal}
**Status:** Draft | Approved | Implemented
**Related:** REQUEST-jordan-XXXX (if driven by a request; comma-separated for multiple)

## Prompt Context
> {The user prompt(s) that triggered plan mode, quoted verbatim}

## Plan
{The approved plan content}

## Outcome
{Filled in after implementation — what actually happened, commit hashes, etc.}
```

### REQUEST Linkage

Plans are often driven by REQUESTs. A single REQUEST may produce multiple plans (phases, iterations, alternatives).

- **Always include the REQUEST ID** in the `Related` field when a plan implements part or all of a REQUEST
- The `TaskCompleted` hook auto-detects REQUEST references in the transcript and session context
- Use `N/A` only when the plan is ad-hoc (not driven by a REQUEST)

### Auto-Capture

The `TaskCompleted` hook (`.claude/hooks/plan-capture.py`) automatically:
1. Detects plan mode completions (`permission_mode: "plan"`)
2. Extracts plan content and user prompts from the transcript
3. Scans for REQUEST references in transcript, task subject, and session context
4. Creates the `PLAN-XXXX` artifact with all metadata populated
5. Skips if the agent already manually created a plan file (2-minute window)

If auto-capture doesn't fire, create the plan file manually following the structure above.

### Workflow

1. **Enter plan mode** — user requests or agent proposes planning
2. **Capture prompt** — quote the user's prompt(s) that triggered planning
3. **Write plan** — develop the plan through exploration and analysis
4. **Save artifact** — `TaskCompleted` hook auto-creates `claude/plans/PLAN-XXXX-short-slug.md` with status `Draft`, or agent creates manually
5. **Get approval** — exit plan mode for user review
6. **Implement** — update status to `Approved`, then `Implemented` after completion
7. **Record outcome** — fill in the Outcome section with commit hashes and results

### Sequence Numbers

Use the next available number. Check existing plans:
```bash
ls claude/plans/PLAN-*.md | tail -1
```

## Work Items

Work in The Agency is tracked through REQUEST files. Each REQUEST goes through defined stages.

### Work Item Types
- `REQUEST-principal-XXXX` - Work requested by a principal
- `BUG-XXXX` - Bug fixes (can be addressed individually or via REQUEST)
- `ADHOC-` - Agent-initiated work (logged in ADHOC-WORKLOG.md)

### Managing Work Items

**ALWAYS use the request service tools - never manually edit status:**

```bash
# List open requests
./tools/requests

# Create a new request
./tools/request --agent captain --summary "Add feature X"

# Mark request complete (creates git tag + updates service)
./tools/request-complete REQUEST-jordan-0017 "Feature implemented"

# Sync request files to service (after manual file changes)
./tools/requests-backfill
```

The request service tracks all work items in a database. Use the API for status updates:
```bash
# Update request status via API
curl -X POST "http://127.0.0.1:3141/api/request/update/REQUEST-jordan-0017" \
  -H "Content-Type: application/json" \
  -d '{"status": "Complete"}'
```

### REQUEST Stages
```
impl     → Implementation complete, tested locally
review   → Code review complete, fixes applied
tests    → Test review complete, improvements applied
complete → All phases done, ready for release
```

### Tagging Convention
```bash
./tools/tag REQUEST-jordan-0017 impl      # REQUEST-jordan-0017-impl
./tools/tag REQUEST-jordan-0017 review    # REQUEST-jordan-0017-review
./tools/tag REQUEST-jordan-0017 tests     # REQUEST-jordan-0017-tests
./tools/tag REQUEST-jordan-0017 complete  # REQUEST-jordan-0017-complete
./tools/tag release 0.6.0                 # v0.6.0
```

## Development Workflow

**The working tree should ALWAYS be clean.**

### Breaking Work into Iterations

Large REQUESTs should be broken into **phases** or **iterations**. Each iteration:
- Has a clear, testable deliverable
- Includes tests for the new functionality
- Goes through the full review cycle
- Is tagged independently (e.g., `REQUEST-xxx-phase1-impl`)

### Development Cycle (Red-Green Model)

**CRITICAL: Never commit on RED. Every commit must have passing tests (GREEN).**

This cycle applies to completing any work item: REQUEST, Phase, Task, Iteration, or Sprint.

#### 1. Implement + Tests
- Build the feature/fix
- Write tests alongside the implementation
- Run tests locally → **GREEN**
- **COMMIT + TAG**: `{WORK-ITEM}-impl`
- Document work completed and tag in the work item file

#### 2. Code Review + Security Review
- Spawn **2+ code review subagents** (parallel)
- Spawn **1+ security review subagent**
- Wait for all subagents to complete
- **Consolidate** all findings into a single modification list
- Apply all code changes (do NOT apply piecemeal)
- Run tests locally → **GREEN**
- **COMMIT + TAG**: `{WORK-ITEM}-review`
- Document work completed and tag in the work item file

#### 3. Test Review (including Security Tests)
- Spawn **2+ test review subagents** (parallel)
- Reviews should identify:
  - Missing test cases
  - Edge cases not covered
  - Security-related tests needed
- **Consolidate** all findings into a single modification list
- Apply all test changes
- Run tests locally → **GREEN**
- **COMMIT + TAG**: `{WORK-ITEM}-tests`
- Document work completed and tag in the work item file

#### 4. Complete
- **TAG**: `{WORK-ITEM}-complete`
- Cut release if applicable: `./tools/release X.Y.Z --push --github`

### Commit/Tag Summary

This workflow applies to any work item: REQUEST, Phase, Task, Iteration, or Sprint.

| Stage | Commit? | Tag Pattern |
|-------|---------|-------------|
| Implementation complete | YES | `{WORK-ITEM}-impl` |
| Code/Security review complete | YES | `{WORK-ITEM}-review` |
| Test review complete | YES | `{WORK-ITEM}-tests` |
| Work item complete | NO | `{WORK-ITEM}-complete` |

**Tag Examples:**
```bash
./tools/tag REQUEST-jordan-0065 impl       # REQUEST-jordan-0065-impl
./tools/tag SPRINT-web-2026w03 review      # SPRINT-web-2026w03-review
./tools/tag ITERATION-hub-mvh-1 tests      # ITERATION-hub-mvh-1-tests
./tools/tag PHASE-hub-A complete           # PHASE-hub-A-complete
./tools/tag TASK-auth-refactor impl        # TASK-auth-refactor-impl
```

### Key Principles
- **Red-Green model**: Never commit on RED - iterate until GREEN
- **Clean working tree**: Always commit before moving on
- **Small commits**: Each commit is a logical unit with passing tests
- **Tags for milestones**: Tag after each stage (impl, review, tests, complete)
- **Multi-agent review**: 2+ code reviewers, 1+ security reviewer, 2+ test reviewers
- **Consolidate first**: Gather ALL feedback before applying ANY changes
- **Security throughout**: Security review in code phase, security tests in test phase
- **Document as you go**: Update work item file after each commit/tag

### Code Review Process

**Important:** `./tools/code-review` is an **automated pattern checker** (secrets, SQL injection, console.log). It runs as a pre-commit hook but is NOT the subagent-based review described above.

The multi-subagent code review is performed by the lead agent:
1. Run `./tools/review-spawn {WORK-ITEM} code` to get prompts
2. Spawn 2+ Task subagents with code review prompts (parallel)
3. Spawn 1+ Task subagent with security review prompt
4. Wait for all to complete
5. Use `claude/templates/prompts/consolidation.md` to merge findings
6. Apply changes systematically

**Test Review Process:**
1. Run `./tools/review-spawn {WORK-ITEM} test` to get prompts
2. Spawn 2+ Task subagents with test review prompts (parallel)
3. Wait for all to complete
4. Consolidate findings and apply test changes

**Available Templates:**
- `claude/templates/prompts/code-review.md` - Code reviewer prompt
- `claude/templates/prompts/security-review.md` - Security reviewer prompt
- `claude/templates/prompts/test-review.md` - Test reviewer prompt
- `claude/templates/prompts/consolidation.md` - Findings consolidation format

### Quality Enforcement

**Pre-commit Hook:**
Run `./tools/install-hooks` to install the pre-commit hook. This runs `./tools/commit-precheck` before every commit, blocking on failures.

**Tag Verification:**
`./tools/tag` verifies tests pass (GREEN) before allowing tags for impl, review, and tests stages. Use `--skip-tests` to bypass (sparingly).

---

*The Agency - Multi-agent development, done right.*
