# MockAndMark

**Screenshot annotation and quick mockup tool**

A TheAgency AI product for rapid visual communication.

## Vision

When you need to quickly mark up a screenshot, create a simple UI mockup, or annotate an image - MockAndMark gets out of your way and lets you focus on the idea.

## Features

### Core

- **Import** - PNG, JPEG, screenshots, camera, screen capture
- **Draw** - Circles, arrows, rectangles, freehand (PencilKit)
- **Text** - Scribble handwriting input, tap-to-type fallback
- **Export** - PNG output, clipboard, share sheet

### Drawing Tools

| Tool | Purpose | Gesture |
|------|---------|---------|
| Circle | Highlight areas | Draw oval |
| Arrow | Point to things | Drag start→end |
| Rectangle | Frame regions | Draw rectangle |
| Freehand | Annotations | Draw freely |
| Text | Labels | Tap to place, scribble to write |

### Modes

1. **Draw Mode** - PencilKit canvas active, draw shapes
2. **Text Mode** - Tap to place text, Scribble for input
3. **Select Mode** - Move/resize annotations

## User Flow

```
[Import Image] → [Annotate] → [Export]
      ↑              ↓
   Camera       Draw/Text/Select
   Photos       tools toggle
   Files
   Clipboard
```

## Data Model

```swift
@Model
class MarkupProject {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var backgroundImage: Data?  // Original image
    var drawing: Data?          // PKDrawing data
    @Relationship var textAnnotations: [TextAnnotation]
}

@Model
class TextAnnotation {
    var id: UUID
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var color: String  // Hex color
}
```

## Platform Considerations

| Platform | Notes |
|----------|-------|
| **iPad** | Primary target, Apple Pencil, Scribble |
| **iPhone** | Finger drawing, keyboard text |
| **Mac** | Mouse/trackpad, keyboard shortcuts |

## iCloud Sync

Projects sync automatically via SwiftData + CloudKit:
- Work on iPad, continue on Mac
- Offline-first, syncs when connected

## Technical Stack

- SwiftUI for UI
- SwiftData for persistence
- PencilKit for drawing
- PhotosUI for image import
- CloudKit for sync

## File Structure

```
MockAndMark/
├── MockAndMarkApp.swift
├── Models/
│   ├── MarkupProject.swift
│   └── TextAnnotation.swift
├── Views/
│   ├── ContentView.swift
│   ├── EditorView.swift
│   ├── CanvasView.swift
│   ├── ToolbarView.swift
│   └── ProjectListView.swift
├── Services/
│   ├── ImageService.swift
│   └── ExportService.swift
└── Resources/
    └── Assets.xcassets
```

## MVP Scope

### Must Have (v1.0)
- [ ] Import from Photos
- [ ] Circle tool
- [ ] Arrow tool
- [ ] Text with Scribble
- [ ] Export as PNG

### Nice to Have (v1.1)
- [ ] Rectangle tool
- [ ] Freehand drawing
- [ ] Color picker
- [ ] Undo/redo
- [ ] iCloud sync

### Future (v2.0)
- [ ] Mac app
- [ ] Screen capture
- [ ] Templates
- [ ] Collaboration
