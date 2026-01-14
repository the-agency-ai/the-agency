# Setup: PostHog Analytics

**Time:** ~15 minutes
**Difficulty:** Beginner

## Step 1: Create PostHog Account

```bash
# Visit https://posthog.com and sign up
# Or use CLI (if you have existing account):
# PostHog doesn't have official CLI, use dashboard

# Get your project API key from:
# Settings > Project > Project API Key
```

## Step 2: Get Credentials

From PostHog dashboard (Settings > Project):

- **Project API Key** (public, for client)
- **Personal API Key** (private, for server - Settings > Personal API Keys)

```bash
# Add to .env.local
cat >> .env.local << 'EOF'
NEXT_PUBLIC_POSTHOG_KEY=phc_xxxxx
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
POSTHOG_PERSONAL_API_KEY=phx_xxxxx
EOF
```

## Step 3: Install Dependencies

```bash
pnpm add posthog-js posthog-node
```

## Step 4: Create PostHog Provider

```bash
mkdir -p src/lib/posthog

cat > src/lib/posthog/client.ts << 'EOF'
import posthog from 'posthog-js';

export function initPostHog() {
  if (typeof window !== 'undefined' && process.env.NEXT_PUBLIC_POSTHOG_KEY) {
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://us.i.posthog.com',
      person_profiles: 'identified_only',
      capture_pageview: false, // We capture manually for Next.js
      capture_pageleave: true,
    });
  }
  return posthog;
}

export { posthog };
EOF
```

## Step 5: Create Provider Component

```bash
cat > src/lib/posthog/provider.tsx << 'EOF'
'use client';

import { useEffect } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { initPostHog, posthog } from './client';

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    initPostHog();
  }, []);

  useEffect(() => {
    if (pathname && posthog) {
      let url = window.origin + pathname;
      if (searchParams.toString()) {
        url = url + '?' + searchParams.toString();
      }
      posthog.capture('$pageview', { $current_url: url });
    }
  }, [pathname, searchParams]);

  return <>{children}</>;
}
EOF
```

## Step 6: Create Server Client

```bash
cat > src/lib/posthog/server.ts << 'EOF'
import { PostHog } from 'posthog-node';

let posthogClient: PostHog | null = null;

export function getPostHogServer(): PostHog {
  if (!posthogClient) {
    posthogClient = new PostHog(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
      host: process.env.NEXT_PUBLIC_POSTHOG_HOST,
      flushAt: 1,
      flushInterval: 0,
    });
  }
  return posthogClient;
}

export async function captureServerEvent(
  distinctId: string,
  event: string,
  properties?: Record<string, unknown>
) {
  const client = getPostHogServer();
  client.capture({
    distinctId,
    event,
    properties,
  });
  await client.shutdown();
}
EOF
```

## Step 7: Add Provider to Layout

```bash
# Update src/app/layout.tsx
# Add import and wrap children

cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { Suspense } from 'react';
import { PostHogProvider } from '@/lib/posthog/provider';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'My Agency App',
  description: 'Built with The Agency',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Suspense fallback={null}>
          <PostHogProvider>{children}</PostHogProvider>
        </Suspense>
      </body>
    </html>
  );
}
EOF
```

## Step 8: Create Analytics Hook

```bash
cat > src/lib/posthog/hooks.ts << 'EOF'
'use client';

import { posthog } from './client';

export function useAnalytics() {
  const track = (event: string, properties?: Record<string, unknown>) => {
    posthog.capture(event, properties);
  };

  const identify = (userId: string, properties?: Record<string, unknown>) => {
    posthog.identify(userId, properties);
  };

  const reset = () => {
    posthog.reset();
  };

  return { track, identify, reset };
}
EOF
```

## Step 9: Export from Index

```bash
cat > src/lib/posthog/index.ts << 'EOF'
export { posthog, initPostHog } from './client';
export { PostHogProvider } from './provider';
export { useAnalytics } from './hooks';
export { getPostHogServer, captureServerEvent } from './server';
EOF
```

## Step 10: Git Commit

```bash
git add .
git commit -m "Add posthog-analytics starter pack"
```

## Done!

Proceed to [VERIFY.md](./VERIFY.md) to confirm setup.
