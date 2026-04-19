---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05
status: created
priority: high
subject: "CLAUDE-THEAGENCY.md revisions needed for ISCP v1"
in_reply_to: null
---

# CLAUDE-THEAGENCY.md Revisions for ISCP v1

## Context

ISCP v1 is shipping. CLAUDE-THEAGENCY.md is the methodology document read by every agent. It has several references to ISCP as "future" or "not yet implemented" that are now stale. It also lacks documentation for the new tools, hooks, and enforcement rules.

This dispatch itemizes every change needed, organized by section. Captain should incorporate these into CLAUDE-THEAGENCY.md on main after the iscp branch lands.

---

## Section-by-Section Changes

### 1. Repo Structure — `agency/tools/` listing (around line 28)

**Add** to the tools list:
```
    agent-identity         — "who am I" identity resolution
    iscp-check             — "you got mail" notification hook
    iscp-migrate           — legacy flag/dispatch migration (one-shot)
```

The `flag` and `dispatch` tools are already listed but their descriptions should be updated to reflect v2 (SQLite-backed, not JSONL/git-only).

### 2. Dispatch & Flag Payload Locations (around line 244-248)

**Current text (stale):**
> Both dispatch notifications and flags will be persisted in a local database outside the repo (see the ISCP workstream for the design). Until that is implemented, dispatches are markdown files in git and flags are JSONL files staged on write.

**Replace with:**
> Both dispatch notifications and flags are persisted in a SQLite database at `~/.agency/{repo-name}/iscp.db` (outside git). The DB stores notification metadata and mutable state (read/unread, timestamps). Dispatch payloads remain as immutable markdown files in git. Flags are DB-only (no git payload). See the ISCP reference: `agency/workstreams/iscp/iscp-reference-20260405.md`.

### 3. Dispatch description (around line 244)

**Current text:**
> A **dispatch** is a structured message between agents or from principal to agent. It consists of a notification pointing to a payload file in git at the resolved location above. Dispatch payloads are immutable once written. Named `{type}-{YYYYMMDD-HHMM}.md`.

**Add after this paragraph:**
> Dispatches are managed by the `dispatch` tool — never created manually. The tool creates both the DB record and the git payload atomically. Dispatch types are validated against an 8-type enum: `directive`, `seed`, `review`, `review-response`, `commit`, `master-updated`, `escalation`, `dispatch`. Integer IDs (from the DB) are used to reference dispatches, not file paths.

### 4. Flag description (around line 246)

**Current text:**
> A **flag** is a quick-capture observation for later discussion. Flags use the same addressing scheme but have no git payload — the content lives in the notification itself. Flags are agent-addressable: `/flag TEXT` (current agent), `/flag agent TEXT` (specific agent).

**Replace with:**
> A **flag** is a quick-capture observation for later discussion. Flags are DB-only — no git payload, instant capture from any worktree. Agent-addressable: `flag <message>` (self), `flag --to <agent> <message>` (specific agent). Three-state lifecycle: unread → read (on `flag list`) → processed (on `flag discuss` or `flag clear`).

### 5. Transport layer reference (around line 231)

**Current text:**
> The transport layer (git push/pull, future ISCP) is separate from addressing. Addresses identify; transport delivers.

**Replace with:**
> The transport layer (git push/pull, ISCP) is separate from addressing. Addresses identify; transport delivers. ISCP v1 uses the local filesystem (SQLite DB + git payloads) — cross-machine transport is a future extension.

### 6. Dispatch handling protocol (around line 567)

**Current text:**
> **If you receive a dispatch:** Merge master, read the dispatch file at `usr/{{principal}}/{project}/code-reviews/`, evaluate findings, fix with red→green cycle...

**Update to:**
> **If you receive a dispatch:** Run `dispatch list` to see pending dispatches with their integer IDs. Run `dispatch read <id>` to read the payload and mark it as read. Evaluate findings, fix with red→green cycle, append a resolution table, run `/iteration-complete`. When done, `dispatch resolve <id>` marks it resolved. For review dispatches, send a `review-response` dispatch with `--reply-to <id>`.

### 7. Worktree agents and dispatches (around line 354-361)

**Current text:**
> - Merge master regularly (`git merge master`) to pick up dispatches, CLAUDE.md updates, and other agents' work.

**Add after:**
> - The `iscp-check` hook automatically notifies you of unread dispatches on SessionStart — you don't need to merge master to know about them. However, you still need to merge master to access dispatch payload files (the DB notification tells you the file exists; the payload lives on master).

**Current text:**
> - **Dispatch handling** — worktree agent picks up the dispatch after merging master.

**Replace with:**
> - **Dispatch handling** — `iscp-check` notifies the worktree agent automatically. The agent runs `dispatch read <id>` to see the payload. If the payload file is on master, merge master first to access it.

### 8. NEW SECTION: ISCP (Inter-Session Communication Protocol)

**Add a new top-level section** (after "Session Handoff" section, before "Discussion Protocol"):

```markdown
## ISCP (Inter-Session Communication Protocol)

ISCP is the notification and messaging backbone. Every agent has automatic mail.

### How It Works

The `iscp-check` hook fires on SessionStart, UserPromptSubmit, and Stop. It queries the SQLite DB at `~/.agency/{repo-name}/iscp.db` for unread items addressed to the current agent. Silent when empty (zero tokens). One-line JSON summary when items are waiting.

### Tools

| Tool | What |
|------|------|
| `flag <message>` | Quick-capture to self (DB-only, instant) |
| `flag --to <agent> <message>` | Quick-capture to specific agent |
| `flag list` / `flag discuss` / `flag clear` | Process flags |
| `dispatch create --to <addr> --subject <text>` | Send a dispatch (DB + git payload) |
| `dispatch list` | See dispatches for current agent |
| `dispatch read <id>` | Read payload, mark as read |
| `dispatch resolve <id>` | Mark dispatch resolved |
| `agent-identity` | Resolve "who am I" (repo/principal/agent) |

### When You Have Mail

- **SessionStart:** Process unread items FIRST before other work (hookify enforced)
- **Mid-session:** Act on mail at a natural break, not immediately
- **Dispatch types:** directive (do this), review (fix these), seed (input material), escalation (urgent)

### Reference

Full details: `agency/workstreams/iscp/iscp-reference-20260405.md`
```

### 9. Enforcement Triangle — add ISCP entries (around the hookify rules table)

**Add to the hookify rules list:**
- `hookify.dispatch-manual.md` — blocks writing to `*/dispatches/` without dispatch tool
- `hookify.flag-manual.md` — blocks writing to flag-queue.jsonl or flag DB directly
- `hookify.directive-authority.md` — only principal/captain may send directive type
- `hookify.review-authority.md` — only captain may send review type
- `hookify.session-start-mail.md` — process unread mail FIRST on session start

### 10. Repo Structure — hookify listing

**Add** to the hookify section:
```
  hookify/
    hookify.dispatch-manual.md
    hookify.flag-manual.md
    hookify.directive-authority.md
    hookify.review-authority.md
    hookify.session-start-mail.md
```

### 11. Settings.json — hook documentation

If there's any reference to the hook configuration, note that `iscp-check` is now in the SessionStart, UserPromptSubmit, and Stop hook arrays.

### 12. Testing section

**Add to testing section:**
> ISCP tools: `bats tests/tools/iscp-db.bats tests/tools/agent-identity.bats tests/tools/dispatch-create.bats tests/tools/dispatch.bats tests/tools/flag.bats tests/tools/iscp-check.bats tests/tools/iscp-migrate.bats` (142 tests)

---

## Acceptance Criteria

- [ ] All 12 changes above incorporated into CLAUDE-THEAGENCY.md
- [ ] "Future ISCP" / "not yet implemented" language removed
- [ ] New ISCP section added with tool reference
- [ ] Dispatch handling protocol updated to use integer IDs
- [ ] Flag description updated to reflect DB-backed v2
