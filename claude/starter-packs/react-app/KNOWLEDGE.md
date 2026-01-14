# Knowledge: React App

Context for agents working with this pack.

## Tech Stack

- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript 5.x
- **Styling:** Tailwind CSS 3.x
- **Components:** shadcn/ui
- **Build:** Turbopack (dev), Webpack (prod)

## Key Concepts

### App Router

- File-based routing in `src/app/`
- `page.tsx` = route endpoint
- `layout.tsx` = shared layouts
- `loading.tsx` = loading states
- `error.tsx` = error boundaries

### Server vs Client Components

```tsx
// Server Component (default)
export default function ServerPage() {
  return <div>Runs on server</div>;
}

// Client Component
('use client');
export default function ClientPage() {
  const [state, setState] = useState();
  return <div>Runs in browser</div>;
}
```

### shadcn/ui Components

```bash
# Add new component
pnpm dlx shadcn@latest add dialog

# Components are copied to src/components/ui/
# You own them - customize freely
```

## Common Patterns

### Adding a New Page

```tsx
// src/app/dashboard/page.tsx
export default function DashboardPage() {
  return <div>Dashboard</div>;
}
```

### Adding a Layout

```tsx
// src/app/dashboard/layout.tsx
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex">
      <Sidebar />
      <main>{children}</main>
    </div>
  );
}
```

### API Routes

```tsx
// src/app/api/hello/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ message: 'Hello' });
}
```

## Agent Instructions

When working with this pack:

1. **Prefer Server Components** - Only use 'use client' when needed
2. **Use shadcn/ui** - Don't reinvent UI components
3. **Keep layouts simple** - Heavy logic in pages, not layouts
4. **Check build** - `pnpm build` before committing

## Troubleshooting Guide

| Issue               | Solution                                        |
| ------------------- | ----------------------------------------------- |
| Hydration mismatch  | Check server vs client rendering                |
| CSS not loading     | Verify Tailwind config                          |
| Component not found | Run `pnpm dlx shadcn@latest add X`              |
| Build fails         | Check for 'use client' on hook-using components |
