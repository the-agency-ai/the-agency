# Verify: Vercel

## Automated Check

```bash
# Check vercel.json exists and is valid JSON
cat vercel.json | jq . > /dev/null && echo "vercel.json valid"

# Check packages installed
grep -q "@vercel/analytics" package.json && echo "Analytics installed"
grep -q "@vercel/speed-insights" package.json && echo "Speed Insights installed"

# Check middleware exists
test -f middleware.ts && echo "Middleware exists"
```

## Manual Checks

### 1. Local Build

```bash
pnpm build
# Expected: Build succeeds with no errors
```

### 2. Vercel Preview Deploy

```bash
vercel
# Expected: Deploys to preview URL
# Inspect URL: https://your-app-xxx.vercel.app
```

### 3. Security Headers

```bash
# After deploying, check headers
curl -I https://your-preview-url.vercel.app | grep -E "X-Content-Type|X-Frame|X-XSS"
# Expected: Security headers present
```

### 4. Analytics Setup

Open deployed site in browser, then check:

- Vercel Dashboard > Analytics tab
- Should show page views appearing

## Verification Checklist

- [ ] `vercel.json` exists with security headers
- [ ] `middleware.ts` exists
- [ ] `.vercelignore` exists
- [ ] `@vercel/analytics` in package.json
- [ ] `@vercel/speed-insights` in package.json
- [ ] GitHub workflow at `.github/workflows/vercel-deploy.yml`
- [ ] `pnpm build` succeeds
- [ ] `vercel` deploys without errors
- [ ] Security headers present on deployed site

## Troubleshooting

### Vercel CLI not authenticated

```bash
vercel login
```

### Project not linked

```bash
vercel link
```

### Missing environment variables

```bash
# Check Vercel dashboard for required env vars
vercel env ls
```

### Build fails on Vercel

```bash
# Check build logs
vercel logs

# Common issues:
# - Missing env vars (add in Vercel dashboard)
# - Node version mismatch (check engines in package.json)
# - pnpm lockfile issues (delete and regenerate)
```

### Analytics not showing

1. Ensure Analytics component is in root layout
2. Disable ad blockers for testing
3. Wait a few minutes for data to appear
