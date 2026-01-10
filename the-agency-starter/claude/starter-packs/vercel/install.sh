#!/bin/bash
#
# Vercel Starter Pack Installer
#
# Usage:
#   ./claude/starter-packs/vercel/install.sh
#
# This installs:
#   - vercel.json configuration
#   - Security headers
#   - Analytics and Speed Insights
#   - Middleware template
#   - Environment variable templates
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
echo -e "${BLUE}  Vercel Starter Pack Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"

# ============================================================================
# Verify Next.js project
# ============================================================================

if [[ ! -f "package.json" ]]; then
    log_warn "No package.json found. Run from project root."
    exit 1
fi

if ! grep -q "next" package.json 2>/dev/null; then
    log_warn "This doesn't appear to be a Next.js project."
    log_warn "Install Next.js first: ./claude/starter-packs/nextjs-react/install.sh"
    exit 1
fi

# ============================================================================
# Create vercel.json
# ============================================================================

log_step "Creating vercel.json..."

cat > vercel.json << 'JSON'
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "regions": ["sfo1"],
  "functions": {
    "api/**/*.ts": {
      "memory": 1024,
      "maxDuration": 10
    }
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Permissions-Policy",
          "value": "camera=(), microphone=(), geolocation=()"
        }
      ]
    },
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-store, must-revalidate"
        }
      ]
    }
  ]
}
JSON

log_info "Created vercel.json with security headers"

# ============================================================================
# Install Vercel packages
# ============================================================================

log_step "Installing Vercel packages..."

npm install @vercel/analytics @vercel/speed-insights

log_info "Installed @vercel/analytics and @vercel/speed-insights"

# ============================================================================
# Update layout with Analytics
# ============================================================================

log_step "Checking layout for analytics..."

LAYOUT_FILE="src/app/layout.tsx"
if [[ -f "$LAYOUT_FILE" ]]; then
    if ! grep -q "@vercel/analytics" "$LAYOUT_FILE"; then
        log_warn "Add Analytics to your layout manually:"
        echo ""
        echo "  import { Analytics } from '@vercel/analytics/react';"
        echo "  import { SpeedInsights } from '@vercel/speed-insights/next';"
        echo ""
        echo "  // Add inside <body>:"
        echo "  <Analytics />"
        echo "  <SpeedInsights />"
        echo ""
    else
        log_info "Analytics already in layout"
    fi
else
    log_warn "Layout file not found at $LAYOUT_FILE"
fi

# ============================================================================
# Create middleware template
# ============================================================================

log_step "Creating middleware template..."

if [[ ! -f "middleware.ts" ]]; then
    cat > middleware.ts << 'CODE'
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Add request ID for tracing
  const requestId = crypto.randomUUID();
  response.headers.set('x-request-id', requestId);

  // Example: Protected routes
  // const token = request.cookies.get('auth-token');
  // if (request.nextUrl.pathname.startsWith('/dashboard') && !token) {
  //   return NextResponse.redirect(new URL('/login', request.url));
  // }

  return response;
}

export const config = {
  matcher: [
    // Match all paths except static files and images
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
CODE
    log_info "Created middleware.ts"
else
    log_info "middleware.ts already exists"
fi

# ============================================================================
# Create/update .env files
# ============================================================================

log_step "Updating environment files..."

# Add Vercel-specific variables to .env.example
if [[ -f ".env.example" ]]; then
    if ! grep -q "VERCEL" .env.example; then
        cat >> .env.example << 'ENV'

# Vercel (auto-set in production)
# VERCEL_URL=your-app.vercel.app
# VERCEL_ENV=production|preview|development
ENV
        log_info "Added Vercel variables to .env.example"
    fi
fi

# ============================================================================
# Create GitHub Actions workflow for Vercel
# ============================================================================

log_step "Creating Vercel deployment workflow..."

mkdir -p .github/workflows

cat > .github/workflows/vercel-deploy.yml << 'WORKFLOW'
name: Vercel Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
  VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install Vercel CLI
        run: npm install -g vercel@latest

      - name: Pull Vercel Environment
        run: vercel pull --yes --environment=preview --token=${{ secrets.VERCEL_TOKEN }}

      - name: Build
        run: vercel build --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy Preview
        if: github.event_name == 'pull_request'
        run: vercel deploy --prebuilt --token=${{ secrets.VERCEL_TOKEN }}

      - name: Deploy Production
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
WORKFLOW

log_info "Created .github/workflows/vercel-deploy.yml"

# ============================================================================
# Create .vercelignore
# ============================================================================

log_step "Creating .vercelignore..."

cat > .vercelignore << 'IGNORE'
# Dependencies
node_modules

# Local env files
.env*.local

# Testing
coverage
.nyc_output

# IDE
.idea
.vscode

# OS
.DS_Store

# Build cache (let Vercel handle)
.next

# The Agency specific
claude/logs
IGNORE

log_info "Created .vercelignore"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Vercel Starter Pack Installed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Created:"
echo "  vercel.json           - Vercel configuration with security headers"
echo "  middleware.ts         - Edge middleware template"
echo "  .vercelignore         - Files to exclude from deployment"
echo "  .github/workflows/    - Vercel deployment workflow"
echo ""
echo "Installed:"
echo "  @vercel/analytics     - Web analytics"
echo "  @vercel/speed-insights - Performance monitoring"
echo ""
echo "Next steps:"
echo "  1. Add Analytics to your layout.tsx:"
echo "     import { Analytics } from '@vercel/analytics/react';"
echo "     import { SpeedInsights } from '@vercel/speed-insights/next';"
echo ""
echo "  2. Connect your repo in Vercel dashboard:"
echo "     https://vercel.com/new"
echo ""
echo "  3. Add GitHub secrets for CI/CD:"
echo "     - VERCEL_TOKEN (from https://vercel.com/account/tokens)"
echo "     - VERCEL_ORG_ID (from .vercel/project.json after linking)"
echo "     - VERCEL_PROJECT_ID (from .vercel/project.json after linking)"
echo ""
echo "  4. Run 'vercel link' to connect this project"
echo ""
echo "See CONVENTIONS.md for detailed documentation."
echo ""
