# The Agency Workshop Guide

## For Workshop Facilitators

This document covers running an Agency workshop — from pre-work instructions to the live session.

---

## Pre-Work (Send to Participants Before Workshop)

### WhatsApp/Email Template

```
🚀 The Agency Workshop — Pre-Work

Hey! Before Friday's workshop, please complete these 3 things:

━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣ CLAUDE ACCOUNT (Required)

Sign up for Claude Pro ($20/mo) or Max ($100-200/mo):
→ https://claude.ai

This is what powers the AI. Without it, you can't participate hands-on.

━━━━━━━━━━━━━━━━━━━━━━━━━

2️⃣ GITHUB ACCOUNT (Required)

If you don't have one, create a free account:
→ https://github.com/signup

We use GitHub for cloning and version control.

━━━━━━━━━━━━━━━━━━━━━━━━━

3️⃣ GITHUB TOKEN (Required)

Create a Personal Access Token so we can clone the framework:

1. Go to: https://github.com/settings/tokens?type=beta
2. Click "Generate new token"
3. Name it: "agency-workshop"
4. Expiration: 7 days (or custom date after Jan 9)
5. Repository access: "All repositories" (read-only is fine)
6. Permissions → Repository permissions → Contents: "Read-only"
7. Click "Generate token"
8. COPY THE TOKEN — you won't see it again!

Save it somewhere safe. You'll paste it during the workshop.

━━━━━━━━━━━━━━━━━━━━━━━━━

That's it! Everything else happens live. See you Friday! 🎉
```

### Alternative: Facilitator-Provided Token

If you don't want participants creating their own tokens, use this simpler message:

```
🚀 The Agency Workshop — Pre-Work

Before Friday's workshop, please complete these 2 things:

1️⃣ CLAUDE ACCOUNT
Sign up for Claude Pro ($20/mo) or Max:
→ https://claude.ai

2️⃣ GITHUB ACCOUNT
Create a free account if you don't have one:
→ https://github.com/signup

That's it! I'll provide everything else during the workshop. See you Friday! 🎉
```

### Why These Requirements?

- **Claude account:** Claude Code requires authentication (can't automate — requires payment)
- **GitHub account:** Needed for git clone, version control
- **GitHub token:** For private repo access (or facilitator provides workshop token)

---

## Workshop Setup (Facilitator)

### Before the Workshop

1. **Generate a workshop token** (if repo is private):
   - Create a GitHub PAT with `repo` scope
   - Set expiration for after workshop ends
   - This token goes in the install command

2. **Prepare the one-liner** (for private repo access):
   ```bash
   # Token goes in BOTH the curl URL AND the AGENCY_TOKEN env var
   curl -fsSL "https://TOKEN@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="TOKEN" bash -s -- my-project
   ```

   **Example with real token:**
   ```bash
   curl -fsSL "https://github_pat_xxx@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="github_pat_xxx" bash -s -- my-project
   ```

3. **Test the install** on a clean machine or VM if possible

4. **Have backup plan:**
   - Direct clone instructions if curl fails
   - Manual Claude Code install link: https://claude.ai/code

---

## Live Workshop Flow

### 1. Introduction (5 min)

- What is The Agency?
- What we'll build today
- Quick demo of a running agent

### 2. Installation (10 min)

**Put this on screen:**

```bash
curl -fsSL "https://TOKEN@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="TOKEN" bash -s -- my-project
```

(Replace `TOKEN` with the actual workshop token)

**What happens:**
1. Installs Claude Code (if needed)
2. Prompts for Claude login (if needed)
3. Clones and sets up the project
4. Installs recommended tools (macOS: via brew)
5. Asks "Launch The Captain now?"
6. Drops them into their first agent session

**Troubleshooting during install:**
- "Permission denied" → They need to run in a directory they own
- "git not found" → `xcode-select --install` on macOS
- Claude login fails → Check they have an active Claude subscription

### 3. The Welcome Interview (10 min)

Once in the Claude session, participants type:

```
/welcome
```

The Captain (housekeeping agent) runs a 10-minute guided interview:
1. Asks what they're building
2. Creates their first workstream
3. Creates their first agent
4. Quick tour of the structure
5. Builds something real (a simple tool)

### 4. Exploration (15-30 min)

Suggested exercises:
- "Ask your agent to explain the directory structure"
- "Run `./tools/find-tool` to see available tools"
- "Create a simple tool that does X"
- "Have your agent write a small feature"

### 5. Wrap-Up (5 min)

- What they built
- Where to go next (GETTING_STARTED.md, documentation)
- Community links (if applicable)

---

## The One Command

For easy copy-paste, here's the workshop command with placeholder:

```bash
curl -fsSL "https://__TOKEN__@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="__TOKEN__" bash -s -- my-project
```

Replace `__TOKEN__` with your GitHub PAT before sharing.

**Jan 9 Workshop Token:**
```bash
curl -fsSL "https://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@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="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" bash -s -- my-project
```

Token expires: Mon, Jan 12 2026

---

## What the Install Does

| Step | What Happens |
|------|--------------|
| 1 | Checks for git (required) |
| 2 | Installs Claude Code if missing |
| 3 | Checks Claude authentication |
| 4 | Checks recommended tools (jq, gh, tree, etc.) |
| 5 | Clones the-agency-starter repo |
| 6 | Initializes fresh git repo |
| 7 | Makes all tools executable |
| 8 | Runs platform setup (installs tools via brew on macOS) |
| 9 | Prompts to launch The Captain |
| 10 | Execs into `./tools/myclaude housekeeping housekeeping` |

---

## FAQ

**Q: What if someone doesn't have a Claude account?**
A: They can't participate in the hands-on portion. They can watch and pair with someone who has an account.

**Q: What if the install fails?**
A: Manual fallback (for private repo):
```bash
git clone https://TOKEN@github.com/the-agency-ai/the-agency-starter.git my-project
cd my-project
chmod +x tools/*
./tools/myclaude housekeeping housekeeping
```

Manual fallback (for public repo):
```bash
git clone https://github.com/the-agency-ai/the-agency-starter.git my-project
cd my-project
chmod +x tools/*
./tools/myclaude housekeeping housekeeping
```

**Q: What if Claude Code install fails?**
A: Direct them to https://claude.ai/code for manual install instructions.

**Q: Can they use Claude Pro or do they need Max?**
A: Pro works fine for the workshop. Max is better for real projects with multiple agents.

**Q: How long should the workshop be?**
A: Minimum 45 minutes. Ideal is 90 minutes for exploration time.

---

## Post-Workshop

Send participants:
- Link to GETTING_STARTED.md in their project
- Community links (Discord, GitHub Discussions) if applicable
- Reminder that their project is ready to use

---

*Last updated: 2026-01-06*
