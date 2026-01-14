# Verify: React App

## Automated Check

```bash
pnpm dev &
sleep 5
curl http://localhost:3000 | grep -q "Agency" && echo "✅ App running"
pkill -f "next dev"
```

## Manual Checks

### 1. Development Server

```bash
pnpm dev
# Open http://localhost:3000
# Expected: See welcome card with "The Agency"
```

### 2. Production Build

```bash
pnpm build
# Expected: No errors, .next folder created
```

### 3. shadcn/ui Components

```bash
ls src/components/ui/
# Expected: button.tsx, card.tsx, input.tsx, label.tsx
```

## Verification Checklist

- [ ] `pnpm dev` starts without errors
- [ ] Browser shows welcome page
- [ ] `pnpm build` succeeds
- [ ] shadcn components exist in `src/components/ui/`
- [ ] Tailwind styles working (card has styling)

## Troubleshooting

### Port 3000 in use

```bash
lsof -i :3000 | awk 'NR>1 {print $2}' | xargs kill
```

### Module not found

```bash
pnpm install
```

### Tailwind not working

```bash
# Check tailwind.config.ts exists
# Check globals.css has @tailwind directives
```
