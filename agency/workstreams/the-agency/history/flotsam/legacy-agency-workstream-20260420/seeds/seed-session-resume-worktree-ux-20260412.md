---
type: seed
workstream: agency
date: 2026-04-12
captured_by: the-agency/jordan/captain
principal: jordan
status: draft-pending-filing
report: usr/jordan/reports/report-feedback-session-resume-worktree-ux-20260412.md
---

# Seed: `claude --resume` and remote-control show unfiltered sessions with garbage names in worktree workflows

## What this is

A UX bug report for Claude Code's session resume and remote-control features when used in a multi-worktree, multi-agent development workflow. Three interconnected issues that compound into a broken experience:

1. **Unfiltered session list in worktrees:** `claude --resume` shows ALL sessions for the entire repository (44 in our case), regardless of which worktree/branch the user is in. A developer in the `devex` worktree sees captain sessions, ISCP sessions, mdpal-app sessions — none of which they can resume (see #3).

2. **Garbage session names:** Session names display seemingly random text from the session — possibly a user message, a truncated instruction, or generated text — rather than the agent name. Examples from the screenshot:
   - *"Please dispatch captain on the git issues It feels like you are not using tools and skills appropriate"*
   - *"Do a handoff"*
   - *"resume"*
   
   These are meaningless labels that make it impossible to identify which session belongs to which agent or which task. When you have 44 sessions, scanning for "the devex session from yesterday" is a guessing game. The `@agent` tag IS visible on some entries, proving the system knows the agent name — but it uses random session text as the primary label instead.

3. **Claude Code randomly overrides user-assigned session names:** Even when you explicitly assign a session name (via `--name` or the session naming UI), Claude Code silently replaces it with auto-generated text at some later point. This is the worst variant of the naming problem — it's not just "bad defaults," it's **actively overriding user intent**. You assign a name, you see it confirmed, and later the name is something else entirely. This makes the naming system untrustworthy.

4. **Cross-worktree resume silently fails:** The session list happily shows sessions from other worktrees. If you select one, it fails — because the session was running in a different worktree with different branch state. The UI lets you select something that cannot work. This is the worst kind of UX: an affordance that is always wrong.

5. **Remote-control shows the same garbage:** The Claude Desktop Code tab's session picker mirrors the same unfiltered, badly-named list. A principal looking at their remote-control sessions sees every agent's sessions mixed together with unhelpful names.

## Evidence

Screenshot from Jordan's terminal (2026-04-12) showing `claude --resume` in a worktree directory:

- **44 sessions listed** across all branches/worktrees in the repo
- Session entries show: name (first user message), age, size, agent flag (e.g., `@devex`, `@captain`), directory path
- Sessions from different worktrees (`.claude/worktrees/devex/`, `.claude/worktrees/iscp/`, `.claude/worktrees/mdpal-app/`, etc.) are intermixed
- The `@agent` tag IS present on some entries — so the system knows the agent name. But the session NAME (the primary display text) is still the first user message, not the agent name.

## Why this matters for multi-agent workflows

We run 5-8 concurrent worktree agents (captain, devex, iscp, mdpal-app, mdpal-cli, mock-and-mark, mdslidepal-web, mdslidepal-mac) on the same repository. Each agent has its own worktree, branch, and identity. The session resume and remote-control UX is the primary way the principal navigates between agents.

Today, that navigation is:
1. Open `claude --resume` (or remote-control)
2. See 44 sessions with garbage names
3. Try to identify the right one by guessing from the truncated first message
4. Maybe pick the wrong one → fail
5. Try again

The experience should be:
1. Open `claude --resume` in the devex worktree
2. See only devex sessions (filtered by current branch/worktree)
3. Session names show the agent name or a meaningful label
4. Pick the right one → resume instantly

## Requested behavior

### Priority 1: Filter sessions by worktree/branch

When `claude --resume` is invoked inside a worktree directory, default to showing only sessions that were started in that worktree (matching the branch name or directory path). Show a "Show all sessions" toggle or `Ctrl+A` shortcut to expand to the full list if the user explicitly wants cross-worktree visibility.

### Priority 2: Use agent name as session display name

When a session is started with `--agent <name>` or `--name <name>`, the session's display name should be the agent name, not the first user message. The first user message can be a subtitle or secondary line — but the primary label should be `devex`, `captain`, `mdslidepal-web`, etc.

For sessions started without `--agent`, the current behavior (first user message as name) is acceptable as a fallback. But agent-named sessions should always display the agent name prominently.

### Priority 3: Prevent or warn on cross-worktree resume

If a user selects a session from a different worktree, either:
- **(a)** Hide it from the default filtered list (preferred — don't show what can't work)
- **(b)** Show it with a clear label: `⚠ different worktree (devex) — cannot resume from here`
- **(c)** Allow resume but switch to the correct worktree directory first (if technically feasible)

Never silently show a session the user can select but cannot resume. That wastes time and trust.

### Priority 4: Fix remote-control session picker

Apply the same filtering and naming improvements to the Claude Desktop Code tab's session picker. The principal managing a fleet of agents should see a clean, agent-named, worktree-filtered list — not the raw dump of every session ever started in the repo.

### Stretch: User-settable session names

Allow `claude --name "Day 37 workshop prep"` to set a custom session display name, or a `/rename` command mid-session. This gives users agency over how their sessions appear in the resume list. The `--name` flag already exists for agent naming — extend it to accept a human-readable label.

## Relationship to --agent env var feedback

This is the session-level companion to the previously-filed `--agent/--name env var` feedback (flag #78, drafted as `seed-agent-name-env-var-20260411.md`). That feedback asks for the agent name to be exposed as an environment variable; this feedback asks for the agent name to be used as the session display name. Both are about the same underlying gap: Claude Code knows the agent name but doesn't surface it where users need it.

## Mechanical notes for submission

**Role split:** Captain authors seed + draft text. Principal files via `/feedback` + `gh issue create`.

**Reporter identity (from `agency.yaml`):**
- Jordan Dea-Mattson
- GitHub: @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- Email: jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- Framework: https://github.com/the-agency-ai/the-agency
- Claude Code version: run `claude --version` at filing time

## Draft feedback text (ready for principal to file)

---

# Session identity is broken for multi-agent worktree workflows (naming, filtering, resume, remote-control)

## Problem

Four interconnected session-identity issues that compound into a broken experience when running multiple agents in separate git worktrees:

1. **Unfiltered session list:** `claude --resume` shows ALL sessions for the entire repository (44 in my case) regardless of which worktree/branch the user is in. No filtering by current worktree.

2. **Garbage session names:** Session names display random text from the session — not the agent name, not a user-assigned name. Examples: *"Please dispatch captain on the git issues It feels like you are not using tools and skills appropriate"*, *"Do a handoff"*, *"resume"*. The `@agent` tag IS visible on some entries (proving the system knows the agent name), but the primary display label is garbage text.

3. **Claude Code randomly overrides user-assigned session names:** Even when a session name is explicitly assigned by the user, Claude Code silently replaces it with auto-generated text at some later point. This is not "bad defaults" — it's the system actively overriding user intent. You assign a name, you see it confirmed, and later the name is something else. This makes the naming system untrustworthy.

4. **Cross-worktree resume fails silently:** Sessions from other worktrees are shown in the list, but selecting one fails because the session was started in a different worktree with different branch state. The UI shows an affordance that always fails.

5. **Remote-control mirrors the same broken list:** The Claude Desktop Code tab's session picker shows the same unfiltered, badly-named session list. A principal managing a fleet of agents sees every agent's sessions mixed together with meaningless names.

**Observable from my setup (8 concurrent worktree agents on one repo):**

- `claude --resume` lists 44 sessions across all branches/worktrees
- Session names are random session text, not agent names or user-assigned names
- Sessions from `devex`, `iscp`, `mdpal-app`, `captain`, and other worktrees are intermixed
- The `@agent` tag IS present on some entries but the primary display text is still garbage
- Selecting a session from a different worktree fails
- User-assigned session names get silently overwritten by Claude Code

## Steps to reproduce

1. Create a git repo with multiple worktrees: `git worktree add .worktrees/devex -b devex`
2. Start sessions in different worktrees with different agent names: `cd .worktrees/devex && claude --agent devex`
3. Exit the session
4. Run `claude --resume` from the devex worktree
5. Observe: sessions from main, other worktrees, and other agents are all visible
6. Select a session from a different worktree
7. Observe: fails

## Expected behavior

1. **Filter by worktree by default** — `claude --resume` in the devex worktree shows only devex sessions. `Ctrl+A` or a toggle to show all.
2. **Use agent name as session display name** — sessions started with `--agent devex` display "devex" as the primary label, not random session text.
3. **Never override user-assigned session names** — if the user names a session, that name persists for the lifetime of the session. Claude Code may suggest a name for unnamed sessions, but must never silently replace a user-assigned name.
4. **Prevent or warn on cross-worktree resume** — don't show sessions the user can select but cannot resume.
5. **Fix remote-control session picker** — apply the same filtering and naming to the Claude Desktop Code tab.

## Why this matters

Multi-agent development with worktrees is a growing pattern (Claude Code's own `--agent` flag and `EnterWorktree` tool encourage it). The current session management UX assumes a single-session, single-directory workflow. When scaled to 5-8 concurrent agents on the same repo, the resume/remote-control experience breaks down completely. The principal managing a fleet of agents needs clean, agent-named, worktree-filtered navigation — not a raw dump of every session ever started.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency (8 concurrent worktree agents)
- **Claude Code version:** (fill at submission — `claude --version`)
- **Screenshot:** (attach from `/Users/jdm/.claude/image-cache/996153b6-ab38-4aca-aebd-728d2af55af5/3.png`)

## Related

- `--agent/--name` env var feedback (separate filing, same reporter) — the agent name exists internally but isn't surfaced to the session display
- Filed as part of the 2026-04-11/12 feedback batch clearing a backlog

---

## Conversation source

Principal showed captain a screenshot of `claude --resume` output from a worktree directory on 2026-04-12 and identified the three-part problem (unfiltered list, garbage names, cross-worktree failure). Added remote-control observation from direct experience.
