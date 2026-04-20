# Mark and Mock
## Design Document v1.1
*iPad (Phase 1) · macOS (Future) · Claude Desktop & Claude Code*

---

> **VISION:** An iPad-native tool for marking up existing UX and sketching new mockups — with deep Apple Pencil support. Annotated screens and cleaned-up lo-fi mocks become structured context packets that Claude Desktop and Claude Code consume directly. No AI in the app itself — the intelligence lives where the developer already is.

---

## 1. Product Overview

Mark and Mock has two distinct and complementary modes, reflected in its name:

| Mode | What it does |
|------|-------------|
| **MARK** | Annotate an existing screenshot or UI with Apple Pencil — redlines, semantic stamps, intent notes, questions. Capture what needs to change and why. |
| **MOCK** | Sketch a new screen freehand with Apple Pencil. The app cleans up the sketch into a structured lo-fi mockup — schematic enough for Claude Code to implement, clear enough for a designer or PM to review. |

Both modes produce the same output: a structured context packet (image + JSON + markdown) that drops straight into Claude Desktop or Claude Code as attached context. No API calls inside the app. No in-app AI sidebar. Mark and Mock is a capture and structuring tool — Claude is the intelligence at the other end.

### 1.1 Core Problems Solved

- Developers working with Claude Code have no good way to communicate visual intent — screenshots can be attached but are unstructured and unannotated
- Freehand sketches on iPad stay locked in Notes or Freeform — never structured, never connected to a development workflow
- Balsamiq-style tools exist on desktop but not as iPad-first, Pencil-native, Claude-integrated tools
- The gap between "I sketched this on my iPad" and "Claude Code can build this" is currently bridged only by manual description

### 1.2 Product Pillars

| Pillar | Description |
|--------|-------------|
| Screenshot Markup (Mark) | Import any screen, annotate with Apple Pencil, tag with semantic intent stamps |
| Freehand Sketch (Mock) | Draw a new screen with Apple Pencil on a blank or grid canvas |
| Sketch Cleanup (Mock) | On-device Vision framework interprets the sketch and renders a clean lo-fi schematic |
| User Confirmation (Mock) | User reviews and corrects component type assignments before export |
| Wireframe Markup (Mark + Mock) | Mark up a cleaned wireframe just like a screenshot — layer annotations on top |
| Structured Export | Every canvas exports as a ZIP packet: PNG + annotations JSON + components JSON + prompt.md |
| Claude Desktop / Code Delivery | Packet delivered via Share Sheet, iCloud handoff, or Mac companion app |
| Figma Import (v2) | Import Figma files, generate lo-fi variant mocks, extract design system for Claude Code |
| macOS App (v3) | Native macOS version with drawing tablet support and mouse/keyboard wireframe tools |

---

## 2. The Mock Flow — Sketch to Lo-Fi

The Mock side of the app is the key differentiator. This section describes it in detail.

### 2.1 Why Lo-Fi, Not Hi-Fi

The cleaned-up mockup is intentionally schematic — Balsamiq-style grayscale boxes, labels, and component outlines. This is the right fidelity for Claude Code because:

- Claude Code needs semantic clarity, not visual polish — it needs to know what components are present, their hierarchy, their labels, and their relationships
- A schematic is faster to produce, faster to correct, and easier to iterate on
- Hi-fi rendering is the job of the code Claude Code generates, not the mockup that drives it
- The design system (colours, typography, spacing) is captured separately in `design-system.json`, not baked into the mockup image

> **KEY PRINCIPLE:** The lo-fi mockup plus the structured JSON component tree gives Claude Code everything it needs to generate a working, correctly-structured implementation. Visual polish is applied by Claude Code using the design system — not by the mockup tool.

### 2.2 Sketch-to-Lo-Fi Pipeline

#### Step 1 — Freehand Sketch
- User opens a blank Mock canvas (white or 8pt grid background)
- Draws freely with Apple Pencil: boxes for containers, squiggles for text, rough shapes for buttons, circles for icons
- Scribble converts any handwritten labels to text automatically
- No constraints at this stage — sketch as fast as you think

#### Step 2 — Vision Framework Detection (On-Device)
- User taps **Clean Up** when sketch is ready
- Apple Vision framework analyses the PKDrawing strokes on-device — no network call
- Detects geometric primitives: rectangles, lines, circles, text regions
- Maps detected shapes to candidate component types using a rule-based classifier:
  - Wide short rectangle near top of canvas → Navigation Bar candidate
  - Row of small rectangles at bottom → Tab Bar candidate
  - Rounded rectangle with text inside → Button candidate
  - Rectangle with underline only → Text Field candidate
  - Tall rectangle with internal rows → List / Table candidate
  - Rectangle containing image placeholder (X through it) → Image View candidate
- Vision confidence score attached to each detection

#### Step 3 — User Confirmation
- App renders the detected layout as a clean lo-fi schematic overlay
- Each component shown with its candidate type label and confidence indicator
- Low-confidence detections highlighted for user attention
- User taps any component to correct its type via a popover picker
- User can merge, split, or delete detected components
- User confirms when satisfied — sketch strokes are hidden, lo-fi render becomes the canvas

#### Step 4 — Label & Annotate
- All components now have editable labels (Scribble or keyboard)
- User adds semantic annotations on top: behaviour notes, requirements, questions
- Connection arrows can be drawn between components to indicate navigation
- This is now identical to the Mark flow — a structured canvas ready for export

### 2.3 Lo-Fi Render Specification

| Component Type | Visual Treatment |
|---------------|-----------------|
| Navigation Bar | Gray filled bar, title text centred, optional back chevron left |
| Tab Bar | Gray bar with evenly-spaced icon placeholders and labels |
| Button | Rounded rect outline, label centred; filled for primary / outlined for secondary |
| Text Field | Rect with bottom border only, placeholder text in muted gray |
| Text Block | Horizontal lines of varying width simulating body text |
| Image / Media | Rect with diagonal cross (X) and optional label |
| Card | Rect with drop shadow simulation (offset border) |
| List Row | Full-width rect with left icon placeholder and two text lines |
| Modal / Sheet | Rounded rect with drag handle at top |
| Icon Placeholder | Circle with glyph name label |
| Container / Group | Dashed rect border, no fill |

---

## 3. Core User Flows

### 3.1 Screenshot Markup Flow (Mark)

1. User captures or imports a screenshot — Photos, Files, drag from Mac via Continuity, or screenshot directly in-app
2. App opens it in the Markup Canvas at native resolution
3. User annotates with Apple Pencil: arrows, circles, redlines, text labels
4. User applies semantic stamps: Bug, Requirement, Question, Suggestion, Note
5. User taps Export — app packages PNG + annotations.json + prompt.md into a ZIP
6. User delivers ZIP to Claude Desktop or Claude Code via Share Sheet, iCloud, or Mac companion app
7. Claude receives the packet as attached context and proceeds with the stated intent

### 3.2 Freehand Mock Flow (Mock)

1. User opens a new Mock canvas
2. User sketches a screen layout freehand with Apple Pencil
3. User taps Clean Up — Vision framework runs on-device and proposes component assignments
4. User confirms or corrects component types in the review overlay
5. App renders the clean lo-fi schematic
6. User labels components, adds annotations, draws flow arrows
7. User taps Export — same structured packet as the Mark flow
8. Claude Code receives the packet and implements the screen

### 3.3 Markup Over Mock Flow (Mark + Mock)

1. User starts with a lo-fi mock (from flow 3.2 or imported from Figma in v2)
2. User marks up the mock: adds requirements, flags questions, notes edge cases
3. Export includes both the component tree (Mock) and the annotations (Mark) in one packet
4. Claude Code gets the full picture: structure + intent + requirements in a single context drop

### 3.4 Claude Desktop vs Claude Code Delivery

| Target | Best For |
|--------|----------|
| **Claude Desktop** | Design review, requirements discussion, generating alternative layout descriptions, reviewing the mock before implementation begins |
| **Claude Code** | Direct implementation — generates screen code, components, navigation wiring, and data model from the packet |

---

## 4. Feature Specification

### 4.1 Mark — Annotation Tools

- **Freehand pen** — pressure-sensitive, Apple Pencil 2 and Pro
- **Highlighter** — with adjustable opacity
- **Arrow** — tap-to-place start and end points, auto-straightened
- **Rectangle and ellipse** — with optional semi-transparent fill
- **Text label** — typed or Scribble, attached to canvas coordinates
- **Redline ruler** — dimension callout with measured pixel values
- **Semantic stamp** — tap to place: Bug / Requirement / Question / Suggestion / Note

### 4.2 Mark — Canvas Controls

- Pinch-to-zoom, two-finger pan
- Layer panel: toggle annotation layer visibility
- Undo / Redo — shake gesture or toolbar button
- Palm rejection in Pencil mode
- Colour palette — 6 quick-access swatches + custom picker
- Annotation list sidebar — all annotations listed with type, text, and jump-to location

### 4.3 Mock — Sketch Canvas

- Blank canvas or 8pt grid overlay (toggleable)
- Full PencilKit freehand drawing — pressure and tilt responsive
- Scribble active on all text regions — handwritten labels auto-converted
- Clean Up button — triggers on-device Vision analysis
- Sketch layer preserved beneath lo-fi render (can be toggled back)

### 4.4 Mock — Component Review & Correction

- Each detected component shown with type badge and confidence ring
- Tap to reassign type via popover — full component type list
- Drag handle to resize component bounds
- Merge: select two components, merge into one
- Delete: remove a misdetected component
- Add: tap empty canvas area to manually place a component

### 4.5 Apple Pencil Integration

- **Pencil:** draw / annotate in all modes
- **Double-tap (Pencil 2):** toggle between last two active tools
- **Hover preview (Pencil Pro):** shows tool cursor before contact
- **Squeeze (Pencil Pro):** open context tool picker
- **Pressure:** modulates line weight and opacity
- **Tilt:** modulates shading angle on highlighter
- **Scribble:** active everywhere text input is accepted

### 4.6 Export

- Export as ZIP packet: `canvas.png` + `annotations.json` + `components.json` + `prompt.md` + `manifest.json`
- **Share Sheet:** standard iOS sharing — AirDrop, Files, Mail, any registered handler
- **iCloud Drive:** saved to shared Mark and Mock container, accessible from Mac
- **Mac companion app:** auto-delivers to active Claude Code workspace
- **Copy prompt.md:** quick-copy the markdown summary to clipboard for pasting into Claude Desktop

---

## 5. Context Packet Format

Every export produces a ZIP archive. This is the contract between Mark and Mock and Claude Desktop / Claude Code.

| File | Contents |
|------|----------|
| `manifest.json` | Project name, canvas type (mark / mock / mark+mock), export timestamp, annotation count, component count, app version |
| `canvas.png` | Full-resolution flattened canvas: background image or lo-fi schematic render + all annotation layers composited |
| `annotations.json` | Array of all annotations: id, type, shape, frame, text, linked component id |
| `components.json` | Component tree (Mock canvases): id, stencilType, frame, label, properties, children, connections |
| `prompt.md` | Human-authored markdown template pre-filled with canvas metadata — the user's intent statement for Claude |
| `design-system.json` | Colour tokens, font sizes, spacing values extracted from canvas or Figma source (v2+) |

### 5.1 prompt.md Structure

The `prompt.md` file is a template the user fills in at export time. Structural sections are auto-populated from metadata; the Context and Intent sections are written by the user.

```markdown
## Context
[User describes what screen or flow this represents]

## Intent
[User states what they want Claude to do: implement / review / fix / discuss]

## Components
[Auto-populated from components.json]

## Annotations
[Auto-populated, grouped by type: Bug / Requirement / Question / Suggestion / Note]

## Requirements
[All Requirement-stamped annotations as a distilled actionable list]

## Open Questions
[All Question-stamped annotations surfaced for Claude's attention]
```

> **KEY DESIGN DECISION:** `prompt.md` is written by the user, not generated by an AI inside the app. Mark and Mock pre-fills the structural sections from metadata, but the Context and Intent sections are the user's voice. This keeps the app simple, offline-capable, and honest about where the intelligence lives.

---

## 6. Technical Architecture

### 6.1 Technology Stack — iPad (Phases 1–4)

| Layer | Technology |
|-------|------------|
| App Framework | SwiftUI + UIKit — SwiftUI for navigation and project browser; UIKit required for PencilKit canvas |
| Drawing Engine | PencilKit (PKCanvasView) for freehand strokes; CoreGraphics for lo-fi schematic rendering |
| Sketch Analysis | Apple Vision framework (VNDetectRectanglesRequest, VNRecognizeTextRequest) — fully on-device |
| Component Canvas | Custom CALayer hierarchy over PKCanvasView for lo-fi component render and interaction |
| Scribble | UIIndirectScribbleInteraction on all text-accepting component labels and annotation fields |
| Data Model | SwiftData for projects and canvas state; FileManager + iCloud ubiquitous URLs for image assets |
| Cloud Sync | CloudKit + iCloud Drive — project sync across iPad and Mac |
| Export Engine | CoreGraphics canvas flattening to PNG; Codable structs to JSON; ZIPFoundation for packaging |
| Mac Companion App | SwiftUI menubar extra (NSStatusItem) — receives packets from iCloud container, delivers to Claude Code |
| Claude Code Bridge | Shared iCloud App Group container + CloudKit change notifications |

### 6.2 Technology Stack — macOS (Phase 5+)

| Layer | Technology |
|-------|------------|
| App Framework | SwiftUI for macOS — native Mac app, not Catalyst |
| Drawing Engine | Same CoreGraphics renderer as iPad; PencilKit available on macOS 14+ via Sidecar |
| Drawing Tablet Support | NSEvent tablet pressure/tilt APIs for Wacom and compatible tablets |
| Mouse / Keyboard Mode | Click-to-place stencils; drag handles; keyboard shortcuts for all tools |
| Screenshot Capture | ScreenCaptureKit for capturing any window or screen region directly into a Mark canvas |
| Shared Core | CanvasEngine, AnnotationLayer, VisionAnalyser, ExportEngine — shared Swift packages across iOS and macOS targets |

### 6.3 Data Model

#### Project
```swift
id: UUID
name: String
createdAt: Date
updatedAt: Date
canvases: [Canvas]
exportHistory: [ExportRecord]
```

#### Canvas
```swift
id: UUID
type: CanvasType          // .mark | .mock | .markAndMock
backgroundImage: ImageAsset?
strokes: PKDrawing
annotations: [Annotation]
components: [WireframeComponent]
sketchCleanupState: CleanupState  // .unsketched | .pending | .reviewed | .confirmed
viewport: CGRect
```

#### Annotation
```swift
id: UUID
type: AnnotationType      // .bug | .requirement | .question | .suggestion | .note | .freeform
shape: AnnotationShape    // .arrow | .circle | .rect | .text | .redline | .stamp
frame: CGRect
text: String?
color: Color
linkedComponentId: UUID?
```

#### WireframeComponent
```swift
id: UUID
stencilType: StencilType
frame: CGRect
label: String
properties: [String: String]    // placeholder text, variant, state, etc.
children: [UUID]
connections: [ComponentConnection]
visionConfidence: Float?        // nil if manually placed
```

### 6.4 Module Structure

| Module | Responsibility |
|--------|---------------|
| ProjectBrowser | SwiftUI project grid, creation, deletion, iCloud status indicator |
| CanvasEngine | Core canvas host: PKCanvasView + overlay layers + gesture coordination |
| AnnotationLayer | CoreGraphics shape rendering, hit-testing, annotation CRUD |
| VisionAnalyser | VNDetectRectanglesRequest + rule-based component classifier; runs on background queue |
| ComponentCanvas | Lo-fi schematic render layer; component drag/resize/type-correction interactions |
| ScribbleHandler | UIIndirectScribbleInteraction bridge for labels and annotation text |
| ExportEngine | Canvas flattening to PNG; JSON serialisation; prompt.md template assembly; ZIP packaging |
| MacBridge | iCloud App Group writer + CloudKit notification sender for companion app |
| FigmaImporter (v2) | Figma REST API client; component model mapper; design system token extractor |

---

## 7. Mac Companion App

A lightweight menubar app — not a full application. Its sole job is to bridge a packet arriving in iCloud and Claude Code receiving it as context.

### 7.1 Delivery Flow

1. User taps "Send to Claude Code" on iPad
2. ExportEngine writes packet ZIP to shared iCloud App Group container
3. CloudKit sends a change notification to the Mac companion
4. Companion detects the new packet and presents a menubar notification
5. User clicks "Attach to Claude Code" in the menubar
6. Companion copies the packet to the active Claude Code workspace directory
7. Claude Code sees the packet as a new file — user attaches it to the next prompt

### 7.2 Companion Features

- Menubar icon with badge count for undelivered packets
- Packet history — last 20 exports with canvas name and timestamp
- One-click delivery to Claude Code workspace (user sets workspace path in preferences)
- Quick-copy `prompt.md` to clipboard — paste directly into Claude Desktop or Claude Code chat
- Auto-open packet folder in Finder

---

## 8. Implementation Roadmap

| Phase | Scope |
|-------|-------|
| **Phase 1 — Mark MVP (Months 1–3)** | SwiftData project model + CanvasEngine + PencilKit markup + semantic annotation stamps + ExportEngine (PNG + JSON + prompt.md) + Share Sheet ZIP export. iPad + Apple Pencil only. |
| **Phase 2 — Mock (Months 3–6)** | Blank Mock canvas + freehand sketch layer + VisionAnalyser (on-device cleanup) + ComponentCanvas (lo-fi render) + component type correction UI + Scribble on labels + connection arrows. |
| **Phase 3 — iCloud + Mac Companion (Months 6–8)** | iCloud Drive project sync + CloudKit notifications + Mac companion menubar app + Claude Code workspace delivery + quick-copy prompt.md. |
| **Phase 4 — Flow Diagrams (Months 8–10)** | Multi-canvas projects with named screens + connection arrows between canvases + flow overview map + full flow graph in components.json. |
| **Phase 5 — macOS App (Months 10–14)** | Native macOS SwiftUI app + ScreenCaptureKit + drawing tablet support + mouse/keyboard stencil placement + shared Swift packages. |
| **Phase 6 — Figma (Months 14–18)** | Figma REST API import + component model mapping + design system extraction + lo-fi variant mock generation + design-system.json in all packets. |

### 8.1 Phase 1 Technical Priorities (Ordered)

1. SwiftUI app shell with NavigationSplitView and SwiftData project model
2. PKCanvasView integration inside a UIViewRepresentable CanvasEngine
3. CoreGraphics annotation overlay layer with CALayer above PKCanvasView
4. Annotation CRUD: tap-to-place stamps, drag to reposition, tap to edit text
5. Background image import via UIImagePickerController + Photos picker
6. ExportEngine: flatten PKDrawing + CoreGraphics overlay to PNG via UIGraphicsImageRenderer
7. JSON serialisation of annotations via Codable
8. prompt.md template assembly with auto-populated annotation list
9. ZIPFoundation package integration for packet assembly
10. Share Sheet presentation via UIActivityViewController

### 8.2 Key Technical Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Vision detection accuracy on rough sketches | Tune VNDetectRectanglesRequest parameters; always fall back to manual placement; keep sketch layer visible for reference |
| PencilKit + CoreGraphics overlay hit-testing conflicts | Custom gesture recogniser that inspects Pencil vs touch source; route Pencil to PKCanvasView, touch to annotation overlay |
| Large screenshot memory on Pro display iPads | Load background images with ImageIO downsampling to 2x display resolution; CATiledLayer for very large canvases |
| Scribble latency on component labels | Pre-warm UIIndirectScribbleInteraction at canvas load; optimistic text update with visual correction indicator |
| iCloud sync conflicts between iPad and Mac | SwiftData persistent history + NSMergeByPropertyObjectTrumpMergePolicy; surface conflicts as non-blocking UI banners |
| Mac companion sandboxing for Claude Code file access | NSOpenPanel to grant sandbox bookmark to Claude Code workspace; persist bookmark in UserDefaults |

---

## 9. Claude Code Prompt Templates

Accessible from the Export sheet and the Mac companion. User selects a template; it pre-fills the Intent section of `prompt.md`.

| Template | Intent Injected into prompt.md |
|----------|-------------------------------|
| **Implement Screen** | Implement this screen in full. Use components.json for structure and annotations for requirements. Follow design-system.json tokens if present. |
| **Fix Annotated Issues** | Address all Bug-stamped annotations. Each includes a description and canvas location. Confirm each fix with a brief note. |
| **Implement Requirements** | Implement all Requirement-stamped annotations as code changes. Treat each as a discrete task. Do not change anything not covered by an annotation. |
| **Generate Components** | Generate individual reusable components for each entry in the component tree. Each should accept props implied by its label and properties fields. |
| **Review & Suggest** | Review this screen against the annotations. Identify implementation concerns, missing edge cases, or accessibility issues not already annotated. |
| **Apply Design System** | Refactor the existing implementation to conform to design-system.json tokens. Do not change layout or behaviour — visual properties only. |

---

## 10. Open Questions

- **Claude Code target:** CLI tool, VS Code extension, or both? Determines companion app delivery mechanism.
- **Distribution:** App Store, TestFlight, or internal/enterprise only for v1?
- **Offline-first:** All Mark and Mock features should work without network — confirm this is a hard requirement.
- **Collaboration:** Single-user v1 confirmed — multi-user annotation sessions deferred to which phase?
- **Accessibility:** VoiceOver + Switch Control priority for v1 — required for App Store or deferred?
- **Flow diagrams:** Currently Phase 4 — should this move earlier given it was part of the original vision?

---

> **NEXT STEP:** Feed this document to Claude Code with the prompt:
>
> *"Use this design document to scaffold the Phase 1 Mark and Mock iPad application. Create the Xcode project structure, SwiftData model (Project, Canvas, Annotation), CanvasEngine skeleton with PKCanvasView integration, and the ExportEngine stub. Use Swift 6 and SwiftUI with UIKit interop where required."*
