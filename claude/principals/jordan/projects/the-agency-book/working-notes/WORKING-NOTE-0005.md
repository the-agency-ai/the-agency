# THE-AGENCY-BOOK-WORKING-NOTE-0005

**Date:** 2026-01-03 17:22 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** iTerm Performance Research - Multi-Agent CPU Management

---

## Problem Statement

When running 3+ Claude Code instances in iTerm2, the system becomes unresponsive:

- iTerm tabs freeze/lag
- Cannot switch between tabs
- Overall laptop performance degrades
- Fan ramps up

**Key Observation:** Terminal.app handles this situation better than iTerm2.

## Research Findings

### Why cpulimit Won't Work

**cpulimit does NOT work on Apple Silicon (M1/M2/M3).**

- Only supports Intel CPUs
- The ARM hooks haven't been implemented
- Same for AppPolice - Intel only

### Root Cause: iTerm2 Resource Usage

| Metric          | iTerm2    | Terminal.app |
| --------------- | --------- | ------------ |
| Memory per tab  | ~180MB    | ~40MB        |
| Renderer        | CPU-based | Optimized    |
| 20+ tabs        | 2-3GB RAM | ~800MB       |
| High-throughput | Struggles | Handles well |

iTerm2's CPU-based renderer struggles with high-throughput output (Claude Code's streaming). The renderer can spike CPU usage just from rendering text.

### iTerm2 Known Issues

1. **GPU Renderer Bug**: The GPU renderer (counterintuitively named) can cause pathological CPU spikes
2. **Memory Leaks**: Long-running sessions accumulate memory
3. **tmux Sessions**: Multiple tmux connections can spike CPU 50-115%
4. **Idle CPU**: Can use 15-30% CPU even when idle

## Potential Solutions (Ranked)

### 1. iTerm2 Settings Optimization (Free, Try First)

- **Disable GPU Renderer**: Settings > General > Magic > GPU Renderer OFF
  - Reported to reduce idle CPU from 30% to 5%
- **Reduce scrollback buffer**: Limit lines saved (Claude outputs a lot)
- **Restart periodically**: Clears memory leaks

### 2. Switch Terminal Emulator (Free, Recommended Long-term)

**Kitty** (https://sw.kovidgoyal.net/kitty/)

- GPU-accelerated rendering
- Significantly lower CPU than iTerm2
- Similar feature set

**Ghostty** (https://ghostty.org/)

- Modern, GPU-accelerated
- Built for performance
- Growing feature set

### 3. App Tamer ($14.95, Works)

- Fully supports Apple Silicon M1/M2/M3
- Can move apps between Performance and Efficiency cores
- GUI-based, set-and-forget
- Uses SIGSTOP/SIGCONT internally

### 4. Custom SIGSTOP/SIGCONT Script (Free, DIY)

```bash
# Throttle a process to ~50% by cycling stop/continue
while true; do
  kill -STOP $PID
  sleep 0.1
  kill -CONT $PID
  sleep 0.1
done
```

Could integrate into myclaude wrapper.

### 5. Use Nice/Renice (Limited)

```bash
renice 20 $PID
```

Only changes priority, doesn't cap CPU usage. Helps with scheduling but processes can still max CPU when nothing else needs it.

## Sources

- [iTerm2 High CPU when idle](https://gitlab.com/gnachman/iterm2/-/issues/8640)
- [iTerm2 High CPU/Memory](https://gitlab.com/gnachman/iterm2/-/issues/11261)
- [iTerm2 vs Terminal comparison](https://www.slant.co/versus/1713/1715/~iterm2_vs_terminal-app)
- [App Tamer Apple Silicon](https://www.stclairsoft.com/blog/2022/02/17/app-tamer-2-7b1-advanced-support-for-apple-silicon-processors/)
- [SIGSTOP/SIGCONT approach](https://phoikoi.io/2023/01/27/limiting-cpu-cli.html)
- [HN: M1 Throttling Discussion](https://news.ycombinator.com/item?id=33405359)

---

## Decision: Switch to Ghostty

After research, the decision is to switch from iTerm2 to Ghostty for multi-agent development.

**Why Ghostty:**

- GPU-accelerated rendering (handles Claude Code's high-throughput output)
- Lower memory footprint than iTerm2
- Modern, actively developed
- Supports OSC 0 for tab naming (our tools work)

---

## Ghostty Setup for The Agency

### 1. Install Ghostty

```bash
brew install --cask ghostty
```

### 2. Configure Ghostty

Copy `claude/docs/templates/ghostty-agency-config.txt` to `~/.config/ghostty/config`

**Critical setting:**

```
shell-integration-features = cursor,sudo
```

This omits 'title' so our `myclaude` and `tab-status` tools can control tab names.

### 3. Launch Agency Window

From project root:

```bash
./tools/agency-window
```

This opens Ghostty with pre-named tabs:

- jordan (principal)
- housekeeping, agent-client, agent-manager, analytics, catalog, content-manager, web (agents)

### 4. Launch Agents

In each tab, run:

```bash
./tools/myclaude WORKSTREAM AGENTNAME
```

Examples:

```bash
./tools/myclaude housekeeping housekeeping
./tools/myclaude agents agent-manager
./tools/myclaude web web
```

### 5. Status Indicators

Once agents are running, tab titles show status:

- 🔵 Available - agent waiting for commands
- 🟢 Working - agent actively processing
- 🔴 Attention - agent needs input/permission

To manually update status:

```bash
./tools/tab-status available   # 🔵
./tools/tab-status working     # 🟢
./tools/tab-status attention   # 🔴
```

---

## Tools Created

| Tool                  | Purpose                                 |
| --------------------- | --------------------------------------- |
| `tools/myclaude`      | Launch agent with auto tab title        |
| `tools/tab-status`    | Update tab status indicator             |
| `tools/agency-window` | Open Ghostty with pre-named Agency tabs |

---

## For agency-starter Projects

The Agency Starter should include:

1. `tools/agency-window` - pre-configured for project agents
2. `tools/myclaude` - agent launcher
3. `tools/tab-status` - status indicator
4. `claude/docs/templates/ghostty-agency-config.txt` - Ghostty config

When spinning up a new Agency project:

```bash
# 1. Clone/create project
git clone the-agency-starter my-project
cd my-project

# 2. Configure agents in tools/agency-window DEFAULT_TABS

# 3. Launch
./tools/agency-window
```

---

## Action Items

- [x] Create `tools/tab-status`
- [x] Create `tools/agency-window`
- [x] Update `tools/myclaude` with OSC tab title
- [x] Create Ghostty config template
- [x] Document in INSTR-0041
- [ ] Test workflow after installing Ghostty
- [ ] Add to agency-starter template

---

_Working note for project: the-agency-book_
_Related: INSTR-0041 - iTerm Performance - Multi-Instance CPU Management_

---

## Resolution (2026-01-03)

**Solution: iTerm2 Settings Fix**

The performance issue was resolved by disabling GPU rendering:

**Settings > General > Magic:**

- ☐ GPU Renderer - **OFF**
- ☐ Maximize throughput - **OFF**

**Result:** System remains responsive with 3+ Claude Code agents running simultaneously.

**Ghostty Status:** Parked. Works but cannot lock per-tab titles (Claude Code overrides them). Created `tools/agency-windows` for future use if needed.

**iTerm2 remains the recommended terminal** for The Agency multi-agent workflow.

---

## Tab Status Indicators (2026-01-03)

### What Works

| Method                      | Works? | Notes                                       |
| --------------------------- | ------ | ------------------------------------------- |
| `./tools/myclaude` launch   | ✅     | Sets 🔵 on agent start                      |
| Manual `./tools/tab-status` | ✅     | Works from terminal                         |
| Automatic hooks             | ⚠️     | Experimental - subprocess tty access varies |

### Dual Indicator System

Observation: Our emoji prefix appears at the **front** of the tab title, while Claude Code's standard indicator appears at the **back**:

```
🔵 housekeeping [Claude's task indicator]
```

This provides complementary information:

- **Front (ours):** Agent availability (available/working/attention)
- **Back (Claude's):** Current task or tool status

### Automatic Hooks (Experimental)

Hooks configured in `.claude/settings.local.json`:

- SessionStart → 🔵 available
- PreToolUse → 🟢 working
- PermissionRequest → 🔴 attention
- Stop → 🔵 available

**Limitation:** Hooks run in subprocesses that may not have `/dev/tty` access. The script exits silently if it can't write to the terminal.

### Tab Colors (iTerm2)

In addition to emoji prefixes, iTerm2 tabs get background colors:

- 🔵 Available: Blue (#3B82F6)
- 🟢 Working: Green (#22C55E)
- 🔴 Attention: Red (#EF4444)

### User Variables (iTerm2)

For status bar/badge customization, two user variables are set:

- `agentStatus`: current status (available/working/attention)
- `agentName`: agent identity

Access in iTerm2 status bar with: `\(user.agentStatus)` and `\(user.agentName)`

---

## Claude Code Status Line (2026-01-03)

Added official Claude Code status line that displays at the bottom of the Claude Code interface.

### Configuration

Added to `.claude/settings.local.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "./tools/agency-statusline",
    "padding": 0
  }
}
```

### Display Format

```
[housekeeping] Opus | 📊 45% | $0.12 | 5:30
```

Shows:

- Agent name (from AGENTNAME env var)
- Model being used
- Context window usage percentage (⚠️ warning at 80%+)
- Session cost
- Session duration

### Updates

Status line updates every 300ms when conversation changes.

### Tool

`./tools/agency-statusline` - Receives JSON via stdin, outputs single line
