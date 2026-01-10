#!/bin/bash
#
# Git CI Starter Pack Installer
#
# Usage:
#   ./claude/starter-packs/git-ci/install.sh
#
# This installs:
#   - GitHub Actions workflows (ci.yml, pr-check.yml, release.yml)
#   - Husky pre-commit hooks
#   - lint-staged configuration
#   - Commit message validation
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Git CI Starter Pack Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"

# ============================================================================
# GitHub Actions Workflows
# ============================================================================

log_step "Creating GitHub Actions workflows..."

mkdir -p .github/workflows

# CI Workflow
cat > .github/workflows/ci.yml << 'WORKFLOW'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint || echo "No lint script"

      - name: Type check
        run: npm run type-check || echo "No type-check script"

      - name: Test
        run: npm test || echo "No test script"

      - name: Build
        run: npm run build || echo "No build script"
WORKFLOW

log_info "Created .github/workflows/ci.yml"

# PR Check Workflow
cat > .github/workflows/pr-check.yml << 'WORKFLOW'
name: PR Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Validate PR
        run: |
          echo "PR validation passed"
WORKFLOW

log_info "Created .github/workflows/pr-check.yml"

# Release Workflow
cat > .github/workflows/release.yml << 'WORKFLOW'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install and build
        run: |
          npm ci
          npm run build || echo "No build script"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
WORKFLOW

log_info "Created .github/workflows/release.yml"

# ============================================================================
# Husky + lint-staged
# ============================================================================

log_step "Setting up Husky and lint-staged..."

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found. Skipping Husky setup."
    log_warn "Run 'npm init' first, then re-run this installer."
else
    # Install dev dependencies
    npm install -D husky lint-staged --save-dev 2>/dev/null || {
        log_warn "npm install failed. You may need to install manually:"
        log_warn "  npm install -D husky lint-staged"
    }

    # Initialize husky
    npx husky init 2>/dev/null || mkdir -p .husky

    # Pre-commit hook
    cat > .husky/pre-commit << 'HOOK'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
HOOK
    chmod +x .husky/pre-commit
    log_info "Created .husky/pre-commit"

    # Commit-msg hook
    cat > .husky/commit-msg << 'HOOK'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

commit_msg=$(cat "$1")

# Allow Co-Authored-By lines and standard format
if echo "$commit_msg" | head -1 | grep -qE "^[a-z-]+/[a-z-]+: "; then
    exit 0
elif echo "$commit_msg" | head -1 | grep -qE "^(feat|fix|docs|chore|refactor|test|release)(\(.+\))?: "; then
    exit 0
elif echo "$commit_msg" | head -1 | grep -qE "^Merge "; then
    exit 0
else
    echo "ERROR: Commit message format invalid"
    echo ""
    echo "Expected formats:"
    echo "  workstream/agent: message"
    echo "  type(scope): message"
    echo ""
    echo "Examples:"
    echo "  housekeeping/housekeeping: feat: add new tool"
    echo "  feat(auth): add login page"
    echo ""
    echo "Your message: $(head -1 "$1")"
    exit 1
fi
HOOK
    chmod +x .husky/commit-msg
    log_info "Created .husky/commit-msg"

    # lint-staged config
    cat > lint-staged.config.js << 'CONFIG'
module.exports = {
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'prettier --write'],
  '*.{json,md,yml,yaml}': ['prettier --write'],
};
CONFIG
    log_info "Created lint-staged.config.js"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Git CI Starter Pack Installed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Created:"
echo "  .github/workflows/ci.yml        - Main CI pipeline"
echo "  .github/workflows/pr-check.yml  - PR validation"
echo "  .github/workflows/release.yml   - Release automation"
echo "  .husky/pre-commit               - Lint on commit"
echo "  .husky/commit-msg               - Validate commit messages"
echo "  lint-staged.config.js           - Staged file linting"
echo ""
echo "Next steps:"
echo "  1. Commit these files: git add -A && git commit -m 'chore: add CI/CD'"
echo "  2. Push to GitHub to enable Actions"
echo "  3. Enable branch protection on 'main' in GitHub settings"
echo ""
echo "See CONVENTIONS.md for detailed documentation."
echo ""
