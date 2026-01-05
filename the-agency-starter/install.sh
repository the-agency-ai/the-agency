#!/bin/bash
#
# The Agency Starter - Quick Install
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/TheAgencyAI/the-agency-starter/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/TheAgencyAI/the-agency-starter/main/install.sh | bash -s -- my-project
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

# Check prerequisites
check_prereqs() {
    local missing=0

    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ git not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ git found${NC}"
    fi

    if ! command -v claude &> /dev/null; then
        echo -e "${YELLOW}⚠ Claude Code not found in PATH${NC}"
        echo "  Install from: https://claude.ai/code"
        echo "  (Continuing anyway - you'll need it to use The Agency)"
    else
        echo -e "${GREEN}✓ Claude Code found${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo ""
        echo -e "${RED}Missing required prerequisites. Please install them first.${NC}"
        exit 1
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

echo ""
echo "Installing to: ${GREEN}$PROJECT_NAME${NC}"
echo ""

# Clone the repository
echo "Cloning The Agency Starter..."
git clone --depth 1 https://github.com/TheAgencyAI/the-agency-starter.git "$PROJECT_NAME" 2>/dev/null || {
    # Fallback to full clone if shallow fails
    git clone https://github.com/TheAgencyAI/the-agency-starter.git "$PROJECT_NAME"
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

# Test the setup
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Your Agency is ready at: $(pwd)"
echo ""
echo "Next steps:"
echo ""
echo "  1. Enter your project:"
echo -e "     ${BLUE}cd $PROJECT_NAME${NC}"
echo ""
echo "  2. Launch the housekeeping agent (your guide):"
echo -e "     ${BLUE}./tools/myclaude housekeeping housekeeping${NC}"
echo ""
echo "  3. Or run the welcome interview:"
echo -e "     ${BLUE}claude /welcome${NC}"
echo ""
echo "Documentation:"
echo "  - GETTING_STARTED.md - Step-by-step guide"
echo "  - CLAUDE.md - The constitution"
echo "  - ./tools/find-tool -l - All available tools"
echo ""
echo "Need help? Ask your housekeeping agent or visit:"
echo "  https://github.com/TheAgencyAI/the-agency-starter"
echo ""
