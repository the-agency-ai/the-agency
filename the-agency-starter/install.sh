#!/bin/bash
#
# The Agency Starter - Quick Install
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh | bash -s -- my-project
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

    echo -e "${BLUE}Required:${NC}"

    if ! command -v git &> /dev/null; then
        echo -e "${RED}  ✗ git not found${NC}"
        missing=1
    else
        echo -e "${GREEN}  ✓ git${NC}"
    fi

    if ! command -v claude &> /dev/null; then
        echo -e "${YELLOW}  ⚠ claude (Claude Code) not found${NC}"
        echo "    Install from: https://claude.ai/code"
    else
        echo -e "${GREEN}  ✓ claude${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo ""
        echo -e "${RED}Missing required prerequisites. Please install them first.${NC}"
        exit 1
    fi
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

# macOS: Install recommended CLI tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "Setting up macOS tools..."

    # Check/install Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    # Install recommended tools via setup-mac
    if command -v brew &> /dev/null; then
        ./tools/setup-mac --all
    fi
fi

# Done
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
echo "  https://github.com/the-agency-ai/the-agency-starter"
echo ""
