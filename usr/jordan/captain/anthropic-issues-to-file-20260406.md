---
type: tracking
date: 2026-04-06
updated: 2026-04-11
status: drafts-ready-awaiting-filing
---

# Claude Code Issues to File with Anthropic

Collected issues from The Agency development. `/feedback` is broken (see item 4), so all items file via GitHub issues at https://github.com/anthropics/claude-code/issues.

## Filing status (2026-04-11)

All five items have been drafted as proper feedback reports in `usr/jordan/reports/`. Awaiting principal review before filing to GitHub.

| # | Item | Draft location | Status |
|---|------|----------------|--------|
| 1 | --agent/--name env var missing | [feedback-agent-name-env-var-20260411.md](../reports/feedback-agent-name-env-var-20260411.md) | draft |
| 2 | Brace expansion triggers permission prompts | Folded into [feedback-agent-permission-ux-20260411.md](../reports/feedback-agent-permission-ux-20260411.md) | draft (combined with broader permission UX feedback) |
| 3 | macOS permissions break on every update | [feedback-macos-permissions-break-on-update-20260411.md](../reports/feedback-macos-permissions-break-on-update-20260411.md) | draft |
| 4 | /feedback command silently fails (META) | [feedback-slash-feedback-silent-failure-20260411.md](../reports/feedback-slash-feedback-silent-failure-20260411.md) | draft |
| 5 | Content filter returns no signal (NEW 2026-04-11) | [feedback-content-filter-opacity-20260411.md](../reports/feedback-content-filter-opacity-20260411.md) | draft — tweet public |

Original brief descriptions preserved below for reference.

---

---

## 1. --name flag does not set AGENTNAME environment variable

**Summary:** When launching an agent with `claude --agent devex` or `claude --name devex`, the spawned process does not receive an environment variable (e.g., `AGENTNAME` or `CLAUDE_AGENT_NAME`) containing the agent name. All agent terminal tabs show a generic "agent" label, making it impossible to distinguish between concurrent agents.

**Steps to Reproduce:**
1. Launch multiple agents: `claude --agent devex`, `claude --agent captain`
2. Inspect environment variables in each session (`env | grep -i agent`, `env | grep -i claude`)
3. Observe terminal tab titles

**Expected:** An environment variable (e.g., `CLAUDE_AGENT_NAME=devex`) is set in the agent process, allowing terminal multiplexers, status lines, and shell prompts to display the specific agent name.

**Actual:** No agent-name environment variable is set. All agent tabs display "agent" generically. `$CLAUDE_AGENT_NAME` is unset.

**Impact:** When running multiple agents simultaneously (captain, devex, pm), there is no programmatic way to determine which agent is running in which terminal. Blocks terminal status line differentiation, automated tab naming, and agent-aware shell scripting. This is a fundamental gap for multi-agent workflows.

**Workaround:** None that preserves the `--agent` launch path. Manual tab renaming is fragile and does not survive terminal restarts.

---

## 2. Brace expansion triggers permission prompts

**Summary:** Bash commands containing brace expansion (e.g., `mkdir -p {a,b,c}`) trigger Claude Code's permission system as though they are compound or multiple commands. This forces tools to avoid standard shell idioms and use verbose alternatives.

**Steps to Reproduce:**
1. In a Claude Code session, run a bash command with brace expansion: `mkdir -p dir/{sub1,sub2,sub3}`
2. Observe the permission prompt

**Expected:** Brace expansion is a single command — the shell expands it before execution. It should be treated as a single `mkdir` invocation and matched against the allowed-tools list normally.

**Actual:** Claude Code treats the brace expansion as a compound command (possibly parsing it as multiple commands due to the commas or braces). A permission prompt is triggered even when `mkdir` is in the allowed list.

**Impact:** Tools like `agency-init` that scaffold directory trees must avoid brace expansion entirely, resulting in verbose repetitive code (one `mkdir` per directory). This is a tax on every tool that creates multiple paths, copies multiple files, or uses any brace-expansion pattern.

**Workaround:** Replace all brace expansion with separate individual commands. E.g., replace `mkdir -p {a,b,c}` with three separate `mkdir -p a`, `mkdir -p b`, `mkdir -p c` calls.

---

## 3. macOS permissions break on every Claude Code update

**Summary:** macOS accessibility and automation permissions are pinned to the specific binary path, which includes the Claude Code version number. Every update changes the binary path, invalidating all previously granted permissions. Users must re-grant permissions in System Settings after every update.

**Steps to Reproduce:**
1. Grant Claude Code accessibility/automation permissions in System Settings > Privacy & Security
2. Update Claude Code to a new version (e.g., 2.1.63 to 2.1.64)
3. Attempt to use features requiring accessibility permissions (e.g., Computer Use MCP)
4. Observe permission failure

**Expected:** Permissions persist across updates. The binary path used for permission grants should be version-stable (e.g., a symlink or stable wrapper path that does not change between versions).

**Actual:** The permission-granting path includes the version number. Each update is a new binary path from macOS's perspective, requiring the user to navigate System Settings > Privacy & Security > Accessibility, remove the old entry, and add the new one. On some updates, the old entry remains as a ghost and the new binary must be manually located.

**Impact:** Every Claude Code update (often multiple per week) requires manual macOS permission re-granting. This is especially painful for Computer Use MCP, which requires accessibility permissions to function. The friction discourages staying on the latest version. Not fixable in the framework — requires Anthropic to use a stable binary path or symlink for the permission target.

**Workaround:** Manually re-grant permissions after each update. Some users create shell aliases that re-symlink, but this is fragile and version-specific.

---

## 4. /feedback command silently fails

**Summary:** The `/feedback` command accepts input, generates a feedback SHA, and reports success — but the feedback is never actually filed. Silent failure with no error message.

**Steps to Reproduce:**
1. Run `/feedback` in a Claude Code session
2. Enter feedback text
3. Receive a SHA confirmation
4. Check for the filed feedback (GitHub issues, Anthropic feedback portal)

**Expected:** Feedback is submitted to Anthropic and appears in their tracking system. The SHA should correspond to a retrievable record.

**Actual:** The command completes with a SHA but no feedback is filed. No error message indicates failure. The SHA does not correspond to any retrievable record.

**Impact:** Users believe their feedback has been submitted when it has not. This erodes trust in the feedback mechanism and means legitimate bugs and feature requests are silently lost. The only reliable alternative is filing GitHub issues directly on the claude-code repo.

**Workaround:** File issues directly on GitHub at https://github.com/anthropics/claude-code/issues instead of using `/feedback`.
