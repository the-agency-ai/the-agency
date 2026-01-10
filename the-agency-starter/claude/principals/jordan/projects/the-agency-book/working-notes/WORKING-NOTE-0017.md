# THE-AGENCY-BOOK-WORKING-NOTE-0017

**Date:** 2026-01-06 12:30 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Boris Cherny's "How I Use Claude Code" - Creator's Workflow
**Source:** https://threads.net/@boris_cherny (captured via screenshots)

---

## The Thread (Complete)

### Introduction

> "I'm Boris and I created Claude Code. Lots of people have asked how I use Claude Code, so I wanted to show off my setup a bit."
>
> "My setup might be surprisingly vanilla! Claude Code works great out of the box, so I personally don't customize it much. There is no one correct way to use Claude Code: we intentionally built it in a way that you can use it, customize it, and hack it however you like. Each person on the Claude Code team uses it very differently."
>
> "So, here goes."

---

### 1. Parallel Terminal Sessions

> "I run 5 Claudes in parallel in my terminal. I number my tabs 1-5, and use system notifications to know when a Claude needs input."

**The Agency parallel:** This is exactly what `./tools/myclaude` does with named tabs.

---

### 2. Cloud + Local Hybrid

> "I also run 5-10 Claudes on claude.ai/code, in parallel with my local Claudes. As I code in my terminal, I will often hand off local sessions to web (using &), or manually kick off sessions in Chrome, and sometimes I will --teleport back and forth."
>
> "I also start a few sessions from my phone (from the Claude iOS app) every morning and throughout the day, and check in on them later."

**Key insight:** 10-15 Claude instances running simultaneously across terminal, web, and mobile.

---

### 3. Model Choice: Opus for Everything

> "I use Opus 4.5 with thinking for everything. It's the best coding model I've ever used, and even though it's bigger & slower than Sonnet, since you have to steer it less and it's better at tool use, it is almost always faster than using a smaller model in the end."

**Key insight:** Steering overhead makes smaller models slower in practice.

---

### 4. Shared CLAUDE.md

> "Our team shares a single CLAUDE.md for the Claude Code repo. We check it into git, and the whole team contributes multiple times a week. Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time."
>
> "Other teams maintain their own CLAUDE.md's. It is each team's job to keep theirs up to date."

Example from their CLAUDE.md:

```
# Development Workflow
**Always use 'bun', not 'npm'.**

# 1. Make changes
# 2. Typecheck (fast)
bun run typecheck
# 3. Run tests
bun run test -- -t "test name"    # Single suite
bun run test:file -- "glob"       # Specific files
# 4. Lint before committing
bun run lint:file -- "file1.ts"   # Specific files
bun run lint                      # All files
# 5. Before creating PR
bun run lint:claude && bun run test
```

**The Agency parallel:** This is our `CLAUDE.md` + `KNOWLEDGE.md` pattern.

---

### 5. Compounding Engineering via Code Review

> "During code review, I will often tag @claude on my coworkers' PRs to add something to the CLAUDE.md as part of the PR. We use the Claude Code GitHub action (/install-github-action) for this. It's our version of @danshipper's Compounding Engineering."

Shows Claude responding to:

> "rb: use a string literal, not to enum"
> "@claude add to CLAUDE.md to never use enums, always prefer literal unions"

Claude then:

1. Read current CLAUDE.md to understand existing guidance
2. Updated CLAUDE.md to strengthen "no enums" guidance
3. Committed the change

**Key insight:** The knowledge base compounds automatically through code review.

---

### 6. Plan Mode First

> "Most sessions start in Plan mode (shift+tab twice). If my goal is to write a Pull Request, I will use Plan mode, and go back and forth with Claude until I like its plan. From there, I switch into auto-accept edits mode and Claude can usually 1-shot it. A good plan is really important!"

**Key insight:** Planning → Auto-accept = high quality + speed.

---

### 7. Slash Commands for Inner Loops

> "I use slash commands for every inner loop workflow that I do many times a day. This saves me from repeated prompting, and makes it so Claude can use these workflows, too. Commands are checked into git and live in .claude/commands/."
>
> "eg. Claude and I use a /commit-push-pr slash command every day."

```
> /commit-push-pr    Commit, push, and open a PR
```

**The Agency parallel:** This is our `./tools/` pattern.

---

### 8. Subagents for Common Workflows

> "I use a few subagents regularly: code-simplifier simplifies the code after Claude is done working, verify-app has detailed instructions for testing Claude Code end to end, and so on. Similar to slash commands, I think of subagents as automating the most common workflows that I do for most PRs."

His `.claude/agents/` directory:

- `build-validator.md`
- `code-architect.md`
- `code-simplifier.md`
- `oncall-guide.md`
- `verify-app.md`

**The Agency parallel:** This is our agent specialization pattern.

---

### 9. PostToolUse Hook for Formatting

> "We use a PostToolUse hook to format Claude's code. Claude usually generates well-formatted code out of the box, and the hook handles the last 10% to avoid formatting errors in CI later."

```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "bun run format || true"
      }
    ]
  }
]
```

**The Agency parallel:** This is our pre-commit hook pattern.

---

### 10. Permissions Pre-configuration

> "I don't use --dangerously-skip-permissions. Instead, I use /permissions to pre-allow common bash commands that I know are safe in my environment, to avoid unnecessary permission prompts. Most of these are checked into .claude/settings.json and shared with the team."

His allowed commands:

```
12. Bash(bq query:*)
13. Bash(bun run build:*)
14. Bash(bun run lint:file:*)
15. Bash(bun run test:*)
16. Bash(bun run test:file:*)
17. Bash(bun run typecheck:*)
18. Bash(test:*)
19. Bash(cc:*)
20. Bash(comm:*)
21. Bash(find:*)
```

**The Agency parallel:** This is our `.claude/settings.local.json` pattern.

---

### 11. MCP for External Tools

> "Claude Code uses all my tools for me. It often searches and posts to Slack (via the MCP server), runs BigQuery queries to answer analytics questions (using bq CLI), grabs error logs from Sentry, etc. The Slack MCP configuration is checked into our .mcp.json and shared with the team."

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://slack.mcp.anthropic.com/mcp"
    }
  }
}
```

---

### 12. Long-Running Tasks with Verification

> "For very long-running tasks, I will either prompt Claude to verify its work with a background agent when it's done, use an agent Stop hook to do that more deterministically, or use the ralph-wiggum plugin. I will also use either --permission-mode=dontAsk or --dangerously-skip-permissions in a sandbox to avoid permission prompts for the session, so Claude isn't blocked on me."

Shows a session running: **"Reticulating... (1d 2h 47m - 2.4m tokens - thinking)"**

**Key insight:** Sessions can run for over a day, consuming millions of tokens.

---

### 13. The Final Tip: Feedback Loops

> "A final tip: probably the most important thing to get great results out of Claude Code -- **give Claude a way to verify its work**. If Claude has that feedback loop, it will 2-3x the quality of the final result."
>
> "Claude tests every change I land on claude.ai/code using the Chrome extension. It opens a browser, tests the UI, and iterates until the code works."

**This is the key insight for The Agency:** Verification loops are the multiplier.

---

### Community Response

**@pbw2049:**

> "'My setup might be surprisingly vanilla' and then proceeds to describe extremely complicated setup with five copies in parallel, plus more in the cloud, plus having CC read and post to Slack! But good to hear these details!"

**@olivbruno:**

> "How much does this cost for someone outside of Anthropic? Easily 50-60 USD per day, per person?"

---

## Comprehensive Pattern Analysis

### Boris's 13 Patterns vs The Agency

| # | Boris Pattern | What Boris Does | The Agency: Current | The Agency: Plans | Should Consider |
|---|---------------|-----------------|---------------------|-------------------|-----------------|
| 1 | **Parallel Sessions** | 5 terminal tabs numbered 1-5, system notifications | `./tools/myclaude` creates named tabs per agent/workstream | - | ✅ Parity achieved |
| 2 | **Cloud + Local Hybrid** | 5-10 more on claude.ai/code, `--teleport` between, mobile sessions | Local only currently | - | 🤔 Add `--teleport` workflow? Document cloud handoff? |
| 3 | **Opus for Everything** | Uses Opus 4.5 with thinking; steering overhead makes smaller models slower | Opus as conductor, Sonnet/Haiku for subagents | - | 🤔 Reconsider? Boris says Opus faster overall |
| 4 | **Shared CLAUDE.md** | Single CLAUDE.md in git, team contributes weekly | CLAUDE.md + KNOWLEDGE.md per agent/workstream | - | ✅ We go further with layered knowledge |
| 5 | **Compounding Engineering** | `@claude` in PR reviews to update CLAUDE.md via GitHub action | Manual knowledge updates | PROP-0014 Knowledge Indexer | 🔴 Add GitHub action for auto CLAUDE.md updates |
| 6 | **Plan Mode First** | shift+tab twice, iterate on plan, then auto-accept for 1-shot | We use plan mode | - | ✅ Parity achieved |
| 7 | **Slash Commands** | `.claude/commands/` for inner loops, e.g., `/commit-push-pr` | `./tools/` directory with 50+ tools | - | ✅ We go further |
| 8 | **Subagents** | `.claude/agents/` for code-simplifier, verify-app, etc. | `claude/agents/` with specialized agents | - | ✅ Parity achieved |
| 9 | **PostToolUse Hooks** | Format on Write/Edit automatically | Pre-commit hooks (5-step) | - | 🤔 Add PostToolUse for instant formatting? |
| 10 | **Permissions Pre-config** | `/permissions` to pre-allow safe commands, shared in settings.json | `.claude/settings.local.json` with extensive allow list | - | ✅ Parity achieved |
| 11 | **MCP for External Tools** | Slack, BigQuery, Sentry via MCP servers | Limited MCP usage | - | 🔴 Document MCP patterns, add common servers |
| 12 | **Long-Running Tasks** | 1d+ sessions, 2.4M tokens, Stop hooks, ralph-wiggum plugin | Session backup/restore | - | 🤔 Add Stop hooks for verification? |
| 13 | **Verification Loops** | Chrome extension tests UI, iterates until works; 2-3x quality | Pre-commit checks, code review tool | PROP-0015 CDP for browser | 🔴 Key gap - need automated verification |

### Additional Patterns Observed

| # | Pattern | What Boris Does | The Agency: Current | The Agency: Plans | Should Consider |
|---|---------|-----------------|---------------------|-------------------|-----------------|
| 14 | **Notifications** | System notifications when Claude needs input | Terminal stays open | - | 🤔 Add notification tool? |
| 15 | **Mobile Sessions** | Starts from Claude iOS app, checks later | Not supported | - | 📝 Document as option |
| 16 | **Team Shared Config** | `.claude/settings.json` + `.mcp.json` in git | `.claude/settings.local.json` (local) | PROP-0006 dist vs local | ✅ Planned in distribution structure |
| 17 | **No dangerously-skip** | Never uses --dangerously-skip-permissions | Same philosophy | - | ✅ Aligned |

### What The Agency Does That Boris Doesn't Mention

| # | The Agency Pattern | What We Do | Boris Equivalent | Advantage |
|---|-------------------|------------|------------------|-----------|
| A | **Principal/Agent Hierarchy** | Structured relationship, instructions flow down | Single-user, flat | Scales to teams |
| B | **Structured Work Tracking** | WORKLOG.md, ADHOC-WORKLOG.md, instructions | Not mentioned | Audit trail, continuity |
| C | **Agent Collaboration** | `./tools/collaborate`, `post-news`, `read-news` | Shared CLAUDE.md only | Async agent-to-agent |
| D | **Quality Gates** | 5-step pre-commit-check | Hooks handle some | More comprehensive |
| E | **Session Persistence** | `backup-session`, `restore`, context files | Uses --teleport | Works offline, versioned |
| F | **Time Awareness** | `./tools/now`, SGT default | Not mentioned | Consistent timestamps |
| G | **Identity System** | `whoami`, `agentname`, `workstream` | Not mentioned | Multi-agent clarity |
| H | **Artifact Capture** | `capture-artifact`, `capture-instruction` | Not mentioned | Principal deliverables |

---

## Gap Priority

### 🔴 High Priority (Should Add)

1. **Compounding Engineering** - GitHub action to auto-update CLAUDE.md from PR reviews
2. **MCP Integration Patterns** - Document and provide common MCP server configs
3. **Automated Verification** - Beyond pre-commit; test UI, iterate until works

### 🤔 Consider Adding

1. **Cloud Handoff** - Document `--teleport` workflow for hybrid local/cloud
2. **PostToolUse Hooks** - Instant formatting vs batch pre-commit
3. **Stop Hooks** - Verification agent triggered on task completion
4. **Notifications** - Alert when agent needs input (long-running tasks)

### ✅ Parity or Better

- Parallel sessions (named tabs)
- Shared knowledge (we layer it better)
- Slash commands / tools
- Subagents
- Permissions
- Plan mode
- No dangerous skip

---

## Key Quotes for the Book

> "There is no one correct way to use Claude Code: we intentionally built it in a way that you can use it, customize it, and hack it however you like."

> "Since you have to steer [Opus] less and it's better at tool use, it is almost always faster than using a smaller model in the end."

> "Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time." (Compounding Engineering)

> "A good plan is really important!"

> "Probably the most important thing to get great results out of Claude Code -- give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."

---

## Book Placement

- **Chapter: Working with Claude Code** - Reference Boris's vanilla approach as validation
- **Chapter: Team Workflows** - Compounding Engineering via shared CLAUDE.md
- **Chapter: Verification** - The 2-3x quality multiplier from feedback loops
- **Introduction** - "The creator of Claude Code runs 10-15 instances in parallel"

---

_Working note for project: the-agency-book_
_Source: Screenshots captured 2026-01-06 from Threads_
