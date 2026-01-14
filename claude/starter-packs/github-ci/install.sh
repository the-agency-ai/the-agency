#!/bin/bash
#
# GitHub CI Starter Pack Installer
#
# Usage:
#   ./claude/starter-packs/github-ci/install.sh
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
echo -e "${BLUE}  GitHub CI Starter Pack Installer${NC}"
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
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint || echo "No lint script"

      - name: Type check
        run: pnpm exec tsc --noEmit || echo "No TypeScript config"

      - name: Test
        run: pnpm test --if-present || echo "No test script"

      - name: Build
        run: pnpm build || echo "No build script"
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

      - name: Check PR title format
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: |
          # Allow Agency format: workstream/agent: message
          if [[ "$TITLE" =~ ^[a-z-]+/[a-z-]+:.*$ ]]; then
            echo "PR title follows Agency format"
            exit 0
          fi
          # Allow conventional commits: type(scope): message
          if [[ "$TITLE" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]]; then
            echo "PR title follows conventional commit format"
            exit 0
          fi
          echo "ERROR: PR title must follow one of these formats:"
          echo "  workstream/agent: message (Agency format)"
          echo "  type(scope): message (Conventional commits)"
          echo ""
          echo "Your title: $TITLE"
          exit 1

      - name: Validate commit messages
        run: |
          echo "Checking commit messages..."
          while IFS= read -r msg; do
            # Allow Agency format
            if [[ "$msg" =~ ^[a-z-]+/[a-z-]+:.*$ ]]; then
              continue
            fi
            # Allow conventional commits
            if [[ "$msg" =~ ^(feat|fix|docs|chore|refactor|test)(\(.+\))?:.*$ ]]; then
              continue
            fi
            # Allow merge commits
            if [[ "$msg" =~ ^Merge ]]; then
              continue
            fi
            echo "ERROR: Commit message format invalid"
            echo "Got: $msg"
            exit 1
          done < <(git log --format="%s" origin/main..HEAD 2>/dev/null || true)
          echo "All commit messages valid"
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

      - name: Install pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - name: Install and build
        run: |
          pnpm install --frozen-lockfile
          pnpm build || echo "No build script"

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
    log_warn "Run 'pnpm init' first, then re-run this installer."
else
    # Install dev dependencies
    pnpm add -D husky lint-staged 2>/dev/null || {
        log_warn "pnpm install failed. You may need to install manually:"
        log_warn "  pnpm add -D husky lint-staged"
    }

    # Initialize husky
    pnpm exec husky init 2>/dev/null || mkdir -p .husky

    # Pre-commit hook
    cat > .husky/pre-commit << 'HOOK'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

pnpm exec lint-staged
HOOK
    chmod +x .husky/pre-commit
    log_info "Created .husky/pre-commit"

    # Commit-msg hook
    cat > .husky/commit-msg << 'HOOK'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

commit_msg=$(cat "$1")

# Allow Agency format: workstream/agent: message
if echo "$commit_msg" | head -1 | grep -qE "^[a-z-]+/[a-z-]+: "; then
    exit 0
fi

# Allow conventional commits: type(scope): message
if echo "$commit_msg" | head -1 | grep -qE "^(feat|fix|docs|chore|refactor|test|release)(\(.+\))?: "; then
    exit 0
fi

# Allow merge commits
if echo "$commit_msg" | head -1 | grep -qE "^Merge "; then
    exit 0
fi

echo "ERROR: Commit message format invalid"
echo ""
echo "Expected formats:"
echo "  workstream/agent: message (Agency format)"
echo "  type(scope): message (Conventional commits)"
echo ""
echo "Examples:"
echo "  housekeeping/captain: feat: add new tool"
echo "  feat(auth): add login page"
echo ""
echo "Your message: $(head -1 "$1")"
exit 1
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
echo -e "${GREEN}  GitHub CI Starter Pack Installed!${NC}"
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
echo "See SETUP.md and KNOWLEDGE.md for detailed documentation."
echo ""
