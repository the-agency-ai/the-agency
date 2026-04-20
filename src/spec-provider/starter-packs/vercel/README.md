# Vercel Starter Pack

**Production Deployment with Vercel**

## What This Pack Does

Sets up production deployment with:

- Vercel project configuration
- Security headers (XSS, CSRF, clickjacking protection)
- Edge middleware template
- Analytics and Speed Insights
- GitHub Actions CI/CD workflow

## Why Vercel?

| Choice            | Alternative        | Why We Chose This               |
| ----------------- | ------------------ | ------------------------------- |
| Vercel            | Netlify, AWS       | Native Next.js, zero-config     |
| Edge Functions    | Lambda             | Low latency, global deployment  |
| Vercel Analytics  | GA, Plausible      | Native integration, no sampling |
| GitHub Actions CI | Vercel Git Hook    | Full control, pre-deploy checks |

## Dependencies

**Required:** `node-base`, `react-app`
**Optional:** `github-ci` (for full CI/CD workflow)

## What's Next?

After completing this pack:

- Configure custom domain in Vercel dashboard
- Set up environment variables for production
- Enable preview deployments for PRs
- Add Vercel integrations (Postgres, KV, Blob)
