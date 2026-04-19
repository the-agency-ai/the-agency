---
type: research-report
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
research_agent: agent-4-of-4 (React vs React Native platform split)
status: complete
part_of: Figma → UI research batch (2026-04-11)
---

# React vs React Native: Platform Differences for Figma-to-Code Workflows

Research Agent 4 of 4 · Focus: platform split · Date: 2026-04-11

## Summary

- **"React Native is not React for mobile."** It shares JSX and the React component model, but the rendering layer, styling system, layout engine, animation primitives, and accessibility API are all different. A component that renders correctly in a web React app will not compile in React Native at all, and vice versa. Figma-to-code tooling that treats them as one pipeline is almost always lying.
- **The single biggest platform split for Figma work is styling.** Web React has CSS, CSS-in-JS, Tailwind, CSS Grid, container queries, pseudo-classes, media queries, and the full cascade. React Native has a subset of flexbox, a `StyleSheet` object, no cascade, no Grid, no pseudo-classes, and no media queries. Every Figma token system has to be emitted twice or emitted through a universal shim (Tamagui, NativeWind, RN-Reusables).
- **Universal apps are viable in 2026 but not free.** Expo Router, React Native Web, and Tamagui/NativeWind make "one codebase, three platforms" a real option for the first time — at the cost of living in an opinionated framework and accepting that ~20% of each screen will need platform-specific branches. If the team wants pixel-perfect results on all three surfaces they still ship three implementations.
- **Figma file structure must be decided upfront.** The question is not "can we reuse components" — the question is "are we designing one product that renders everywhere, or two products that share a brand?"
- **The-agency's current UI knowledge is web-only.** `figma-workflow.md`, the `tailwind-config.md` emitter in `figma-extract`, and the `ux-dev` agent template all assume Tailwind-on-web. There is no React Native codepath, no mention of `StyleSheet`, `View/Text`, `Dimensions`, density variants, or `accessibilityRole`. This is a gap to close before monofolk needs it.

## Platform Differences That Matter for Figma → Code

| Concern | React (web) | React Native (iOS + Android) | Figma-workflow impact |
|---|---|---|---|
| **Primitives** | `div`, `span`, `img`, `button`, `a`, `input`, `p`, `h1..h6` — semantic HTML | `View`, `Text`, `Image`, `Pressable`, `TextInput`, `ScrollView`, `FlatList` — no semantic layer | All text in RN **must** be wrapped in `<Text>`. A Figma "card with title + subtitle" becomes `<View><Text/><Text/></View>`. Code extractors that emit HTML tags are useless for RN. |
| **Layout** | Flexbox, CSS Grid, `position: sticky`, `display: block/inline/table`, container queries | **Flexbox only** (Yoga engine). No Grid, no `block`, no `inline`, default `flexDirection` is `column` (web default is `row`) | Figma auto-layout maps cleanly to RN Flex. Figma frames that rely on Grid (most complex marketing pages) have no direct RN equivalent. |
| **Styling** | CSS, Tailwind, CSS-in-JS, CSS variables, cascade, pseudo-classes | `StyleSheet.create`, inline style objects, no cascade, no `:hover`/`:focus` classes (state is a prop), no CSS variables (themes are React context) | Tokens extracted from Figma must be emitted in two forms: CSS variables + Tailwind for web; a JS theme object (or NativeWind config) for RN. `figma-extract` currently emits only the first. |
| **Typography** | System + `@font-face`, `rem`/`em`, `line-height: 1.5`, user zoom | Fonts loaded via `expo-font`, `lineHeight` is always pixels (not unitless), iOS Dynamic Type + Android font scale | Line-height in Figma is usually a pixel value — port directly to RN, divide by font-size for web. RN apps must test with OS font scaling at 200%. |
| **Responsive** | Media queries, `vw`/`vh`, container queries, fluid layouts | `Dimensions.get('window')`, `useWindowDimensions()`, `Platform.select()`, `PixelRatio`. No viewport unit. | A Figma file with `sm/md/lg` breakpoints translates trivially on web and not at all on RN. |
| **Motion** | CSS transitions/animations, Framer Motion | **Reanimated 3/4** (worklets on UI thread), **Moti** (declarative Framer-like API), LayoutAnimation (legacy) | Figma Smart Animate maps poorly to both. Reanimated's spring is not the same curve as CSS `ease-out`. Reanimated 4 requires New Architecture. |
| **Accessibility** | ARIA roles, `tabindex`, semantic HTML | `accessibilityRole`, `accessibilityLabel`, `accessibilityHint`, `accessibilityState`, `accessible={true}` | No `role="button"` in RN — it's `accessibilityRole="button"`. Focus order is also different: RN has no tab key by default. |
| **Images** | `<img src>`, SVG inline or via sprite, `srcset`/`<picture>` for DPR, WebP/AVIF | `<Image source={require(...)}>` with `@1x/@2x/@3x` filename variants auto-selected, SVG via `react-native-svg`, WebP supported but not universal on Android | Figma exports need density variants for RN. Web needs one WebP + one fallback. `figma-extract` has no `assets.md` filler — gap. |
| **Interaction state** | `:hover`, `:focus`, `:active`, `:focus-visible` via CSS | No hover on touch. Pressed state via `Pressable`'s render prop. | Designers who spec hover states for a mobile app are specifying something that does not exist. |

## React Component Libraries — 2026 Landscape

**The center of gravity is shadcn/ui + Radix + Tailwind.** Default starting point for new React web apps in 2026. Copy-paste, not an npm dependency.

| Library | Figma story | Notes |
|---|---|---|
| **shadcn/ui** (Radix + Tailwind) | Multiple community Figma UI kits. No official first-party kit. | Default choice. Owned source, maximum flexibility for token work. |
| **Radix UI Primitives** | No Figma kit — primitives are unstyled | Underneath shadcn/ui. Headless. |
| **MUI (Material UI)** | **Official Material Design Figma kit** maintained by Google + MUI. Closest to Figma↔code parity. | Heavy, opinionated. Good when brand is Material. |
| **Chakra UI v3** | Community Figma kits | Solid DX, less dominant in 2026. |
| **Mantine** | Community kits | Batteries-included, strong forms/hooks story. |
| **Park UI** | Figma kit available | Built on Ark UI + styling engine of choice. shadcn-adjacent. |

**For Figma-driven work ranking:** (1) MUI if brand is Material and first-party parity matters, (2) shadcn/ui otherwise.

## React Native Component Libraries — 2026 Landscape

| Library | Model | Web support | Figma story |
|---|---|---|---|
| **NativeWind** (v4) | Tailwind compiled for RN's `StyleSheet` | Yes, via RN Web | No native Figma kit, but reuses massive Tailwind Figma ecosystem. **~403k weekly downloads — the clear leader**. |
| **Tamagui** | Compile-time atomic CSS extraction, universal from day one | Yes, first-class | Tamagui Studio for themes; no Figma kit per se. Strongest universal story. ~75k weekly downloads. |
| **React Native Reusables (rnr)** | shadcn/ui ported to RN, NativeWind v4 under the hood, copy-paste | Now building universal web support | Closest thing to "shadcn for RN + web." |
| **Gluestack UI** (v2) | Universal, now supports NativeWind v4 | Yes | Component-heavy, opinionated. |
| **React Native Paper** | Material Design for RN | Partial | Good for Material on both platforms. |
| **Dripsy** | Theme UI for RN, responsive style props | Yes | Smaller community. |
| **RN Elements** | Classic cross-platform component kit | Limited | Legacy. |

**The real 2026 question is styling engine:** NativeWind (familiar Tailwind mental model, huge adoption) or Tamagui (compiler-optimized, universal-first, steeper learning curve). Everything else is a component layer on top of one of these two.

## Universal Apps — Three Viable Stacks in 2026

1. **Expo + Expo Router + React Native Web + NativeWind + RN-Reusables.** Most common path. Expo Router provides file-based routing with shared screens, SplitView for tablet, SSR/static rendering for web. **Recommended for monofolk.**
2. **Tamagui + Expo Router (or Next.js + Solito).** Fastest universal story, genuinely optimized CSS on web while using RN primitives on native. Better performance, smaller community, harder onboarding.
3. **Next.js + React Native Web + Solito.** Older pattern, fading.

**What "universal" buys you:** shared routing, shared components for ~80% of UI, shared state, shared business logic, shared design tokens.
**What it doesn't:** pixel-perfect parity. Every non-trivial universal app has a `.native.tsx` / `.web.tsx` split somewhere.

## Figma File Structure for Multi-Platform Projects

Three patterns in use:

1. **One file, platform variants on components.** A `Button` has `platform=web/ios/android` variants. Works for atomic components. Breaks at screen level.
2. **One file, separate page per platform.** Design system page is shared. Each feature has Web and Mobile pages. Most common pragmatic choice.
3. **Separate files per platform, shared library.** Library file holds tokens + atomic components. Web and Mobile are separate files consuming the library. Best for teams where web and mobile are different designers.

**Decision heuristic:** if designers expect pixel parity across platforms, use pattern 1 or 2. If platforms have genuinely different IA (iOS sheets + tab bars vs web sidebars + modals), use pattern 3. Most production mobile-first companies end up on pattern 3.

## Existing Artifacts Review — RN Awareness Audit

| Artifact | Path | RN awareness |
|---|---|---|
| Figma workflow guide | `/Users/jdm/code/the-agency/claude/knowledge/ui-development/figma-workflow.md` | **Web-only.** References Tailwind, `md:`/`lg:` breakpoints, `hover:`, semantic HTML, `role=`, desktop browser screenshots. Zero RN content. |
| Design system example | `/Users/jdm/code/the-agency/claude/knowledge/design-systems/ordinaryfolk-003/` | **Web-only.** Emits `tailwind-config.md`. No RN theme object, no `@1x/@2x/@3x` asset story, no `StyleSheet` export. |
| Figma extractor | `/Users/jdm/code/the-agency/agency/tools/figma-extract` | **Web-only.** Generates Tailwind config. No RN theme emit option. |
| UX-dev agent template | `/Users/jdm/code/the-agency/agency/agents/templates/ux-dev/agent.md` | **Platform-agnostic in language, web-only in practice.** No RN toolchain, no Expo/Metro, no simulator awareness. |

**Nothing in the-agency is currently RN-aware.** Not a bug — framework has focused on web — but monofolk is explicitly multi-platform and will need this soon.

## Recommended Approach for the-agency's Multi-Platform Story

1. **Split the Figma workflow guide.** Rename existing → `figma-workflow-web.md`, add `figma-workflow-rn.md`, create `figma-workflow-universal.md` router, put shared concepts in `figma-workflow-shared.md`.
2. **Teach `figma-extract` to emit RN theme.** Add `--target=web|rn|universal`. For `rn`, emit TypeScript theme object consumable by NativeWind or plain JS theme. For `universal`, emit both + token mapping doc. Line-heights as pixels for RN.
3. **Add asset density variants.** Export images at `@1x/@2x/@3x` for RN. SVG + WebP + fallback for web.
4. **Fork `ux-dev` agent template into three:** `ux-dev-web`, `ux-dev-rn`, `ux-dev-universal`. Each with platform-specific knowledge directory and tool list.
5. **Pick one universal stack as the-agency's default:** **Expo Router + NativeWind + React Native Reusables (rnr)**. Rationale: reuses shadcn/Tailwind mental model; RN-Reusables becoming universal; NativeWind has biggest community; Expo Router is dominant universal framework. Document Tamagui as alternative for teams prioritizing runtime performance over familiarity.
6. **Do NOT try to auto-convert web components to RN.** Correct mental model: **tokens are shared, components are reimplemented, screens are reimplemented.** Shared artifact is the token layer, not the component layer.
7. **Document Figma file structure decision** — short decision doc walking teams through choosing one of the three patterns.

## Sources

- [React Native Reusables (founded-labs)](https://github.com/founded-labs/react-native-reusables)
- [React Native Reusables docs](https://reactnativereusables.com/)
- [NativeWind vs Tamagui vs twrnc: RN Styling in 2026](https://www.pkgpulse.com/blog/nativewind-vs-tamagui-vs-twrnc-react-native-styling-2026)
- [Best React Native UI libraries 2026 — LogRocket](https://blog.logrocket.com/best-react-native-ui-component-libraries/)
- [Tamagui benchmarks](https://tamagui.dev/docs/intro/benchmarks)
- [Expo Router introduction](https://docs.expo.dev/router/introduction/)
- [Expo develop for web](https://docs.expo.dev/workflow/web/)
- [Building Universal Apps in React Native — ZET Engineering](https://zetapp.medium.com/building-universal-apps-in-react-native-part-1-design-system-243749fbab72)
- [Moti animation library](https://moti.fyi/)
- [React Native Reanimated docs](https://docs.swmansion.com/react-native-reanimated/)
- [RN accessibility — Accessibility props](https://reactnative.dev/docs/accessibility)
- [RN StyleSheet API](https://reactnative.dev/docs/stylesheet)
- [RN Image asset density](https://reactnative.dev/docs/images#static-image-resources)
