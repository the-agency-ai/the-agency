---
type: transcript
date: 2026-04-07
author: the-agency/jordan/captain
sessions:
  - iscp: 1c010e18-a978-4bb4-92fa-8ac43b2849cb
  - devex: 0643b000-f415-46af-87d6-31be16bd497b
  - mdpal-cli: 426391e1-6740-4dc7-b79b-d9c97e35ed1a
---

# Agent Session Friction Analysis — 2026-04-07

Three worktree agent sessions analyzed: ISCP, DevEx, mdpal-cli. All ran on 2026-04-06 in the evening, version 2.1.92. Each session opened with `Hello?` and ran through startup, then into workstream tasks.

---

## 1. ISCP Session

**File:** `1c010e18-a978-4bb4-92fa-8ac43b2849cb.jsonl` (105 entries)
**Branch:** `iscp`
**CWD:** `/Users/jdm/code/the-agency/.claude/worktrees/iscp`

### Permission Prompts

No `tool_rejected` events. Two `is_error: true` results observed:

1. **Entry 25** — `Read` on `claude/workstreams/agency/valueflow-plan-20260407.md` returned file-not-found because the plan lived on main and the branch hadn't been merged yet. Not a permission error — a legitimate workflow problem (agent read from the wrong branch). The agent self-corrected with `git show main:...` to verify existence, then merged main.

2. No blocked commands. Permission model appears to be working for ISCP — this is the agent that wrote the permissions in settings-template.json.

### Startup Friction

The handoff's startup sequence was:
1. Read handoff — 1 tool call
2. `dispatch list` — 1 tool call (cd to main repo — see below)
3. `flag list` — 1 tool call (cd to main repo)
4. Read dispatch #95 — 1 tool call
5. Read agent.md — 1 tool call
6. Read KNOWLEDGE.md — 1 tool call
7. Enter dispatch loop with `/loop` — 2 tool calls (ToolSearch + CronCreate)
8. `dispatch check` — 1 tool call

**9 tool calls before actual work begins.** That's the full ISCP boot sequence. It's well-structured, but 9 tool calls for startup is expensive when it happens every session.

The startup prescribed in the handoff includes "Merge main to pick up cross-agent changes" as step 5 — which means EVERY session triggers a merge, even when there's nothing to merge. In this session the merge actually brought in substantial changes (new collaboration tool, settings changes), but it's still a mandatory step that costs time even when not needed.

### Identity Confusion

None. Agent knew it was `the-agency/jordan/iscp` without hesitation. The handoff clearly stated identity and the agent confirmed it in its first prose response. The `.agency-agent` file approach is working for ISCP.

### Off-the-Rails Behavior

One significant confusion: Agent received dispatch #100 (its own review-response dispatch, sent TO captain) as "mail," processed it, and tried to resolve it as if it were actionable inbound. The dispatch was `from: iscp, to: captain` — it was outbound mail in the inbox. The agent correctly recognized this ("these are outgoing mail...not actions for me") but still wasted 4 tool calls (list, read, read, resolve) processing dispatches it sent.

Root cause: `dispatch list` shows ALL dispatches for the agent — both inbound and outbound. Agents have to read and mentally filter "wait, I sent this." The tool doesn't distinguish direction clearly enough in its output.

### Compound Command Violations

**2 compound command violations** (both with `cd /Users/jdm/code/the-agency &&`):

- Entry 11: `cd /Users/jdm/code/the-agency && ./claude/tools/dispatch list 2>&1`
- Entry 12: `cd /Users/jdm/code/the-agency && ./claude/tools/flag list 2>&1`

The agent was running from the worktree CWD (`/Users/jdm/code/the-agency/.claude/worktrees/iscp`) and prefixed both dispatch/flag commands with `cd` to the main repo. This is wrong — the tools work from any CWD. The `cd` is unnecessary and violates the compound command rule.

The ISCP tools themselves use `CLAUDE_PROJECT_DIR` as authoritative, so the cd prefix is harmless but adds noise and potential confusion about which dir the tools resolve against.

### Token Waste

Moderate. The subagent spawning at entries 92-94 was appropriate — two parallel subagents to explore ISCP internals for plan design. However, the subagents returned very verbose text blocks that re-described the entire codebase. A future improvement would be more targeted subagent queries ("just the schema DDL" rather than "full implementation").

The dispatch loop setup (ToolSearch for CronCreate, then CronCreate) costs 2 extra tool calls that could be streamlined if the loop skill didn't require ToolSearch.

---

## 2. DevEx Session

**File:** `0643b000-f415-46af-87d6-31be16bd497b.jsonl` (117 entries)
**Branch:** `devex`
**CWD:** `/Users/jdm/code/the-agency/.claude/worktrees/devex`

### Permission Prompts

No `tool_rejected` events. One notable error sequence:

**Entry 60-62 — Stop hook: phantom dirty tree / failed commit:**

```
Stop hook feedback: Uncommitted changes (1 files): M .agency-agent
```

Agent ran `git add .agency-agent && git commit -m "..."` (compound command). The pre-commit hook ran `commit-precheck` which said "No staged changes to check." Then git said "nothing added to commit." Exit code 1 returned as is_error.

The stop hook correctly identified the uncommitted change. But the agent's attempt to commit it failed mysteriously. Investigation revealed the merge commit `ae538d1 "Merge main — resolve .agency-agent to devex"` had already committed the file, so the working tree was clean by the time the commit ran. The `git add && git commit` sequence succeeded in staging but had nothing to commit because the merge already resolved it.

**This wasted 3 extra tool calls** (diff, status, log) and confused the agent about why the commit failed.

There's a separate permission-mode entry that appeared 3 times in DevEx (vs 1 each in ISCP and mdpal-cli). Examining the raw JSONL, DevEx has `permissionMode: "default"` in its session header. This is the same as the others. The extra entries were mid-session permission-mode change events — likely related to the stop hook interaction.

### Startup Friction

DevEx startup sequence:
1. Read handoff — 1 tool call
2. Read agent class definition — 1 tool call
3. Read KNOWLEDGE.md — 1 tool call
4. Read Valueflow A&D — 1 tool call
5. `/loop 5m dispatch check` — 3 tool calls (Skill → skill text injected → ToolSearch → CronCreate)
6. `dispatch list` (cd to main repo) — 1 tool call
7. `flag list` (cd to main repo) — 1 tool call
8. Read devex seed — 1 tool call

**10 tool calls before actual work begins.** The agent also read the Valueflow A&D in startup even though it's not strictly required — it was listed in the handoff under "context to review." That's one extra Read that could be deferred.

### Identity Confusion

None at startup. Agent stated `the-agency/jordan/devex` immediately and correctly.

However: the `.agency-agent` file was set to `iscp` when the devex session started (left from previous session). The agent updated it in memory and it showed up as a dirty file. A stop hook caught it. The agent tried to commit it (failed because already committed by a merge). The agent spent 3 tool calls debugging a non-problem.

The `.agency-agent` file mechanism creates a race condition between agents: the last agent to run sets the file. When two agents run in parallel worktrees, each will see the other's `.agency-agent` value as dirty on startup.

### Off-the-Rails Behavior

**The raw `git commit` at Entry 60** — agent used `git add .agency-agent && git commit -m "..."` instead of the required `./claude/tools/git-commit`. This is a CLAUDE.md violation ("Always use `/git-commit` — never raw `git commit`"). The hookify rule should have blocked this. The pre-commit hook ran (so the hook IS there) but the `git-commit` tool wrapper was bypassed.

The commit failed for unrelated reasons, so no harm done — but the agent demonstrated it doesn't honor the git-commit wrapper requirement when acting quickly in response to stop hook feedback.

**Entry 82** — during the later dispatch check, the agent used `cd /Users/jdm/code/the-agency && ./claude/tools/dispatch list --status unread` — both a cd-to-main-repo violation and a compound command.

### Compound Command Violations

**4 compound command violations**:

- Entry 27: `cd /Users/jdm/code/the-agency && ./claude/tools/dispatch list 2>/dev/null`
- Entry 28: `cd /Users/jdm/code/the-agency && ./claude/tools/flag list 2>/dev/null`
- Entry 60: `git add .agency-agent && git commit -m "$(cat <<'EOF'...EOF)"` (also a /git-commit bypass)
- Entry 82: `cd /Users/jdm/code/the-agency && ./claude/tools/dispatch list --status unread 2>/dev/null`
- Entry 87: `git add usr/jordan/devex/devex-handoff.md && git commit -m "$(cat <<'EOF'...EOF)"` (another /git-commit bypass)

Note: entries 87-88 — the second raw commit succeeded. Agent committed the handoff file via bare `git commit`, not `./claude/tools/git-commit`. The pre-commit hook ran and passed, but the git-commit wrapper's QGR check was bypassed entirely.

### Token Waste

Moderate. The `/define` skill invocation loaded the PVR checklist but the agent had already read the PVR and knew its state — the checklist was somewhat redundant. The skill infrastructure overhead (Skill tool call → skill text injection) is inherent to the architecture but adds tokens every time.

The A&D write (`Write` tool with a large file) at Entry 117 is correct and efficient — that's real work.

---

## 3. mdpal-cli Session

**File:** `426391e1-6740-4dc7-b79b-d9c97e35ed1a.jsonl` (114 entries)
**Branch:** `mdpal-cli`
**CWD:** `/Users/jdm/code/the-agency/.claude/worktrees/mdpal-cli`

### Permission Prompts

No `tool_rejected` events. Five `is_error: true` results — the highest error rate of the three sessions:

1. **Entry 53** — `Read` on `usr/jordan/mdpal/ad-mdpal-20260404.md` failed: file content exceeded 10,000 token limit. Agent had to re-read with `offset` and `limit`. Wasted 1 tool call.

2. **Entry 107-109** — `cd apps/mdpal && swift test` — cd failed because the shell resets CWD between calls. The agent was already IN `apps/mdpal/` (the worktree CWD was set to it after build), then tried to cd again. Two failed error-is-true results. Agent spent 2 extra tool calls diagnosing why `cd` failed before running `swift test` directly.

3. **Entry 111** — `swift test` itself failed with "no such module Testing" — Swift Testing framework not available on the installed toolchain. Expected error, correctly handled.

No permission-model rejections — but the cwd reset behavior caused genuine confusion and wasted tool calls.

### Startup Friction

mdpal-cli startup is the heaviest of the three:
1. Read mdpal-cli handoff — 1 tool call
2. Read mdpal-APP handoff (!) — 1 extra tool call
3. Read tech-lead agent class — 1 tool call
4. Read KNOWLEDGE.md — 1 tool call
5. `dispatch list` (cd to main repo) — 1 tool call
6. `flag list` (cd to main repo) — 1 tool call
7. Read Valueflow A&D — 1 tool call
8. `git status` — 1 tool call
9. `git log` — 1 tool call

**9-10 tool calls before actual work begins**, but includes one wasted read: the agent read the `mdpal-APP handoff` even though it's the mdpal-CLI agent. The agent note at entry 11 says it did this intentionally to understand the app agent state — the handoff told it to coordinate with mdpal-app. But this is startup overhead that could be deferred.

### Identity Confusion

None initially. Agent stated `the-agency/jordan/mdpal-cli` correctly.

However: at Entry 26-27, the agent noticed `.agency-agent` was modified (git status). Rather than recognizing this as the normal stale-agent-marker issue (the previous session set it to a different agent), the agent logged it as a concern and investigated. No hookify guidance or handoff note explained this is expected behavior.

### Off-the-Rails Behavior

**The most significant off-rails behavior in any of the three sessions:**

**Entry 31-60: Agent discovered the iteration 1.1 code was missing and rebuilt it from scratch.** The handoff said "1.1 complete" but `apps/mdpal/` didn't exist. The agent correctly diagnosed this (the code was never committed — lost in a worktree split), checked all branches, found no CLI code on any branch, read the plan and A&D, and then rebuilt the entire iteration from scratch.

This is not wrong behavior per se — the code was genuinely lost and needed to be rebuilt. But it represents:
- A significant gap in the handoff: the handoff claimed work was done that hadn't been committed
- The agent spent no tool calls verifying before trusting the handoff — it assumed the handoff was accurate and went to find "current code" only to discover there wasn't any

The agent ultimately did exactly the right thing (rebuild from plan), but the code loss itself is a prior-session failure that compounded into this session's workload.

**Entry 106-111: cwd confusion cascade.**

The agent built in `apps/mdpal/` by running `cd apps/mdpal && swift build`. This set the shell CWD for that call. But the next Bash call reset to the prior CWD. The agent then ran `cd apps/mdpal && swift test` — which failed because `apps/mdpal` is NOT relative to the prior CWD (which was already `apps/mdpal/`). This caused:
- 1 failed cd
- 1 diagnostic pwd+ls to understand what happened
- 1 re-run of swift test from correct dir

Three extra tool calls from the cwd reset behavior that CLAUDE.md specifically warns about ("The shell already starts in cwd, so do not prefix commands with `cd <cwd> &&`").

### Compound Command Violations

**5 compound command violations**:

- Entry 18: `cd /Users/jdm/code/the-agency && ./claude/tools/dispatch list 2>&1 | tail -20`
  (also uses a pipe — double violation)
- Entry 19: `cd /Users/jdm/code/the-agency && ./claude/tools/flag list 2>&1 | tail -20`
  (pipe too)
- Entry 42: `git log mdpal --oneline -5 2>/dev/null; echo "---"; git show mdpal:apps/mdpal/Package.swift 2>/dev/null | head -5 || echo "No mdpal code on mdpal branch"`
  (three different chain operators: `;`, `|`, `||`)
- Entry 100: `cd apps/mdpal && swift build 2>&1`
- Entry 106: `cd apps/mdpal && swift test 2>&1`

The `tail -20` pipe on dispatch/flag list is particularly unnecessary — the tools already paginate their output.

### Token Waste

High. Several contributors:

1. **Duplicate handoff read** (mdpal-app handoff) — ~100 tokens of irrelevant context
2. **Missing code investigation** — entries 31-49 were 8+ tool calls to determine whether the code existed, on what branch, and in what state. All confirmed: nothing there. This is unavoidable given the data situation, but the handoff claiming "1.1 complete" was misleading.
3. **cwd confusion** — 3 extra tool calls (entries 107-109) wasted on diagnosing a known framework behavior
4. **A&D file too large** — needed 2 reads (offset/limit) instead of 1

---

## 2. Common Patterns Across All Three Sessions

### Pattern 1: cd-to-main-repo for dispatch/flag tools

All three agents prefix `./claude/tools/dispatch` and `./claude/tools/flag` with `cd /Users/jdm/code/the-agency &&`. This happens CONSISTENTLY in every session startup:

- ISCP: 2 occurrences (entries 11, 12)
- DevEx: 3 occurrences (entries 27, 28, 82)
- mdpal-cli: 2 occurrences (entries 18, 19)

**Total: 7 cd-to-main-repo violations across 3 sessions.** This suggests agents have a persistent belief that dispatch/flag tools only work from the main repo checkout. Either the tools actually require it (likely false — they use `CLAUDE_PROJECT_DIR` and `~/.agency/`) or the agents absorbed this pattern from early sessions when it may have been necessary.

### Pattern 2: Dispatch loop startup overhead

Every session sets up a `/loop 5m dispatch check` cron. This requires:
- Skill tool call → skill text injection (1 entry)
- ToolSearch for CronCreate (1 tool call)
- CronCreate (1 tool call)

Three tool calls for something that happens every session. If the dispatch loop were set up automatically by the SessionStart hook or via the agent's hookify rules, this would cost zero explicit tool calls.

### Pattern 3: Startup reads the same files every time

All three sessions read:
- Their workstream KNOWLEDGE.md (always empty or near-empty)
- The tech-lead agent class definition (rarely changes)
- The Valueflow A&D (never changes between sessions)

These are low-value reads. The handoff should carry the key context so agents can skip re-reading static files every session. Currently the handoffs tell agents to read these files on every startup.

### Pattern 4: Compound commands at startup

All three agents open with compound commands for dispatch/flag. None triggered permission rejections in these sessions (permissions are now correctly configured), but they still violate CLAUDE.md discipline. The `2>&1` stderr redirect is particularly common and unnecessary — tool output already goes to stderr in useful ways.

### Pattern 5: Raw `git commit` instead of `/git-commit`

DevEx used raw `git add && git commit` twice (entries 60, 87). The second one succeeded. The `/git-commit` wrapper was bypassed. This is a hookify rule gap — the rule exists but apparently doesn't block the compound form.

### Pattern 6: Stop hook causes reactive micro-sessions

DevEx got a stop hook alert about `.agency-agent` being dirty (entry 53). This triggered:
- 1 git diff
- 1 git add && git commit (compound, failed)
- 1 git status
- 1 git log

Four tool calls to handle something that should have been a no-op (the file was already committed). The stop hook is doing its job, but the `.agency-agent` mechanism generates false alerts when worktrees share the same file.

---

## 3. Prioritized Fixes

### P1: Fix the dispatch/flag cd-to-main-repo habit (HIGH — affects every session)

**Observed:** All 3 agents prefix dispatch/flag commands with `cd /Users/jdm/code/the-agency &&`. 7 violations in 3 sessions.

**Why it's wrong:** The tools work from any directory — they resolve project root via `CLAUDE_PROJECT_DIR`. The cd is unnecessary and creates a compound command.

**Actual check needed:** Verify the tools actually work from worktree CWDs without cd. If there's a real bug where they don't, fix the tools. If they do work, the problem is the agents' mental model.

**Fix options:**
- **CLAUDE.md update:** Add explicit callout: "dispatch and flag tools work from any worktree CWD. Never prefix them with `cd /path/to/main-repo &&`."
- **Hookify rule:** Block `cd .*/the-agency && .*dispatch` and `cd .*/the-agency && .*flag` with guidance to use relative paths.
- **Tool improvement:** Make the tools print a diagnostic if run from a worktree to confirm they're resolving correctly, so agents gain confidence they work from anywhere.

**What to change:** CLAUDE-THEAGENCY.md (add callout in ISCP section), hookify rule in `claude/hookify/`.

---

### P2: Automate the dispatch loop (HIGH — affects every session)

**Observed:** All 3 agents spend 3 tool calls setting up `/loop 5m dispatch check` as their first explicit startup action. It happens every session without exception.

**Fix:** Move the dispatch loop setup into the SessionStart hook. The `iscp-check` hook already fires on SessionStart — the loop should be automatically initialized there or via a hookify rule that fires on agent boot.

Alternatively: the agent class definition (`claude/agents/tech-lead/agent.md`) should specify that the dispatch loop is automatic infrastructure, not a manual startup step — and the SessionStart hook should CronCreate it.

**What to change:** SessionStart hook or hookify rule; remove dispatch loop setup from handoff startup sequences.

---

### P3: Resolve the `.agency-agent` dirty-file problem (HIGH — causes confusion and wasted tool calls)

**Observed:** Both ISCP and DevEx sessions encountered `.agency-agent` showing as modified. DevEx spent 4 tool calls handling a stop hook alert about it. The file gets set to the last-running agent's name, which is always "wrong" when a different agent starts.

**Root causes:**
1. `.agency-agent` is a shared file across all agents in the worktree (it tracks "which agent is this worktree"). When worktrees are truly per-agent, this should be set at worktree creation and never change.
2. The current implementation updates it at runtime, which creates churn.

**Fix options:**
- **Per-agent worktrees:** If each worktree belongs to exactly one agent, set `.agency-agent` at `worktree-create` time and never update it again. No runtime modification = no dirty file.
- **Gitignore it:** Add `.agency-agent` to `.gitignore` if it doesn't need to be version-controlled (it's runtime state).
- **Stop hook tolerance:** Update the stop hook to not flag `.agency-agent` as a concern — it's expected churn.

**What to change:** `worktree-create` skill, `.gitignore`, stop hook `quality-check.sh`.

---

### P4: Add compound command hookify rule for worktrees (HIGH — affects all agents)

**Observed:** 12+ compound command violations across 3 sessions. CLAUDE.md explicitly prohibits them but agents consistently use `&&`, `||`, `;`, and pipes.

**Currently:** The hookify warning exists for `git commit` but not for `&&` chains in general. Agents have absorbed the compound command prohibition verbally but don't have mechanical enforcement.

**Fix:** Hookify rule that triggers on patterns like `&& git`, `&& ./claude/tools/`, `;` chains in Bash tool calls. The rule should:
1. Block the call
2. Explain why (CWD resets, permission model)
3. Show the simple form

**Caveat:** Some `&&` is legitimate (build commands, heredoc commit messages). The rule needs to be specific to the problematic patterns — primarily `cd /path && tool` and `git add X && git commit`.

**What to change:** New hookify rule in `claude/hookify/hookify.compound-commands.md`.

---

### P5: Fix the raw-git-commit bypass (HIGH — QG integrity issue)

**Observed:** DevEx used `git add X && git commit` twice, bypassing `./claude/tools/git-commit`. The second commit succeeded without QGR verification.

**Currently:** There's a hookify rule warning about raw `git commit` but it didn't block the DevEx instance. This may be because:
- The rule fires on bare `git commit` but the compound form `git add X && git commit` is parsed differently
- The agent was responding to a stop hook (reactive mode) which may suppress hookify

**Fix:** Verify the hookify rule fires on the compound `git add && git commit` pattern. If not, update the pattern to catch it. The QGR bypass is a real integrity issue — it undermines the quality gate entirely.

**What to change:** `claude/hookify/hookify.warn-raw-git-commit.md` (or equivalent) — strengthen pattern matching.

---

### P6: Reduce mandatory startup reads (MEDIUM — token economy)

**Observed:** All 3 sessions read files that rarely change (KNOWLEDGE.md, agent class definition, Valueflow A&D). KNOWLEDGE.md for both DevEx and ISCP is nearly empty. The agent class definition hasn't changed in weeks. Valueflow A&D is frozen pending principal review.

**Fix:** Update handoff templates and agent startup sequences to:
1. Skip KNOWLEDGE.md reads when the file is empty (or instruct agents not to read it as a startup action — let it be reference-on-demand)
2. Skip agent class reads — the agent knows its class from the handoff
3. Reference stable artifacts by key decision, not by re-reading the full document

**What to change:** Handoff template, agent class `agent.md` startup sequence, `CLAUDE-THEAGENCY.md` startup guidance.

---

### P7: Fix mdpal-cli handoff's false "complete" claim (MEDIUM — off-rails behavior)

**Observed:** mdpal-cli handoff claimed "iteration 1.1 code is complete" but the code was never committed. The agent rebuilt it from scratch.

**Root cause:** The previous session wrote the handoff AFTER the session ended (SessionEnd trigger), claiming work that was done but not committed. The stop hook should have caught uncommitted code files.

**Fix:**
1. The stop hook `quality-check.sh` should check for uncommitted new files that look like implementation (not just tracked-but-modified files)
2. The handoff template should not encourage agents to claim completion for work that isn't committed
3. Stronger: the `handoff` tool could check `git status` and refuse to write "Current State" claims that contradict dirty/uncommitted state

**What to change:** `claude/hooks/quality-check.sh`, handoff write guidance in `CLAUDE-THEAGENCY.md`.

---

### P8: Fix the cwd-reset confusion in mdpal-cli (MEDIUM — wasted tool calls)

**Observed:** mdpal-cli ran `cd apps/mdpal && swift build` to build in the package directory. On the next call, tried `cd apps/mdpal && swift test` — which failed because the shell was already in `apps/mdpal`. Classic cwd-reset confusion.

**This is the exact problem CLAUDE.md warns about** ("The shell already starts in cwd"). The agent used `cd` in the prior command, which made it expect that CWD would persist.

**Fix:** Hookify rule: "Never use `cd` to navigate into a subdirectory for a single command. Use absolute paths or run the command from the correct CWD." Additionally, the mdpal-cli handoff should note the correct CWD for swift build operations.

**What to change:** Hookify rule, mdpal-cli handoff CWD documentation.

---

### P9: Make dispatch list direction-aware (LOW — minor confusion)

**Observed:** ISCP agent received its own outbound dispatches as "unread mail" and had to mentally filter them. Spent 4 tool calls processing outbound-as-inbound mail.

**Fix:** `dispatch list` should separate inbound (to-me, unread) from outbound (from-me, awaiting captain). Or add a `--inbox` flag that shows only dispatches where `to == current_agent`. The default view (`dispatch list`) should be inbox-only.

**What to change:** `claude/tools/dispatch` — add `--inbox` filter or change default behavior.

---

## 4. Summary Table

| # | Issue | Sessions Affected | Tool Calls Wasted | Fix Type |
|---|-------|-------------------|-------------------|----------|
| P1 | cd-to-main-repo for dispatch/flag | All 3 | 7 | Hookify rule + CLAUDE.md |
| P2 | Manual dispatch loop setup | All 3 | 9 (3 per session) | SessionStart hook |
| P3 | .agency-agent dirty file noise | ISCP, DevEx | 4-6 | worktree-create + .gitignore |
| P4 | Compound command violations | All 3 | 12+ | Hookify rule |
| P5 | Raw git commit bypass | DevEx | 2 (+ QG integrity risk) | Hookify rule strengthening |
| P6 | Redundant startup reads | All 3 | 6-9 | CLAUDE.md + handoff updates |
| P7 | False "complete" in handoff | mdpal-cli | Full session rebuild | stop hook + handoff discipline |
| P8 | cwd-reset confusion | mdpal-cli | 3 | Hookify rule |
| P9 | Dispatch inbox/outbox confusion | ISCP | 4 | dispatch tool |

**Total observable tool call waste across 3 sessions: ~45-52 tool calls** out of roughly 130 effective tool calls. That's 30-40% overhead attributable to framework friction.

---

## 5. What the Principal Is Frustrated About

The specific complaint was "permission prompts and startup problems."

**On permission prompts:** In these three sessions, there are zero `tool_rejected` events and zero true permission-model rejections. The permission model is working correctly for all three agents. The prior friction (flags #1-3 captured 2026-04-05) has been resolved. These sessions do not reproduce the permission prompt problem.

**However:** The cd-to-main-repo pattern (P1) persists despite the permissions being fixed. This suggests agents adopted the cd prefix as a workaround during the period when the permissions weren't working, and the workaround became habitual even after the fix. The hookify rule (P4) would break this habit.

**On startup problems:** The startup is slow (9-10 tool calls before actual work), partially redundant (same files read every session), and produces confusing noise (`.agency-agent` dirty, dispatch loop setup, outbound-as-inbound mail). None of these are showstoppers, but they add up to a startup experience that feels broken even when it's technically functional.

The mdpal-cli session had the worst startup due to the lost-code situation — that's a one-time problem from a prior session failure, not a systematic startup bug.

---

*Analysis completed 2026-04-07. Based on direct JSONL transcript reading for all three sessions.*
