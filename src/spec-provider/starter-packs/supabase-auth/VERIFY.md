# Verify: Supabase Auth

## Manual Checks

### 1. Supabase Connection

```bash
# Check environment variables
cat .env.local | grep SUPABASE
# Should show URL and keys
```

### 2. Create Test User

```bash
# Via Supabase Dashboard:
# 1. Go to Authentication > Users
# 2. Click "Add user"
# 3. Add email and password
```

### 3. Test Login Flow

1. Run `pnpm dev`
2. Go to http://localhost:3000/login
3. Enter test user credentials
4. Should redirect to /dashboard

### 4. Test Protected Route

1. Open incognito window
2. Go to http://localhost:3000/dashboard
3. Should redirect to /login

## Verification Checklist

- [ ] `.env.local` has Supabase credentials
- [ ] Supabase client imports work
- [ ] Login page renders
- [ ] Login redirects to dashboard
- [ ] Dashboard shows user email
- [ ] Unauthenticated access redirects to login

## Troubleshooting

### "Invalid API key"

```bash
# Verify keys in .env.local match Supabase dashboard
supabase projects api-keys --project-ref YOUR_REF
```

### Login fails silently

```bash
# Check browser console for errors
# Enable email auth in Supabase dashboard
```

### Middleware not running

```bash
# Ensure matcher config in middleware.ts
# Check for typos in path
```
