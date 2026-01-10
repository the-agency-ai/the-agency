# Next.js + React Starter Pack

Conventions for Next.js and React projects in The Agency.

## Project Structure

```
project/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (auth)/             # Route groups
│   │   │   ├── login/
│   │   │   └── register/
│   │   ├── api/                # API routes
│   │   │   └── resource/
│   │   │       ├── create/route.ts
│   │   │       ├── list/route.ts
│   │   │       ├── get/[id]/route.ts
│   │   │       ├── update/[id]/route.ts
│   │   │       └── delete/[id]/route.ts
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/                 # Reusable UI components
│   │   ├── forms/              # Form components
│   │   └── layouts/            # Layout components
│   ├── lib/                    # Utilities and helpers
│   │   ├── api.ts              # API client
│   │   ├── utils.ts            # General utilities
│   │   └── constants.ts        # App constants
│   ├── hooks/                  # Custom React hooks
│   ├── types/                  # TypeScript types
│   └── styles/                 # Additional styles
├── public/                     # Static assets
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

---

## API Routes (Explicit Operations)

**IMPORTANT:** Follow The Agency's explicit operation pattern. Do NOT rely on HTTP verb semantics.

### Pattern

```typescript
// src/app/api/resource/create/route.ts
export async function POST(request: Request) {
  const body = await request.json();
  // Create resource
  return Response.json({ id: 'new-id', ...body });
}

// src/app/api/resource/list/route.ts
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const limit = searchParams.get('limit') || '10';
  // List resources
  return Response.json({ items: [], total: 0 });
}

// src/app/api/resource/get/[id]/route.ts
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  // Get single resource
  return Response.json({ id: params.id });
}

// src/app/api/resource/update/[id]/route.ts
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const body = await request.json();
  // Update resource
  return Response.json({ id: params.id, ...body });
}

// src/app/api/resource/delete/[id]/route.ts
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  // Delete resource
  return Response.json({ deleted: true });
}
```

### Anti-patterns (DO NOT USE)

```typescript
// BAD: Relies on HTTP verb semantics
export async function DELETE(request: Request) { ... }
export async function PATCH(request: Request) { ... }

// BAD: Ambiguous endpoints
// POST /api/resource (is this create? update?)
// GET /api/resource/123 (use /get/123 instead)
```

---

## Component Patterns

### Server Components (Default)

```tsx
// src/app/dashboard/page.tsx
async function DashboardPage() {
  const data = await fetchData(); // Server-side fetch

  return (
    <div>
      <h1>Dashboard</h1>
      <DataDisplay data={data} />
    </div>
  );
}

export default DashboardPage;
```

### Client Components

```tsx
// src/components/ui/Counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count}
    </button>
  );
}
```

### Component File Structure

```tsx
// src/components/ui/Button.tsx

// 1. Imports
import { forwardRef } from 'react';
import { cn } from '@/lib/utils';

// 2. Types
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

// 3. Component
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', loading, children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'rounded font-medium transition-colors',
          variants[variant],
          sizes[size],
          loading && 'opacity-50 cursor-not-allowed',
          className
        )}
        disabled={loading}
        {...props}
      >
        {loading ? 'Loading...' : children}
      </button>
    );
  }
);

Button.displayName = 'Button';

// 4. Variants (colocated)
const variants = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700',
  secondary: 'bg-gray-200 text-gray-800 hover:bg-gray-300',
  danger: 'bg-red-600 text-white hover:bg-red-700',
};

const sizes = {
  sm: 'px-3 py-1 text-sm',
  md: 'px-4 py-2',
  lg: 'px-6 py-3 text-lg',
};
```

---

## State Management

### Server State (React Query / SWR)

```tsx
// src/hooks/useResource.ts
'use client';

import useSWR from 'swr';

const fetcher = (url: string) => fetch(url).then(r => r.json());

export function useResource(id: string) {
  const { data, error, isLoading, mutate } = useSWR(
    `/api/resource/get/${id}`,
    fetcher
  );

  return {
    resource: data,
    isLoading,
    isError: error,
    refresh: mutate,
  };
}
```

### Client State (Zustand)

```tsx
// src/lib/store.ts
import { create } from 'zustand';

interface AppState {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}

export const useAppStore = create<AppState>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
}));
```

---

## Form Handling

### With React Hook Form + Zod

```tsx
// src/components/forms/CreateResourceForm.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
});

type FormData = z.infer<typeof schema>;

export function CreateResourceForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    const response = await fetch('/api/resource/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });

    if (!response.ok) throw new Error('Failed to create');
    // Handle success
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} placeholder="Name" />
      {errors.name && <span>{errors.name.message}</span>}

      <input {...register('email')} placeholder="Email" />
      {errors.email && <span>{errors.email.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create'}
      </button>
    </form>
  );
}
```

---

## Error Handling

### Error Boundary

```tsx
// src/app/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      <h2>Something went wrong!</h2>
      <p>{error.message}</p>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

### Loading States

```tsx
// src/app/dashboard/loading.tsx
export default function Loading() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
    </div>
  );
}
```

---

## Environment Variables

```bash
# .env.local (never commit)
DATABASE_URL=postgresql://...
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# .env.example (commit this)
DATABASE_URL=
NEXT_PUBLIC_API_URL=
```

### Usage

```typescript
// Server-side (any env var)
const dbUrl = process.env.DATABASE_URL;

// Client-side (only NEXT_PUBLIC_ vars)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;
```

---

## TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

---

## Quick Start Checklist

- [ ] Run installer: `./claude/starter-packs/nextjs-react/install.sh`
- [ ] Set up environment variables in `.env.local`
- [ ] Configure API routes with explicit operations
- [ ] Add error boundary and loading states
- [ ] Set up form validation with Zod
- [ ] Configure state management (SWR/Zustand)
