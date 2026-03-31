# Monofolk Tools Documentation

Tools ported from monofolk for incorporation into the-agency framework. These are bash tools and TypeScript libraries that support the Agency methodology.

---

## `handoff` — Context Bootstrap Tool

**Location:** `claude/tools/handoff` (bash)
**Purpose:** First-class Agency primitive for session context bootstrapping.

### Subcommands

| Command | What it does |
|---------|-------------|
| `handoff write [--trigger <name>]` | Auto-archives existing handoff to `history/`, then signals agent to write new content |
| `handoff write --lightweight [--trigger <name>]` | Appends/updates a status line without archiving (for `/sync-all`) |
| `handoff read` | Outputs current handoff content (used by session-start hooks) |
| `handoff path` | Outputs the resolved handoff file path |
| `handoff archive` | Archives current handoff to `history/` without writing new content |

### How it works

1. **Path resolution:** Resolves `claude/usr/{principal}/{project}/handoff.md` automatically from git branch name and principal directory. `master` → `captain`, `proto/catalog` → `catalog`, etc.
2. **Auto-rotation:** Every `write` (non-lightweight) copies the existing handoff to `history/handoff-YYYYMMDD-HHMMSS.md` before signaling the agent.
3. **Hook integration:** For `PreCompact` and `SessionEnd` triggers, outputs JSON `{"systemMessage": "..."}` that Claude Code injects as a system message reminding the agent to write the handoff.
4. **Telemetry:** Uses `_log-helper` for structured logging to `tool-runs.jsonl`.
5. **Sanitization:** Trigger names are sanitized to alphanumeric + hyphens + underscores.

### Triggers

`SessionEnd`, `PreCompact`, `iteration-complete`, `phase-complete`, `plan-complete`, `pre-phase-review`, `sync-all` (lightweight), `manual`.

---

## `plan-capture` — Plan File Management

**Location:** `claude/tools/plan-capture` (bash)
**Purpose:** Extracted from a 243-line hook. Captures plan files created during Claude Code plan mode.

### Modes

| Mode | What it does |
|------|-------------|
| `--from-hook` | Called by the plan-capture hook. Reads JSON from stdin (plan event data), writes plan to `docs/plans/`. |
| `--manual <path>` | Manually capture a plan file. |
| `--list` | List recent plans. |

### How it works

1. Receives plan event JSON on stdin (from Claude Code's plan mode hook).
2. Extracts plan content, generates filename from date + slug.
3. Writes to `docs/plans/YYYYMMDD-plan-{slug}.md` with frontmatter.
4. ERR trap emits warning (never crashes the hook pipeline).
5. Transcript path validated before writing.

---

## `lib/_log-helper` — Structured Telemetry Library

**Location:** `claude/tools/lib/_log-helper` (bash, sourced)
**Purpose:** Provides structured logging functions for all Agency tools.

### Functions

| Function | Purpose |
|----------|---------|
| `log_start "tool" "args"` | Starts a log entry, returns a UUID7 run ID |
| `log_end "$RUN_ID" "status" exit_code duration "summary"` | Completes the log entry |
| `log_detail "$RUN_ID" "key" "value"` | Adds detail to an in-progress entry |
| `tool_output "tool" "$RUN_ID" "message"` | Structured 3-line output format |

### How it works

- Emits JSONL to `tool-runs.jsonl` in the project root.
- Uses `jq --arg` for JSON construction (not printf — injection-safe).
- UUID7 run IDs for temporal ordering.
- Fields: agency, principal, agent, tool, args, status, exit_code, duration_ms, summary.
- Falls back gracefully if `jq` is not available (warns, continues).

---

## `stage-hash` — Deterministic Staging Area Hash

**Location:** `tools/lib/stage-hash.ts` (TypeScript library) + `tools/stage-hash.ts` (CLI)
**Purpose:** Computes a deterministic 7-character hash from the git staging area. Used for QGR receipt file naming.

### Algorithm

1. `git diff --cached --name-only` → sorted list of staged file paths
2. `git ls-files -s` → index entries with object hashes
3. Filter to staged files only
4. For each: concatenate `"mode objectHash path"`
5. SHA-256 the concatenation, take first 7 hex chars

### CLI Usage

```bash
tsx tools/stage-hash.ts          # prints 7-char hash
tsx tools/stage-hash.ts --json   # prints JSON: { hash, fileCount, files }
```

### Properties

- **Deterministic:** Same staged content always produces same hash, regardless of platform or timing.
- **Pre-commit:** Hash exists before the commit — ties QGR to staged content.
- **Deletion-aware:** Staged deletions use a zero-hash placeholder.
- **Order-independent:** Files are sorted, so staging order doesn't matter.

### Tests

9 tests covering: empty staging, 7-char format, file count, determinism across repos, content sensitivity, file name sensitivity, order independence, staged deletions, nested paths.

### Adaptation for the-agency

Currently TypeScript (requires `tsx`/Node.js). For the-agency framework, consider:
- Bash wrapper that calls `tsx` if available
- Pure bash implementation using `git ls-files -s` + `shasum`
- Or keep as TypeScript with Node.js as a dependency

---

## How Skills Use These Tools

### The QG → Commit Flow

```
/iteration-complete (skill)
  → invokes /quality-gate (skill)
    → runs 4 reviewer agents + own review
    → consolidates, tests (red→green), fixes
    → presents QGR
    → Step 10: runs `tsx tools/stage-hash.ts` to compute hash
    → writes QGR receipt to claude/usr/{principal}/{project}/qgr-{boundary}-{phase-iter}-{hash}-YYYYMMDD-HHMM.md
  → invokes /git-commit (skill)
    → runs `tsx tools/stage-hash.ts` to compute hash
    → globs for matching QGR receipt file
    → found → proceeds with commit
    → not found → warns, asks if QG should run
  → updates plan file
  → updates handoff (calls `claude/tools/handoff write --trigger iteration-complete`)
```

### The Handoff Flow

```
Session starts
  → session-handoff.sh hook fires
  → calls `claude/tools/handoff read`
  → injects handoff content as system message

Session ends / context compresses
  → SessionEnd or PreCompact hook fires
  → calls `claude/tools/handoff write --trigger {SessionEnd|PreCompact}`
  → handoff auto-archives previous, agent writes new content
```

### The Discussion Flow

```
/discuss (skill)
  → invokes /transcript start "topic" (via Skill tool)
  → /transcript writes file to claude/usr/{principal}/{project}/transcripts/
  → dialogue mode activates (appends exchanges to transcript)
  → each resolved item: /transcript capture "Item N" "Decision: ..."
  → on completion: /transcript stop
```
