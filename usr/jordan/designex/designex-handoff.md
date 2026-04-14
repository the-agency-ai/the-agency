---
type: handoff
agent: the-agency/jordan/designex
workstream: designex
date: 2026-04-12
trigger: initial-setup
---

## Resume — DesignEx Initial Handoff

### Mission

Build the-agency's **Figma-to-code pipeline** as a standard framework capability. Upgrade existing tools (figma-extract, figma-diff, designsystem-add) to 2026 state of the art: DTCG tokens, Style Dictionary v4, Figma Variables API, Code Connect protocol, multi-platform output (web + React Native).

### Context

**Monofolk launched a parallel DesignEx workstream** (dispatch: `dispatch-designex-workstream-launched--coordinate-20260412.md` in the collaboration repo). They have an April 17 deadline for of-mobile and need a working design-to-code pipeline. They're building ON our tools. We share the research, each side builds, we consolidate and contribute to the framework.

### Seed material — 4 research reports (READ THESE FIRST)

1. `claude/workstreams/agency/seeds/research-figma-designer-workflow-20260411.md` — what designers need to do for handoff-ready Figma files
2. `claude/workstreams/agency/seeds/research-figma-codegen-survey-20260411.md` — tool landscape (Builder.io, Figma Make, Anima, etc.)
3. `claude/workstreams/agency/seeds/research-figma-design-system-bridge-20260411.md` — tokens extraction, DTCG spec, Style Dictionary v4, shadcn + Tamagui pipelines
4. `claude/workstreams/agency/seeds/research-figma-react-vs-rn-20260411.md` — platform differences, NativeWind vs Tamagui, universal app stacks

### Existing tools to upgrade (READ THESE)

- `claude/tools/figma-extract` — currently uses old Styles API, emits ad-hoc markdown. Needs DTCG JSON output, Variables API support.
- `claude/tools/figma-diff` — visual regression. Needs component-level snapshot mode.
- `claude/tools/designsystem-add` — scaffold. Needs DTCG file structure, Style Dictionary config.
- `claude/knowledge/design-systems/ordinaryfolk-003/` — prior extraction example
- `claude/knowledge/ui-development/figma-workflow.md` — workflow guide (web-only, needs RN)

### Recommended architecture (from research reports)

1. **DTCG-first extraction** — `figma-extract` upgraded to emit `.tokens.json` (W3C DTCG format). Dual-path: Variables REST API for Enterprise, plugin-export for non-Enterprise.
2. **`designsystem-build` tool** (NEW) — runs Style Dictionary v4 over DTCG JSON, emits platform outputs: CSS variables (shadcn), Tailwind preset, Tamagui config, NativeWind config.
3. **Three-layer token architecture** — primitive → semantic → component. Light/dark via mode swapping at semantic layer.
4. **Component mapping** — `components.json` manifest linking Figma node IDs to Storybook entries. `figma-components-check` tool validates.
5. **Figma Code Connect adapter** — writes Code Connect mapping files from our design-system markdown.
6. **Figma MCP integration** — connect Claude Code to Figma's MCP server for agent-in-the-loop codegen.

### Coordination with monofolk

- They're starting with the token pipeline today (Style Dictionary v4 + sd-transforms)
- They'll build against our upgraded tools
- Send findings via dispatch to `monofolk/jordan/designex` when you have something to share
- Their research is in the collaboration repo — check for updates via `./claude/tools/collaboration check`

### Execution approach

Follow Valueflow: Seed (research reports) → PVR → A&D → Plan → Implement → Ship. Start with the PVR — what exactly are we building and why. Then A&D for the tool upgrade architecture. Then plan phases. This is framework work (MIT licensed, ships to all projects via `agency update`).

### Constraints

- Ship as PRs (always)
- Captain reviews at boundaries (dispatch when ready)
- Run autonomously — captain is focused on workshop content today
- Monofolk has April 17 deadline — prioritize the token pipeline (figma-extract DTCG upgrade + designsystem-build) since that's their critical path
