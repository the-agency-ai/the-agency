# THE-AGENCY-BOOK-WORKING-NOTE-0009

**Date:** 2026-01-03 23:42 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Spinning Up MockAndMark - Agency Starter in Action

---

## Discussion

### The Request

Jordan: "Starter kit for swift + swift UI + swift data ;) Support of iCloud synchronization"

That's it. One sentence. From that seed, we spun up an entire multi-agent development framework for Apple platforms in under an hour.

### What We Built

**Apple Platforms Starter Kit** at `/Users/jdm/code/apple-platforms-starter/`

```
apple-platforms-starter/
├── CLAUDE.md              # Swift/SwiftUI development guide
├── README.md              # Project overview
├── agents/
│   ├── architect/         # System design, architecture decisions
│   ├── ios-dev/           # iOS/iPadOS implementation
│   ├── ui-dev/            # SwiftUI, design system
│   └── macos-dev/         # macOS-specific (added mid-session)
├── knowledge/
│   └── swift-patterns.md  # Shared Swift conventions
├── projects/
│   └── mockandmark/       # First project
│       ├── README.md
│       └── KNOWLEDGE.md   # Product vision, technical decisions
└── tools/                 # Apple-specific tooling (future)
```

### The Agency Starter Pattern in Action

What made this fast wasn't magic—it was following established patterns:

**1. CLAUDE.md First**
Before any code, we created the development guide. Swift conventions, SwiftUI patterns, testing approaches, common pitfalls. This becomes the shared brain for all agents.

**2. Agent Definitions by Domain**
We didn't create one monolithic "iOS agent." We split by concern:

- **architect** - owns system design, data models, iCloud sync strategy
- **ios-dev** - owns iOS/iPadOS implementation specifics
- **ui-dev** - owns SwiftUI components, design system, animations
- **macos-dev** - owns macOS differences (no PencilKit, menus, keyboard shortcuts)

**3. Shared Knowledge Layer**
`knowledge/swift-patterns.md` captures conventions all agents follow. No agent operates in isolation.

**4. Project-Specific Context**
Each project (like MockAndMark) gets its own `KNOWLEDGE.md` capturing product vision and technical decisions specific to that app.

### The MockAndMark Discovery

The most valuable part wasn't the scaffolding—it was the collaborative product design that emerged naturally.

**Initial concept:** Screenshot annotation tool with PencilKit

**Problem discovered:** PencilKit and Scribble (handwriting-to-text) can't run simultaneously. Apple limitation.

**Solution designed:** Mode switching

- Annotation Mode (PencilKit active, Scribble disabled)
- Text Mode (Scribble active, for input fields)
- Clear visual indicators, smooth transitions

**Real insight:** Jordan clarified the product vision:

> "The ambiguity in the name is intentional. It does both of them. Neither is primary. You know what is primary? The workflow of feeding simple, simple mocks to Claude Code. You can't put 'Claude Code' in the name or marketing."

MockAndMark isn't a screenshot tool. It's a **visual context creator for AI-assisted development**. The mocking and marking are means to an end.

### Why This Works

**The Agency Starter provides scaffolding, not constraints.**

We didn't copy a template blindly. We adapted the patterns:

- Added `macos-dev` agent mid-session when we realized macOS differs significantly
- Created `KNOWLEDGE.md` at the project level (not just agent level) for product vision
- Kept `tools/` directory empty—we'll add Apple-specific tooling as needed

**The conversation drove the structure.**

Traditional approach: Plan everything upfront, build the scaffold, then start working.

Agency approach: Start with minimal structure, let the conversation reveal what's needed, add as you go.

The macos-dev agent didn't exist in our initial plan. The product vision in KNOWLEDGE.md emerged from discussion. The mode-switching solution came from exploring a technical constraint together.

### Time Investment

- Initial scaffolding: ~15 minutes
- CLAUDE.md (Swift development guide): ~10 minutes
- Agent definitions: ~10 minutes
- Product discussion + KNOWLEDGE.md: ~15 minutes
- Adding macos-dev (realized we needed it): ~5 minutes

**Total: ~55 minutes** from "starter kit for swift" to production-ready multi-agent framework with a clear first project.

---

## Decisions Made

- Apple Platforms Starter lives at `/Users/jdm/code/apple-platforms-starter/` (sibling to the-agency-starter)
- Four agents: architect, ios-dev, ui-dev, macos-dev
- MockAndMark uses mode switching for PencilKit/Scribble conflict
- Product positioning: visual context creator for AI-assisted development
- macOS is secondary to iOS/iPadOS (but fully supported)

---

## Action Items

- [ ] Document this as a case study for "Spinning Up New Projects" chapter
- [ ] Create template checklist for new starter kit creation
- [ ] Consider recording a video walkthrough of this process

---

## Next Steps

- MockAndMark development can begin with ios-dev agent
- Need to create Xcode project structure (architect agent)
- Consider what tools/ scripts would be useful for Apple development

---

_Working note for project: the-agency-book_
