# Knowledge: Vercel

Context for agents working with this pack.

## Tech Stack

- **Platform:** Vercel
- **Runtime:** Edge (middleware), Node.js (API routes)
- **Analytics:** @vercel/analytics, @vercel/speed-insights
- **CI/CD:** GitHub Actions with Vercel CLI

## Key Concepts

### Deployment Environments

| Environment | Trigger           | URL Pattern                    |
| ----------- | ----------------- | ------------------------------ |
| Production  | Push to `main`    | your-app.vercel.app            |
| Preview     | PR or other branch| your-app-xxx-team.vercel.app   |
| Development | Local             | localhost:3000                 |

### Edge vs Node.js

```typescript
// Edge runtime (faster, limited APIs)
export const runtime = 'edge';

// Node.js runtime (full APIs, slower cold start)
export const runtime = 'nodejs';
```

### Environment Variables

| Prefix           | Scope              | Example                    |
| ---------------- | ------------------ | -------------------------- |
| `NEXT_PUBLIC_`   | Client + Server    | `NEXT_PUBLIC_API_URL`      |
| (none)           | Server only        | `DATABASE_URL`             |
| `VERCEL_`        | Auto-set by Vercel | `VERCEL_URL`, `VERCEL_ENV` |

## Common Patterns

### Protected API Routes

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  if (request.nextUrl.pathname.startsWith('/api/admin')) {
    const token = request.headers.get('authorization');
    if (!token) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
  }
  return NextResponse.next();
}
```

### Caching API Responses

```typescript
// src/app/api/data/route.ts
export async function GET() {
  const data = await fetchData();

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

### Edge API Route

```typescript
// src/app/api/fast/route.ts
import { NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: Request) {
  return NextResponse.json({
    region: process.env.VERCEL_REGION,
    timestamp: Date.now(),
  });
}
```

## Vercel Integrations

### Vercel Postgres

```bash
pnpm add @vercel/postgres

# Usage
import { sql } from '@vercel/postgres';
const { rows } = await sql`SELECT * FROM users`;
```

### Vercel KV

```bash
pnpm add @vercel/kv

# Usage
import { kv } from '@vercel/kv';
await kv.set('key', 'value');
const value = await kv.get('key');
```

### Vercel Blob

```bash
pnpm add @vercel/blob

# Usage
import { put } from '@vercel/blob';
const blob = await put('file.txt', 'content', { access: 'public' });
```

## Agent Instructions

When working with this pack:

1. **Check environment** - Use `VERCEL_ENV` to detect context
2. **Test locally first** - `pnpm build` before deploying
3. **Use preview deployments** - Deploy to preview before production
4. **Monitor builds** - Check Vercel dashboard for build logs
5. **Security first** - Never expose secrets in client code

## Troubleshooting Guide

| Issue                     | Solution                                           |
| ------------------------- | -------------------------------------------------- |
| Build fails               | Check `pnpm build` locally first                   |
| Env var undefined         | Add to Vercel dashboard, redeploy                  |
| Edge function timeout     | Move to Node.js runtime or optimize                |
| CORS errors               | Add headers in vercel.json or API route            |
| Preview URL not working   | Check branch protection rules                      |
| Analytics not showing     | Disable ad blockers, wait for propagation          |

## Domain Configuration

### Custom Domain

1. Add domain in Vercel Dashboard > Domains
2. Update DNS:
   - A record: `76.76.21.21`
   - Or CNAME: `cname.vercel-dns.com`

### Wildcard Subdomains

```json
// vercel.json
{
  "rewrites": [
    {
      "source": "/:path*",
      "destination": "/api/tenant/:path*",
      "has": [{ "type": "host", "value": "(?<tenant>.*).example.com" }]
    }
  ]
}
```
