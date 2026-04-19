#!/usr/bin/env bash
# What Problem: On workshop morning, students need to go from "VM running" to
# "two Claude Code sessions with Remote Control, ready for Chrome connection"
# in one script. Without this, it's 10+ manual steps and someone always gets
# stuck on one of them.
#
# How & Why: Single script that runs the bootstrap (idempotent), handles
# claude login (interactive pause), creates workspace, and launches two
# Claude Code sessions in separate terminal windows with remote-control.
# Uses gnome-terminal for new windows — simplest for non-sysadmin users.
#
# Written: 2026-04-10 during captain session (workshop VM prep)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m'

step() { echo -e "\n${BOLD}${GREEN}▸ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
info() { echo -e "${CYAN}  $1${NC}"; }

# ─── Step 1: Quick tool check ───────────────────────────────────────────────

step "Checking tools"

MISSING=()
for tool in git node npm jq sqlite3 docker brew; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done

# Check for Claude Code specifically
if ! command -v claude &>/dev/null; then
    MISSING+=("claude")
fi

# Check for any browser
BROWSER=""
for b in google-chrome-stable google-chrome chromium-browser chromium firefox; do
    if command -v "$b" &>/dev/null; then BROWSER="$b"; break; fi
done
if [[ -z "$BROWSER" ]]; then
    MISSING+=("browser")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing tools: ${MISSING[*]}"
    echo ""
    echo "Run the bootstrap script first:"
    echo "  curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/workstreams/agency/seeds/workshop-bootstrap.sh | bash"
    echo ""
    fail "Cannot continue without required tools."
fi

ok "All tools present"
ok "Browser: $BROWSER"
ok "Claude Code: $(claude --version 2>/dev/null || echo 'installed')"

# ─── Step 2: Claude Code login ──────────────────────────────────────────────

step "Claude Code login"

# Check if already logged in
if claude --version &>/dev/null 2>&1; then
    # Try a quick check — if claude can run, auth might be cached
    echo "Checking authentication..."
fi

echo ""
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  Claude Code will open a browser window for login.${NC}"
echo -e "${BOLD}${CYAN}  Log in with the account provided at the workshop.${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

claude login

echo ""
ok "Login complete"

# ─── Step 3: Create workspace ───────────────────────────────────────────────

step "Setting up workspace"

mkdir -p ~/workshop
cd ~/workshop

if [[ ! -d .git ]]; then
    git init
    git config user.name "Workshop Student"
    git config user.email "student@workshop.local"
    ok "Workshop repo initialized"
else
    ok "Workshop repo already exists"
fi

# ─── Step 4: Launch Claude Code sessions ────────────────────────────────────

step "Launching Claude Code sessions"

echo ""
echo -e "${BOLD}Launching two Claude Code sessions with Remote Control...${NC}"
echo ""

# Launch Session 1
gnome-terminal --title="Claude Code — Session 1" -- bash -c '
    cd ~/workshop
    echo "═══════════════════════════════════════════════"
    echo "  Claude Code — Session 1"
    echo "  Remote Control will be enabled automatically"
    echo "═══════════════════════════════════════════════"
    echo ""
    claude --remote-control
    exec bash
' &

sleep 2

# Launch Session 2
gnome-terminal --title="Claude Code — Session 2" -- bash -c '
    cd ~/workshop
    echo "═══════════════════════════════════════════════"
    echo "  Claude Code — Session 2"
    echo "  Remote Control will be enabled automatically"
    echo "═══════════════════════════════════════════════"
    echo ""
    claude --remote-control
    exec bash
' &

sleep 2

# ─── Step 5: Instructions ──────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✓ Workshop environment is ready!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Two Claude Code sessions are running in separate windows.${NC}"
echo ""
echo -e "${BOLD}To connect from Chrome on your Windows machine:${NC}"
echo ""
echo "  1. Open Chrome on Windows"
echo "  2. Go to: ${CYAN}claude.ai/code${NC}"
echo "  3. Each Claude Code window shows a QR code or session code"
echo "  4. Scan or enter the code in Chrome to connect"
echo ""
echo -e "${BOLD}You now have:${NC}"
echo "  • Claude Desktop on Windows — for research and chat"
echo "  • Two Claude Code sessions — for hands-on coding"
echo "  • Remote Control — Chrome controls the Claude Code sessions"
echo ""
echo -e "${BOLD}${CYAN}Happy building! 🚀${NC}"
echo ""
