# Chapter 4: Getting Set Up

## Review Convention

When reviewing this chapter, use this format:

```
[Reviewer: Original block being reviewed]
[Reviewer: Instructions, rewrite, commentary, questions, etc.]
```

**Rules:**
- Copy the EXACT text being reviewed in the first bracket
- Put your feedback in the second bracket
- Be specific — quote the text you're addressing
- One issue per bracket pair (multiple pairs fine)

---

## Housekeeping Review (2026-01-06)

[(housekeeping) **Claude Pro** | $20/month | Good for learning, light usage... **Claude Max 5x** | $100/month | Serious work, multiple agents... **Claude Max 20x** | $200/month | Heavy usage, parallel agents]
[(housekeeping) Verify pricing before publication. Also: Boris Cherny notes that Opus 4.5 is "almost always faster than using a smaller model in the end" due to less steering overhead. Consider adding a note that the cost difference between Pro and Max may be less than expected when accounting for productivity.]

[(housekeeping) If you're coming from the API side, you can also use Claude Console with pre-paid credits.]
[(housekeeping) "Claude Console" — verify this is the correct product name. I believe it's "Anthropic Console" or just "console.anthropic.com". Also may want to mention that Claude Code can be configured to use API credits instead of subscription.]

[(housekeeping) **Terminal** | iTerm2 (macOS), Windows Terminal, or any terminal with tab support]
[(housekeeping) Excellent — this addresses the tab naming requirement. ✓ Approve.]

[(housekeeping) **Why These Matter**... **Terminal with tab support** — The Agency names your terminal tabs to show which agent is running.]
[(housekeeping) This is well-explained. Consider adding that this becomes critical when you have 5+ agents active — without named tabs, you lose track of which terminal is which agent.]

[(housekeeping) ### macOS or Linux... curl -fsSL https://claude.ai/install.sh | bash]
[(housekeeping) Verify this URL is correct before publication. The actual install URL may differ. Check docs.anthropic.com or claude.ai for current installation instructions.]

[(housekeeping) git clone https://github.com/the-agency-ai/the-agency-starter.git my-project]
[(housekeeping) This URL must exist and be public before book publication. Flagging as dependency — the repo needs to be created and populated with the starter content.]

[(housekeeping) ./tools/init-agency]
[(housekeeping) This tool doesn't exist yet in the starter repo. It's described but not implemented. Flagging as MUST HAVE before publication.]

[(housekeeping) **Configure the housekeeping agent** — Your guide and coordinator]
[(housekeeping) Consider whether this should be "creates the housekeeping agent directory" rather than "configures." The init script creates the structure; the agent doesn't exist until you launch it.]

[(housekeeping) ./tools/myclaude general housekeeping]
[(housekeeping) This is the correct pattern. The command format (workstream then agent) matches our convention. ✓ Approve.]

[(housekeeping) **SGT (Singapore Time)** — you can change this in configuration]
[(housekeeping) Specify WHERE to change it. Is it in CLAUDE.md? In a config file? In tools/now? Being specific helps readers actually make the change.]

[(housekeeping) ./tools/sync --dry-run]
[(housekeeping) This flag may not exist on the sync tool. Verify. If it doesn't, consider adding it or using a different verification command like `git status`.]

[(housekeeping) ### What You Get vs. Vanilla Claude Code... | Session persistence | Basic `/resume` | Full state restoration |]
[(housekeeping) Boris's thread mentions `--teleport` for session transfer between terminal and cloud. Consider noting this in the "Vanilla Claude Code" column or explaining how The Agency's approach differs (offline-capable, git-versioned).]

[(housekeeping) **The `!` Shortcut**... You can also just type commands directly — Claude understands bash. But the `!` prefix makes your intent explicit: "run this, don't interpret it."]
[(housekeeping) This is accurate and well-explained. ✓ Approve.]

[(housekeeping) ### Init script fails... If issues persist, ask in the GitHub discussions or file an issue.]
[(housekeeping) Implies GitHub Discussions will exist. This is flagged as 🚩 Open Issue in the outline. Ensure this is resolved before publication.]

[(housekeeping) **Summary**... Total time: 10-15 minutes if you already have the prerequisites. Maybe 30 minutes if you need to set up Node or a proper terminal.]
[(housekeeping) This is a good realistic estimate. Readers appreciate knowing the time investment upfront. ✓ Approve.]

---

## What We Can't Do For You

The Agency can provision a lot. It can create your agent structure, set up collaboration infrastructure, configure quality gates, and give you a framework that makes multi-agent development possible.

But there's one thing it absolutely cannot do: give you access to Claude.

Before you do anything else, you need a Claude account with sufficient capacity to run Claude Code. This is non-negotiable. Without it, nothing else in this book works.

### Claude Account Options

| Account Type | Monthly Cost | What You Get |
|--------------|--------------|--------------|
| **Claude Pro** | $20/month | Good for learning, light usage |
| **Claude Max 5x** | $100/month | Serious work, multiple agents |
| **Claude Max 20x** | $200/month | Heavy usage, parallel agents |
| **Claude Team** | $30/user/month | Team collaboration features |

**My recommendation:** Start with Pro to learn the system. Move to Max 5x when you're doing real work. I run Max 20x because I routinely have multiple agents working in parallel — during Project X, I had seven agents active simultaneously.

The cost math is simple: $200/month for capabilities that would otherwise require a team. That's the price of a few hours of contractor time for a month of unlimited AI collaboration.

If you're coming from the API side, you can also use Claude Console with pre-paid credits. But for most practitioners, a Claude.ai subscription is simpler.

### System Requirements

| Requirement | Details |
|-------------|---------|
| **Operating System** | macOS, Linux, or Windows (WSL recommended for Windows) |
| **Node.js** | Version 18 or higher |
| **Git** | For version control |
| **Shell** | bash or zsh |
| **Terminal** | iTerm2 (macOS), Windows Terminal, or any terminal with tab support |
| **GitHub Account** | For repository hosting |

Most developers already have these. If you don't, get them sorted before proceeding.

### Why These Matter

**Node.js 18+** — Claude Code is distributed via npm. You need a recent Node to install it.

**Git** — The Agency uses git for everything. Quality gates run on commit. Agents coordinate through the repository. If you're not comfortable with git basics, this isn't the framework for you.

**Terminal with tab support** — The Agency names your terminal tabs to show which agent is running. This sounds minor until you have four agents active and need to know which tab is which. iTerm2 on macOS handles this beautifully. Windows Terminal works. The default macOS Terminal does not.

**GitHub** — You'll clone The Agency Starter from GitHub. Your project will live in a repository. Collaboration between agents happens through git. GitHub isn't strictly required — any git host works — but it's what we use and document.

---

## Install Claude Code

Once you have a Claude account, installing Claude Code takes one command.

### macOS or Linux

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://claude.ai/install.ps1 | iex
```

### Verify Installation

```bash
claude --version
```

You should see a version number. If you get "command not found," add Claude to your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.claude/bin:$PATH"

# Reload your shell
source ~/.zshrc  # or ~/.bashrc
```

### First Login

Run `claude` in any directory. You'll be prompted to log in with your Claude account. Complete the authentication flow in your browser.

Once logged in, you can exit (`Ctrl+C`) — we're not going to use vanilla Claude Code. We're going to set up The Agency.

---

## Get The Agency Starter

The Agency Starter is a template repository that gives you everything you need: the directory structure, the tools, the configuration files, the conventions.

### Clone the Repository

```bash
cd ~/code  # or wherever you keep projects
git clone https://github.com/the-agency-ai/the-agency-starter.git my-project
cd my-project
```

Replace `my-project` with whatever you want to call your project.

### Make Tools Executable

```bash
chmod +x ./tools/*
```

The Agency includes 35+ tools. They're shell scripts that need execute permission.

### Initialize Your Agency

```bash
./tools/init-agency
```

This interactive script will:

1. **Ask for your name** — This becomes your principal identity
2. **Create the directory structure** — Agents, workstreams, principals, docs
3. **Set up CLAUDE.md** — The constitution that all agents read
4. **Configure the housekeeping agent** — Your guide and coordinator
5. **Initialize git hooks** — Quality gates that run on every commit

When it completes, you have a fully instrumented Agency ready to run.

---

## Launch Your First Agent

The moment of truth. Let's start an agent.

```bash
./tools/myclaude general housekeeping
```

This command has two arguments:

- **`general`** — The workstream (where work belongs)
- **`housekeeping`** — The agent name (who's doing the work)

### What Happens

1. Your terminal tab renames to show the agent context
2. Claude Code launches with Agency instrumentation
3. The agent reads CLAUDE.md and understands the framework
4. The agent checks for pending instructions, collaborations, and news
5. You get a prompt, ready to work

### First Conversation

The housekeeping agent is your guide. It knows The Agency inside and out. Start by asking it to orient you:

```
> what can you help me with?
```

Or ask it to explain the structure:

```
> explain the directory structure you just created
```

Or have it verify everything is working:

```
> run through a quick systems check
```

Housekeeping will walk you through the framework, answer questions, and help you understand what you've just set up.

---

## Verify It Works

Before going further, let's confirm everything is properly configured.

### Check Your Identity

```bash
./tools/whoami
```

Should output your principal name (what you entered during init).

```bash
./tools/agentname
```

Should output `housekeeping`.

```bash
./tools/workstream
```

Should output `general`.

### Check Timestamps

```bash
./tools/now
```

Should output the current date and time in your configured timezone. The Agency defaults to SGT (Singapore Time) — you can change this in configuration.

### Check Tool Discovery

```bash
./tools/list-tools
```

Should show all available tools, categorized by function.

### Check Git Integration

```bash
./tools/sync --dry-run
```

Should report what would be pushed (or that there's nothing to push). The `--dry-run` flag means it won't actually push anything.

If all of these work, your Agency is properly configured.

---

## What You Just Built

Let's look at what the initialization created.

### Directory Structure

```
my-project/
├── CLAUDE.md                    # The constitution
├── tools/                       # 35+ Agency tools
└── claude/
    ├── agents/
    │   ├── housekeeping/        # Your first agent
    │   │   ├── agent.md         # Agent identity and purpose
    │   │   ├── KNOWLEDGE.md     # What this agent has learned
    │   │   ├── WORKLOG.md       # Sprint-based work tracking
    │   │   └── ADHOC-WORKLOG.md # Ad-hoc task tracking
    │   └── collaboration/       # Inter-agent messages
    ├── principals/
    │   └── [your-name]/
    │       ├── instructions/    # Tasks you assign to agents
    │       └── artifacts/       # Deliverables agents produce
    ├── workstreams/
    │   └── general/
    │       └── KNOWLEDGE.md     # Shared workstream knowledge
    └── docs/                    # Guides and reference
```

### What Each Piece Does

**CLAUDE.md** — Every agent reads this on startup. It defines the framework, the conventions, the expectations. It's the constitution of your Agency.

**tools/** — Shell scripts that agents (and you) use constantly. Session management, collaboration, quality checks, git operations. You'll learn these as you go.

**claude/agents/** — Each agent gets a directory. The `agent.md` file defines who they are. The knowledge and worklog files persist across sessions.

**claude/principals/** — That's you (and any other humans). Instructions you give agents go here. Artifacts they produce for you go here.

**claude/workstreams/** — Areas of work. The `general` workstream is created by default. You'll add more as your project grows — `web`, `api`, `infrastructure`, whatever makes sense.

### What You Get vs. Vanilla Claude Code

| Capability | Vanilla Claude Code | The Agency |
|------------|---------------------|------------|
| Agent identity | None | Built-in (name, workstream, principal) |
| Session persistence | Basic `/resume` | Full state restoration |
| Work tracking | None | WORKLOG, ADHOC, instructions |
| Quality gates | Manual | Automated 5-step pre-commit |
| Multi-agent collaboration | None | NEWS, COLLABORATE, handoffs |
| Principal instructions | None | Structured assignment system |
| Time awareness | None | Consistent timestamps |
| Terminal organization | Manual | Automatic tab naming |

The Agency doesn't replace Claude Code. It instruments it. Everything Claude Code can do, your agents can do — plus the coordination, persistence, and discipline that makes multi-agent development actually work.

---

## Essential Tools to Know

You don't need to memorize all 35+ tools. But these are the ones you'll use constantly.

### Session Management

| Tool | What It Does |
|------|--------------|
| `./tools/myclaude [workstream] [agent]` | Launch an agent |
| `./tools/welcomeback` | Resume after a break |
| `./tools/backup-session` | Save session state |

### Identity

| Tool | What It Does |
|------|--------------|
| `./tools/whoami` | Your principal name |
| `./tools/agentname` | Current agent |
| `./tools/workstream` | Current workstream |
| `./tools/now` | Current timestamp |

### Collaboration

| Tool | What It Does |
|------|--------------|
| `./tools/collaborate [agent] "subject" "request"` | Ask another agent for help |
| `./tools/post-news "message"` | Broadcast to all agents |
| `./tools/read-news` | Check for broadcasts |

### Quality

| Tool | What It Does |
|------|--------------|
| `./tools/pre-commit-check` | Run all quality gates |
| `./tools/sync` | Push with quality checks |

### Discovery

| Tool | What It Does |
|------|--------------|
| `./tools/list-tools` | See all available tools |
| `./tools/find-tool "keyword"` | Search for a tool |

When in doubt, ask housekeeping. It knows all the tools and when to use them.

---

## The `!` Shortcut

One Claude Code feature you'll use constantly: the `!` prefix.

Inside a Claude Code session, prefix any command with `!` to run it directly in bash:

```
> !./tools/now
> !git status
> !ls -la
```

This is how agents run tools, check status, and interact with the system. You'll see it throughout this book.

You can also just type commands directly — Claude understands bash. But the `!` prefix makes your intent explicit: "run this, don't interpret it."

---

## What's Next

You have a working Agency. One principal (you), one agent (housekeeping), one workstream (general).

From here, the typical next steps:

1. **Create a workstream** for your actual project — Chapter 6 covers workstreams in depth
2. **Create specialized agents** — Chapter 3 explains what makes an effective agent
3. **Give your first instruction** — Chapter 10 walks through the instruction system
4. **Start building** — Part 3 covers real-world practice

But first, take some time to explore. Ask housekeeping questions. Poke around the directory structure. Run the tools. Get comfortable with what you've built.

The Agency is a framework, but it's also a way of working. The more familiar you are with the foundation, the more effectively you'll build on it.

---

## Troubleshooting

### "claude: command not found"

Claude Code isn't in your PATH. Add it:

```bash
export PATH="$HOME/.claude/bin:$PATH"
source ~/.zshrc  # or ~/.bashrc
```

### "Permission denied" on tools

Make them executable:

```bash
chmod +x ./tools/*
```

### Agent not picking up context

Run the restore tool:

```bash
./tools/restore
```

### Terminal tab not renaming

This requires a terminal that supports escape sequences for tab naming:
- **macOS:** Use iTerm2, not the default Terminal
- **Windows:** Use Windows Terminal
- **Linux:** Most modern terminals work

### Init script fails

Check that you have:
- Git installed and configured
- Write permission in the directory
- Node.js 18+ installed

If issues persist, ask in the GitHub discussions or file an issue.

---

## Summary

Getting set up requires:

1. **A Claude account** (Pro, Max, or Team) — we can't do this for you
2. **System requirements** (Node 18+, Git, proper terminal)
3. **Claude Code installed** (one command)
4. **The Agency Starter cloned** (git clone)
5. **Initialization run** (`./tools/init-agency`)
6. **First agent launched** (`./tools/myclaude general housekeeping`)

Total time: 10-15 minutes if you already have the prerequisites. Maybe 30 minutes if you need to set up Node or a proper terminal.

At the end, you have a fully instrumented development environment with agent identity, session persistence, collaboration infrastructure, and quality gates.

You're ready to build.

---

*Chapter 4 of The Agency Guide: Multi-Agent Development with Claude Code*
*Draft v1 | 2026-01-06*
