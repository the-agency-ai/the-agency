# Setup: React App

**Time:** ~15 minutes
**Difficulty:** Beginner

## Step 1: Create Next.js App

```bash
# Create Next.js app with TypeScript and Tailwind
pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --turbopack

# Note: This will modify existing package.json
```

## Step 2: Configure shadcn/ui

```bash
# Initialize shadcn/ui
pnpm dlx shadcn@latest init

# Select options:
# - Style: Default
# - Base color: Neutral
# - CSS variables: Yes
```

## Step 3: Add Essential Components

```bash
# Add commonly used components
pnpm dlx shadcn@latest add button card input label
```

## Step 4: Create Basic Layout

```bash
# Create layout structure
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
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
      <body className={inter.className}>{children}</body>
    </html>
  );
}
EOF
```

## Step 5: Create Home Page

```bash
cat > src/app/page.tsx << 'EOF'
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Welcome to The Agency</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Your multi-agent development framework is ready.
          </p>
          <Button>Get Started</Button>
        </CardContent>
      </Card>
    </main>
  );
}
EOF
```

## Step 6: Update Scripts

```bash
pnpm pkg set scripts.dev="next dev --turbopack"
pnpm pkg set scripts.build="next build"
pnpm pkg set scripts.start="next start"
pnpm pkg set scripts.lint="next lint"
```

## Step 7: Git Commit

```bash
git add .
git commit -m "Add react-app starter pack"
```

## Done!

Proceed to [VERIFY.md](./VERIFY.md) to confirm setup.
