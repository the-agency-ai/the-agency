# Knowledge: PostHog Analytics

Context for agents working with this pack.

## Tech Stack

- **Platform:** PostHog Cloud (US or EU region)
- **Client SDK:** posthog-js
- **Server SDK:** posthog-node
- **Integration:** Next.js App Router

## Key Concepts

### Client vs Server Tracking

```typescript
// Client (browser) - use in Client Components
import { posthog } from '@/lib/posthog';
posthog.capture('event_name', { property: 'value' });

// Server (API routes, Server Components) - use posthog-node
import { captureServerEvent } from '@/lib/posthog/server';
await captureServerEvent(userId, 'event_name', { property: 'value' });
```

### User Identity

```typescript
// Identify user (after login)
posthog.identify(userId, {
  email: user.email,
  name: user.name,
  plan: 'pro',
});

// Reset on logout
posthog.reset();
```

### Feature Flags

```typescript
// Check feature flag
if (posthog.isFeatureEnabled('new-dashboard')) {
  // Show new dashboard
}

// Get flag payload
const config = posthog.getFeatureFlagPayload('pricing-experiment');
```

## Common Patterns

### Track Button Clicks

```tsx
<button onClick={() => track('cta_clicked', { button: 'signup' })}>Sign Up</button>
```

### Track Form Submissions

```tsx
const handleSubmit = async (data) => {
  track('form_submitted', { form: 'contact', fields: Object.keys(data) });
  await submitForm(data);
};
```

### Track Errors

```tsx
try {
  await riskyOperation();
} catch (error) {
  track('error_occurred', {
    error: error.message,
    context: 'checkout',
  });
}
```

### Group Analytics

```typescript
// Associate user with company
posthog.group('company', companyId, {
  name: company.name,
  plan: company.plan,
});
```

## Agent Instructions

When working with this pack:

1. **Use descriptive event names** - `button_clicked` not `click`
2. **Include context** - What page, what user state
3. **Don't track PII** - No passwords, full credit cards
4. **Reset on logout** - Call `posthog.reset()`
5. **Test events** - Verify in PostHog Live Events

## PostHog Dashboard Locations

| Feature           | Dashboard Path                |
| ----------------- | ----------------------------- |
| Events            | Activity > Live Events        |
| Funnels           | Product Analytics > Funnels   |
| Retention         | Product Analytics > Retention |
| Feature Flags     | Feature Flags                 |
| Session Recording | Session Replay                |

## Troubleshooting Guide

| Issue                 | Solution                                   |
| --------------------- | ------------------------------------------ |
| No events             | Check API key and host region              |
| Duplicate page views  | Ensure `capture_pageview: false`           |
| Identity not linking  | Call `identify()` before other events      |
| Server events failing | Check `posthog-node` is imported correctly |
| Feature flags stale   | Call `posthog.reloadFeatureFlags()`        |

## Environment Variables

| Variable                   | Required | Description                      |
| -------------------------- | -------- | -------------------------------- |
| `NEXT_PUBLIC_POSTHOG_KEY`  | Yes      | Project API key (phc_xxx)        |
| `NEXT_PUBLIC_POSTHOG_HOST` | Yes      | API host (us or eu)              |
| `POSTHOG_PERSONAL_API_KEY` | Optional | For server-side with full access |
