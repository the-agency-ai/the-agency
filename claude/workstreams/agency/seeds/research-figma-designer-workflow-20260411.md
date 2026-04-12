---
type: research-report
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
research_agent: agent-1-of-4 (designer workflow)
status: complete
part_of: Figma → UI research batch (2026-04-11)
---

# Designer Workflow for Figma → High-Fidelity React / React Native Handoff

Research Agent 1 of 4 · Focus: designer-side workflow · Date: 2026-04-11

## Summary

- The Agency already has strong *downstream* Figma tooling (API extraction, token generation, visual diff, design-system agent template) but no canonical guidance for the *upstream* designer step — what a designer must do before a file is safe to codegen against. That is the gap this report fills.
- In 2026 the handoff-ready baseline is: **Variables (not Styles) for color/number tokens, Styles only for typography and composite effects, everything wrapped in Auto Layout, everything an instance of a component, and every handoff surface marked "Ready for dev" in a Section**. Files that meet this bar are roughly 5x faster to code against than files that don't.
- Variables are not the system of record — they are the *output* of a token pipeline. The healthy 2026 pattern is Tokens Studio (or code-owned tokens) → Figma Variables → Dev Mode → codegen. Variables edited directly in Figma drift; variables sourced from JSON don't.
- Web and native diverge mainly on **layout primitives, density units, and platform states**: React can use CSS Grid, viewport units, and hover/focus/active pseudo-states; React Native is Flexbox-only (auto-layout maps cleanly), uses density-independent pixels at 1x, and has pressed/disabled but no hover. Designers must prep differently for each.
- The most valuable designer habit for AI-agent handoff is **annotations + Ready-for-dev Sections**. Figma Dev Mode annotations persist as layer metadata, survive redesigns, and are readable via the Figma REST API — meaning an agent extracting a file gets the designer's intent, not just the geometry.

## Existing Artifacts Audit

| Artifact | What it does | Designer-workflow gap |
|---|---|---|
| `claude/knowledge/ui-development/figma-workflow.md` | 475-line playbook for *implementers* — phases 1–6 cover inspection, structure, styling, responsive, states, QA. Good for devs/ux-dev agents. | Zero guidance for what a designer must do on the Figma side. Assumes the file is already good. |
| `claude/knowledge/design-systems/ordinaryfolk-003/` | Worked example: hybrid API+PDF extraction of NOAH-APP Figma file, 69 colors, 20+ text styles, Tailwind config output. | Demonstrates *recovery* from a non-token-first file (colors pulled from fills, styles from PDFs). A handoff-ready file in 2026 wouldn't need PDF enhancement — variables would be queryable directly. |
| `claude/agents/templates/design-system/agent.md` + `KNOWLEDGE.md` | Extraction-specialist class: runs `figma-extract`, reads designer PDFs, merges, generates Tailwind config. | Class is reactive (extract what's there). Doesn't own the "is this file ready?" pre-flight check. No `figma-audit` or `figma-lint` tool referenced. |
| `claude/agents/templates/ux-dev/agent.md` | Implementation specialist, uses `figma-diff` for visual QA. | Consumer only — no feedback loop to tell the designer what to fix in Figma. |
| `claude/tools/figma-extract` (v1.2.0) | Bash tool: fetches file JSON via REST API, extracts unique SOLID fills and font families via grep/sed, writes `source/figma-file.json` + `source/figma-styles.json`. | Works on fill data, not on variables/modes. Doesn't enumerate components, variants, component-properties, Ready-for-dev sections, annotations, or detached instances. No handoff-readiness score. |
| `claude/tools/figma-diff` | Screenshots a URL, diffs against a mockup PNG. | Late-stage tool — catches drift but doesn't prevent it. |

**Net gap:** there is no "handoff-ready checklist" document, no Figma-side-lint/audit tool, and no convention for how a monofolk designer should structure a file so an agent can read it without guesswork. This report provides the first; a proposed `figma-audit` tool would provide the second.

## The Handoff-Ready Figma File — Checklist

A file is **handoff-ready** when all of the following are true.

### Structure & Organization

- [ ] **Pages are named with intent.** `🚀 Ready for Dev`, `🎨 Explorations`, `📚 Components`, `🗃 Archive`.
- [ ] **Every handoff surface lives in a Section** (not just a Frame). Sections are the unit Dev Mode uses for Ready-for-Dev status.
- [ ] **Every Ready-for-Dev Section is marked with the status.** Unmarked = not ready = do not codegen.
- [ ] **Frames are named semantically**, not `Frame 1423`. `screen/onboarding/welcome`, `component/Button/Primary/Pressed`.
- [ ] **One artboard size per target.** Web: a desktop frame (1440) and a mobile frame (375 or 390). Native: iPhone reference (393 or 402 wide in iOS 17) and an Android reference (360).

### Components & Variants

- [ ] **No detached instances.** Run a detach-finder plugin (ComponentQA, Design System Tracker, Master) before handoff.
- [ ] **Every reusable thing is a component**, not a copy.
- [ ] **Variants encode states and configurations, not copies.** `Button` should have `variant=Primary/Secondary/Tertiary`, `size=S/M/L`, `state=Default/Hover/Pressed/Disabled`, `icon=None/Leading/Trailing` as component properties.
- [ ] **Component properties use the right type.** Boolean for toggles, Text for content, Instance swap for icon slots, Variant for enumerated states.
- [ ] **Every interactive element has all states as variants:** default, hover (web only), focus, pressed/active, disabled, loading.
- [ ] **Main components live on a dedicated Components page** and are published to a library if consumed across files.
- [ ] **Component descriptions are filled in.** Shows up in Dev Mode and in the REST API.

### Layout

- [ ] **Auto Layout everywhere.** Non-negotiable for React Native.
- [ ] **Spacing is token-driven, not freehand.** Padding, gap, and item-spacing values come from number variables.
- [ ] **Sizing modes are explicit.** Fill container / Hug contents / Fixed.
- [ ] **Constraints are set on absolutely-positioned children.**
- [ ] **No nested frames that exist only for grouping.**

### Tokens (Variables + Styles)

- [ ] **Color tokens are Variables**, organized in collections (`primitives`, `semantic`, optionally `component`).
- [ ] **Variables have modes for themes** (light/dark) and optionally brand/density.
- [ ] **Variables use Code Syntax** (per-platform name override).
- [ ] **Variables have Scoping** set correctly.
- [ ] **Number tokens are Variables** for spacing, radius, border-width, opacity, sizing.
- [ ] **Typography is Styles** (variables don't yet fully replace text styles for typography).
- [ ] **Effect Styles** for shadows and blurs.
- [ ] **No detached styles.**
- [ ] **Colors not in the variables collection = forbidden.**

### Dev Mode Prep

- [ ] **Annotate non-obvious intent.** Dev Mode annotations (Shift+T) for: accessibility labels, tap-target expansions, motion specs, conditional visibility, localization notes, responsive breakpoints.
- [ ] **Add measurements** (Shift+M) for any spacing that isn't obvious from Auto Layout.
- [ ] **Add Dev Resource links** to each Section — PR, storybook entry, Jira ticket.
- [ ] **Walk through the file in Dev Mode yourself** before marking Ready.

## Web vs Native Divergence

| Dimension | React (web) | React Native (iOS/Android) |
|---|---|---|
| Layout primitives | Flexbox, CSS Grid, `position`, floats | Flexbox only. Auto Layout is a 1:1 match. |
| Units | `px`, `rem`, `%`, `vw/vh` | Density-independent points (iOS pt, Android dp). Figma pixels map 1:1. |
| Reference frame | Desktop 1440, mobile 375/390 | iPhone ref: 393pt or 402pt. Android ref: 360dp. |
| Typography | CSS font-size, line-height, letter-spacing | Font must be bundled. `letterSpacing` is absolute pt, not em. |
| Responsive | Media queries, container queries, fluid type | No media queries. `Dimensions`/`useWindowDimensions`. |
| Interaction states | Default, **hover**, focus, active, disabled | Default, **pressed**, focus, disabled. **No hover**. |
| Images | CSS `background-image`, `<img>`, SVG inline | `<Image>` with local require() or URI; SVG needs `react-native-svg`. |
| Shadows | CSS `box-shadow` — multi-layer, inset, spread | iOS `shadowColor/Offset/Opacity/Radius`, Android `elevation`. **Spread is unsupported.** |
| Gradients | CSS `linear-gradient`, `radial-gradient`, `conic-gradient` | Requires `react-native-linear-gradient`. Conic unsupported. |
| Safe areas | Not applicable | Must design with notch/Dynamic Island/home-indicator awareness. |

## Annotations & Documentation Conventions

- **Dev Mode annotations (Shift+T)** — first-class mechanism. Attach to a layer, survive moves, exposed in REST API. Use for accessibility labels, keyboard behavior, motion, conditional visibility, empty/loading/error states.
- **Measurements (Shift+M)** for non-obvious spatial relationships.
- **Ready-for-dev status** on every Section you want built.
- **Section descriptions** for full prose context.
- **Component descriptions** on main components.
- **Dev Resources** linking Sections to PR/storybook/issue tracker.
- **Prototype flows** for interaction intent.
- **State variants for every interactive component.**
- **Responsive frames** for each breakpoint where layout changes shape.
- **Motion specs** in annotations or separate `🎬 Motion` page.
- **Empty states, error states, skeletons** — drawn, not assumed.

## Ecosystem of Supporting Tools

| Tool | Role |
|---|---|
| **Figma Variables + Dev Mode** | Native 2024+ — token storage, theme modes, annotations, Ready-for-dev |
| **Tokens Studio** | Token system-of-record plugin. 23+ token types, GitHub sync, JSON export to Style Dictionary |
| **EightShapes Specs** | Auto-generates measurement, spacing, anatomy annotations |
| **ComponentQA / Design System Tracker / Master** | Lint plugins: detached instances, orphan styles, rogue values |
| **Figma REST API** | Programmatic read of everything above |
| **Figma Code Connect** | Links Figma components to real code components |
| **Storybook + Chromatic** | Other end of the pipe; Figma addon links back |

## Open Questions

1. **Monofolk's token pipeline direction.** Tokens Studio (design-led, JSON-exported) or code-owned (Style Dictionary, Tailwind) with sync into Figma Variables? Industry 2026 consensus: code-as-source or Tokens-Studio-as-source with Variables as rendered output.
2. **Single file or separated web/native files?** Common 2026 pattern: single file with web-only and native-only Sections, shared tokens collection.
3. **Who lints the Figma file?** No `figma-audit` / `figma-lint` tool today. Should we build one following the Enforcement Triangle pattern?
4. **Relationship between `design-system` and a new `figma-designer` agent class.** Extend existing or add new?
5. **Monofolk designer's current practice.** What variables/Styles discipline exists today?
6. **Annotation culture.** Need agreement on which annotations are mandatory vs optional.
7. **Feedback loops.** When `figma-audit` finds a problem, how does it flow back to the designer?

## Sources

- [Guide to Dev Mode — Figma Learn](https://help.figma.com/hc/en-us/articles/15023124644247-Guide-to-Dev-Mode)
- [Dev Mode: Design-to-Development — Figma](https://www.figma.com/dev-mode/)
- [Add measurements and annotate designs in Dev Mode — Figma Learn](https://help.figma.com/hc/en-us/articles/20774752502935-Add-measurements-and-annotate-designs-in-Dev-Mode)
- [The Art and Science of Annotations in Dev Mode — Figma Blog](https://www.figma.com/blog/annotations-in-dev-mode/)
- [The Designer's Handbook for Developer Handoff — Figma Blog](https://www.figma.com/blog/the-designers-handbook-for-developer-handoff/)
- [Optimize design files for developer handoff — Figma Learn](https://help.figma.com/hc/en-us/articles/360040521453-Optimize-design-files-for-developer-handoff)
- [Guide to variables in Figma — Figma Learn](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)
- [Design System Mastery with Figma Variables: The 2025/2026 Best-Practice Playbook](https://www.designsystemscollective.com/design-system-mastery-with-figma-variables-the-2025-2026-best-practice-playbook-da0500ca0e66)
- [ComponentQA — Design System Audit plugin](https://www.figma.com/community/plugin/1564328602359376130/componentqa-design-system-audit-detached-instances-component-health-monitoring)
- [From Figma to Pixel-Perfect React Native UI: 2025 Edition](https://medium.com/@moeenshah54/from-figma-to-pixel-perfect-react-native-ui-my-complete-workflow-2025-edition-ca928f6f5e37)
