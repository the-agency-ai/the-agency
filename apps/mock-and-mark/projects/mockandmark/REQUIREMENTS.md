# MockAndMark Requirements

## Problem Statement

There's no simple, fast app for annotating screenshots with:
1. Quick shape drawing (circles, arrows)
2. Scribble text input (write with Apple Pencil → text)
3. Immediate PNG export

Existing tools are either too complex (Figma, Sketch) or too limited (iOS Markup).

## User Stories

### As a product person, I want to:
- Quickly circle a UI element and add text explaining what's wrong
- Export the annotated screenshot to share with engineers
- Not learn a complex interface

### As a developer, I want to:
- Mark up designs with technical notes
- Create quick wireframes for ideas
- Share annotated screenshots in Slack

### As a designer, I want to:
- Quickly sketch feedback on designs
- Add handwritten notes that convert to text
- Maintain a library of annotated screenshots

## Functional Requirements

### FR-1: Image Import
- **FR-1.1**: Import from Photos library
- **FR-1.2**: Import from Files app
- **FR-1.3**: Import from clipboard (paste)
- **FR-1.4**: Capture new photo (camera)
- **FR-1.5**: Support PNG, JPEG, HEIC formats

### FR-2: Drawing Tools
- **FR-2.1**: Circle/oval tool with stroke customization
- **FR-2.2**: Arrow tool (line with arrowhead)
- **FR-2.3**: Rectangle tool
- **FR-2.4**: Freehand drawing
- **FR-2.5**: Color selection (preset colors)
- **FR-2.6**: Stroke width adjustment

### FR-3: Text Annotations
- **FR-3.1**: Tap to place text box
- **FR-3.2**: Scribble input (handwriting → text)
- **FR-3.3**: Keyboard input fallback
- **FR-3.4**: Font size adjustment
- **FR-3.5**: Text color selection

### FR-4: Editing
- **FR-4.1**: Select and move annotations
- **FR-4.2**: Resize annotations
- **FR-4.3**: Delete annotations
- **FR-4.4**: Undo/redo

### FR-5: Export
- **FR-5.1**: Export as PNG
- **FR-5.2**: Copy to clipboard
- **FR-5.3**: Share via share sheet
- **FR-5.4**: Save to Photos

### FR-6: Project Management
- **FR-6.1**: Save projects locally
- **FR-6.2**: List saved projects
- **FR-6.3**: Delete projects
- **FR-6.4**: Rename projects

### FR-7: iCloud Sync (v1.1)
- **FR-7.1**: Sync projects across devices
- **FR-7.2**: Work offline, sync when connected
- **FR-7.3**: Handle conflicts gracefully

## Non-Functional Requirements

### NFR-1: Performance
- App launch < 2 seconds
- Drawing latency < 16ms (60fps)
- Export < 3 seconds for 4K image

### NFR-2: Usability
- Core workflow (import → annotate → export) < 30 seconds
- No tutorial required for basic use
- Accessible (VoiceOver support)

### NFR-3: Reliability
- No data loss on crash
- Graceful handling of large images
- Works offline

### NFR-4: Platform Support
- iOS 17+ (iPhone)
- iPadOS 17+ (iPad)
- macOS 14+ (Sonoma) - future

## Constraints

### Technical
- Must use PencilKit for drawing (Apple standard)
- Scribble only works in text fields (not on canvas)
- SwiftData requires iOS 17+

### Business
- MVP in 2 weeks
- Solo developer (agent-assisted)
- Open source friendly architecture

## Acceptance Criteria

### MVP Complete When:
1. Can import a screenshot from Photos
2. Can draw a circle on the image
3. Can add text using Scribble
4. Can export as PNG
5. Works on iPad with Apple Pencil
