# Mark and Mock — Design Session Transcript

---

## Message 1

**User:** This:

Mark and Mock is an iPad application strongly integrated with Mac OS and Claude / Claude Code. It allows you to: 1. Take a screen shot of a UX and mark it up. 2. Do a quick and dirty Balsamiq like wire frame 3. Take a wire frame and mark it up. Will support Apple Pencil and Scribble. Claude and Claude Code can accept these as inputs and use them in the development process. A future version will be able to suck in a Figma file, give you various mocks you can mark up, and also create design system guide for Claude or Claude Code to produce a high-fidelity user interface.

You can't read this?

**Claude:** I can read it perfectly! It's a concept for an iPad app called **Mark and Mock**. Really interesting idea.

Let me save a reminder for you to come back to this.

*(Added memory: Remind user to come back to their "Mark and Mock" iPad app concept — an Apple Pencil-supported UX markup/wireframing tool integrated with Mac OS and Claude/Claude Code, with a future Figma import and design system generation feature.)*

Done! I'll remind you about **Mark and Mock** when you're back.

The concept sounds genuinely compelling — especially the Claude Code integration loop where annotated wireframes become direct development inputs. The Figma-to-design-system pipeline in the future version is the kind of thing that could seriously speed up the handoff between design and implementation. Worth developing further!

---

## Message 2

**User:** Let's start designing this one, okay?

**Claude:** Let's do it! Before we dive in, a few questions to focus the design effort:

*(Asked: Where do you want to start? / What's the primary output you want today?)*

---

## Message 3

**User:** Get a solid design in place that captures both features and architecture and implementation strategy. I want to feed it to Claude Code to kick-start the process.

**Claude:** *(Read docx skill, generated Design Document v1.0 as a .docx)*

Here's your full design document. It covers:

- **Product overview** — the three problems it solves and five product pillars
- **Core user flows** — Screenshot Markup, Wireframe Creation, and Claude Code handoff step by step
- **Full feature spec** — every annotation tool, stencil type, Apple Pencil interaction, and Mac integration point
- **Technical architecture** — full stack (SwiftUI/PencilKit/CloudKit/Anthropic API), complete data model, and module breakdown
- **Claude integration** — the context packet format (manifest, PNG, annotations JSON, components JSON, prompt.md, design tokens), three delivery mechanisms, and in-app Claude sidebar
- **5-phase roadmap** — from MVP through Figma integration, with month estimates
- **Risk register** — six key risks with mitigations
- **Figma v2 plan** — import flow, design system extraction, and mock variant generation
- **Prompt template library** — ready-to-use Claude Code starters
- **Open questions** — things to resolve before you start coding

To kick off Phase 1, the last callout in the doc gives you the exact prompt to feed Claude Code.

---

## Message 4

**User:** What role is the Anthropic API playing? Not sure I see it. The documents will be consumed by Claude Desktop or Claude Code.

**Claude:** Good catch. Let me clarify the actual integration picture.

The Anthropic API was doing two things in the doc that don't actually make sense for your use case:

1. **In-app Claude sidebar** — unnecessary. The user is already *in* Claude Desktop or Claude Code when they consume the output.
2. **Auto-generating prompt.md at export time** — this was the doc calling the API from inside the iPad app, which adds complexity and a dependency that doesn't belong in the tool itself.

**The real model is simpler and better:**

Mark and Mock's job is to produce a **rich, well-structured context packet** — annotated image + structured JSON + a human-readable markdown summary. That packet gets dropped into Claude Desktop or Claude Code, and *Claude does the interpretation there*, where the user already is.

The iPad app is purely a **capture and annotation tool**. No API calls needed in v1. The "intelligence" lives in Claude Desktop/Code, not in the app.

The prompt.md should be **hand-authored or templated** (not AI-generated inside the app) — just a clean markdown file that describes the canvas intent in a format Claude Desktop/Code can immediately act on.

Want me to revise the document to reflect this — strip the API dependency, reframe the export as a Claude Desktop/Code context attachment, and clarify the companion Mac app's role as purely a file delivery mechanism rather than an API proxy?

---

## Message 5

**User:** I think you have captured the Mark piece of it, but not sure the Mock piece is captured.

**Claude:** You're right. Let me think about what "Mock" really means here.

The "Mark" side is clear — annotate screenshots, draw redlines, stamp intent onto existing UIs.

But "Mock" should be about **creating something from scratch** — and I don't think the wireframe canvas I described fully captures it. Let me check my understanding:

*(Asked: What does "Mock" mean in Mark and Mock? / What's the primary output of the Mock side?)*

---

## Message 6

**User:**
- Q: What does "Mock" mean? → I think it is freehand sketch that gets cleaned up into lo-fi mockups. I think then in a later version we can demonstrate flows.
- Q: Primary output? → Both — Mock feeds both the dev and design workflow

**Claude:** That's a really clear and elegant definition. So the Mock flow is:

**Freehand sketch with Apple Pencil → app cleans it up into a structured lo-fi mockup → that mockup feeds both design review AND Claude Code**

The "clean up" step is the key piece I missed. That's where the intelligence lives — not in the Anthropic API at export time, but in the **sketch-to-structure interpretation**.

*(Asked: How does sketch-to-lo-fi cleanup happen? / What does the cleaned-up lo-fi mockup look like? / Who is the reviewer?)*

---

## Message 7

**User:**
- Q: How does cleanup happen? → How about you suggest various ways given iPad and iPadOS capability. I think we are also not considering the Mac OS use case. Marking up and Mocking on your Mac is a use case as well. Phase 1 is iPad + Apple Pencil, but later?
- Q: What does the lo-fi mockup look like? → What will be best to guide Claude Code in implementation. Something quick and dirty that can be implemented and tested.
- Q: Who is the reviewer? → Could be either

**Claude:** Great — let me think through both of those properly.

---

**On sketch-to-lo-fi cleanup — iPad/iPadOS/macOS options:**

**iPad (Phase 1)**
- **PencilKit + Vision framework** — Apple's on-device Vision can detect rectangles, lines, and text from a PKDrawing. No network needed, fast, private. Works well for recognising "that squiggle is a button, that box is a nav bar"
- **Hybrid: Vision auto-detect + user confirmation** — Vision makes its best guess at component types, user taps to confirm or correct via a quick popover. Probably the right Phase 1 approach
- **Scribble-driven** — user writes the component name inside the shape they drew, Scribble converts it, app uses that as the label. Simple, explicit, no ML ambiguity

**Mac (later phases)**
- **Same Vision pipeline** — Vision framework is available on macOS, so the core engine is portable
- **Drawing tablet support** (Wacom, etc.) — via macOS drawing APIs, same canvas engine
- **Mouse + keyboard fallback** — click-to-place shapes and drag handles, more like a traditional wireframe tool. No Pencil required
- **Continuity** — sketch on iPad, refine/view on Mac. The canvas is the same document

---

**On what the cleaned-up mockup should look like for Claude Code:**

The answer is probably **Balsamiq-style schematic** — because what Claude Code needs isn't visual fidelity, it needs **semantic clarity**: what components are present, their hierarchy, their labels, and their relationships. A clean grayscale schematic plus the structured JSON component tree is more useful to Claude Code than a pretty render.

The render can come later (Figma v2 phase). For now: tidy geometry + clear labels + component type tags = everything Claude Code needs to generate a working implementation.

---

Does that framing feel right? If so I can update the document with:
- A proper Mock flow section covering the sketch → Vision detection → user confirmation → lo-fi schematic pipeline
- Mac as a later-phase target with the same engine
- Clearer framing of the lo-fi output as "semantically rich, visually simple — optimised for Claude Code consumption"

---

## Message 8

**User:** Yes, this feels right.

**Claude:** *(Generated revised Design Document v1.1 .docx with:)*
- New Section 2: The Mock Flow — Sketch to Lo-Fi (full pipeline, render spec table)
- Anthropic API removed throughout
- macOS as Phase 5 with its own tech stack section (ScreenCaptureKit, drawing tablet, shared Swift packages)
- prompt.md explicitly framed as user-authored, not AI-generated
- Updated cover: "No AI in the app itself — the intelligence lives where the developer already is"
- Updated closing Claude Code scaffold prompt

---

## Message 9

**User:** I need this as a .md file not a .docx!

**Claude:** *(Regenerated the full v1.1 document as a clean markdown file: `MarkAndMock-DesignDocument-v1.1.md`)*

There you go — same content, clean markdown. Ready to drop straight into Claude Code.

---

## Message 10

**User:** Can you put this entire chat into a markdown artifact?

**Claude:** *(This document.)*

---

*End of transcript.*
