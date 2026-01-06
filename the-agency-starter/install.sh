#!/bin/bash
#
# The Agency Starter - Quick Install
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash -s -- my-project
#
# Workshop usage (with token):
#   AGENCY_TOKEN=xxx curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash -s -- my-project
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  The Agency Starter${NC}"
echo -e "${BLUE}  Multi-Agent Development Framework for Claude Code${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Install Claude Code if not present
install_claude_code() {
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}  ✓ Claude Code already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}  ⚠ Claude Code not found - installing...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://claude.ai/install.sh | bash
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        powershell -Command "irm https://claude.ai/install.ps1 | iex"
    else
        echo -e "${RED}Unsupported platform for automatic Claude Code install${NC}"
        echo "Please install manually from: https://claude.ai/code"
        exit 1
    fi

    # Reload PATH to pick up claude
    export PATH="$HOME/.claude/bin:$PATH"

    if command -v claude &> /dev/null; then
        echo -e "${GREEN}  ✓ Claude Code installed successfully${NC}"
    else
        echo -e "${RED}  ✗ Claude Code installation failed${NC}"
        echo "Please install manually from: https://claude.ai/code"
        exit 1
    fi
}

# Check if user is logged into Claude
check_claude_auth() {
    echo ""
    echo -e "${BLUE}Checking Claude authentication...${NC}"

    # Check if Claude has been used before (has session history)
    if [ -d "$HOME/.claude" ] && [ -f "$HOME/.claude/history.jsonl" ]; then
        echo -e "${GREEN}  ✓ Claude has been used before${NC}"
    else
        echo -e "${YELLOW}  ⚠ First time using Claude Code${NC}"
        echo ""
        echo -e "${BLUE}You'll need to log in to Claude.${NC}"
        echo "A browser window will open - complete the login there."
        echo ""
        # Use /dev/tty for input when running via curl pipe
        if [ -e /dev/tty ]; then
            read -p "Press Enter to continue..." < /dev/tty 2>/dev/null || true
        fi
        claude --help > /dev/null 2>&1 || {
            echo ""
            echo -e "${YELLOW}Running Claude for first-time setup...${NC}"
            claude
        }
        echo ""
        echo -e "${GREEN}  ✓ Claude setup complete${NC}"
    fi
}

# Check prerequisites
check_prereqs() {
    local missing=0

    echo -e "${BLUE}Checking prerequisites...${NC}"
    echo ""

    # Git is required
    if ! command -v git &> /dev/null; then
        echo -e "${RED}  ✗ git not found${NC}"
        echo "    Please install git first: https://git-scm.com"
        missing=1
    else
        echo -e "${GREEN}  ✓ git${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo ""
        echo -e "${RED}Missing required prerequisites. Please install them first.${NC}"
        exit 1
    fi

    # Install Claude Code if needed
    install_claude_code

    # Check authentication
    check_claude_auth
}

# Check recommended tools (non-blocking)
check_recommended() {
    local missing_tools=""

    echo ""
    echo -e "${BLUE}Recommended:${NC}"

    # Essential recommended
    for tool in jq gh tree; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}  ✓ $tool${NC}"
        else
            echo -e "${YELLOW}  ○ $tool${NC}"
            missing_tools="$missing_tools $tool"
        fi
    done

    # Nice to have
    for tool in yq fzf bat rg; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}  ✓ $tool${NC}"
        else
            echo -e "${YELLOW}  ○ $tool${NC}"
            missing_tools="$missing_tools $tool"
        fi
    done

    if [ -n "$missing_tools" ]; then
        echo ""
        # Detect macOS and suggest brew
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${YELLOW}Tip: Install missing tools with:${NC}"
            echo -e "  brew install$missing_tools"
            echo -e "  Or run: ${BLUE}./tools/setup-mac${NC} after installation"
        fi
    fi
}

# Get project name
PROJECT_NAME="${1:-the-agency-project}"

# Validate project name
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}Invalid project name. Use only letters, numbers, hyphens, underscores.${NC}"
    exit 1
fi

# Check if directory exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Directory '$PROJECT_NAME' already exists.${NC}"
    echo "Please choose a different name or remove the existing directory."
    exit 1
fi

echo "Checking prerequisites..."
check_prereqs
check_recommended

echo ""
echo -e "Installing to: ${GREEN}$PROJECT_NAME${NC}"
echo ""

# Clone the repository
echo "Cloning The Agency Starter..."

# Support authenticated clone for private repo (beta access)
if [ -n "$AGENCY_TOKEN" ]; then
    REPO_URL="https://${AGENCY_TOKEN}@github.com/the-agency-ai/the-agency-starter.git"
else
    REPO_URL="https://github.com/the-agency-ai/the-agency-starter.git"
fi

git clone --depth 1 "$REPO_URL" "$PROJECT_NAME" 2>/dev/null || {
    # Fallback to full clone if shallow fails
    git clone "$REPO_URL" "$PROJECT_NAME"
}

cd "$PROJECT_NAME"

# Remove git history (fresh start)
rm -rf .git
git init
git add -A
git commit -m "Initial commit from The Agency Starter" --quiet

# Make tools executable
echo "Setting up tools..."
chmod +x tools/*

# Configure principal
SYSTEM_USER=$(whoami)
echo "Configuring principal..."
if [ -f "claude/config.yaml" ]; then
    # Update config with current user
    sed -i.bak "s/your_username: YourName/$SYSTEM_USER: $SYSTEM_USER/" claude/config.yaml 2>/dev/null || \
    sed -i '' "s/your_username: YourName/$SYSTEM_USER: $SYSTEM_USER/" claude/config.yaml
    rm -f claude/config.yaml.bak
fi

# Platform-specific setup (delegates to tools/setup-{platform})
setup_platform() {
    local setup_script=""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        setup_script="./tools/setup-mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        setup_script="./tools/setup-linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        setup_script="./tools/setup-windows"
    fi

    if [[ -n "$setup_script" ]] && [[ -x "$setup_script" ]]; then
        echo ""
        echo "Running platform setup..."
        "$setup_script" --all
    elif [[ -n "$setup_script" ]]; then
        echo ""
        echo -e "${YELLOW}Platform setup script not found: $setup_script${NC}"
        echo "You can create one to install recommended tools for your platform."
    fi
}

setup_platform

# Done with setup
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Your Agency is ready at: ${GREEN}$(pwd)${NC}"
echo ""

# Store the project path for launching
PROJECT_PATH="$(pwd)"

# Ask if they want to launch now
echo -e "${BLUE}Ready to meet your first agent?${NC}"
echo ""

# Try to read from /dev/tty (works with curl pipe), fallback to assuming yes
if [ -e /dev/tty ] && [ -r /dev/tty ]; then
    read -p "Launch The Captain now? [Y/n] " launch_now < /dev/tty 2>/dev/null || launch_now="Y"
else
    # No TTY available, auto-launch
    launch_now="Y"
fi
launch_now=${launch_now:-Y}

if [[ "$launch_now" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}Launching The Captain (housekeeping agent)...${NC}"
    echo ""
    echo "Once inside, type: /welcome"
    echo ""
    sleep 2

    # Launch myclaude - this will exec and replace this shell
    exec ./tools/myclaude housekeeping housekeeping
else
    echo ""
    echo "When you're ready, run:"
    echo ""
    echo -e "  ${BLUE}cd $PROJECT_PATH${NC}"
    echo -e "  ${BLUE}./tools/myclaude housekeeping housekeeping${NC}"
    echo ""
    echo "Then type: /welcome"
    echo ""
    echo "Documentation:"
    echo "  - GETTING_STARTED.md - Step-by-step guide"
    echo "  - CLAUDE.md - The constitution"
    echo "  - ./tools/find-tool -l - All available tools"
    echo ""
fi
