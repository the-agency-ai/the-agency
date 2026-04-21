# Session Backup — 2026-01-06 @ 21:45

## What We Accomplished

### Workshop Prep (P0 Complete)
- ✅ install.sh tested end-to-end
- ✅ /welcome interview flow verified
- ✅ AGENCY_TOKEN clone verified with workshop token
- ✅ Pre-approved permissions added (.claude/settings.json)
- ✅ the-agency-starter repo synced to GitHub
- ✅ Pre-work WhatsApp message drafted
- ✅ WORKSHOP.md updated with correct curl command
- ✅ GitHub tokens stored in secrets (workshop + admin)

### Key Files Updated
- `the-agency-starter/.claude/settings.json` — Pre-approved permissions
- `the-agency-starter/WORKSHOP.md` — Curl command + WhatsApp template
- `claude/principals/jordan/resources/secrets/github.env` — Tokens
- `claude/principals/jordan/projects/the-agency-book/JAN-23-PRODUCT-BACKLOG.md` — Progress update

### Repos Synced
- `the-agency` → main (6ae8eb5)
- `the-agency-starter` → main (54fbeed)

---

## Workshop Token

```
Name: the-agency-workshop-beta-read-only
Token: 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
Expires: Mon, Jan 12 2026
```

**Workshop curl command:**
```bash
curl -fsSL "https://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@raw.githubusercontent.com/the-agency-ai/the-agency-starter/main/install.sh" | AGENCY_TOKEN="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" bash -s -- my-project
```

---

## Product Architecture Discussed

### Two Target Profiles
1. **Solo Principal Agency** (1 human, N agents)
2. **Multi-Principal Agency** (N humans, N agents)

### Three Deployment Flavors
1. **localhost** — runs on your machine
2. **self-hosted** — you run it on your server
3. **multi-tenant cloud** — we run it (SaaS)

### What's IN the-agency-starter (Free/Open Source)
- 40+ tools
- install.sh
- CLAUDE.md, PHILOSOPHY.md
- /welcome onboarding
- Housekeeping agent
- Workstream/agent scaffolding
- Collaboration tools
- Quality tools

### What's OUTSIDE (Paid/Services)
- The Agency Guide book ($29-99)
- Workbench (modular shell + modules)
- MockAndMark (native app)
- Open Feedback (AI feedback platform)
- CLI Integrations (Gumroad, Discord)
- Team licenses

---

## Services Pipeline

### Web Services (localhost → self-host → cloud)

| Service | Proposal | Status | Priority |
|---------|----------|--------|----------|
| Markdown Manager | PROP-0008 | Design | HIGH |
| Workbench | PROP-0011 | Design | Medium |
| Open Feedback | PROP-0012 | Design | Medium |
| Knowledge Indexer | PROP-0014 | Design | HIGH |

### Native Apps

| App | Description | Platform | Status |
|-----|-------------|----------|--------|
| MockAndMark | **Screenshot** annotation + quick mockups | iOS/iPadOS/macOS | Scaffolded |

### CLI Tools (for starter)

| Tool | Proposal | Status |
|------|----------|--------|
| Gumroad CLI | PROP-0018 | Design |
| Discord CLI | PROP-0018 | Design |
| Open Webpage | PROP-0013 | Design |

---

## Achievable for Jan 23 Launch

| Service | Effort | Notes |
|---------|--------|-------|
| **Markdown Browser V1** | 4-8 hrs | File browser + preview + search |
| **Knowledge Indexer** | 2-4 hrs | ./tools/where "topic" |
| **Discord/Gumroad CLI** | 4-8 hrs | Basic operations |
| **MockAndMark MVP** | 2-3 days | iPadOS, stretch goal |

---

## Remaining Workshop P0

| Task | Status |
|------|--------|
| Workshop slides | 🔴 Pending |

---

## Key Proposals to Reference

- `PROP-0008` — Markdown Manager (browser/editor)
- `PROP-0010` — Pricing Model
- `PROP-0011` — Workbench (shell + modules)
- `PROP-0012` — Open Feedback
- `PROP-0014` — Knowledge Indexer
- `PROP-0018` — CLI Integrations (Gumroad/Discord)

---

## To Restart

```bash
cd /Users/jdm/code/the-agency
./tools/myclaude housekeeping housekeeping
```

Then share this file or say:
> "Read SESSION-BACKUP-2026-01-06-2145.md and continue"

---

## Next Session Priorities

1. **Decide:** Which services to build for Jan 23?
2. **Build:** Markdown Browser V1 (if yes)
3. **Build:** Knowledge Indexer (quick win)
4. **Build:** Discord/Gumroad CLI (you need these)
5. **Optional:** MockAndMark MVP (if time)
6. **Remaining:** Workshop slides

---

_Session backup created 2026-01-06 @ 21:45_
