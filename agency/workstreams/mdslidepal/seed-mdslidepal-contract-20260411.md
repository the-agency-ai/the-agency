---
type: seed
workstream: mdslidepal
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: contract-v1.3-approved
version: 0.1.0
license: Reference Source License (RSL)
mar_applied:
  - agent-1-technical-correctness: 2026-04-11 (autonomous triage, applied)
  - agent-2-completeness-ambiguity: 2026-04-11 (autonomous triage, applied)
  - agent-3-scope-realism: 2026-04-11 (autonomous triage, applied)
  - agent-4-divergence-risk: 2026-04-11 (autonomous triage, applied)
reconciliation:
  - decision-1-fixture-08-strictness: B (50-line regex pre-processor in web Iteration 1)
  - decision-2-license: RSL (matches mdpal-app, mock-and-mark precedent)
  - decision-3-file-layout: workstream for coordination, apps/ for source trees
  - decision-4-mac-cli: A (GUI only for MVP, CLI binary deferred to Phase 2)
---

**CONTRACT v1.3 — Post-Reconciliation (2026-04-11)**

Four reconciliation decisions baked in (see frontmatter + the "Reconciled Decisions" section below). License shifted from MIT (v1.2) to RSL (v1.3) to match the app-workstream precedent. Source trees now explicitly live under `apps/mdslidepal-web/` and `apps/mdslidepal-mac/`; this workstream directory holds coordination artifacts only.

---

## Reconciled Decisions (post-MAR, 2026-04-11)

Captain spun two planning agents (mdslidepal-web, mdslidepal-mac) against contract v1.2. Both plans returned. Four decisions were flagged as collaborative and resolved 1B1 with the principal.

### Decision 1 — Fixture 08 strictness for web Iteration 1: **B**

reveal.js's native markdown plugin uses a regex splitter, not AST-based detection. This creates a contract-compliance gap for fixture 08's strict edge cases (two adjacent `---` = one empty slide; trailing `---` doesn't create phantom slide).

**Resolution:** web Iteration 1 implements a ~50-line regex pre-processor that runs BEFORE reveal.js sees the content. It collapses `---\n\n---` sequences and strips trailing `---` lines. This closes the fixture 08 gap without pulling in `remark`. ~30 minutes of Saturday work. Web and Mac reconcile cleanly on fixture 08 with no known divergence at Iteration 1.

### Decision 2 — License: **RSL**

Contract v1.2 had MIT. After 1B1 review, switched to **Reference Source License (RSL)** to match existing app-workstream precedent (`mdpal-app`, `mock-and-mark`). mdslidepal is categorically an app, not a framework tool.

### Decision 3 — File layout: **workstream + apps/ split**

Two different concepts, not a choice between alternatives:

- **Workstream** (`claude/workstreams/mdslidepal/`) = **how we manage things** — contract, shared themes, fixtures, plan-b safety net, plans, reconciliation receipts, decisions. This is the coordination locus.
- **Source trees** (`apps/mdslidepal-web/`, `apps/mdslidepal-mac/`) = **where we put the code** — actual implementations, each with its own `package.json` / `Package.swift`, build configs, and local `claude/` agency configuration. This matches the existing `apps/mdpal-app/` precedent.

A workstream and a source tree can share a name (`mdslidepal` workstream ↔ `apps/mdslidepal-*/` sources) but they are different kinds of things. One is management; the other is code.

### Decision 4 — Mac CLI: **A (GUI only for MVP)**

mdslidepal-mac ships as a single `.app` bundle for MVP. No companion CLI binary. Users interact via menus, file-open dialogs, keyboard shortcuts. A CLI binary is a reasonable Phase 2 addition (~1-2 days of Swift work + a menu item for "Install CLI tool") but not required for MVP.

---



This version incorporates findings from all four MAR agents (technical correctness, completeness/ambiguity, scope realism, divergence risk). All findings triaged autonomously — conservative defaults applied everywhere. Changes since v1.0:

- **Scope for web MVP explicitly reduced** (Agent 3) — one theme, reveal.js native markdown plugin (no custom parser), `serve` only, no front-matter, no per-slide metadata, no custom speaker notes syntax, offline-first, `file://` fallback, Plan B safety net
- **Theme definition moved to shared JSON files** (Agents 2, 4) — `themes/agency-default.json` and `themes/agency-dark.json` with schema at `themes/theme-schema.json`. Both implementations consume these files as the single source of truth. Each platform implements a loader that maps JSON schema to native rendering primitives. This collapses the largest divergence risk.
- **Slide aspect ratio pinned to 16:9** (Agents 2, 4) — logical dimensions 1920×1080, specified in theme files, enforced at renderer level
- **Slide overflow policy specified** (Agent 2) — auto-scale if <20% overflow, vertical scroll in present mode otherwise, no pagination
- **Error handling section added** (Agent 2) — all error classes enumerated with required behaviors
- **Front-matter disambiguation rule** (Agent 1) — front-matter MUST be at offset 0 of file; `---` anywhere else is a slide break
- **Speaker notes aligned to reveal.js** (Agent 1) — use reveal.js native `Notes:` marker (web gets free via reveal.js markdown plugin; Mac implements the same convention)
- **Mac parser specified** (Agent 1) — `swift-markdown` (Apple, cmark-gfm-backed). Ink and MarkdownUI explicitly disqualified
- **Mac syntax highlighter specified** (Agent 1) — HighlightSwift (active SwiftUI-native). Highlightr explicitly disqualified
- **Fixture corpus requirement** (Agents 2, 4) — 8 canonical `.md` fixtures committed to `fixtures/` as acceptance tests
- **Reconciliation protocol with visual diff** (Agent 4) — captain runs both implementations on fixtures, compares output, identifies divergences
- **Version and license added** (Agent 2) — MVP ships as 0.1.0, MIT license
- **"Platform-appropriate" escape hatch tightened** (Agent 4) — replaced with "visually equivalent within theme tolerance"
- **Per-slide metadata grammar pinned** (Agents 2, 4) — YAML 1.2 block style, standard library parser (Mac only; web MVP defers this feature)
- **Mid-slide metadata blocks defined** (Agent 2) — only recognized when first non-whitespace after slide break, ignored elsewhere
- **Slide break edge cases specified** (Agents 2, 4) — boundary detection on the AST post-parse, thematic breaks inside code/lists/blockquotes are NOT slide breaks
- **SwiftUI + AppKit interop noted** (Agent 1) — presenter mode and multi-display window management MAY require AppKit interop; this is expected SwiftUI-first idiom
- **Slidev noted as post-Monday alternative** (Agent 1) — reveal.js chosen for Monday deadline but Slidev is re-evaluable Phase 2
- **GFM extension mandatory** (Agent 1) — plain CommonMark-only parsers are disqualified
- **Layout property deferred** (Agents 2, 4) — `layout:` field deferred to Phase 2 entirely; MVP has no slide layouts beyond "default"

See each section below for the applied fixes. Finding numbers reference the MAR agent reports saved at:
- `claude/workstreams/agency/seeds/research-figma-*-20260411.md` (Figma research, unrelated)
- MAR reports are captured inline in this spec via the `mar_applied` frontmatter above.

# Seed: mdslidepal — Shared Contract Spec

## Purpose

This is the **shared contract** that both the web agent (mdslidepal-web) and the Mac agent (mdslidepal-mac) must honor when planning and building mdslidepal. It exists to prevent divergence between the two implementations: both agents consume the same input, interpret it the same way, and produce conceptually-equivalent slides on their respective platforms. The contract is deliberately minimal — it constrains the input and the user-facing commands, not the implementation.

The name is **mdslidepal** (following the `mdpal` / "pal" suffix convention).

## Problem mdslidepal solves

Jordan needs a markdown-first slide tool for the-agency workshops (first workshop: Republic Polytechnic, Monday 13 April 2026) and for ongoing presentation work. Existing slide tools either require GUI authoring (Keynote, PowerPoint), run only in browsers with kitschy themes (reveal.js raw), or lock content into proprietary formats (Pitch). None are "write markdown, get a real slide deck, use on every platform."

mdslidepal is that tool. Primary use cases:
1. **Workshop presentation** — deliver slides to a live audience from a markdown file
2. **Deck drafting** — write content in any editor, preview and iterate fast
3. **Handoff-friendly** — the source is plain markdown, version-controllable, diffable, readable
4. **Cross-platform** — use the web version in a browser, use the Mac version as a native app

## Why both web and Mac?

Different use cases, different strengths:
- **Web** is deployable anywhere, works from any device, is the only viable MVP for the Monday workshop deadline, and can be served from the workshop VM if needed
- **Mac native** is the proper authoring environment — tighter integration with local files, presenter view with multi-display support, offline-first, no browser quirks, first-class export

Both must be able to consume the same markdown source and produce visually-equivalent output so a deck authored anywhere renders anywhere.

## The contract — the hard constraints

### 1. Input format

**File format:** `.md` (plain markdown). A single file per deck for MVP. Directory-of-files loaders are Phase 2.

**Markdown dialect:** CommonMark + GFM. GFM extension is **mandatory** — plain CommonMark-only parsers are disqualified. Required GFM features: tables, task lists (`- [ ]` / `- [x]`), strikethrough (`~~text~~`), autolinks, fenced code blocks with language info strings.

**Web parser:** `unified`/`remark` + `remark-gfm` + `remark-frontmatter`. AST-based approach is strongly preferred because slide splitting and notes extraction are AST transforms. (Web MVP uses reveal.js's native markdown plugin — see mdslidepal-web scope — which handles these internally. Full `unified/remark` pipeline is Phase 2 for web.)

**Mac parser:** `swift-markdown` (Apple, `swiftlang/swift-markdown`, cmark-gfm-backed). This is the only acceptable choice. Ink (`JohnSundell/Ink`) is stagnant and disqualified. MarkdownUI (`gonzalezreal/swift-markdown-ui`) is a renderer not a parser and is in maintenance mode — do not use.

**YAML front-matter for document-level metadata** — parsed before any slide content:

```yaml
---
title: "Workshop Day 1"
author: "Jordan Dea-Mattson"
theme: "agency-default"   # name of a theme file in themes/
date: "2026-04-13"
---
```

**Front-matter disambiguation rule (critical):** YAML front-matter MUST begin at offset 0 of the file (no leading whitespace or BOM) and is terminated by the first `---` line after at least one YAML key. Any subsequent `---` on its own line is a slide break. A document with no leading `---` at offset 0 has no front-matter; a `---` on line 1 starts front-matter, not a slide. This matches Marp, Slidev, Jekyll, Hugo, and gray-matter conventions.

Required fields: none (all optional).
Reserved fields (agents must honor if present): `title`, `author`, `theme`, `date`, `description`, `footer`.
Custom fields: exposed to the theme engine as a `meta` dictionary; MVP themes do NOT use custom fields.

**Note:** mdslidepal-web MVP defers YAML front-matter parsing entirely — hardcoded title or first-H1 is acceptable for web MVP. Full front-matter support is Phase 2 for web. Mac honors the full spec from MVP.

### 2. Slide boundaries

**Primary slide break:** `---` on its own line (three hyphens, nothing else on the line, with blank lines before and after). This matches reveal.js's `data-separator` default regex.

**AST-based detection (critical):** slide boundary detection runs **after** markdown parsing, on the AST — a `ThematicBreak` node at the document top level is a slide break. Thematic breaks inside code blocks, lists, block quotes, or HTML blocks are **NOT** slide breaks. This prevents ambiguity with `---` appearing inside fenced code or indented lists.

**Empty and degenerate inputs:**

- **Empty file** or **front-matter-only file** → render a single placeholder slide with the title from front-matter (or "Untitled") and nothing else
- **A lone `---`** on its own → one empty slide (explicit section divider)
- **Two adjacent `---`** (`---` immediately followed by `---`) → one empty slide (NOT two empty slides)
- **Trailing `---`** after all content → does NOT create a phantom empty final slide (trailing separator is absorbed)

**Secondary slide break (optional mode, Phase 2):** a level-1 heading (`# `) may start a new slide if the author enables `auto_break_on_h1: true` in the front-matter. Default is `false`. **MVP defers this mode entirely** — both web and Mac MVP honor only `---` as slide breaks. Phase 2 adds auto_break_on_h1.

**Front-matter vs slide-break interaction:** when front-matter is present, the terminating `---` of the front-matter block is NOT a slide break. The first `---` on its own line AFTER the front-matter is the first slide break (if any).

### 3. Per-slide metadata

Inline HTML comment blocks immediately after a slide break provide slide-level metadata:

```markdown
---
<!-- slide:
  background: "#0a0a0a"
  transition: fade
-->

# Welcome to the Workshop

Jordan Dea-Mattson · 13 April 2026
```

**Location rule:** A `<!-- slide: ... -->` block is only recognized when it is the first non-whitespace content after a slide break. Any occurrence elsewhere in the slide is ignored (treated as a plain HTML comment and not rendered).

**Grammar:** The body of `<!-- slide: ... -->` is YAML 1.2 block style, parsed with a conformant YAML library. Flow style, anchors, and merge keys are NOT required to be supported. Keys are the reserved set below plus theme pass-throughs.

**Reserved slide-level fields for MVP:** `background`, `transition`, `class`.

Fields explicitly **deferred to Phase 2**:
- `layout` — slide layouts are Phase 2. MVP has no layouts beyond "default."
- `notes_file` — external notes file loading is Phase 2

**Transition values:** `none` (default) or `fade` (250ms linear opacity cross-fade of the entire slide content region, background unchanged). Unknown transition values warn and fall back to `none`.

**Note:** mdslidepal-web MVP defers per-slide metadata parsing entirely. Phase 2 for web brings it to parity with Mac. Mac honors this from MVP.

### 4. Speaker notes

Speaker notes use the **reveal.js bare marker convention** so the web implementation gets them for free from the reveal.js markdown plugin:

```markdown
## Key point

Some content for the audience.

Notes:
These are speaker notes only visible in presenter mode.
They can span multiple lines and include **markdown**.
```

The marker is a line starting with `Note:` or `Notes:` (case-insensitive). Everything from the marker line through the end of the slide is the speaker notes block.

**Rendering rules:**
- Speaker notes are rendered as markdown (CommonMark + GFM) in the presenter view
- Speaker notes are NEVER rendered in the main slide view under any circumstances
- Notes may include markdown formatting including code blocks, lists, and links

Both agents MUST parse `Notes:` markers and make them available in presenter/speaker mode. Divergence from reveal.js's native marker is explicitly avoided to eliminate an integration gap for the web agent.

**Note:** mdslidepal-web MVP defers speaker notes (and presenter mode) entirely. The conservative default assumes a single-display setup at Republic Polytechnic on Monday. If dual display is confirmed pre-workshop, the web agent may implement reveal.js's native speaker view on top — it's free from reveal.js. Mac implements speaker notes from MVP (Phase 3 of the Mac plan, per the mdslidepal-mac phases).

### 5. Images and media

**Local paths** resolve relative to the source `.md` file. Both agents must handle `![alt](path/to/image.png)` identically.

**Remote URLs** (http/https) are loaded directly. No caching mandated.

**Video and audio** via HTML tags are supported on web; Mac agent treats them as "render-if-possible, graceful degradation if not" for Phase 1.

### 6. Code blocks

Fenced code blocks with language identifiers (` ```python `, ` ```bash `, ` ```swift `) must be syntax-highlighted. Web: Shiki or Prism. Mac: native text attributes with a tokenizer library. Both should recognize at minimum: bash, javascript, typescript, python, swift, go, rust, markdown, json, yaml, html, css.

### 7. Command surface

Both platforms expose the same top-level commands, even if the implementation differs:

| Command | Purpose | Web (CLI) | Mac (app) |
|---|---|---|---|
| `render` | Parse input, produce output | `mdslidepal render input.md --output out.html` | Menu: File → Export → HTML |
| `present` | Start a live presentation from input | `mdslidepal serve input.md` (opens browser) | Menu: File → Present (or ⌘P) |
| `export` | Convert to static format | `mdslidepal export input.md --format pdf` | Menu: File → Export → PDF |

Web's primary user interface is the CLI + a local dev server. Mac's primary user interface is the app window with a sidebar of slides and a main preview area.

### 8. Output format

**Web MVP output:** a self-contained HTML file (or a small directory with HTML + CSS + JS) that runs offline in any modern browser. The HTML file must include all styles inline or as linked CSS in the same directory. Suitable for serving from Vercel, a static host, or `file://`.

**Mac MVP output:** a native window renderer using SwiftUI (2026 default) with proper display support, keyboard navigation, and presenter mode on an external display. Mac agent should NOT try to build a web view wrapping reveal.js — the Mac version is a first-class native implementation.

**Both must export to PDF** as a Phase 2 target (stretch for MVP).

### 9. Themes

**Themes are shared JSON files at the workstream level:**

- `claude/workstreams/mdslidepal/themes/agency-default.json` (light theme)
- `claude/workstreams/mdslidepal/themes/agency-dark.json` (dark theme)
- `claude/workstreams/mdslidepal/themes/theme-schema.json` (JSON Schema for validation)

Both implementations MUST load and honor these files. Each platform implements a theme loader that maps the JSON schema to its native rendering primitives (CSS variables on web, SwiftUI environment values or token structs on Mac). The theme files are the single source of truth; theme file changes are workstream-level, not platform-level.

**What the theme defines:** colors (background, foreground, accent, muted, subtle, border, link, code_background, code_border), fonts (sans_family, mono_family, display_family), heading_scale (h1-h6 sizes in logical units), body_size, line_height, spacing_unit, slide_padding, code_theme (syntax highlight palette with 11 token types), transitions (default type, fade duration, easing).

**Aspect ratio:** 16:9 (fixed for MVP). Logical dimensions 1920×1080. Both implementations render into this logical box and scale uniformly to fit the rendering surface.

**Visual equivalence:** the two implementations must produce output that is **visually equivalent within the tolerances defined in the theme file**. This means:
- Identical slide count, slide order, text content
- Identical code block content (including which lines are highlighted)
- Identical speaker notes
- Identical theme colors (to JSON spec)
- Same aspect ratio
- Same font category (sans vs mono) — exact font metrics may differ between platforms

Platform-appropriate rendering (font antialiasing, native controls) may differ; theme-specified values may not.

**MVP scope:** only `agency-default` is required by web MVP. `agency-dark` is Phase 2 for web, MVP for Mac. Custom themes are Phase 2 for both.

### 10. Keyboard navigation (present/serve mode)

Both platforms must support the same keys in presentation mode:

- `ArrowRight` / `Space` / `n` → next slide
- `ArrowLeft` / `p` → previous slide
- `Home` → first slide
- `End` → last slide
- `Esc` → exit presentation mode
- `f` → toggle fullscreen (web) / enter full-screen (Mac)
- `s` → toggle speaker notes view (opens presenter window)
- `b` / `.` → black screen toggle
- `?` → show help overlay

### 11. Error handling

All errors produce a stderr/console warning (web) or a non-modal alert (Mac). No error aborts rendering unless the file is unparseable as markdown at all.

| Error class | Behavior |
|---|---|
| Invalid YAML front-matter | Warn; render without metadata (use defaults) |
| Unclosed speaker notes block | Treat notes as running to end of current slide; warn |
| Missing local image | Render placeholder box with alt text; warn |
| Unreachable remote URL (image/video) | Render placeholder with alt text; warn |
| Unknown code language identifier | Render as plain monospace; no warning (common case) |
| Malformed `<!-- slide: -->` YAML | Warn; skip the metadata block; render slide with defaults |
| File unparseable as markdown | Error dialog (Mac) or stderr + non-zero exit (web CLI); no rendering |
| Asset path with `..` segments escaping source dir | Warn; refuse to load; render placeholder |

**Slide overflow policy:** when slide content exceeds the logical viewport (1920×1080):
- If overflow is **less than 20%**, auto-scale the content uniformly to fit
- If overflow is **20% or greater**, allow vertical scroll within the slide during present mode (but NOT paginate and NOT crop)
- Both platforms MUST use the same policy

**Video and audio on Mac** (which the spec says "graceful-degrades"): when Mac cannot render a video or audio element, it renders a placeholder box with the media's poster image (if any) or a neutral "Media not available" label plus the alt/title text. Silent skip is forbidden.

### 12. Acceptance criteria

Both implementations are "done" (MVP Iteration 1) when they render every fixture in `claude/workstreams/mdslidepal/fixtures/` correctly.

The fixture corpus is:

| Fixture | Tests |
|---|---|
| `01-minimal.md` | Single slide, single H1, smoke test |
| `02-multi-slide.md` | Multiple slides separated by `---` |
| `03-code-blocks.md` | Fenced code blocks with syntax highlighting |
| `04-images.md` | Local image rendering |
| `05-tables-and-lists.md` | GFM tables, nested lists, task lists |
| `06-front-matter.md` | YAML front-matter at BOF (Mac only for MVP; web optional) |
| `07-speaker-notes.md` | Speaker notes in presenter view (Mac only for MVP) |
| `08-edge-cases.md` | Edge cases: `---` in code, empty slides, trailing separators |

**Captain is responsible for committing the fixture corpus** before either implementation agent starts. See the "Safety Net / Plan B" section below.

### 13. Reconciliation protocol (revised)

At reconciliation, captain:

1. Runs both implementations on every fixture in `fixtures/`
2. Produces PNG snapshots of each slide from each implementation
3. Compares snapshots at the specification level:
   - Slide count identical
   - Slide order identical
   - Text content semantically identical
   - Code block content identical
   - Speaker notes identical (presenter view)
   - Theme colors match JSON spec
4. Flags any divergences as reconciliation bugs to be fixed before merge
5. Documents the reconciliation in a receipt at `claude/workstreams/mdslidepal/reconciliation-{date}.md`

### 14. What mdslidepal is NOT responsible for

- **Text editing.** Authors use whatever editor they prefer; mdslidepal is a reader/renderer, not an authoring environment. The Mac app may include a simple live-preview pane, but it is not a markdown editor replacement.
- **Source control.** The source is a plain `.md` file; version control is the user's git, not our concern.
- **Real-time collaboration.** Phase 2+. MVP is single-author.
- **Charts and diagrams.** Phase 2. MVP users can embed images.
- **Animations between slides beyond simple transitions.** MVP has fade/none. Rich motion is Phase 2.
- **Webcam / screen sharing / live streaming.** Out of scope indefinitely. Use Zoom, OBS, etc.

## Non-goals for MVP (both platforms)

1. No plugin system
2. No theme marketplace
3. No cloud sync
4. No collaborative editing
5. No built-in diagrams (Mermaid, PlantUML) — Phase 2
6. No RTL or vertical text support — Phase 2
7. No internationalization of the UI — Phase 2 (content can be in any language; UI strings are English-only for MVP)

## mdpal integration — deferred

Jordan has been building **mdpal** — a section-oriented Markdown engine. mdslidepal could in principle leverage mdpal's parser or its section model. **For MVP, mdslidepal is standalone** — it uses its own parser on each platform. Phase 2 will evaluate whether mdslidepal should consume mdpal's AST or share its section model. Both agents should note this as "Phase 2 exploration" in their plans but NOT build the integration in MVP.

## Constraints for each agent's plan

### mdslidepal-web

- **Monday 13 April 2026 is a hard deadline.** Iteration 1 must produce a working "render markdown to a slide deck in a browser" MVP by **Saturday night** (not Sunday — Sunday is buffer for dry-run and recovery). The Republic Polytechnic workshop Monday morning is the forcing function.

#### MVP scope for web — what's IN (revised per MAR-3)

The web agent's Phase 1 is deliberately the smallest possible wrapper over reveal.js. Phase 1 includes ONLY:

1. **Reveal.js native markdown plugin** — do not write a custom markdown parser. Use reveal.js's `markdown` plugin which reads a markdown source file via `data-markdown` and uses `---` as slide breaks natively. This eliminates an entire class of parser bugs and GFM-compliance work.
2. **A thin CLI:** `mdslidepal serve <input.md>` — reads the markdown, produces a reveal.js-compatible HTML output in a temp directory or the same directory, starts a local dev server, opens the browser, done. That's it. No `render`, no `export`, no flags beyond `--port`.
3. **One theme:** a lightly-customized reveal.js theme (`agency-default`). No `agency-dark`.
4. **Fenced code blocks with syntax highlighting** — reveal.js ships with `highlight.js` built-in, free. Must support bash, javascript, typescript, python, swift, markdown, json, yaml, html, css at minimum.
5. **Local images** — reveal.js handles `<img src>` natively, no work required.
6. **Fullscreen + arrow/space/escape navigation** — reveal.js native, free.
7. **Black screen (`b`/`.`), help overlay (`?`)** — reveal.js native, free.
8. **`file://` fallback** — verify the generated HTML runs from `file://` with no local server. Republic Polytechnic wifi is unknown; the deck must work offline with zero network dependencies. **NO CDN dependencies** — reveal.js and highlight.js must be vendored locally.
9. **Offline-first by default** — all assets bundled, no CDN references anywhere in the output HTML.
10. **A sample workshop deck** — a real `sample-workshop.md` with the content shapes Jordan will actually use: headings, paragraphs, bulleted lists, fenced code blocks (bash + typescript), and at least one embedded local image. Used as the acceptance test.
11. **A Sunday-evening smoke test protocol** — a short checklist Jordan runs Sunday night to verify: `serve` starts, browser opens, arrow keys advance slides, code blocks highlight, images load, fullscreen works, reveal.js loads from `file://` if the server fails. Document this as `test-smoke-workshop.md` alongside the sample deck.

#### MVP scope for web — what's OUT (deferred to Phase 2+)

- `agency-dark` theme
- Custom markdown parser (use reveal.js native plugin instead)
- YAML front-matter parsing (hardcode title or take from first H1 for MVP)
- Per-slide `<!-- slide: ... -->` metadata blocks
- `<!-- notes: ... -->` speaker notes (requires dual display to be useful; assume single display at Republic Polytechnic for MVP)
- `render` CLI subcommand (just `serve`)
- `export` CLI subcommand
- PDF export (was "stretch"; now explicitly Phase 2)
- Vercel deployment validation (Jordan presents from laptop Monday)
- Per-slide transitions (`fade`, etc.) beyond reveal.js's default
- Theme customization beyond one light theme
- Auto-break on H1 mode
- Custom keyboard shortcuts beyond what reveal.js provides free

**The web MVP may defer any feature listed in the Phase 2+ section without violating this contract.** The Mac agent honors the full contract; the web agent honors the contract AS CONSTRAINED BY THIS SCOPE SECTION. Phase 2 of the web agent brings it to full contract parity with Mac.

#### Tech stack guidance for web

- **Node 20+ + TypeScript + pnpm** — consistent with the-agency framework conventions
- **No custom markdown parser** — reveal.js's native markdown plugin is the only acceptable choice for MVP
- **Vendored dependencies** — `npm install --save reveal.js`, bundle with the output, do not reference CDNs
- **Bin script** — a small `bin/mdslidepal.ts` that implements the `serve` command via a tiny static file server (`sirv` or raw `http.createServer`)
- **Source tree location:** `apps/mdslidepal-web/` (not inside the workstream — see Decision 3)

#### Fixture 08 strictness — required regex pre-processor (Decision 1)

Web Iteration 1 MUST include a small pre-parse step (estimated ~50 lines of TypeScript regex work) that runs on the raw markdown BEFORE handing it to reveal.js's native markdown plugin. The pre-processor:

1. **Collapses empty-slide sequences** — replaces `---\n\n---\n\n---` (three adjacent separators) with `---\n\n---` (two, producing one empty slide between them)
2. **Strips trailing separators** — removes any `---` line that appears at the end of the file after all content (prevents phantom trailing slide)
3. **Respects fenced code blocks** — must not touch `---` lines that appear inside `` ``` `` or `~~~` fences. Easiest approach: track fence state line-by-line during the pre-processing pass

This closes the fixture 08 gap that arises because reveal.js's native markdown plugin uses a regex splitter rather than AST walking. Without this pre-processor, web Iteration 1 would diverge from Mac on fixture 08 at reconciliation time.

The pre-processor does NOT replicate the full AST-based contract (that's Phase 2.1 via `remark`). It only fixes the two specific edge cases needed for fixture 08 compliance.

#### Post-Monday iterations for web (Phase 2 and later)

Phase 2 brings web agent to full contract parity with Mac:
- Custom markdown parser (if needed beyond reveal.js native plugin)
- YAML front-matter support
- Per-slide metadata blocks
- Speaker notes + presenter view (requires dual-display scenario)
- `render`, `export`, PDF export
- `agency-dark` theme and theme customization
- Directory-of-files loader
- Vercel deployment target

### Safety Net / Plan B — REQUIRED before agents start

Before either implementation agent begins its plan, the following must exist in the repo as an unconditional workshop fallback:

1. **`claude/workstreams/mdslidepal/plan-b/sample-workshop.md`** — a real sample workshop deck
2. **`claude/workstreams/mdslidepal/plan-b/reveal-js-template.html`** — a pre-built reveal.js HTML file with a `<section data-markdown>` block that loads `sample-workshop.md`. Vendored reveal.js in the same directory (no CDN).
3. **`claude/workstreams/mdslidepal/plan-b/README.md`** — one paragraph: "If mdslidepal-web is not working by Sunday night, open reveal-js-template.html in a browser. This is your workshop deck. Replace sample-workshop.md with your real workshop content."
4. **`claude/workstreams/mdslidepal/fixtures/`** — the canonical fixture corpus (8 `.md` files) required by the acceptance criteria section of this contract
5. **Marp CLI as second safety net** — Jordan installs `npm install -g @marp-team/marp-cli` on his laptop as a documented Plan C. If Plan B's reveal.js template fails for any reason, `marp` is a known-good one-command alternative.

This is **Plan B + Plan C**. Plan B takes ~15 minutes to set up. Plan C takes a one-line install. Together they eliminate the "what if everything breaks" risk for Monday, and give Jordan known-good fallbacks that don't depend on any agent work. The web agent's Iteration 1 can then iterate on top of Plan B, progressively replacing the raw template with the `mdslidepal serve` wrapper.

**Captain (me) is responsible for committing Plan B and the fixture corpus to the repo before either implementation agent starts.** This is not delegated.

### Notes on Slidev (Phase 2 web alternative)

reveal.js was chosen for the Monday deadline because its markdown plugin matches this spec's conventions out of the box and its runway of documentation is deepest. **Slidev** (`sli.dev`) is a credible 2026 alternative with better developer-conference polish, active maintenance by Anthony Fu, and strong code-walkthrough support. Post-Monday, the web agent may re-evaluate Slidev as the underlying engine for Phase 2. For MVP, reveal.js is locked.

### Required documentation deliverables

MVP deliverables include:
- `README.md` at each implementation root with install and usage
- `claude/workstreams/mdslidepal/USAGE.md` — shared user guide at the workstream level, consumed by both platforms
- Mac in-app help is Phase 2

### mdslidepal-mac

- **No Monday pressure.** Plan properly from the start.
- **SwiftUI as the primary UI framework.** SwiftUI-first is the 2026 default for new macOS apps. However, **presenter mode and multi-display window management MAY require NSViewRepresentable / NSWindow (AppKit) interop** — this is expected and not a deviation from SwiftUI-first; it is the idiomatic way to handle gaps SwiftUI has not yet filled on macOS (specifically: `fullScreenCover()` is unavailable on macOS; precise multi-screen targeting for audience-view vs presenter-view is still clunky in pure SwiftUI). Plan for the interop work in the presentation phase.
- **Swift Package Manager** for dependencies, no CocoaPods.
- **Target: macOS 14+ (Sonoma)** to leverage modern SwiftUI features.
- **Tech stack guidance:** single `.app` bundle, universal binary (x86_64 + arm64), signed and notarizable. Xcode project file or SPM-managed.
- **Markdown parser:** `swift-markdown` (`swiftlang/swift-markdown`) — Apple's cmark-gfm-backed library. This is the only acceptable choice. Do NOT use Ink (stagnant). Do NOT use MarkdownUI (maintenance mode, not a parser).
- **Syntax highlighter:** HighlightSwift (`appstefan/HighlightSwift`) — actively-maintained SwiftUI-native highlighter. Do NOT use Highlightr (no longer maintained in 2026). Splash (John Sundell, Swift-only) is acceptable only for Swift-language code blocks but is insufficient for a workshop deck that needs bash, typescript, python, etc.
- **Theme loader:** consume `claude/workstreams/mdslidepal/themes/{name}.json` as source of truth; map to SwiftUI environment values or equivalent token struct.
- **Real native feel:** menu bar, keyboard shortcuts, window management, presenter mode with multi-display awareness. This is not a web-view wrapper.
- **Source tree location:** `apps/mdslidepal-mac/` (not inside the workstream — see Decision 3). Standard SPM layout matching `apps/mdpal-app/` precedent: `Package.swift`, `Sources/`, `Tests/`, local `claude/` for agency config.
- **GUI only for MVP (Decision 4):** mdslidepal-mac ships as a single `.app` bundle. No companion CLI binary. CLI target is Phase 2 work (~1-2 days) and is NOT in scope for MVP.
- **Phases likely:** (1) core renderer + slide model + theme loader, (2) window and file-load UI, (3) presentation/presenter mode (with AppKit interop for multi-display), (4) PDF export, (5) additional themes + Phase 2 contract parity items.

## Required deliverables from each agent

Each agent should produce a **plan document** following the agency's PVR/A&D/Plan pattern:

1. **Short PVR** (Problem, Vision, Requirements) — maybe 1 page, extending this contract with platform-specific requirements
2. **A&D** (Architecture & Design) — key technical decisions, tech stack, dependencies, library choices, file layout
3. **Plan** — phases and iterations with deliverables, with Iteration 1 of mdslidepal-web explicitly targeting the Monday deadline
4. **Open questions** — anything the agent can't resolve without Jordan's input

Save the deliverables at:
- `claude/workstreams/mdslidepal/plan-mdslidepal-web-20260411.md`
- `claude/workstreams/mdslidepal/plan-mdslidepal-mac-20260411.md`

## What the agents should NOT do

- Do NOT start building code. This is planning only.
- Do NOT deviate from the contract above. If you think the contract is wrong, flag it in "Open questions" — don't silently redefine.
- Do NOT duplicate work with the other agent. Each owns its platform; the contract is the seam.
- Do NOT invent their own name for the product. It is **mdslidepal**.

## Reconciliation protocol

Captain (me) will reconcile both plans when they return:
1. Verify contract compliance on both sides
2. Surface any conflicts (tech assumptions, timeline assumptions, integration assumptions)
3. Merge into a single coherent project plan
4. Present for Jordan's approval
5. Execute — web agent hits Monday MVP first, Mac agent proceeds at proper pace

## Contract version

**v1.0 — 2026-04-11.** This contract is the seed that each agent's plan extends. If either agent proposes a change to the contract, it must be surfaced in their "Open questions" and approved by captain before implementation.
