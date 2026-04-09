---
type: seed
workstream: agency
date: 2026-04-09
origin: captain Day 34 — Republic Polytechnic teaching event planning
status: active
---

# Workshop VM Bootstrap — Republic Polytechnic Monday 2026-04-14

## Context

Teaching Claude Code to faculty at Republic Polytechnic with Sean. Audience runs Windows. Solution: VMware Workstation Pro (free) with a pre-baked Ubuntu 24.04 LTS VM image containing everything needed.

## Build workflow

1. Jordan creates fresh Ubuntu 24.04 minimal VM in Fusion on Mac
2. Claude Code on macOS SSHs into the VM (Desktop SSH session)
3. Claude Code runs the bootstrap script inside the VM
4. Snapshot → export as OVA
5. Students import OVA in Workstation Pro on Windows
6. Open Ghostty, `claude login`, ready to work

## Bootstrap script

Run this on a fresh Ubuntu 24.04 LTS minimal install. Only `apt` for system prerequisites; **everything else via `brew`**.

```bash
#!/bin/bash
#
# Workshop VM Bootstrap — Republic Polytechnic 2026-04-14
# Run as a non-root user with sudo access on a fresh Ubuntu 24.04 LTS.
# Takes ~10-15 minutes depending on network speed.

set -euo pipefail

echo "=== Workshop VM Bootstrap ==="
echo "Ubuntu 24.04 LTS → Claude Code + Agency ready-to-teach environment"
echo ""

# ─── Step 1: System prerequisites (apt — minimal) ───────────────────────
echo ">>> Step 1/7: System prerequisites via apt"
sudo apt update -qq
sudo apt install -y -qq \
    build-essential \
    curl \
    file \
    git \
    openssh-server \
    procps \
    locales

# Ensure en_US.UTF-8 locale (Homebrew needs it)
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8

# Enable SSH (for image-build workflow — Claude Code on macOS SSHs in)
sudo systemctl enable --now ssh

# ─── Step 2: Homebrew ───────────────────────────────────────────────────
echo ">>> Step 2/7: Installing Homebrew"
if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to PATH for this session + permanently
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile

echo "Homebrew $(brew --version | head -1) installed"

# ─── Step 3: Dev tools via brew ─────────────────────────────────────────
echo ">>> Step 3/7: Dev tools via brew"
brew install \
    gh \
    jq \
    sqlite \
    node \
    bats-core \
    tree \
    ripgrep \
    fd

echo "Dev tools installed:"
echo "  node $(node --version)"
echo "  jq $(jq --version)"
echo "  gh $(gh --version | head -1)"
echo "  bats $(bats --version)"

# ─── Step 4: Ghostty terminal ──────────────────────────────────────────
echo ">>> Step 4/7: Ghostty terminal"
# Ghostty may need to be installed via its Linux instructions
# Check if brew has it, otherwise use the official method
if brew install --cask ghostty 2>/dev/null; then
    echo "Ghostty installed via brew"
else
    echo "Ghostty not in brew — install via official Linux instructions:"
    echo "  See: https://ghostty.org/docs/install/binary"
    echo "  (Manual step — add to the OVA before snapshot)"
fi

# ─── Step 5: Docker Engine CE ──────────────────────────────────────────
echo ">>> Step 5/7: Docker Engine CE"
# Docker via official repo (apt is correct here — Docker doesn't ship via brew on Linux)
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed. Log out and back in for group membership."
else
    echo "Docker already installed: $(docker --version)"
fi

# ─── Step 6: Claude Code CLI ──────────────────────────────────────────
echo ">>> Step 6/7: Claude Code CLI"
# Install via npm (brew-installed node)
if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed: $(claude --version 2>/dev/null || echo 'installed')"
else
    echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'present')"
fi

# ─── Step 7: Pre-baked workshop repo ──────────────────────────────────
echo ">>> Step 7/7: Workshop repo"
REPO_DIR="$HOME/workshop"
if [ ! -d "$REPO_DIR" ]; then
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    git init
    git config user.name "Workshop Student"
    git config user.email "student@workshop.local"

    # Create a minimal project structure
    cat > README.md << 'HEREDOC'
# Claude Code Workshop — Republic Polytechnic

Welcome! This repo is pre-configured for the Claude Code workshop.

## Getting started

1. Open Ghostty terminal
2. Run `claude login` to authenticate
3. Run `claude` to start a session
4. Try: "Create a simple Python web server that returns 'Hello from the workshop!'"

## What's installed

- Claude Code CLI
- Node.js, Python3, Docker
- Ghostty terminal
- git, gh, jq, ripgrep

## Workshop exercises

See the `exercises/` directory for guided tasks.
HEREDOC

    mkdir -p exercises
    cat > exercises/01-hello-world.md << 'HEREDOC'
# Exercise 1: Hello World

Ask Claude to create a simple Python web server.

Prompt: "Create a Python file called server.py that serves 'Hello from Republic Polytechnic!' on port 8080. Include error handling."

After Claude creates it:
- Run it: `python3 server.py`
- Test it: open another terminal, `curl localhost:8080`
- Ask Claude to add a `/status` endpoint that returns JSON
HEREDOC

    cat > exercises/02-fix-a-bug.md << 'HEREDOC'
# Exercise 2: Fix a Bug

There's a bug in `buggy.py`. Ask Claude to find and fix it.

First, create the buggy file:
```python
# buggy.py — has 3 bugs, can you find them?
def calculate_average(numbers):
    total = 0
    for i in range(len(numbers) + 1):
        total += numbers[i]
    average = total / len(numbers)
    return round(average)

def process_data(data):
    results = []
    for item in data:
        if item > 0:
            results.append(calculate_average(item))
    return results

print(process_data([1, 2, 3], [4, 5, 6], [-1, -2]))
```

Prompt: "Read buggy.py, find all the bugs, explain each one, and fix them."
HEREDOC

    git add -A
    git commit -m "Initial workshop setup"
    echo "Workshop repo created at $REPO_DIR"
else
    echo "Workshop repo already exists at $REPO_DIR"
fi

# ─── Summary ──────────────────────────────────────────────────────────
echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Installed:"
echo "  Homebrew:    $(brew --version | head -1)"
echo "  Node.js:     $(node --version)"
echo "  Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
echo "  Docker:      $(docker --version 2>/dev/null || echo 'installed (relog needed)')"
echo "  Ghostty:     $(ghostty --version 2>/dev/null || echo 'check manual install')"
echo "  git:         $(git --version)"
echo "  gh:          $(gh --version | head -1)"
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for Docker group)"
echo "  2. Open Ghostty"
echo "  3. Run: claude login"
echo "  4. Run: cd ~/workshop && claude"
echo ""
echo "For image export: snapshot this VM now → File → Export to OVA"
```

## Pre-baked repo options

The script above creates a simple `~/workshop` repo. For a fuller experience, consider:

1. **Agency-init version** — run `agency init` on the workshop repo so students see the full Agency scaffolding (CLAUDE.md, tools, hooks, skills). Heavier but shows the real framework.
2. **Bare project** — just git init + README + exercises. Lighter, focuses on Claude Code itself without the Agency layer.
3. **Both** — `~/workshop` (bare, for exercises) + `~/workshop-agency` (Agency-installed, for demo).

## VM specs

- 4 vCPU, 8 GB RAM minimum (16 GB if host allows)
- 40 GB disk (Ubuntu + brew + Docker images)
- Bridged networking (for `claude login` auth flow + Docker pulls)
- VMware Tools installed (clipboard, shared folders, resolution)

## Student quick-start card (printed)

```
┌─────────────────────────────────────────────┐
│  Claude Code Workshop — Quick Start          │
│                                              │
│  1. Open Ghostty (orange icon in taskbar)    │
│  2. Type: claude login                       │
│  3. Follow the browser auth flow             │
│  4. Type: cd ~/workshop                      │
│  5. Type: claude                             │
│  6. You're in! Try the exercises in          │
│     ~/workshop/exercises/                    │
│                                              │
│  Need help? Raise your hand.                 │
│  WiFi: [network] / Password: [password]      │
└─────────────────────────────────────────────┘
```

## Open questions

1. Do students need Agency framework installed, or just bare Claude Code?
2. Do we want Docker exercises (e.g., "ask Claude to containerize the server")?
3. Internet access during the workshop — confirm WiFi details at Republic Polytechnic
4. How many students? (affects VMware image distribution — USB drive? network share?)
5. Time allocation per exercise?
