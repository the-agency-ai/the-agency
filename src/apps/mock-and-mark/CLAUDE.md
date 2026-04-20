# Apple Platforms Development Guide

Instructions for Claude agents working on iOS, iPadOS, and macOS projects.

## Core Technologies

### Swift 5.9+

```swift
// Modern Swift patterns
// Use async/await for concurrency
func loadImage() async throws -> UIImage { }

// Use Result builders for DSL-style code
@resultBuilder struct ViewBuilder { }

// Prefer value types (struct) over reference types (class)
struct AnnotationModel: Codable, Identifiable { }
```

### SwiftUI

```swift
// Declarative UI
struct ContentView: View {
    @State private var annotations: [Annotation] = []

    var body: some View {
        Canvas { context, size in
            // Drawing code
        }
        .overlay {
            ForEach(annotations) { annotation in
                AnnotationView(annotation: annotation)
            }
        }
    }
}
```

### SwiftData

```swift
import SwiftData

@Model
class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade)
    var annotations: [Annotation]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.annotations = []
    }
}
```

### iCloud Sync

```swift
// Enable in App target capabilities:
// 1. iCloud → CloudKit
// 2. Background Modes → Remote notifications

// SwiftData with CloudKit
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Project.self, isUndoEnabled: true)
        // CloudKit sync enabled automatically when iCloud capability is on
    }
}
```

### PencilKit

```swift
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}
```

## Key Patterns

### Mode Switching for Drawing + Text

PencilKit and Scribble cannot work simultaneously. Use mode switching:

```swift
enum EditMode: String, CaseIterable {
    case draw      // PKCanvasView active
    case text      // TextField with Scribble active
    case select    // Selection/move mode
}

struct EditorView: View {
    @State private var mode: EditMode = .draw

    var body: some View {
        ZStack {
            // Drawing layer (when in draw mode)
            if mode == .draw {
                DrawingView(canvasView: $canvasView)
            }

            // Text annotations (always visible, editable in text mode)
            ForEach(textAnnotations) { annotation in
                TextAnnotationView(
                    annotation: annotation,
                    isEditing: mode == .text
                )
            }
        }
        .toolbar {
            Picker("Mode", selection: $mode) {
                ForEach(EditMode.allCases, id: \.self) { mode in
                    Image(systemName: mode.icon)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
```

### Image Import/Export

```swift
import PhotosUI

// Import
struct ImagePicker: View {
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("Import", systemImage: "photo")
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Use image
                }
            }
        }
    }
}

// Export
func exportAsPNG() -> Data? {
    let renderer = UIGraphicsImageRenderer(size: canvasSize)
    return renderer.pngData { context in
        // Draw background image
        backgroundImage?.draw(in: bounds)
        // Draw PencilKit drawing
        canvasView.drawing.image(from: bounds, scale: 1.0)
            .draw(in: bounds)
        // Draw text annotations
        for annotation in textAnnotations {
            annotation.render(in: context.cgContext)
        }
    }
}
```

### Platform-Specific Code

```swift
#if os(iOS)
// iPhone/iPad specific
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
// Mac specific
import AppKit
typealias PlatformImage = NSImage
#endif

// Or use conditional compilation
struct ContentView: View {
    var body: some View {
        #if os(macOS)
        HSplitView {
            sidebar
            editor
        }
        #else
        NavigationSplitView {
            sidebar
        } detail: {
            editor
        }
        #endif
    }
}
```

## File Organization

```
ProjectName/
├── ProjectName/
│   ├── ProjectNameApp.swift      # App entry point
│   ├── ContentView.swift         # Main view
│   ├── Models/
│   │   ├── Project.swift         # SwiftData models
│   │   └── Annotation.swift
│   ├── Views/
│   │   ├── EditorView.swift
│   │   ├── CanvasView.swift
│   │   └── ToolbarView.swift
│   ├── Services/
│   │   ├── ImageService.swift    # Import/export
│   │   └── SyncService.swift     # iCloud sync helpers
│   └── Resources/
│       └── Assets.xcassets
├── ProjectNameTests/
└── ProjectNameUITests/
```

## Build & Run

```bash
# Build from command line
xcodebuild -project ProjectName.xcodeproj -scheme ProjectName -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -project ProjectName.xcodeproj -scheme ProjectName -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Open in Xcode
open ProjectName.xcodeproj
```

## Common Issues

### Scribble Not Working

Scribble only works in text input fields. Ensure:

1. Text field is focused
2. Apple Pencil is being used
3. Device supports Scribble (iPadOS 14+)

### iCloud Sync Not Working

1. Check iCloud is enabled in Settings
2. Verify CloudKit container in Xcode capabilities
3. Check CloudKit Dashboard for sync errors
4. SwiftData + CloudKit requires iOS 17+

### PencilKit Drawing Not Saving

```swift
// Save drawing data
let drawingData = canvasView.drawing.dataRepresentation()

// Restore drawing
if let drawing = try? PKDrawing(data: drawingData) {
    canvasView.drawing = drawing
}
```

## Testing

```swift
import XCTest
@testable import ProjectName

final class AnnotationTests: XCTestCase {
    func testAnnotationCreation() {
        let annotation = Annotation(type: .circle, position: .zero)
        XCTAssertEqual(annotation.type, .circle)
    }
}
```

## Don't

- Use UIKit directly when SwiftUI provides equivalent
- Force unwrap optionals in production code
- Block the main thread with synchronous I/O
- Store large images in SwiftData (use file references)
- Ignore accessibility (use `.accessibilityLabel`, `.accessibilityHint`)

## Capturing Insights

This project is part of TheAgency AI ecosystem. When you discover something valuable, capture it!

### Book Input (Working Notes)

Insights about multi-agent development, patterns that work, or lessons learned should be captured as working notes for "The Agency" book:

```bash
./tools/book-note "Title of Your Insight"
```

**What to capture:**
- Patterns that emerge during development
- "Aha!" moments about multi-agent collaboration
- Problems solved in interesting ways
- Conversations that clarify product vision
- Time savings or productivity insights

### Agency Framework Feedback

Found something that could improve The Agency framework? Capture it:

```bash
agency feedback "Brief title" "Detailed feedback"
```

**What to report:**
- Missing tools that would help
- Documentation gaps
- Patterns that should be in the framework
- Onboarding friction points
- Ideas for new agent types
