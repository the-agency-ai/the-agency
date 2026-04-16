# MockAndMark Knowledge Base

## Product Vision

### The Name

**MockAndMark** is intentionally ambiguous:
- **Mock** - Create simple UI mockups/wireframes
- **Mark** - Annotate existing screenshots

Neither is primary. Both are equal.

### The Real Primary Use Case

**Feeding visual context to Claude Code.**

The workflow:
```
[Idea] → MockAndMark → [Visual] → Claude Code → [Code]
```

Examples:
1. Sketch a quick wireframe → feed to Claude Code → "Build this UI"
2. Screenshot existing UI → circle problem areas → "Fix these issues"
3. Annotate a design → add implementation notes → "Implement with these specs"

### Why This Matters

Claude Code understands images. But:
- Screenshots alone lack context ("what should I focus on?")
- Text descriptions miss spatial relationships
- Figma is overkill for quick communication

MockAndMark bridges the gap: **visual communication for AI-assisted development**.

### What We Can't Say

We can't put "Claude Code" in the name or marketing because:
- Trademark/branding concerns
- Product should work with any AI that accepts images
- Keeps positioning flexible

But internally, we know: **this is a Claude Code companion tool**.

---

## Technical Decisions

### Platform Priority

1. **iPadOS** (primary) - Apple Pencil + Scribble = fastest input
2. **iOS** (secondary) - Quick captures on the go
3. **macOS** (tertiary) - Desktop workflow, keyboard shortcuts

### PencilKit + Scribble Conflict

**Problem:** PencilKit captures all pencil input, blocking Scribble.

**Solution:** Mode switching

```swift
enum EditMode: String, CaseIterable {
    case draw   // PKCanvasView active - shapes, freehand
    case text   // TextField active - Scribble input
    case select // Move/resize annotations
}
```

**UX Implication:** Need clear mode indicators and easy switching (toolbar, gestures).

### macOS Drawing (No PencilKit)

PencilKit is iOS/iPadOS only. For macOS:

```swift
// Use CGContext / NSBezierPath
class DrawingNSView: NSView {
    var paths: [NSBezierPath] = []

    override func draw(_ dirtyRect: NSRect) {
        for path in paths {
            path.stroke()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        // Build path from mouse movement
    }
}
```

### Image Storage

**Don't** store images directly in SwiftData (bloats CloudKit sync).

**Do:**
- Save image to Documents directory
- Store file path/UUID reference in SwiftData
- Handle missing files gracefully

```swift
@Model
class MarkupProject {
    var id: UUID
    var imageFileName: String?  // Reference, not data

    var imageURL: URL? {
        guard let fileName = imageFileName else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }
}
```

### Export Format

Primary: **PNG** (lossless, transparency support)

Why PNG for Claude Code:
- Lossless preserves text readability
- Transparency useful for overlays
- Universal format Claude Code handles well

---

## Agent Responsibilities

| Agent | MockAndMark Focus |
|-------|-------------------|
| `architect` | Data model, iCloud sync, image storage strategy |
| `ios-dev` | PencilKit drawing, Scribble integration, Photos import |
| `macos-dev` | NSBezierPath drawing, menus, keyboard shortcuts, drag & drop |
| `ui-dev` | Mode switching UX, toolbar design, export flow |

---

## Competitive Landscape

| Tool | Strength | Weakness for Our Use Case |
|------|----------|---------------------------|
| iOS Markup | Built-in, free | Limited tools, no project save, clunky |
| Figma | Powerful | Overkill, slow for quick annotations |
| Notability | Great for notes | Not optimized for screenshots |
| GoodNotes | Apple Pencil native | Note-taking focus, not annotation |
| Skitch | Was perfect | Dead/abandoned |

**Our positioning:** Fast, simple, purpose-built for visual AI communication.

---

## Product Assessment (2026-01-03)

### Strengths

- **Real pain point** - Nothing simple exists for quick annotation + mocking
- **Clear scope** - Import → annotate → export. Hard to over-engineer
- **Native advantage** - PencilKit + Scribble + iCloud is Apple-only
- **Dogfooding** - TheAgency AI uses it internally, proving the product

### Concerns

1. **Scribble friction** - Mode switching adds cognitive load. Users expect to just write anywhere. Platform limitation, but still friction.

2. **Monetization** - Who pays for annotation tools?
   - Professionals have Figma/Sketch
   - Casual users expect free
   - Options: one-time purchase ($4.99), pro features (templates, collaboration)

3. **Competition** - Apple could improve Markup anytime (though they haven't in years)

### Name Alternatives Considered

| Name | Pros | Cons |
|------|------|------|
| MockAndMark | Does both, memorable | Ambiguous (intentional) |
| Scrawl | Quick, casual | Too casual? |
| Markup Pro | Clear positioning vs Apple | Generic |
| Annotate | Simple verb | Too generic |
| Redpen | Classic review metaphor | Might confuse with existing tool |

**Decision:** Keep MockAndMark. Ambiguity is a feature, not a bug.

---

## Why macos-dev Agent Was Added

macOS is different enough from iOS/iPadOS to need its own specialist:

| Aspect | iOS/iPadOS | macOS |
|--------|------------|-------|
| Drawing | PencilKit | No PencilKit - CGContext/NSBezierPath |
| Input | Touch, Pencil | Mouse, trackpad, keyboard |
| Windows | Single scene | Multiple windows, menu bar |
| File access | Sandboxed, pickers | Drag & drop, open dialogs |
| UI foundation | UIKit | AppKit |

Key macOS requirements:
- Keyboard shortcuts (Mac users expect ⌘Z, ⌘S, etc.)
- Menu bar (required for Mac apps)
- Drag & drop (fundamental Mac interaction)
- Custom cursors per tool

---

## Open Questions

1. **Templates** - Pre-made wireframe components? (buttons, inputs, cards)
2. **Shape recognition** - Auto-convert rough circles to clean ones?
3. **Collaboration** - Share projects? (probably v2+)
4. **Clipboard integration** - Paste screenshot, annotate, copy back?

---

## References

- PencilKit: https://developer.apple.com/documentation/pencilkit
- Scribble: https://developer.apple.com/videos/play/wwdc2020/10106/
- SwiftData + CloudKit: https://developer.apple.com/documentation/swiftdata
