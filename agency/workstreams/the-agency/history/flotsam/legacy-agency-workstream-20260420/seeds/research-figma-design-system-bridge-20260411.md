---
type: research-report
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
research_agent: agent-3-of-4 (design-system bridge — tokens + component mapping)
status: complete
part_of: Figma → UI research batch (2026-04-11)
---

# Figma → Code Design System: Tokens & Component Mapping

Research Agent 3 of 4 · Focus: design-system bridge · Date: 2026-04-11

## Summary

- **DTCG became a stable spec in October 2025** (`2025.10`). It is now the lingua franca for interchange between Figma, Tokens Studio, Style Dictionary, Penpot, Sketch, Framer, Supernova, and zeroheight.
- **Figma Variables (2023) + Variables REST API is now the native path.** Since Figma Schema 2025, Figma committed to DTCG-conforming native export/import. **But it requires an Enterprise seat** — a hard commercial gate that matters for our tool design.
- **Three-layer token architecture is the consensus pattern**: primitive → semantic → component. Light/dark and multi-brand are both handled by swapping the primitive layer while keeping semantic/component references identical.
- **shadcn/ui is fully token-driven** via `globals.css` CSS custom properties, and as of the Tailwind v4 migration, via `@theme`.
- **Tamagui has its own closed token system** (`createTokens` + `createTamagui`) and is NOT DTCG-native. The bridge is codegen from DTCG → a Tamagui config file.

## Tokens Extraction — Current State of the Art (2026)

Four-tool stack:

| Tool | Role | Status |
|------|------|--------|
| **Figma Variables** | Source of truth inside Figma (colors, numbers, strings, booleans; multi-mode) | Native since 2023, REST API GA |
| **Tokens Studio** (plugin) | Extended token types (typography composite, shadow composite, math aliases), Git sync, multi-file theme sets | Dominant plugin; ~500k+ installs |
| **DTCG JSON** (`.tokens.json`) | Interchange format | Stable `2025.10`, media type `application/design-tokens+json` |
| **Style Dictionary v4** | Transform DTCG JSON → platform outputs (CSS, SCSS, JS, iOS Swift, Android XML, Flutter) | GA since 2024; Amazon-maintained |

**Canonical 2026 pipeline:**

```
Figma Variables (designer edits)
    ↓  (Variables REST API or Token Press/variables2json plugin)
DTCG JSON (.tokens.json)   ←→  Git repo (source of truth)
    ↓  (SD-Transforms preprocessor, only if using Tokens Studio extensions)
Style Dictionary v4
    ↓
Platform outputs:
  - web: CSS custom properties, Tailwind config, TS module
  - iOS: Swift UIColor extensions / asset catalogs
  - Android: colors.xml, dimens.xml
  - React Native: TS config (or Tamagui/NativeWind config)
```

Two nuances:
1. **Figma Variables REST API requires Enterprise.** For non-Enterprise users (including monofolk), the path is a Figma plugin (Token Press DTCG Exporter, variables2json, Tokens Studio) writing JSON committed to git. One-way push.
2. **Published styles ≠ variables.** The legacy `/v1/files/:key/styles` endpoint only returns the old style system, not Variables — the sparseness trap our existing `figma-extract` hits.

## Token Architecture — Three-Layer Model

**Primitive → Semantic → Component.** Example:

```json
{
  "color": {
    "blue": { "500": { "$value": "#3182ce", "$type": "color" } }
  },
  "semantic": {
    "action": {
      "primary": { "$value": "{color.blue.500}", "$type": "color" }
    }
  }
}
```

- **Multi-theme (light/dark):** separate file (`dark.tokens.json`) redefines the semantic layer to point at different primitives. Components only reference semantic tokens.
- **Multi-brand:** each brand ships its own primitive file. Semantic file is brand-agnostic.
- **Platform-specific values** handled via Style Dictionary transforms (`px → pt` iOS, `px → sp` Android text, `px → dp` Android dimensions) or DTCG modes.
- **Composite tokens** (typography, shadow, gradient, border) are DTCG `$type: "typography"` etc. — pioneered by Tokens Studio, now in the stable spec.

## Figma → Code Component Mapping — Best Practices

Three strategies:

| Approach | How | Maintained by |
|----------|-----|---------------|
| **Storybook ↔ Figma links** | `parameters.design` in `.stories.ts` file points at a Figma node URL. Chromatic's Figma plugin renders the linked story inside Figma. | Storybook + Chromatic |
| **Component manifest JSON** | Explicit `components.json` lists every code component with Figma node ID, prop names, variant map. Used by Knapsack, Supernova. | Hand-maintained or generated |
| **Figma Code Connect** | `.figma.tsx` file per component declares the mapping; Figma Dev Mode renders the actual JSX. | Figma (Enterprise/Organization) |

Drift prevention:
- **Chromatic visual regression** on every PR
- **Storybook Connect + Figma plugin** for bidirectional view
- **CI enforcement** — lint that every exported component has `parameters.design` or a Code Connect file

Teams shipping this well: Shopify Polaris, GitHub Primer, Atlassian Design System.

## Pipeline: Figma → shadcn + Tailwind (v4)

shadcn/ui is copy-paste components relying on `globals.css` (CSS custom properties) and `tailwind.config.js` (optional in v4). The whole theme is HSL/OKLCH channels:

```css
@theme {
  --color-primary: oklch(0.21 0.006 285.89);
  --color-primary-foreground: oklch(0.985 0 0);
  --color-card: oklch(1 0 0);
}

.dark {
  --color-primary: oklch(0.985 0 0);
}
```

**The bridge:**
1. In Figma, define a Variables collection with modes (Light, Dark). Use HSL or OKLCH colors.
2. Export via DTCG plugin.
3. Run Style Dictionary with a `css/variables` format target that emits the shadcn variable names (`--primary`, `--primary-foreground`, `--card`, `--border`, etc.). **Critical: name the Figma variables to match shadcn names.**
4. Write into `app/globals.css` under `@theme` and `.dark` blocks.

Community plugins: **ForgeKit**, **Tailwind Tokens**.

**What breaks:** shadcn's variable names are opinionated. If your DS has different semantic names, either rename in Figma to match shadcn or maintain a translation layer. Rename in Figma.

## Pipeline: Figma → Tamagui (React Native)

Tamagui doesn't consume CSS variables. Its config is a TypeScript file:

```ts
import { createTokens, createTamagui } from '@tamagui/core'

const tokens = createTokens({
  color: { blue500: '#3182ce', ... },
  size: { 0: 0, 1: 4, 2: 8, ... },
  space: { ... },
  radius: { ... },
  zIndex: { ... },
})

const config = createTamagui({
  tokens,
  themes: {
    light: { background: tokens.color.white, color: tokens.color.black },
    dark:  { background: tokens.color.black, color: tokens.color.white },
    light_pink: { ... },
  },
})
```

**The bridge is codegen, not runtime.** A Style Dictionary custom format reads DTCG JSON and emits the TS module.

Key constraints:
- Tamagui tokens must be **flat** at the bottom level — no nested `color.blue.500`, it's `color.blue500`.
- Tamagui supports `$token` references in styles and themes.
- Nested themes (`light_pink`, `dark_pink`) give multi-brand × light/dark without runtime cost.

Cleanest production pattern: keep DTCG JSON as source, run two Style Dictionary builds — `web/css-variables` for shadcn, `tamagui/config-ts` (custom format) for native.

## DTCG and W3C Token Spec — Adoption

- **Stable 2025.10 release** (Oct 2025) — first version tools can commit to without fear of breakage.
- **Implementations landed:** Style Dictionary v4, Tokens Studio, Figma Schema 2025, Penpot, Supernova, Knapsack, zeroheight.
- **Not implementing:** Tamagui (custom config), many UIKit libraries, most older internal design systems.
- **File convention:** `.tokens.json` or `.tokens`, media type `application/design-tokens+json`.

## Our Existing Artifacts Compared

**`figma-extract` (v1.2.0)** — strengths: scaffolds `claude/knowledge/design-systems/{brand}-{version}/` with INDEX, GAPS, tailwind-config templates. Gaps:
1. Uses old Styles API (`/v1/files/:key/styles`), not Variables API
2. No DTCG output — emits ad-hoc markdown/JSON
3. No semantic layer — dumps hex values into one list
4. Uses `grep` on JSON (fragile — `jq` would be safer)
5. Tailwind-only output, no iOS/Android/RN/Tamagui targets

**`figma-diff`** — visual regression between PNG mockup and deployed URL. Complementary. Gap: no Chromatic-style per-component snapshot flow, no CI mode.

**`designsystem-add`** — scaffold only. Gap: template doesn't include `tokens.json` or Style Dictionary config.

## Recommended Architecture for the-agency

1. **Dual-path extraction in `figma-extract`:** try `/v1/files/:key/variables/local` first (Enterprise), fall back to Styles API + embedded-colors walk for non-Enterprise — **emit DTCG JSON** in both cases, not ad-hoc markdown. Use `jq` as hard dependency.
2. **Add `designsystem-build` tool:** runs Style Dictionary v4 over DTCG JSON and emits `dist/web/variables.css` (shadcn-compatible), `dist/web/tailwind.preset.ts`, `dist/native/tamagui.config.ts`, `dist/native/nativewind.css`. Each target opt-in via `agency.yaml`.
3. **Bake three-layer model into scaffold:** `designsystem-add` creates `tokens/primitive.tokens.json`, `tokens/semantic.tokens.json`, `tokens/component.tokens.json`, `tokens/themes/light.tokens.json`, `tokens/themes/dark.tokens.json`, plus `style-dictionary.config.ts`. Templates prefilled with common semantic names.
4. **Lightweight component mapping:** standardize on a `components.json` manifest listing `{ "Button": { "figmaNodeId": "123:456", "storybook": "stories/Button.stories.tsx" } }`. Add a `figma-components-check` tool that walks the manifest, verifies Storybook files exist, flags orphans.
5. **Evolve `figma-diff` → `visual-regression`:** add command taking a Storybook URL + components.json manifest, capturing per-component screenshots. Poor-man's Chromatic locally.
6. **Documentation updates:** rewrite `figma-workflow.md` leading with Variables + DTCG. Add `DTCG-PRIMER.md`.
7. **For monofolk:** standardize on **shadcn + Tailwind v4 for web** and **Tamagui for RN**, single DTCG source feeding both.

**Effort estimate:** DTCG-ification of `figma-extract` ~1-2 days. Style Dictionary wrapper ~1 day. Scaffold refresh ~half day. Components manifest + check tool ~1 day. **Total: ~1 week** of focused work.

## Sources

- [Design Tokens Specification Reaches First Stable Version (W3C DTCG, Oct 2025)](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/)
- [Design Tokens Format Module 2025.10](https://www.designtokens.org/tr/2025.10/format/)
- [Figma Variables REST API](https://developers.figma.com/docs/rest-api/variables/)
- [Style Dictionary v4 docs](https://styledictionary.com/)
- [Style Dictionary DTCG support](https://styledictionary.com/info/dtcg/)
- [Tokens Studio → Style Dictionary (SD Transforms)](https://docs.tokens.studio/transform-tokens/style-dictionary)
- [Always Twisted — Multi-Brand Theming with Style Dictionary](https://www.alwaystwisted.com/articles/a-design-tokens-workflow-part-9)
- [Token Press DTCG Exporter (Figma plugin)](https://www.figma.com/community/plugin/1560757977662930693/token-press-dtcg-exporter)
- [shadcn/ui Tailwind v4 docs](https://ui.shadcn.com/docs/tailwind-v4)
- [ForgeKit Figma MCP](https://github.com/the-single-gentlemans-club/forgekit-figma-mcp)
- [Tamagui Tokens docs](https://tamagui.dev/docs/core/tokens)
- [Specify — How to sync design tokens from Figma to React Native](https://specifyapp.com/blog/figma-to-react-native)
- [Chromatic Figma plugin (Storybook Connect)](https://www.chromatic.com/features/figma-plugin)
