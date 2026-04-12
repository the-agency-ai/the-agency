#!/usr/bin/env bash
# What Problem: Students at the Republic Polytechnic workshop need a fully
# provisioned Ubuntu VM with Ghostty, Homebrew, Claude Code, and The Agency
# framework. Without this script, setup takes 30+ minutes of manual steps
# and students get stuck on different packages and configurations.
#
# How & Why: Single idempotent bootstrap script that installs everything in
# order. Uses apt for system packages, Homebrew for CLI tools (matching our
# macOS workflow — "no compromises"), and npm for Claude Code. Ghostty is
# installed via apt PPA (Ubuntu 24.04+). Each section is guarded by
# command-existence checks so re-running is safe.
#
# Written: 2026-04-10 during captain session (workshop VM prep)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}${GREEN}▸ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

# ─── Pre-flight ──────────────────────────────────────────────────────────────

step "Pre-flight checks"

if [[ "$(id -u)" == "0" ]]; then
    fail "Do not run this script as root. Run as your normal user (it will use sudo when needed)."
fi

if ! command -v apt-get &>/dev/null; then
    fail "This script requires Ubuntu/Debian (apt-get not found)."
fi

ok "Running as $(whoami) on $(uname -m)"

# ─── System packages ────────────────────────────────────────────────────────

step "Installing system packages via apt"

sudo apt-get update -qq

PACKAGES=(
    curl
    wget
    git
    build-essential
    jq
    sqlite3
    tree
    unzip
    ca-certificates
    gnupg
    lsb-release
    software-properties-common
    python3
    python3-pip
    ripgrep
    fd-find
)

sudo apt-get install -y -qq "${PACKAGES[@]}"
ok "System packages installed"

# ─── Google Chrome ──────────────────────────────────────────────────────────

step "Installing Google Chrome"

if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null || command -v chromium-browser &>/dev/null; then
    ok "Chrome/Chromium already installed"
else
    ARCH=$(dpkg --print-architecture)
    if [[ "$ARCH" == "amd64" ]]; then
        # Google Chrome available for x86_64
        wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
        sudo apt-get install -y -qq /tmp/google-chrome.deb
        rm -f /tmp/google-chrome.deb
        ok "Google Chrome installed"
    else
        # ARM64 — Chrome not available, use Chromium
        sudo apt-get install -y -qq chromium-browser 2>/dev/null || sudo snap install chromium 2>/dev/null
        ok "Chromium installed (Chrome not available for $ARCH)"
    fi
fi

# ─── Homebrew ────────────────────────────────────────────────────────────────

step "Installing Homebrew"

if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for this session and permanently
    if [[ -d /home/linuxbrew/.linuxbrew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
    fi
    ok "Homebrew installed"
fi

# ─── Node.js ─────────────────────────────────────────────────────────────────

step "Installing Node.js"

if command -v node &>/dev/null; then
    ok "Node.js already installed ($(node --version))"
else
    # Use brew for Node.js — matches our macOS workflow
    brew install node
    ok "Node.js installed ($(node --version))"
fi

# ─── Claude Code ─────────────────────────────────────────────────────────────

step "Installing Claude Code"

if command -v claude &>/dev/null; then
    ok "Claude Code already installed ($(claude --version 2>/dev/null || echo 'installed'))"
else
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed"
fi

# ─── Docker (optional) ──────────────────────────────────────────────────────

step "Installing Docker"

if command -v docker &>/dev/null; then
    ok "Docker already installed"
else
    # Docker official install for Ubuntu
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    ok "Docker installed (log out and back in for group to take effect)"
fi

# ─── GitHub CLI ──────────────────────────────────────────────────────────────

step "Installing GitHub CLI"

if command -v gh &>/dev/null; then
    ok "GitHub CLI already installed ($(gh --version | head -1))"
else
    brew install gh
    ok "GitHub CLI installed"
fi

# ─── The Agency ──────────────────────────────────────────────────────────────

step "Setting up workshop workspace"

mkdir -p ~/workshop
cd ~/workshop

if [[ ! -d ~/workshop/.git ]]; then
    git init
    ok "Workshop repo initialized"
else
    ok "Workshop repo already exists"
fi

# ─── Verification ────────────────────────────────────────────────────────────

step "Verification"

echo ""
echo "Checking installed tools:"
echo ""

CHROME_CMD=""
for c in google-chrome-stable google-chrome chromium-browser chromium; do
    if command -v "$c" &>/dev/null; then CHROME_CMD="$c"; break; fi
done

if [[ -n "$CHROME_CMD" ]]; then
    ok "browser — $CHROME_CMD"
else
    warn "browser — NOT FOUND (no Chrome or Chromium)"
    ALL_OK=false
fi

TOOLS=(git node npm claude jq sqlite3 gh docker brew)
ALL_OK=true

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        VERSION=$("$tool" --version 2>/dev/null | head -1 || echo "installed")
        ok "$tool — $VERSION"
    else
        warn "$tool — NOT FOUND"
        ALL_OK=false
    fi
done

echo ""

if [[ "$ALL_OK" == "true" ]]; then
    echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  ✓ Workshop environment ready!${NC}"
    echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Pre-workshop setup is complete!"
    echo ""
    echo "At the workshop, we will:"
    echo "  1. Open a terminal (Ctrl+Alt+T)"
    echo "  2. Run: claude login  (opens Chrome for authentication)"
    echo "  3. Run: cd ~/workshop && claude"
    echo ""
else
    echo -e "${YELLOW}Some tools are missing — check the warnings above.${NC}"
    echo "You can re-run this script safely to retry."
fi
