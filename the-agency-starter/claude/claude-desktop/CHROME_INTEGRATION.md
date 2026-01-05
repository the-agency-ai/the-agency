# Claude in Chrome Integration

**Discovery:** Claude in Chrome extension already provides the browser automation we need!

## What Claude in Chrome Does

From [Claude in Chrome](https://claude.com/chrome):

- **Browser automation** - Navigate, click buttons, fill forms
- **Scheduled tasks** - Periodic automation (hourly, daily, etc.)
- **Multi-tab workflows** - Manage multiple tabs simultaneously
- **Platform knowledge** - Built-in for Slack, GitHub, Google Docs, Gmail, Calendar
- **Claude Code integration** - Native Messaging API connects terminal to browser

## The Bridge We Needed

From [Claude Code Chrome docs](https://code.claude.com/docs/en/chrome):

> "Claude Code integrates with the Claude in Chrome browser extension to give browser automation capabilities directly from the terminal."

**This means:**

```
┌─────────────────────────────────────────────────────────────┐
│                    THE AGENCY BRIDGE                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Claude Code ◄──── Native Messaging API ────► Chrome        │
│      │                                            │          │
│      │                                            │          │
│      ▼                                            ▼          │
│  Implementation                              Claude.ai       │
│  Testing                                     Projects        │
│  Deployment                                  Knowledge       │
│                                              Artifacts       │
│                                                              │
│  Scheduled Tasks: Sync knowledge hourly                     │
│  Shortcuts: Export artifact to code                         │
│  HITL: User sees and approves actions                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Capabilities via Chrome Extension

| Action | Chrome Extension | Notes |
|--------|------------------|-------|
| Create project | ✅ Can automate | Navigate + click |
| Add knowledge | ✅ Can automate | Upload files, paste content |
| Manage instructions | ✅ Can automate | Edit project settings |
| Create artifacts | ✅ (via chat) | Send messages, get artifacts |
| Export artifacts | ✅ Can automate | Copy/download |
| Scheduled sync | ✅ Built-in | Tasks feature |
| Code ↔ Browser | ✅ Native Messaging | Direct integration |

## For The Agency

### Shortcuts Library

Pre-built automations for common workflows:

```
agency:create-project      # Create project from template
agency:sync-knowledge      # Sync files from claude/ to project
agency:export-artifact     # Download artifact to file
agency:handoff-to-code     # Copy context to Claude Code
agency:handoff-from-code   # Push context to Claude.ai project
```

### Scheduled Tasks

```
Every hour:     Sync knowledge files
Every morning:  Export new artifacts
On trigger:     Notify on artifact creation
On commit:      Update project with changes
```

### Principal Controls (HITL)

- User approves sensitive actions
- Can pause/resume scheduled tasks
- Manual override always available
- Full visibility (it's their browser)

## Setup for The Agency

### 1. Enable Claude in Chrome

- Requires Max plan subscription
- Install from [Claude in Chrome](https://claude.com/chrome)
- Connect to Claude Code via terminal

### 2. Configure Agency Shortcuts

```bash
# From Claude Code terminal
claude chrome --install-shortcuts agency
```

### 3. Set Up Scheduled Tasks

```bash
# Sync knowledge every hour
claude chrome --schedule "sync-knowledge" --every 1h

# Export artifacts daily
claude chrome --schedule "export-artifacts" --every 1d
```

### 4. Link Project

```bash
# Connect Claude.ai project to local repo
claude chrome --link-project "My Agency Project" --path ./
```

## Security Notes

From [Claude blog](https://claude.com/blog/claude-for-chrome):

- Adversarial testing: 29 attack scenarios evaluated
- Prompt injection mitigations in place (23.6% → lower with safeguards)
- User always sees what's happening
- Enterprise: Admins can enable/disable, configure allowlists

## What This Changes

**Before:** No API = manual copy-paste between Desktop and Code

**After:** Chrome extension = automated bridge with scheduling

The feature request to Anthropic for Projects API is still valuable (native API > browser automation), but we have a working solution now.

## Next Steps

1. [ ] Test Chrome extension with Claude.ai project automation
2. [ ] Document specific DOM selectors / workflows
3. [ ] Create Agency shortcuts library
4. [ ] Build scheduled task templates
5. [ ] Test Claude Code ↔ Chrome Native Messaging

## Resources

- [Claude in Chrome](https://claude.com/chrome)
- [Claude Code Chrome docs](https://code.claude.com/docs/en/chrome)
- [Chrome extension launch blog](https://claude.com/blog/claude-for-chrome)
- [DataCamp tutorial](https://www.datacamp.com/tutorial/claude-for-chrome-ai-powered-browser-assistance-automation)

---

*This discovery significantly de-risks The Agency's Desktop ↔ Code integration story.*
