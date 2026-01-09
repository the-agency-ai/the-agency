#!/bin/bash
#
# The Agency Starter - Install SDK
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
#
# Workshop usage (with token):
#   curl -fsSL "https://TOKEN@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="TOKEN" bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default install location - current directory
INSTALL_DIR="${AGENCY_INSTALL_DIR:-$(pwd)/the-agency-starter}"

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
}

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}The Agency Starter already installed at: $INSTALL_DIR${NC}"
    echo ""
    echo "Options:"
    echo "  1. Update existing installation:"
    echo -e "     ${BLUE}cd $INSTALL_DIR && git pull${NC}"
    echo ""
    echo "  2. Create a new project:"
    echo -e "     ${BLUE}$INSTALL_DIR/tools/new-project my-app${NC}"
    echo ""
    echo "  3. Remove and reinstall:"
    echo -e "     ${BLUE}rm -rf $INSTALL_DIR${NC}"
    echo "     Then run this installer again."
    echo ""
    exit 0
fi

echo "Checking prerequisites..."
check_prereqs

echo ""
echo -e "Installing to: ${GREEN}$INSTALL_DIR${NC}"
echo ""

# Clone the repository
echo "Cloning The Agency Starter..."

# Support authenticated clone for private repo (workshop/beta access)
if [ -n "$AGENCY_TOKEN" ]; then
    REPO_URL="https://${AGENCY_TOKEN}@github.com/the-agency-ai/the-agency-starter.git"
else
    REPO_URL="https://github.com/the-agency-ai/the-agency-starter.git"
fi

git clone "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || {
    echo -e "${RED}Failed to clone repository${NC}"
    echo "Check your network connection or token."
    exit 1
}

cd "$INSTALL_DIR"

# Make tools executable
echo "Setting up tools..."
chmod +x tools/*

# Done with setup
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "The Agency Starter installed at: ${GREEN}$INSTALL_DIR${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "  1. Create your first project:"
echo -e "     ${GREEN}cd the-agency-starter${NC}"
echo -e "     ${GREEN}./tools/new-project ../my-first-app${NC}"
echo ""
echo "  2. Or use full path:"
echo -e "     ${GREEN}$INSTALL_DIR/tools/new-project ~/code/my-app${NC}"
echo ""
