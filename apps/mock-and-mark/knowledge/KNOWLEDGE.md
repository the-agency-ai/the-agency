# Apple Platforms Knowledge Base

Shared technical knowledge for iOS, iPadOS, and macOS development.

## SwiftUI Patterns

### State Management Hierarchy

```
@State           → View owns the state
@Binding         → Parent owns, child can modify
@StateObject     → View creates & owns the ObservableObject
@ObservedObject  → View observes but doesn't own
@EnvironmentObject → Dependency injection via environment
@Environment     → System-provided values (colorScheme, etc.)
@Query           → SwiftData fetch results
```

### When to Use What

| Scenario | Use |
|----------|-----|
| Simple toggle, counter | `@State` |
| Form input passed to child | `@Binding` |
| ViewModel for a view | `@StateObject` |
| Shared app-wide state | `@EnvironmentObject` |
| SwiftData queries | `@Query` |

## SwiftData Essentials

### Model Definition

```swift
import SwiftData

@Model
class Project {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    // Relationships
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []

    init(name: String) {
        self.name = name
    }
}
```

### Container Setup

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Item.self])
    }
}
```

### Queries

```swift
struct ListView: View {
    @Query(sort: \Project.createdAt, order: .reverse)
    var projects: [Project]

    @Environment(\.modelContext) var modelContext

    func addProject() {
        let project = Project(name: "New")
        modelContext.insert(project)
    }
}
```

## PencilKit Reference

### Setup Canvas

```swift
import PencilKit

struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput  // Finger + Pencil
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
```

### Tools

```swift
// Pen
PKInkingTool(.pen, color: .red, width: 5)

// Marker
PKInkingTool(.marker, color: .yellow, width: 20)

// Pencil
PKInkingTool(.pencil, color: .black, width: 3)

// Eraser
PKEraserTool(.vector)  // Erases strokes
PKEraserTool(.bitmap)  // Erases pixels
```

### Save/Load Drawing

```swift
// Save
let data = canvasView.drawing.dataRepresentation()

// Load
if let drawing = try? PKDrawing(data: data) {
    canvasView.drawing = drawing
}
```

### Export as Image

```swift
let image = canvasView.drawing.image(from: bounds, scale: UIScreen.main.scale)
```

## iCloud + SwiftData

### Enable CloudKit

1. Xcode → Target → Signing & Capabilities
2. Add "iCloud" capability
3. Check "CloudKit"
4. Create container: `iCloud.com.yourcompany.appname`

### Automatic Sync

SwiftData automatically syncs to CloudKit when:
- iCloud capability is enabled
- User is signed into iCloud
- Model is serializable

### Limitations

- CloudKit requires iOS 17+ with SwiftData
- Initial sync can be slow for large datasets
- No real-time collaboration (eventual consistency)

## Image Handling

### PhotosPicker

```swift
import PhotosUI

struct ImagePicker: View {
    @State private var selection: PhotosPickerItem?
    @Binding var image: UIImage?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            Label("Select Image", systemImage: "photo")
        }
        .onChange(of: selection) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }
}
```

### Export PNG

```swift
func exportPNG(size: CGSize) -> Data? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.pngData { context in
        // Draw background
        backgroundImage?.draw(in: CGRect(origin: .zero, size: size))

        // Draw annotations
        let drawingImage = canvasView.drawing.image(
            from: CGRect(origin: .zero, size: size),
            scale: 1.0
        )
        drawingImage.draw(in: CGRect(origin: .zero, size: size))
    }
}
```

## Scribble Integration

### Text Field Setup

Scribble works automatically on `TextField` and `TextEditor`:

```swift
TextField("Enter text", text: $text)
    .textContentType(.none)  // Don't suggest autofill
```

### Scribble-Friendly Text Annotation

```swift
struct TextAnnotation: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    let position: CGPoint

    var body: some View {
        TextField("", text: $text)
            .focused($isFocused)
            .position(position)
            .onAppear {
                isFocused = true  // Ready for Scribble
            }
    }
}
```

## Platform Conditionals

### Compile-Time

```swift
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

### Runtime

```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // iPhone layout
        } else {
            // iPad/Mac layout
        }
    }
}
```

## Common Gotchas

### PencilKit + Scribble Conflict

PencilKit captures all pencil input. To use Scribble:
1. Switch to "text mode"
2. Hide/disable PKCanvasView
3. Show TextField for Scribble input

### SwiftData Optional vs Default

```swift
// BAD - will crash on nil
var name: String

// GOOD - has default
var name: String = ""

// GOOD - explicitly optional
var name: String?
```

### Image Data in SwiftData

Don't store large images directly in SwiftData:

```swift
// BAD
var imageData: Data  // Will bloat database

// GOOD
var imagePath: String  // Store in Documents, reference by path
```

## Useful Extensions

### UIImage → PNG Data

```swift
extension UIImage {
    var pngData: Data? {
        return self.pngData()
    }
}
```

### Color from Hex

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
```
