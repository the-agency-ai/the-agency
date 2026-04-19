# Knowledge: Supabase Auth

Context for agents working with this pack.

## Tech Stack

- **Auth Provider:** Supabase Auth
- **Client:** @supabase/ssr (Next.js specific)
- **Protection:** Middleware-based

## Key Concepts

### Client Types

```typescript
// Browser - use in Client Components
import { createClient } from '@/lib/supabase/client';
const supabase = createClient();

// Server - use in Server Components, API routes
import { createClient } from '@/lib/supabase/server';
const supabase = await createClient();
```

### Auth State

```typescript
// Get current user
const {
  data: { user },
} = await supabase.auth.getUser();

// Listen to auth changes (client only)
supabase.auth.onAuthStateChange((event, session) => {
  console.log(event, session);
});
```

### Protected Routes

Middleware in `src/middleware.ts` runs before every request to protected paths.

## Common Patterns

### Sign Up

```typescript
const { data, error } = await supabase.auth.signUp({
  email,
  password,
});
```

### Sign Out

```typescript
await supabase.auth.signOut();
router.push('/');
router.refresh();
```

### Get Session in Server Component

```typescript
const supabase = await createClient();
const {
  data: { session },
} = await supabase.auth.getSession();
```

## Agent Instructions

1. **Always check user** - Never assume user is authenticated
2. **Use correct client** - Browser vs Server
3. **Refresh router** - After auth state changes
4. **Protect routes** - Add paths to middleware matcher

## Troubleshooting Guide

| Issue                  | Solution                   |
| ---------------------- | -------------------------- |
| Session not persisting | Check cookie configuration |
| Redirect loop          | Check middleware matcher   |
| User null after login  | Call router.refresh()      |
