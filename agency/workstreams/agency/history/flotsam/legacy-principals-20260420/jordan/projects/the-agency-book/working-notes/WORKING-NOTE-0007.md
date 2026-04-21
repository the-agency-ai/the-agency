# THE-AGENCY-BOOK-WORKING-NOTE-0007

**Date:** 2026-01-03 22:30 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Apple Platforms Starter Kit - First Platform-Specific Starter

---

## Context

Testing The Agency Starter approach with a platform-specific implementation for Apple ecosystem development (iOS, iPadOS, macOS).

## TheAgency AI Business Structure

| Product                | Type        | Status         | Description                             |
| ---------------------- | ----------- | -------------- | --------------------------------------- |
| **the-agency-starter** | Open Source | Active         | Multi-agent framework for Claude Code   |
| **Workbench**          | Commercial  | In Development | Internal developer tools (may spin out) |
| **MockAndMark**        | Commercial  | Starting       | Screenshot annotation app               |

## Apple Platforms Starter Kit

**Location:** `/Users/jdm/code/apple-platforms-starter/` (sibling to the-agency-starter)

### Tech Stack

- **Swift 5.9+** - Primary language
- **SwiftUI** - Declarative UI framework
- **SwiftData** - Data persistence (iOS 17+)
- **iCloud** - Cross-device synchronization via CloudKit
- **PencilKit** - Apple Pencil / drawing support

### Structure Created

```
apple-platforms-starter/
├── README.md               # Overview, product context
├── CLAUDE.md               # Swift/SwiftUI development guide
├── agents/
│   ├── architect/agent.md  # System design, data models, iCloud sync
│   ├── ios-dev/agent.md    # Implementation, PencilKit, file I/O
│   └── ui-dev/agent.md     # SwiftUI, animations, accessibility
├── knowledge/
│   └── KNOWLEDGE.md        # SwiftData, PencilKit, iCloud patterns
├── tools/
│   ├── xcode-build         # Build project (simulator/device)
│   ├── xcode-test          # Run tests
│   ├── swift-format        # Format Swift code
│   ├── simulator           # Manage simulators (list/boot/screenshot)
│   └── create-project      # Scaffold new projects
└── projects/
    └── mockandmark/
        ├── README.md       # Product vision, features, data model
        └── REQUIREMENTS.md # User stories, FRs, acceptance criteria
```

### Agent Roles

| Agent       | Specialization                                                |
| ----------- | ------------------------------------------------------------- |
| `architect` | SwiftData models, iCloud sync strategy, architecture patterns |
| `ios-dev`   | Swift implementation, PencilKit, file I/O, testing            |
| `ui-dev`    | SwiftUI views, animations, accessibility                      |

### Key Technical Decisions

#### 1. PencilKit + Scribble Mode Switching

**Problem:** PencilKit captures all pencil input, preventing Scribble from working.

**Solution:** Mode switching approach:

- **Draw Mode** - PKCanvasView active for shapes
- **Text Mode** - TextField active for Scribble input
- **Select Mode** - Move/resize annotations

```swift
enum EditMode: String, CaseIterable {
    case draw, text, select
}
```

#### 2. SwiftData + iCloud

SwiftData with CloudKit provides automatic sync when:

1. iCloud capability enabled in Xcode
2. CloudKit container created
3. User signed into iCloud

No additional code needed - sync is automatic.

#### 3. Image Storage

Don't store images directly in SwiftData (bloats database). Instead:

- Store image in Documents directory
- Store file path reference in SwiftData model

---

## MockAndMark Product

**Vision:** When you need to quickly mark up a screenshot, create a simple UI mockup, or annotate an image - MockAndMark gets out of your way.

### Core Features (MVP)

1. Import from Photos
2. Circle tool
3. Arrow tool
4. Text with Scribble
5. Export as PNG

### Platforms

- iPadOS 17+ (primary - Apple Pencil + Scribble)
- iOS 17+ (finger drawing, keyboard text)
- macOS 14+ (future)

### Data Model

```swift
@Model
class MarkupProject {
    var id: UUID
    var name: String
    var createdAt: Date
    var backgroundImage: Data?  // Original image (consider file ref)
    var drawing: Data?          // PKDrawing data
    @Relationship var textAnnotations: [TextAnnotation]
}
```

---

## Research Findings

### Scribble Limitations

- Only works on UITextField, UITextView, UISearchTextField
- Does NOT work directly on PKCanvasView
- Requires iPadOS 14+ and Apple Pencil

### PencilKit Resources

- WWDC 2024: "Build a drawing experience" - https://developer.apple.com/videos/play/wwdc2024/10214/
- Kodeco PencilKit tutorial - https://www.kodeco.com/12198216-drawing-with-pencilkit-getting-started

### SwiftData + CloudKit

- Requires iOS 17+ / macOS 14+
- Automatic sync when iCloud capability enabled
- No manual CloudKit container code needed

---

## For The Agency Starter

This Apple Platforms Starter Kit demonstrates:

1. **Platform-specific starters** - Different platforms need different tools/patterns
2. **Agent specialization** - architect/dev/ui split works well for native apps
3. **Knowledge base** - Technical patterns specific to the platform
4. **Tools** - Wrapper scripts for platform toolchain (xcodebuild, simctl)

### Starter Kit Template Pattern

```
{platform}-starter/
├── README.md           # Platform overview
├── CLAUDE.md           # Platform-specific instructions
├── agents/             # Specialized agents for the platform
├── knowledge/          # Platform patterns and gotchas
├── tools/              # Platform toolchain wrappers
└── projects/           # Actual projects using this stack
```

---

## Action Items

- [x] Create Apple Platforms Starter Kit structure
- [x] Write CLAUDE.md for Swift/SwiftUI
- [x] Define architect, ios-dev, ui-dev agents
- [x] Create knowledge base with SwiftData, PencilKit patterns
- [x] Create tools (xcode-build, xcode-test, swift-format, simulator)
- [x] Set up MockAndMark project with README and REQUIREMENTS
- [ ] Create actual Xcode project for MockAndMark
- [ ] Test the starter kit by launching agents
- [ ] Document patterns back to the-agency-starter

---

_Working note for project: the-agency-book_
_Related: INSTR-0022 - The Agency Starter Framework_
