# PROP-0011: Workbench

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Managing agents, monitoring systems, and operating The Agency requires tooling beyond the terminal. Need a unified UI that scales from Solo to Team.

## Proposal

Workbench is the visual management layer for The Agency, with tiers matching the pricing model.

### Tier Structure

```
WORKBENCH FREE (Solo)
├── Agent list (who's configured)
├── Basic status
└── Link to terminal

WORKBENCH PREMIUM (Solo Premium)
├── Everything in Free
├── Agent Manager (configure, sessions, history)
├── Chat Interface (browser-based agent chat)
├── Analytics Dashboard (Pulse Beat)
├── Feature Flags
└── Log Viewer (local → preview → staging → prod)

WORKBENCH TEAM (Multi-Principal)
├── Everything in Premium
├── Content Manager (team workflows)
├── Principal/Team management
├── Shared dashboards
├── Admin console (users, permissions, billing)
└── Cross-principal analytics
```

---

## Components

### Agent Manager

| Feature | Free | Premium | Team |
|---------|:----:|:-------:|:----:|
| List agents | ✓ | ✓ | ✓ |
| View status | ✓ | ✓ | ✓ |
| Configure agents | | ✓ | ✓ |
| Session history | | ✓ | ✓ |
| Session replay | | ✓ | ✓ |

### Chat Interface

Browser-based chat with agents (Premium+).

- Select agent to chat with
- Full conversation history
- Context from current session
- Same capabilities as terminal

### Analytics Dashboard (Pulse Beat)

| Feature | Free | Premium | Team |
|---------|:----:|:-------:|:----:|
| Basic metrics | | ✓ | ✓ |
| Development health | | ✓ | ✓ |
| Agent performance | | ✓ | ✓ |
| Web performance | | ✓ | ✓ |
| Team dashboards | | | ✓ |
| Custom reports | | | ✓ |

### Log Viewer Service

**New component** - centralized log collection and viewing.

```
LOCAL LOGS          REMOTE LOGS
───────────         ───────────
Development    →    Preview
                    Staging
                    Production
```

| Feature | Free | Premium | Team |
|---------|:----:|:-------:|:----:|
| Local logs | ✓ | ✓ | ✓ |
| Preview logs | | ✓ | ✓ |
| Staging logs | | ✓ | ✓ |
| Production logs | | ✓ | ✓ |
| Log search | | ✓ | ✓ |
| Log correlation | | | ✓ |

### Feature Flags

Manage feature toggles (Premium+).

- Toggle features on/off
- Sync with PostHog or other providers
- Environment-specific overrides

### Content Manager

Team content workflows (Team only).

- Catalog management
- Content versioning
- Approval workflows
- Multi-principal collaboration

### Admin Console

Team administration (Team only).

- User/Principal management
- Permissions and roles
- Billing and usage
- Audit logs

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    WORKBENCH UI                          │
│                   (Next.js App)                          │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                  WORKBENCH API                           │
│                (Nitro Service)                           │
├─────────────────────────────────────────────────────────┤
│  Agent Manager │ Pulse Beat │ Logs │ Flags │ Content   │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                    DATA LAYER                            │
│  Local: SQLite/Files    Cloud: Supabase/Postgres        │
└─────────────────────────────────────────────────────────┘
```

---

## Pricing Fit

| Tier | Workbench | Price |
|------|-----------|-------|
| Free (Solo) | Workbench Free | $0 |
| Solo Premium | Workbench Premium | Included in premium bundle |
| Multi-Principal | Workbench Team | Included in team subscription |

---

## Key Points

- Scales from Solo to Team
- Log collection is a key differentiator
- Browser-based agent chat removes terminal requirement
- Foundation for enterprise features

## Open Questions

- [ ] Standalone app or embedded in project?
- [ ] Electron wrapper for desktop?
- [ ] Mobile-responsive for on-the-go monitoring?

## Dependencies

- Related: PROP-0010 (Pricing Model)
- Related: INSTR-0050 (TheAgency Services)
- Integrates: Pulse Beat analytics

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: web + housekeeping
- Target: v0.3.0

---

## Discussion Log

### 2026-01-06 - Created
Defined tier structure matching pricing model.

### 2026-01-06 - Added Log Viewer
Jordan: "For workbench, pulse beat area is a service for collecting logs: local at first, so that an Agent can see them. We then extend that to make logs available from your preview, staging, and finally production."
