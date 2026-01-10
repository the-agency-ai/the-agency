# Vercel Starter Pack

Conventions for deploying and managing projects on Vercel with The Agency.

## Project Configuration

### vercel.json

```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm ci",
  "regions": ["sfo1"],
  "functions": {
    "api/**/*.ts": {
      "memory": 1024,
      "maxDuration": 10
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" }
      ]
    }
  ],
  "redirects": [],
  "rewrites": []
}
```

---

## Environment Variables

### Naming Conventions

| Prefix | Purpose | Example |
|--------|---------|---------|
| `NEXT_PUBLIC_` | Client-side accessible | `NEXT_PUBLIC_API_URL` |
| `VERCEL_` | Auto-set by Vercel | `VERCEL_URL` |
| (none) | Server-only secrets | `DATABASE_URL` |

### Required Variables

```bash
# .env.local (development)
DATABASE_URL=postgresql://...
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# Vercel Dashboard (production)
DATABASE_URL=postgresql://...
NEXT_PUBLIC_API_URL=https://your-app.vercel.app/api
```

### Environment-Specific

Vercel supports different values per environment:

| Environment | Use Case |
|-------------|----------|
| Production | Live site |
| Preview | PR previews |
| Development | Local development (not used on Vercel) |

---

## Deployment

### Automatic Deployments

- **Production**: Push to `main` branch
- **Preview**: Push to any other branch or open PR
- **Instant Rollback**: One-click in Vercel dashboard

### Manual Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy preview
vercel

# Deploy production
vercel --prod
```

### GitHub Integration

1. Connect repository in Vercel dashboard
2. Configure build settings
3. Set environment variables
4. Enable automatic deployments

---

## Edge Functions

### Middleware

```typescript
// middleware.ts (project root)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Add custom headers
  const response = NextResponse.next();
  response.headers.set('x-custom-header', 'value');

  // Geolocation (Vercel provides)
  const country = request.geo?.country || 'US';

  return response;
}

export const config = {
  matcher: ['/api/:path*', '/dashboard/:path*'],
};
```

### Edge API Routes

```typescript
// src/app/api/edge-example/route.ts
import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: Request) {
  return NextResponse.json({
    message: 'This runs on the edge!',
    region: process.env.VERCEL_REGION,
  });
}
```

---

## Caching

### Static Assets

```typescript
// next.config.ts
const config = {
  images: {
    domains: ['your-cdn.com'],
  },
  async headers() {
    return [
      {
        source: '/static/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
    ];
  },
};
```

### API Caching

```typescript
// src/app/api/cached/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  const data = await fetchExpensiveData();

  return NextResponse.json(data, {
    headers: {
      'Cache-Control': 's-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

### ISR (Incremental Static Regeneration)

```typescript
// src/app/blog/[slug]/page.tsx
export const revalidate = 3600; // Revalidate every hour

export async function generateStaticParams() {
  const posts = await getPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

---

## Monitoring

### Vercel Analytics

```typescript
// src/app/layout.tsx
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
```

### Speed Insights

```typescript
// src/app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />
      </body>
    </html>
  );
}
```

---

## Security

### Security Headers

```json
// vercel.json
{
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
        }
      ]
    }
  ]
}
```

### Protected Routes

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token');

  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }

  return NextResponse.next();
}
```

---

## Domain Configuration

### Custom Domains

1. Add domain in Vercel dashboard
2. Update DNS records:
   - `A` record: `76.76.21.21`
   - `CNAME` record: `cname.vercel-dns.com`

### Preview URLs

Format: `{project}-{branch}-{team}.vercel.app`

---

## Integrations

### Database (Vercel Postgres)

```bash
# Install
npm i @vercel/postgres

# Usage
import { sql } from '@vercel/postgres';

const { rows } = await sql`SELECT * FROM users`;
```

### Blob Storage

```bash
# Install
npm i @vercel/blob

# Usage
import { put } from '@vercel/blob';

const blob = await put('file.txt', 'Hello World!', {
  access: 'public',
});
```

### KV (Key-Value Store)

```bash
# Install
npm i @vercel/kv

# Usage
import { kv } from '@vercel/kv';

await kv.set('key', 'value');
const value = await kv.get('key');
```

---

## CI/CD with GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

---

## Quick Start Checklist

- [ ] Run installer: `./claude/starter-packs/vercel/install.sh`
- [ ] Connect GitHub repo in Vercel dashboard
- [ ] Configure environment variables
- [ ] Add custom domain (if applicable)
- [ ] Enable Analytics and Speed Insights
- [ ] Configure security headers
- [ ] Set up preview deployments for PRs
