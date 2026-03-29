# mock-and-mark Workstream Knowledge

**Created:** 2026-03-29 13:04:37 +08
**Updated:** 2026-03-29

## Overview

Definition, design, and development of **Mock and Mark** — an iPad-native visual communication tool for Claude Code. Two modes: MARK (annotate existing screenshots with Apple Pencil) and MOCK (sketch new screens freehand, on-device Vision framework cleanup to lo-fi wireframes).

Core concept: no AI in the app. The intelligence lives in Claude Code. Mock and Mark is a capture and structuring tool that outputs structured context packets (ZIP: PNG + annotations JSON + components JSON + prompt.md).

## Key Concepts

- **MARK mode** — annotate screenshots with Apple Pencil: redlines, semantic stamps (Bug, Requirement, Question, Suggestion, Note), intent notes
- **MOCK mode** — freehand sketch → on-device Vision framework detection → rule-based component classification → user confirmation → clean lo-fi schematic
- **Context packets** — structured ZIP exports: `canvas.png` + `annotations.json` + `components.json` + `prompt.md` + `manifest.json`
- **Lo-fi by design** — schematic wireframes, not hi-fi. Claude Code needs semantic clarity, not visual polish. Design system tokens are separate.
- **Phase roadmap** — Phase 1: Mark MVP (iPad), Phase 2: Mock, Phase 3: iCloud + Mac companion, Phase 4: Flow diagrams, Phase 5: macOS app, Phase 6: Figma import

## Seed Files

- `usr/jordan/mock-and-mark/mock-and-mark-seed-20260329.md` — full design doc (v1.1)
- `usr/jordan/mock-and-mark/mock-and-mark-analysis-20260329.md` — CoS session analysis
- `usr/jordan/mock-and-mark/mock-and-mark-chatlog-20250310.md` — original chatlog

## References

- `claude/agents/mock-and-mark/agent.md` — agent definition
- Open questions: Claude Code target, distribution, offline-first, collaboration phasing, accessibility, flow diagrams timing
