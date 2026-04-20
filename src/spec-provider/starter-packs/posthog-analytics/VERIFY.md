# Verify: PostHog Analytics

## Automated Check

```bash
# Check environment variables
grep POSTHOG .env.local && echo "✅ PostHog configured"

# Check imports work
pnpm build && echo "✅ Build passes"
```

## Manual Checks

### 1. Environment Variables Set

```bash
cat .env.local | grep POSTHOG
# Should show:
# NEXT_PUBLIC_POSTHOG_KEY=phc_xxxxx
# NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
```

### 2. Provider Loads

1. Run `pnpm dev`
2. Open browser DevTools > Network
3. Look for requests to `posthog.com` or `us.i.posthog.com`
4. Should see initialization request

### 3. Page Views Tracked

1. Navigate between pages in your app
2. Go to PostHog dashboard > Activity
3. Should see `$pageview` events appearing

### 4. Custom Events Work

```tsx
// Add to any component temporarily:
import { useAnalytics } from '@/lib/posthog';

function TestButton() {
  const { track } = useAnalytics();
  return <button onClick={() => track('test_click', { source: 'verify' })}>Test Track</button>;
}
```

Click button, check PostHog dashboard for `test_click` event.

## Verification Checklist

- [ ] `.env.local` has PostHog credentials
- [ ] `pnpm build` succeeds
- [ ] PostHog provider wraps app
- [ ] Network requests to PostHog visible
- [ ] Page views appear in dashboard
- [ ] Custom events trackable

## Troubleshooting

### No events in dashboard

```bash
# Check API key is correct
echo $NEXT_PUBLIC_POSTHOG_KEY

# Check host matches your region (us vs eu)
# US: https://us.i.posthog.com
# EU: https://eu.i.posthog.com
```

### Build errors

```bash
# Ensure posthog packages installed
pnpm add posthog-js posthog-node
```

### Events delayed

PostHog batches events. Wait 1-2 minutes or check "Live Events" in dashboard.

### Server-side not working

```bash
# Ensure POSTHOG_PERSONAL_API_KEY set for server-side
# Or use NEXT_PUBLIC_POSTHOG_KEY (works for both)
```
