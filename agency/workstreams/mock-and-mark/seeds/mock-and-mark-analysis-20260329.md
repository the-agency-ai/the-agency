# Mark and Mock — Analysis

**Date:** 2026-03-29
**Seed:** `mock-and-mark-seed-20260329.md` (design doc v1.1)

## What Is It?

Mark and Mock is an iPad-native tool for visual communication with Claude Code. Two modes:

1. **MARK** — annotate existing screenshots with Apple Pencil (redlines, semantic stamps, intent notes)
2. **MOCK** — sketch new screens freehand, app cleans them into lo-fi wireframes

Output: structured context packets (PNG + JSON + markdown) that drop into Claude Code as attached context.

## Key Insight

**No AI in the app itself.** The intelligence lives in Claude Code. Mark and Mock is a capture and structuring tool. This is architecturally clean — the app handles input/structuring, Claude handles reasoning/implementation.

## Relationship to Agency 2.0

- Solves the "visual intent" problem for Claude Code users
- Context packets could become a standard input format for Agency projects
- The export format (ZIP: image + annotations + components + prompt.md) aligns with Agency's structured document patterns

## Architecture Notes

- Swift/SwiftUI, iPad-first with Apple Pencil
- On-device Apple Vision framework for sketch-to-wireframe cleanup
- Rule-based component classifier (rectangle near top = nav bar, etc.)
- User confirmation step before export (correct component assignments)
- Export formats: ZIP packet, Share Sheet, iCloud handoff

## Phase Roadmap (from seed)

1. **Phase 1** — iPad app (Mark + Mock core)
2. **Phase 2** — Figma import, design system extraction
3. **Phase 3** — macOS native app with drawing tablet support

## Next Steps

1. Set up Swift project in the-agency
2. Define the export packet schema (JSON structure for components)
3. Build the Apple Pencil drawing canvas (PKCanvasView)
4. Implement basic shape detection with Vision framework
