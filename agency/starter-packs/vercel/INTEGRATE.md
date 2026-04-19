# Integrate: Vercel

## Works With

This pack integrates with:

| Pack              | Integration                           |
| ----------------- | ------------------------------------- |
| `react-app`       | Deploys Next.js apps                  |
| `supabase-auth`   | Auth redirect URLs need Vercel domain |
| `github-ci`       | Extends CI with deployment steps      |
| `posthog-analytics` | Alternative analytics option        |

## Integration Steps

### With supabase-auth

Update Supabase auth settings with Vercel URLs:

```bash
# Add to Supabase Dashboard > Authentication > URL Configuration
# Site URL: https://your-app.vercel.app
# Redirect URLs:
#   - https://your-app.vercel.app/auth/callback
#   - https://*.vercel.app/auth/callback (for preview deployments)
```

### With github-ci

If using `github-ci` pack, the Vercel workflow can be merged:

```yaml
# Combine test + deploy in single workflow
jobs:
  test:
    # ... existing test job from github-ci

  deploy:
    needs: test # Only deploy if tests pass
    # ... Vercel deploy job
```

### With posthog-analytics

Vercel Analytics and PostHog can coexist:

```tsx
// src/app/layout.tsx
import { Analytics } from '@vercel/analytics/react';
import { PostHogProvider } from '@/components/providers/posthog';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <PostHogProvider>
          {children}
        </PostHogProvider>
        <Analytics /> {/* Both can run together */}
      </body>
    </html>
  );
}
```

## Environment Variables

Add these to Vercel dashboard for each environment:

| Variable              | Description            | Environment |
| --------------------- | ---------------------- | ----------- |
| `DATABASE_URL`        | Supabase connection    | All         |
| `NEXT_PUBLIC_API_URL` | Public API endpoint    | All         |
| `POSTHOG_KEY`         | PostHog project key    | Production  |

## Preview Deployment URLs

Preview deployments get unique URLs. Handle this in code:

```typescript
// Get correct base URL in any environment
function getBaseUrl() {
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }
  return 'http://localhost:3000';
}
```
