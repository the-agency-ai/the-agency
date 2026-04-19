# PROP-0018: CLI Integrations — Gumroad & Discord

**Status:** design
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

---

## Overview

CLI tools to drive Gumroad (sales) and Discord (community) from The Agency framework.

---

## Gumroad CLI Design

### Existing Ecosystem
- [@deox/gumroad](https://www.npmjs.com/package/@deox/gumroad) — npm API client
- [gumroad-utils](https://github.com/obsessedcake/gumroad-utils) — Python scraper (fragile)
- [Gumroad API](https://gumroad.com/api) — REST, OAuth 2.0

### Our Tools

```bash
# Product management
./tools/gumroad-products           # List all products
./tools/gumroad-product <id>       # Get product details
./tools/gumroad-create-product     # Interactive product creation

# Sales operations
./tools/gumroad-sales              # Recent sales (last 24h default)
./tools/gumroad-sales --today      # Today's sales
./tools/gumroad-sales --week       # This week
./tools/gumroad-revenue            # Revenue summary

# License verification (for automation)
./tools/gumroad-verify <license>   # Verify a license key
./tools/gumroad-customers          # List customers

# Webhooks
./tools/gumroad-webhook-test       # Test webhook endpoint
```

### Implementation Notes
- Use existing `@deox/gumroad` npm package
- Store credentials in `secrets/gumroad.env`
- Cache product list locally (refresh on demand)

---

## Discord CLI Design

### Existing Ecosystem
- [Discord.js](https://discord.js.org/) — Node.js library
- [Discord-CLI by jamesg31](https://github.com/jamesg31/Discord-CLI) — Server management
- Bot API requires bot token (we have this)

### Our Tools

```bash
# Server setup
./tools/discord-create-server      # Create new server (one-time)
./tools/discord-setup-channels     # Create standard channel structure

# Channel management
./tools/discord-channels           # List channels
./tools/discord-create-channel     # Create channel
./tools/discord-post <channel>     # Post message to channel

# Announcements
./tools/discord-announce           # Post to #announcements
./tools/discord-motd               # Set message of the day

# Member management
./tools/discord-members            # List members
./tools/discord-invite             # Generate invite link
./tools/discord-role <user> <role> # Assign role

# Integration
./tools/discord-webhook <channel>  # Get/create webhook for channel
```

### Standard Channel Structure

```
The Agency (Server)
├── 📢 announcements      # Release notes, updates
├── 💬 general            # Community chat
├── 🆘 support            # Help requests
├── 🎨 showcase           # Show your agency
├── 💡 ideas              # Feature requests
├── 📚 Resources
│   ├── guides            # How-to content
│   └── tools             # Tool discussions
└── 🔒 Principals (role-gated)
    ├── feedback          # Book feedback
    └── early-access      # Pre-release access
```

### Implementation Notes
- Use Discord.js
- Store credentials in `secrets/discord.env`
- Bot needs Administrator permission (we have this)

---

## Integration Points

### Gumroad → Discord
```bash
# When sale happens (webhook)
./tools/gumroad-sale-notify        # Post to #sales-log (private)
./tools/discord-role <user> buyer  # Auto-assign buyer role
```

### The Agency → Both
```bash
# Announce release
./tools/announce-release "v1.2.0" "Feature X, Fix Y"
# Posts to: Discord #announcements, Gumroad product update
```

---

## Dependencies

| Tool | Requires |
|------|----------|
| gumroad-* | GUMROAD_ACCESS_TOKEN |
| discord-* | DISCORD_BOT_TOKEN |
| announce-release | Both |

---

## Priority for Jan 23 Announcement

### Must Have
- [ ] `discord-create-server` — Set up community
- [ ] `discord-setup-channels` — Standard structure
- [ ] `discord-invite` — Generate invite for announcement
- [ ] `gumroad-products` — Verify products exist

### Nice to Have
- [ ] `gumroad-verify` — License verification for access control
- [ ] `discord-announce` — Post updates programmatically
- [ ] Webhook integration for sales → Discord

---

_Design proposal for CLI integrations_
_Created 2026-01-06_
