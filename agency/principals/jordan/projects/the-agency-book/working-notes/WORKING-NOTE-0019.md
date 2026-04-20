# THE-AGENCY-BOOK-WORKING-NOTE-0019

**Date:** 2026-01-06 15:00 SGT
**Participants:** jordan (principal), housekeeping (agent)
**Subject:** Workshop Installation Flow — One-Command Setup

---

## The Goal

Reduce workshop friction to absolute minimum. Participants should go from nothing to talking to their first agent with a single command.

---

## The Solution

**Pre-work:** Get Claude Pro/Max account at claude.ai

**Workshop:** One command:

```bash
AGENCY_TOKEN=xxx curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash -s -- my-project
```

**That's it.** The script handles everything else.

---

## What the Script Does

| Step | Action | Notes |
|------|--------|-------|
| 1 | Check git | Required, can't auto-install |
| 2 | Install Claude Code | Auto-installs if missing (macOS/Linux/Windows) |
| 3 | Check Claude auth | Prompts login if first time |
| 4 | Check recommended tools | jq, gh, tree, yq, fzf, bat, rg |
| 5 | Clone repo | Uses AGENCY_TOKEN for private repo access |
| 6 | Fresh git init | Clean history for their project |
| 7 | chmod +x tools/* | Make all 40 tools executable |
| 8 | Platform setup | Installs missing tools via brew (macOS) |
| 9 | Prompt to launch | "Launch The Captain now? [Y/n]" |
| 10 | Launch agent | `exec ./tools/myclaude housekeeping housekeeping` |

After launch, participant types `/welcome` to start the 10-minute guided interview.

---

## Design Decisions

### Why install Claude Code automatically?

We debated requiring Claude Code as pre-work. But:
- One more step = more friction
- Some participants will forget
- The script can do it in seconds

### Why check auth but not force login?

If `~/.claude/history.jsonl` exists, they've used Claude before. If not, we prompt but don't block — Claude itself will handle auth on first real use.

### Why auto-launch The Captain?

Getting participants into their first agent session immediately:
- Creates momentum
- Shows them it works
- Sets expectation that agents are the primary interface

### Why `/welcome` after launch?

Separating install from onboarding interview:
- Install is mechanical (script handles it)
- Onboarding is conversational (agent handles it)
- Different concerns, different modes

### Why AGENCY_TOKEN in command?

For private repo access during beta. Once public, the token is optional.

---

## Book Integration

### Chapter 4: Getting Set Up

The workshop flow validates the Chapter 4 content. Key alignment:

| Chapter 4 Section | Workshop Equivalent |
|-------------------|---------------------|
| Prerequisites | Pre-work (Claude account only) |
| Install Claude Code | Script step 2 |
| Clone the Starter | Script step 5 |
| Initialize | Script steps 6-8 |
| First agent | Script steps 9-10 |
| Verification | `/welcome` interview |

The book can reference the one-command install while explaining what happens under the hood.

### Suggested Book Text

> **The Fast Path**
>
> If you just want to get started:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash -s -- my-project
> cd my-project
> ./tools/myclaude housekeeping housekeeping
> ```
>
> Then type `/welcome` to meet The Captain.
>
> The rest of this chapter explains what that command does. If you're the type who likes to understand before doing, read on. If you prefer learning by doing, come back to this chapter when you're curious about what's under the hood.

---

## Workshop Materials Created

1. **WORKSHOP.md** — Facilitator guide in the-agency-starter repo
   - Pre-work email template
   - Live workshop flow (45-90 min)
   - Troubleshooting guide
   - FAQ

2. **install.sh** — Updated with:
   - Claude Code auto-install
   - Auth detection and prompting
   - Platform setup (brew on macOS)
   - Auto-launch into myclaude
   - TTY handling for curl pipe

3. **/welcome command** — Already existed:
   - 10-minute guided interview
   - Creates workstream and agent
   - Builds something real

---

## Tested Flow

```
$ AGENCY_TOKEN=xxx curl ... | bash -s -- my-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  The Agency Starter
  Multi-Agent Development Framework for Claude Code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking prerequisites...

  ✓ git
  ✓ Claude Code already installed

Checking Claude authentication...
  ✓ Claude has been used before

Recommended:
  ✓ jq
  ✓ gh
  ✓ tree
  ... (continues)

Installing to: my-project

Cloning The Agency Starter...
Setting up tools...
Configuring principal...
Running platform setup...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Installation Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your Agency is ready at: /path/to/my-project

Ready to meet your first agent?

Launch The Captain now? [Y/n] y

Launching The Captain (housekeeping agent)...

Once inside, type: /welcome
```

---

## What Participants Get

After the one command:
- 40 tools ready to use
- Housekeeping agent configured
- Fresh git repo with clean history
- Platform tools installed (macOS: jq, gh, tree, yq, fzf, bat, rg)
- They're talking to The Captain

After `/welcome`:
- Their own workstream created
- Their own agent created
- Something built (a simple tool)
- Understanding of the basic structure

---

## Time Breakdown

| Phase | Time |
|-------|------|
| Pre-work (Claude account) | 5-10 min (done before) |
| Run install command | 2-3 min |
| `/welcome` interview | 10 min |
| **Total to first agent** | **~15 min** |

---

_Working note for project: the-agency-book_
_Documents workshop installation flow for Chapter 4 reference_
