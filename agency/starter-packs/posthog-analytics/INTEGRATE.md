# Integrate: PostHog Analytics

## What This Pack Provides

| Component  | Location                       | Purpose            |
| ---------- | ------------------------------ | ------------------ |
| Client SDK | `src/lib/posthog/client.ts`    | Browser tracking   |
| Server SDK | `src/lib/posthog/server.ts`    | API route tracking |
| Provider   | `src/lib/posthog/provider.tsx` | Auto page views    |
| Hook       | `src/lib/posthog/hooks.ts`     | Easy tracking API  |

## Next Packs

### Recommended Path

```
posthog-analytics → supabase-analytics (for event storage)
```

### With Feature Flags

PostHog includes feature flags - no additional pack needed.

## Integration Points

### With supabase-auth

Track user identity after login:

```tsx
// After successful login
import { useAnalytics } from '@/lib/posthog';

const { identify } = useAnalytics();
identify(user.id, {
  email: user.email,
  plan: user.subscription_tier,
});
```

### With supabase-data

Track database operations:

```tsx
// After successful operation
import { captureServerEvent } from '@/lib/posthog/server';

await captureServerEvent(userId, 'order_created', {
  order_id: order.id,
  total: order.total,
});
```

### With vercel-deploy

Add environment variables to Vercel:

```bash
vercel env add NEXT_PUBLIC_POSTHOG_KEY
vercel env add NEXT_PUBLIC_POSTHOG_HOST
```

## Common Tracking Patterns

### E-commerce

```tsx
track('product_viewed', { product_id, price, category });
track('add_to_cart', { product_id, quantity });
track('checkout_started', { cart_total, item_count });
track('purchase_completed', { order_id, total, items });
```

### SaaS

```tsx
track('feature_used', { feature_name, context });
track('subscription_upgraded', { from_plan, to_plan });
track('onboarding_step_completed', { step, time_spent });
```

### Content

```tsx
track('article_read', { article_id, read_time, scroll_depth });
track('search_performed', { query, results_count });
```
