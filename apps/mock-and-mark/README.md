# Apple Platforms Starter Kit

Agency-style development environment for iOS, iPadOS, and macOS applications.

## Tech Stack

| Technology     | Purpose                        |
| -------------- | ------------------------------ |
| **Swift 5.9+** | Primary language               |
| **SwiftUI**    | Declarative UI framework       |
| **SwiftData**  | Data persistence               |
| **iCloud**     | Cross-device synchronization   |
| **PencilKit**  | Apple Pencil / drawing support |

## Project Structure

```
apple-platforms-starter/
├── CLAUDE.md              # Development instructions for Claude agents
├── agents/
│   ├── architect/         # System design, architecture decisions
│   ├── ios-dev/           # iOS/iPadOS implementation, PencilKit
│   ├── macos-dev/         # macOS implementation, AppKit, menus
│   └── ui-dev/            # SwiftUI, animations, UX
├── tools/                  # Build and development scripts
├── knowledge/             # Shared technical knowledge
└── projects/
    └── mockandmark/       # Current project (TheAgency AI product)
```

## Agents

| Agent       | Role             | Specialization                                           |
| ----------- | ---------------- | -------------------------------------------------------- |
| `architect` | System design    | Data models, architecture patterns, iCloud sync strategy |
| `ios-dev`   | iOS/iPadOS       | PencilKit, touch input, mobile patterns                  |
| `macos-dev` | macOS            | AppKit, menus, keyboard shortcuts, window management     |
| `ui-dev`    | Interface design | SwiftUI views, animations, accessibility                 |

## Quick Start

```bash
# Launch an agent (from this directory)
myclaude apple ios-dev

# Or specify the project
cd projects/mockandmark
myclaude apple architect
```

## Current Project: MockAndMark

**A TheAgency AI product** - Screenshot annotation and quick mockup tool.

- PNG import (screenshots, images)
- Drawing tools (circles, arrows, shapes)
- Scribble text input (handwriting → text)
- PNG export
- iCloud sync across devices

See `projects/mockandmark/README.md` for details.

## TheAgency AI Products

| Product | Description | Status |
|---------|-------------|--------|
| **the-agency** | Open source multi-agent framework | Active |
| **Workbench** | Internal developer tools | In development |
| **MockAndMark** | Screenshot annotation app | Starting |

## Platform Targets

- iOS 17+ (iPhone)
- iPadOS 17+ (iPad with Apple Pencil)
- macOS 14+ (Sonoma)

## Development Workflow

1. **Architecture first** - `architect` designs data models and sync strategy
2. **UI prototyping** - `ui-dev` creates SwiftUI views
3. **iOS/iPadOS** - `ios-dev` implements with PencilKit, touch
4. **macOS** - `macos-dev` adapts for desktop (menus, keyboard, mouse)
5. **Iteration** - Agents collaborate via `./tools/collaborate`
