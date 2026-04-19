# Starter Packs

Modular, composable setup guides for The Agency.

## Philosophy

- **One pack, one purpose** - Each pack does one thing well
- **CLI/API first** - No clicking through UIs
- **Composable** - Chain packs together for your stack
- **Verifiable** - Each pack has verification steps

## Available Packs

| Pack                                        | Purpose            | Dependencies                    |
| ------------------------------------------- | ------------------ | ------------------------------- |
| [node-base](./node-base/)                   | Node.js foundation | None                            |
| [react-app](./react-app/)                   | Next.js web app    | node-base                       |
| [supabase-auth](./supabase-auth/)           | Authentication     | node-base, react-app            |
| [posthog-analytics](./posthog-analytics/)   | Analytics          | node-base, react-app            |
| [github-ci](./github-ci/)                   | CI/CD pipeline     | node-base                       |
| [vercel](./vercel/)                         | Deployment         | node-base, react-app            |

## Composition Paths

### Full-Stack Web App

```
node-base → react-app → supabase-auth → github-ci → vercel
```

**Result:** Next.js app with auth, CI/CD, and production deployment.

### API Service Only

```
node-base → nitro-api → supabase-auth → supabase-data → github-ci → vercel
```

**Result:** API service with auth, database, CI/CD, and deployment.

### Static Site

```
node-base → react-app → github-ci → vercel
```

**Result:** Static Next.js site with CI/CD and deployment.

## Pack Structure

Each pack contains:

```
pack-name/
├── README.md           # Overview, trade-offs
├── PREREQUISITES.md    # Required packs/tools
├── SETUP.md            # Step-by-step instructions
├── VERIFY.md           # Verification checklist
└── INTEGRATE.md        # Integration with other packs
```

## Using Packs

1. Read `PREREQUISITES.md` - ensure dependencies complete
2. Follow `SETUP.md` - step by step
3. Run `VERIFY.md` - confirm it works
4. Read `INTEGRATE.md` - prepare for next pack

## Backlog

Future packs (not yet implemented):

- nitro-api - Nitro.js API layer
- supabase-data - Database setup
- localization - i18n support
- react-native - Mobile apps
- cloudflare-deploy - Alternative deployment

## Contributing

To add a new pack:

1. Create directory with standard structure
2. Document all CLI/API commands
3. Include verification steps
4. Test on fresh environment
5. Submit PR

---

_Starter Packs: Infrastructure as documentation_
