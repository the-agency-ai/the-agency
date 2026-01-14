# Setup: Vercel

**Time:** ~20 minutes
**Difficulty:** Beginner

## Step 1: Install Vercel CLI

```bash
pnpm add -g vercel
```

## Step 2: Create vercel.json

```bash
cat > vercel.json << 'EOF'
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
EOF
```

## Step 3: Install Vercel Packages

```bash
pnpm add @vercel/analytics @vercel/speed-insights
```

## Step 4: Add Analytics to Layout

Update `src/app/layout.tsx`:

```tsx
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

## Step 5: Create Middleware Template

```bash
cat > middleware.ts << 'EOF'
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
EOF
```

## Step 6: Create .vercelignore

```bash
cat > .vercelignore << 'EOF'
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
EOF
```

## Step 7: Update Environment Files

Add to `.env.example`:

```bash
cat >> .env.example << 'EOF'

# Vercel (auto-set in production)
# VERCEL_URL=your-app.vercel.app
# VERCEL_ENV=production|preview|development
EOF
```

## Step 8: Create GitHub Actions Workflow

```bash
mkdir -p .github/workflows

cat > .github/workflows/vercel-deploy.yml << 'EOF'
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

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Install Vercel CLI
        run: pnpm add -g vercel@latest

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
EOF
```

## Step 9: Link Project to Vercel

```bash
vercel link

# Follow prompts:
# - Select or create project
# - Confirm settings
```

## Step 10: Add GitHub Secrets

Add these secrets to your GitHub repository (Settings > Secrets):

1. **VERCEL_TOKEN** - Get from https://vercel.com/account/tokens
2. **VERCEL_ORG_ID** - From `.vercel/project.json` after linking
3. **VERCEL_PROJECT_ID** - From `.vercel/project.json` after linking

## Step 11: Git Commit

```bash
git add .
git commit -m "Add vercel starter pack"
```

## Done!

Proceed to [VERIFY.md](./VERIFY.md) to confirm setup.
