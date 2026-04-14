<!-- What Problem: The monolithic CLAUDE-THEAGENCY.md bootloader loads ~12K tokens
     on every session start, but provenance header rules and script discipline are
     only needed when agents are writing code or scripts. Extracting this into a
     standalone ref doc lets the ref-injector hook inject it on demand.

     How & Why: Verbatim extraction from CLAUDE-THEAGENCY.md "Bash Tool Usage"
     section (lines 589-668), covering provenance headers, script discipline,
     bash tool usage rules, and web content retrieval. Grouped together because
     they are all "how to write and run code" discipline — naturally co-occur
     during implementation work. The ref-injector hook will inject this when
     agents enter implementation mode or invoke code-writing skills.

     Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring) -->

## Provenance Headers & Script Discipline

### Bash Tool Usage

Run each shell command as a **single, simple command** — no `&&`, `||`, `;`, pipes, subshells, or `$(...)` substitutions. These bypass the allowed-tools list, triggering extra permission prompts. Use separate Bash tool calls (parallel when independent, sequential when dependent). Use dedicated tools: Grep not `grep`, Glob not `find`, Read not `cat`, Write not `echo`, `/git-commit` not `git commit`.

**Before writing bash, check if a tool already exists.** Tools in `claude/tools/` have built-in logging, telemetry, and structured output — they're more token-efficient and observable than inline bash. See `claude/README-THEAGENCY.md` for the full alternatives table and the tool ecosystem.

### Provenance Headers

Every piece of code — scripts, tools, modules, classes, methods, functions — carries a provenance header. This is how we learn from our own work. The header has two parts:

**What Problem:** What problem are you solving? Not what the code does — what need drove its creation.

**How & Why:** How are you solving it, what led you to this approach, and why you adopted it over alternatives.

```bash
# What Problem: I need to mine session transcripts for patterns, bugs, and
# decisions across multiple projects. This was being done inline by subagents
# every time, costing 20+ tool calls per mining run.
#
# How & Why: Extract user messages from JSONL session files and output as
# readable markdown for agent analysis. Chose grep+jq over full JSON parsing
# because session files are 50MB+ and streaming line-by-line is the only
# approach that doesn't blow memory. Written as a shell script because it
# needs to run in any repo without dependencies.
#
# Written: 2026-04-04 during captain session 18 (ISCP workstream creation)
```

The **What Problem** forces intent articulation. "What it does" is readable from the code. "What problem it solves" is not — and it's the thing that tells a future reader whether this code is still relevant.

The **How & Why** captures the reasoning chain. When someone needs to change this code, they need to know not just what it does but why it does it *this way*. What alternatives were considered? What constraints drove the choice? This is the context that gets lost when code outlives the session that created it.

The **Written** line gives traceability — you can find the session and plan context where the code was born.

**This applies at every level:**

| Scope | Where the header goes |
|-------|----------------------|
| **Script / tool** | Top of file, as comments |
| **Module / package** | Module docstring or header comment |
| **Class** | Class docstring or header comment |
| **Method / function** | Function docstring or header comment (for non-trivial functions) |

For trivial functions (getters, simple transforms, obvious wrappers), the header is overkill. Use judgment — if someone reading the code would ask "why does this exist?", it needs a header.

This is part of **Continual Learning & Improvement** — provenance headers feed transcript mining, telemetry analysis, and pattern discovery. They are the written record of how we think, not just what we build.

### Script Discipline

Every script — whether part of a plan or written ad hoc — must follow two rules:

**1. Provenance header.** Every script starts with a provenance header (What Problem / How & Why / Written — see above).

**2. Persist and reuse.** Scripts live in two places depending on scope:

| Scope | Location | Lifecycle |
|-------|----------|-----------|
| **Framework tool** (plan work, shipped to all projects) | `claude/tools/` | Committed, reviewed, permanent |
| **Agent script** (ad hoc, session work, one-off automation) | `usr/{principal}/{project}/tools/` | Committed, reusable across sessions |
| **Scratch** (truly ephemeral, intermediate output) | `usr/{principal}/{project}/tmp/` | Gitignored, disposable |

**The workflow for ad hoc scripts:**
1. You realize you need a script (parsing, scanning, transforming, testing).
2. Write it to `usr/{principal}/{project}/tools/` with a provenance header.
3. Run it from there.
4. If you need it again later in the session, it's already there — don't rewrite it.
5. If it proves broadly useful, propose moving it to `claude/tools/`.

**Never write the same script twice.** If you wrote it once, it should be in `tools/` and runnable from there. Rewriting the same script multiple times in a session wastes tokens and context window — and signals that the script should have been persisted on first write.

### Web Content Retrieval

Escalation ladder when fetching web content:

1. **WebFetch** — try first. Fast, no browser needed. Fails on JS-heavy sites.
2. **Playwright MCP snapshot** — JS-heavy sites. Structured accessibility tree, token-efficient.
3. **Playwright MCP screenshot** — when visual context is needed.
4. **Playwright MCP run_code** — extract specific content from large pages.

Extract what you need — don't dump whole pages into context. Summarize, don't paste raw HTML.
