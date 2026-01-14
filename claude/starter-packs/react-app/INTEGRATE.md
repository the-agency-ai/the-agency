# Integrate: React App

## What This Pack Provides

| Component  | Location             | Purpose       |
| ---------- | -------------------- | ------------- |
| Next.js    | `next.config.ts`     | Framework     |
| App Router | `src/app/`           | Routing       |
| Tailwind   | `tailwind.config.ts` | Styling       |
| shadcn/ui  | `src/components/ui/` | UI components |

## Next Packs

### Recommended Path

```
react-app → supabase-auth → localization → vercel-deploy
```

### With API

```
react-app → nitro-api → supabase-auth → supabase-data → vercel-deploy
```

## Integration Points

### With supabase-auth

- Adds auth components to `src/components/auth/`
- Adds middleware for route protection
- Adds auth context provider

### With localization

- Adds `next-intl` configuration
- Adds `src/messages/` for translations
- Adds locale-aware routing

### With vercel-deploy

- Adds `vercel.json` configuration
- Configures environment variables
- Sets up deployment previews
