---
type: plan
workstream: mdslidepal
platform: web
date: 2026-04-11
author: the-agency/jordan/mdslidepal-web
principal: jordan
status: draft-v1
version: 0.1.0
license: MIT
contract_version: v1.2
---

# mdslidepal-web — PVR + A&D + Plan

**Hard deadline:** Saturday 2026-04-11 night (MVP ready) → Sunday dry-run buffer → **Monday 2026-04-13 09:00 Republic Polytechnic workshop.**

This plan extends the shared contract at `agency/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` (v1.2). Every constraint cited here references a contract section by number. It is deliberately the smallest possible wrapper over the already-vendored Plan B template in `agency/workstreams/mdslidepal/plan-b/`.

---

## 1. PVR — Product Vision & Requirements

### Problem (web-scoped)

Jordan needs to deliver a slide deck to a live audience Monday morning from a plain markdown file, from his laptop, with zero network dependencies, on the first hostile wifi he encounters. Plan B (the raw reveal.js template) already works for that. What Plan B lacks is the ergonomics of the-agency tooling: a CLI, a dev server with live reload-ish refresh, a theme loader tied to the shared `themes/agency-default.json`, and a repeatable acceptance harness against the 8 fixtures. mdslidepal-web wraps Plan B in those ergonomics without replacing it.

### Vision

One command: `mdslidepal serve sample-workshop.md`. The CLI reads the markdown, emits a self-contained output directory (HTML + vendored reveal.js + theme CSS + the source markdown), starts a tiny local HTTP server, and opens the browser. Presses `f`, arrows navigate, `?` for help, `Esc` to exit. Works on `file://` if the server dies. Works with no network. The output directory IS the artifact — Jordan can zip it, email it, open the HTML directly, or throw it on a USB key.

### Requirements

**Functional (Iteration 1 — MVP):**

| # | Requirement | Contract ref |
|---|---|---|
| F1 | `mdslidepal serve <input.md>` reads the markdown file, emits an output directory, starts a local HTTP server, opens the browser | §7, §mdslidepal-web |
| F2 | Slide breaks via `---` on its own line (reveal.js native regex `^\r?\n---\r?\n$`) | §2 |
| F3 | CommonMark + GFM rendering via reveal.js's native markdown plugin (`RevealMarkdown`) — no custom parser | §1, §mdslidepal-web |
| F4 | Syntax highlighting for bash, typescript, python, swift, json, yaml, html, css, markdown via reveal.js's built-in `RevealHighlight` (highlight.js) | §6 |
| F5 | Local image resolution relative to the source `.md` — images copied alongside the markdown into the output directory | §5 |
| F6 | GFM tables, task lists, strikethrough, autolinks render (free via reveal.js markdown plugin; highlight.js handles code) | §1 |
| F7 | Theme loader reads `agency/workstreams/mdslidepal/themes/agency-default.json`, emits CSS custom properties (`--r-main-color`, `--r-heading-color`, `--r-link-color`, plus mdslidepal-scoped vars) | §9 |
| F8 | Output is fully self-contained — vendored reveal.js, no CDN references anywhere | §8, §mdslidepal-web |
| F9 | Output runs from `file://` with no local server (verified in smoke test) | §mdslidepal-web |
| F10 | Keyboard navigation: arrows/space/home/end/esc/f/b/. /?  — all inherited from reveal.js | §10 |
| F11 | Fixed 16:9 logical canvas 1920×1080, initialized on `Reveal.initialize({width:1920, height:1080})` | §9 |
| F12 | CLI exit code non-zero on unreadable/missing input file, with a clear stderr message | §11 |
| F13 | `--port <n>` flag (default 8000); auto-increment on conflict | §mdslidepal-web |

**Non-functional:**

- **Offline-first.** Zero network at runtime (build time may fetch reveal.js once via pnpm; that's fine).
- **Performance.** `serve` must start in <2 seconds on Jordan's laptop. Slide transitions are reveal.js default (no requirement beyond "doesn't drop frames").
- **No global install required.** `pnpm exec mdslidepal serve ...` from the repo root must work. A global `npm link` is a nice-to-have.
- **No build step for users.** Developers may have a `tsc` build; users run the bin script directly.
- **Node 20+ / TypeScript / pnpm** — framework convention.

### What's IN Iteration 1

1. `mdslidepal serve <input.md>` CLI (only that verb, only one positional, plus `--port`).
2. One theme: `agency-default`, loaded from `themes/agency-default.json`.
3. reveal.js v5+ vendored via pnpm; copied to output on each serve invocation.
4. Output directory layout (see A&D §2) with the index HTML, theme CSS, vendored reveal.js, and the copied markdown + images.
5. Fixtures 01, 02, 03, 04, 05, 08 pass (the web-applicable subset — see §PVR acceptance).
6. Sample workshop deck renders identically under `mdslidepal serve` as it does under the raw Plan B template.
7. Sunday-evening smoke test protocol (short checklist + `test-smoke-workshop.md`).

### What's deferred to Phase 2+

Per contract §mdslidepal-web "What's OUT":

- `agency-dark` theme
- YAML front-matter parsing (fixture 06)
- Per-slide `<!-- slide: ... -->` metadata blocks
- Speaker notes in presenter view (fixture 07) — reveal.js provides this for free via `RevealNotes`; we just don't commit to it for MVP acceptance
- `render` and `export` CLI subcommands
- PDF export
- `unified`/`remark` custom parser pipeline
- Custom transitions beyond reveal.js's default
- Auto-break on H1
- Directory-of-files loader
- Vercel deployment validation

### Acceptance criteria (Iteration 1)

Iteration 1 is "done" when **all** of the following are true:

1. **Fixture corpus** — running `mdslidepal serve <fixture>` for each of `01-minimal.md`, `02-multi-slide.md`, `03-code-blocks.md`, `04-images.md`, `05-tables-and-lists.md`, `08-edge-cases.md` opens a browser that renders the deck, with:
   - Correct slide count per each fixture's "Acceptance" footer
   - H1/body text visible and legible
   - Code blocks in fixture 03 are syntax-highlighted (not plain monospace)
   - Images in fixture 04 render; the missing-image slide shows alt text (reveal.js/browser default — a broken-image icon plus alt text is acceptable for MVP, per contract §11)
   - Tables, nested lists, task list checkboxes, strikethrough, and autolinks in fixture 05 render
   - **Fixture 08 caveat:** reveal.js's markdown plugin uses regex-based slide splitting, not AST-based. The `---` inside the fenced code block in fixture 08 is handled correctly by reveal.js's default regex (`^\r?\n---\r?\n$` requires blank lines around the separator, and fenced code normally preserves its content). However, trailing-`---` and `---\n\n---`-produces-one-slide behaviors are NOT guaranteed to match the contract exactly under reveal.js's native splitter. **This is flagged in Open Questions §4.1 below** — Iteration 1 acceptance for fixture 08 is "no slide-splitting of the code block content" (the primary AST-vs-regex concern). Exact empty-slide and trailing-separator count is a Phase 2 item when we add AST pre-processing.
2. **Offline** — the output directory runs on a laptop in airplane mode.
3. **`file://`** — double-clicking `index.html` in the output directory opens the deck in Chrome and Safari and navigates correctly. (Known caveat: some browsers block `fetch()` of the `data-markdown` source over `file://`. The fallback is "run the local server" per the smoke-test protocol. This is acceptable because `serve` is the only verb in MVP; `file://` is the recovery path, not the primary path.)
4. **Smoke test** — the checklist in `test-smoke-workshop.md` passes on Jordan's laptop Sunday night.
5. **Theme** — colors on screen visibly match `themes/agency-default.json` (white background, dark foreground, accent blue on links).

---

## 2. A&D — Architecture & Design

### 2.1 High-level architecture

```
┌────────────────────────────────────────────────────────────┐
│  mdslidepal serve <input.md>  [--port 8000]                │
└────────────────────────────────────────────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │  bin/mdslidepal.ts             │
         │   · parse argv                 │
         │   · resolve input path         │
         │   · call buildOutput()         │
         │   · start server               │
         │   · open browser               │
         └────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  src/build.ts                                                │
│   1. read input.md                                           │
│   2. load theme JSON                                         │
│   3. render theme → CSS                                      │
│   4. render HTML template with data-markdown ref             │
│   5. copy vendored reveal.js into output/reveal.js/          │
│   6. copy input.md → output/deck.md                          │
│   7. scan markdown for local images, copy them               │
│   8. write output/index.html + output/theme.css              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │  src/server.ts                 │
         │   · sirv output/               │
         │   · bind 127.0.0.1:<port>      │
         │   · open(http://…/index.html)  │
         └────────────────────────────────┘
                          │
                          ▼
                       Browser
            (reveal.js markdown plugin
             fetches deck.md, splits on ---,
             renders, highlight.js colors code)
```

### 2.2 Tech stack (with justification)

| Decision | Choice | Why |
|---|---|---|
| Runtime | **Node 20+** | Framework convention (CLAUDE-THEAGENCY). |
| Language | **TypeScript, strict mode** | Type safety, matches framework conventions. |
| Package manager | **pnpm** | Framework convention. |
| Slide engine | **reveal.js v5.2.x** (already vendored in plan-b) | Contract §1 & §mdslidepal-web mandate reveal.js native markdown plugin for MVP. No custom parser. |
| Static file server | **`sirv`** (`sirv` standalone, not `sirv-cli`) | ~15 kB, zero-config, serves static dirs with sensible defaults, supports port auto-increment via caller. `http.createServer` is also fine but `sirv` saves ~30 lines of MIME-handling. Final call in Iteration 1 kickoff — both are acceptable. |
| Browser open | **`open` package** (sindresorhus/open) | Small, cross-platform, battle-tested. |
| CLI parsing | **Raw `process.argv`** (no yargs/commander) | Only one verb, one positional, one flag. A commander dependency is overkill and adds bundle weight. ~20 lines of parsing code. |
| Theme engine | **Pure TS function `themeToCss(theme: Theme): string`** | Reads parsed JSON, emits a CSS string with custom properties. No CSS-in-JS runtime. |
| Markdown parser | **reveal.js native `RevealMarkdown` plugin** | Contract §mdslidepal-web mandates this. We do NOT add `unified`/`remark` in Iteration 1. |
| Syntax highlighter | **reveal.js native `RevealHighlight` (highlight.js)** | Ships with reveal.js, no extra dep, supports all contract §6 languages. Shiki is better but not needed for MVP. |
| Testing | **`vitest`** for unit tests; **manual browser** for fixture acceptance | Framework convention. Visual fixture diff is captain's reconciliation job, not ours. |

### 2.3 File layout

Project lives at `agency/workstreams/mdslidepal/web/` (NEW directory — not inside `plan-b/`, which stays untouched as the fallback).

```
agency/workstreams/mdslidepal/web/
├── package.json              # name: mdslidepal, bin: mdslidepal → dist/bin/mdslidepal.js
├── tsconfig.json
├── pnpm-lock.yaml
├── README.md                 # install + usage
├── bin/
│   └── mdslidepal.ts         # argv parse, dispatch to serve()
├── src/
│   ├── serve.ts              # the serve verb: build + server + open
│   ├── build.ts              # pure build — markdown + theme → output dir
│   ├── theme.ts              # loadTheme() + themeToCss()
│   ├── template.ts           # the HTML template function (TaggedTemplate → string)
│   ├── assets.ts             # scan markdown for local image refs, copy to output
│   └── types.ts              # Theme type matching theme-schema.json
├── templates/
│   └── index.html.tmpl       # parameterized version of plan-b/reveal-js-template.html
├── vendor/
│   └── reveal.js/            # symlink or copy of plan-b/reveal.js/ at build time
├── test/
│   ├── build.test.ts         # unit: buildOutput produces expected files
│   ├── theme.test.ts         # unit: themeToCss emits expected CSS vars
│   └── fixtures.manual.md    # the smoke test checklist for fixtures
└── test-smoke-workshop.md    # Sunday-night manual checklist
```

**Output directory** (produced by `serve` into a temp dir by default, or `--out <dir>` Phase 2):

```
<tmpdir>/mdslidepal-<hash>/
├── index.html                # from template, with data-markdown="deck.md"
├── theme.css                 # from themeToCss(agency-default)
├── deck.md                   # copy of the user's input
├── images/                   # any local images the markdown references
│   └── sample.png
└── reveal.js/                # copy of the vendored reveal.js (dist/ + plugin/)
```

### 2.4 The HTML template

`templates/index.html.tmpl` is a direct derivative of `plan-b/reveal-js-template.html` (lines 36-95), parameterized with `${TITLE}`, `${THEME_CSS_HREF}`, `${DECK_MD_HREF}`, `${REVEAL_JS_PATH}`. Key invariants preserved:

- `<section data-markdown="${DECK_MD_HREF}">` with `data-separator="^\r?\n---\r?\n$"`, `data-separator-notes="^Notes?:"`
- Scripts loaded from `${REVEAL_JS_PATH}/dist/reveal.js`, `.../plugin/markdown/markdown.js`, `.../plugin/highlight/highlight.js`, `.../plugin/notes/notes.js`
- `Reveal.initialize({ width: 1920, height: 1080, margin: 0.04, transition: "none", controls: true, progress: true, plugins: [RevealMarkdown, RevealHighlight, RevealNotes] })`

**Relationship to Plan B:** this template IS Plan B's template with four substitutions. Plan B stays in place, untouched. If Iteration 1 blows up, Jordan still has the raw template as the fallback, exactly as designed.

### 2.5 Theme loader

```ts
// src/theme.ts (signature only — no implementation in this plan)
export async function loadTheme(name: string): Promise<Theme>;
export function themeToCss(theme: Theme): string;
```

`loadTheme` reads `../../themes/${name}.json` (relative to the web package root), validates shape matches `Theme` interface (structural — full JSON Schema validation is Phase 2), and returns it. `themeToCss` emits:

```css
:root {
  --r-main-font: <theme.fonts.sans_family>;
  --r-heading-font: <theme.fonts.display_family>;
  --r-code-font: <theme.fonts.mono_family>;
  --r-main-color: <theme.colors.foreground>;
  --r-heading-color: <theme.colors.foreground>;
  --r-link-color: <theme.colors.link>;
  --r-background-color: <theme.colors.background>;
  /* mdslidepal-scoped (not reveal.js recognized, used by our custom block) */
  --mdp-code-bg: <theme.code_background>;
  --mdp-border: <theme.colors.border>;
}
.reveal h1 { font-size: <theme.heading_scale.h1 / 16>rem; }
/* ...and so on for h2-h6, body, slide-padding */
.reveal .slide-background { background-color: <theme.colors.background>; }
```

CSS is emitted once at build time to `output/theme.css`. No runtime theme swap (deferred).

### 2.6 Offline-first strategy

1. `pnpm install reveal.js@5` at development time vendors it into `node_modules`.
2. `build.ts` copies `node_modules/reveal.js/{dist,plugin}` into `<output>/reveal.js/` on each `serve`. (Alternatively, a one-time `pnpm run vendor` step copies to `web/vendor/reveal.js/` and `build.ts` copies from there. Decision at Iteration 1 kickoff — `web/vendor/` is preferred because it lets us ship without a `node_modules` on the workshop laptop.)
3. The template references reveal.js via relative path `./reveal.js/...` — never via CDN, never via absolute URL.
4. Smoke test step: disable wifi, run `mdslidepal serve sample-workshop.md`, verify browser still renders fully.

### 2.7 `file://` fallback strategy

Known issue: Chrome and some browsers block `fetch()` of sibling files over `file://`, and reveal.js's markdown plugin uses `fetch()` to load `data-markdown` sources. This means opening `output/index.html` directly from Finder may fail to load `deck.md`.

Mitigation:

1. **Primary path is the server** — `mdslidepal serve` always starts the server. Jordan uses this Monday.
2. **Recovery path is inline markdown** — `build.ts` has a mode flag `--inline` (Phase 2 default, Iteration 1 nice-to-have) that reads `deck.md` at build time and inlines its contents inside the `<section data-markdown>` block as a `<script type="text/template">` child, which is reveal.js's supported inline-markdown mode. When inlined, the HTML works from `file://` because no `fetch` is needed. **This is an Iteration 1 stretch goal** — if time permits Saturday, ship both modes. If not, ship server-only and document the `python3 -m http.server 8000` fallback in the smoke-test protocol (same fallback Plan B already documents).
3. **Safari is more permissive** than Chrome on `file://` fetch — smoke test in both.

### 2.8 Plan B relationship

- `plan-b/` is **untouched** by this iteration. It remains the unconditional fallback.
- `plan-b/reveal.js/` is the source-of-truth vendored copy for Iteration 1 — `web/vendor/reveal.js/` is a copy (or symlink) of it. If we upgrade reveal.js, we upgrade `plan-b/reveal.js/` first, re-verify Plan B still works, then re-copy to `web/vendor/`.
- `plan-b/sample-workshop.md` is the primary acceptance deck for Iteration 1 — if `mdslidepal serve plan-b/sample-workshop.md` produces a deck that looks identical to opening `plan-b/reveal-js-template.html` directly, Iteration 1 is substantively complete.

---

## 3. Plan — Phases & Iterations

### Iteration 1 — Monday-ready MVP (target: Saturday 2026-04-11 night)

**Goal:** `mdslidepal serve <file.md>` works end-to-end on Jordan's laptop, passes the 6 web-applicable fixtures, runs offline, and is verified by the smoke-test protocol. **Time budget: ~6 hours focused work.**

| Step | Deliverable | Est. | Commit msg (Phase 1.1 slug) |
|---|---|---|---|
| 1 | Scaffold `web/` directory — `package.json`, `tsconfig.json`, `pnpm install reveal.js@5 sirv open`, vendor reveal.js to `web/vendor/reveal.js/` | 30m | `Phase 1.1: scaffold: mdslidepal-web package + vendored reveal.js` |
| 2 | Write `src/types.ts` — the `Theme` interface mirroring `theme-schema.json` | 15m | — (rolled into step 3) |
| 3 | Write `src/theme.ts` — `loadTheme()` + `themeToCss()`; unit test with `test/theme.test.ts` | 45m | `Phase 1.2: feat: theme loader reads agency-default.json, emits CSS vars` |
| 4 | Write `src/template.ts` + `templates/index.html.tmpl` — port of plan-b template with substitutions | 30m | — (rolled into step 5) |
| 5 | Write `src/assets.ts` — scan markdown for `![](...)` local image refs, return paths to copy | 30m | — (rolled into step 5) |
| 6 | Write `src/build.ts` — orchestrate theme + template + asset copy + reveal.js copy → output dir; unit test that verifies output dir contents | 60m | `Phase 1.3: feat: build.ts assembles output directory from markdown + theme` |
| 7 | Write `src/serve.ts` + `bin/mdslidepal.ts` — CLI arg parse, call build, start sirv, call open | 45m | `Phase 1.4: feat: serve command + CLI entry point` |
| 8 | Smoke test manually against `plan-b/sample-workshop.md`. Fix any immediate bugs. | 45m | — |
| 9 | Run against fixtures 01, 02, 03, 04, 05. Fix anything that doesn't render. | 45m | `Phase 1.5: test: fixtures 01-05 pass` |
| 10 | Run against fixture 08. Verify the `---` inside the fenced code block does not split the slide. Document any known divergences from the contract. | 30m | `Phase 1.6: test: fixture 08 passes (code-block separator edge case)` |
| 11 | Write `test-smoke-workshop.md` — the Sunday-night checklist | 15m | — (rolled into step 12) |
| 12 | Write `README.md` — install, usage, troubleshooting (including `python3 -m http.server 8000` fallback) | 30m | `Phase 1.7: docs: README + smoke-test protocol` |
| 13 | Run `/iteration-complete` — QG boundary commit | 30m | `Phase 1.8: chore: iteration 1 complete — MVP ready for Monday` |

**Total: ~6 hours.** Saturday night target is hit with buffer. The plan is scoped so a single agent session on Saturday can complete it.

**Iteration 1 exit criteria (must all be true):**
1. `pnpm exec mdslidepal serve ../plan-b/sample-workshop.md` starts a server, opens the browser, shows the deck.
2. Fixtures 01, 02, 03, 04, 05 render correctly; fixture 08's code block is not split.
3. Airplane-mode smoke test passes.
4. `test-smoke-workshop.md` checklist is all green on Jordan's machine.
5. QGR receipt committed.

### Iteration 2 — Sunday buffer (2026-04-12)

**Goal:** Absorb feedback from Jordan's Saturday-night dry-run. No new features unless the MVP doesn't work. **Time budget: opportunistic.**

Expected work:
- Visual polish — any theme colors that look wrong
- Bug fixes surfaced by the dry-run
- (Stretch) inline-markdown mode for true `file://` support (A&D §2.7)
- (Stretch) fixture 08 strict mode (trailing-`---`, adjacent-`---`) via a 20-line pre-processor
- Update `test-smoke-workshop.md` with any new steps

**Commit discipline:** every fix goes through `/iteration-complete`. If nothing needs fixing, ship an empty "Phase 1.9: chore: dry-run clean" tag on the last commit.

### Phase 2 — Contract parity (post-Monday, 2026-04-14+)

This is the planning sketch, not a committed schedule. After Monday's workshop, in order:

**Phase 2.1 — Front-matter + per-slide metadata (contract §1, §3)**
- Add `unified` + `remark` + `remark-frontmatter` + `remark-gfm` as a pre-processor that runs BEFORE reveal.js receives the markdown
- Parse front-matter, validate against a schema, emit into template (e.g., title → `<title>`)
- Parse `<!-- slide: ... -->` YAML blocks, rewrite to reveal.js `data-*` attributes on `<section>` tags
- Adopt AST-based slide splitting in the pre-processor; hand reveal.js pre-split HTML slides instead of raw markdown
- Add fixture 06 to acceptance

**Phase 2.2 — Speaker notes + presenter view (contract §4)**
- Presenter view is already free via `RevealNotes` plugin (it opens a second window on `s`)
- Validate fixture 07 and add to acceptance

**Phase 2.3 — `render` command (contract §7)**
- `mdslidepal render <in.md> --output <dir>` — same as `serve` but no server, no browser open

**Phase 2.4 — `export pdf` (contract §7, §8)**
- Either reveal.js's built-in print-to-PDF mode (open with `?print-pdf` and tell Chrome to print) driven via Playwright headless, or `decktape`
- Playwright is the cleaner integration; decktape has bitrotted

**Phase 2.5 — `agency-dark` theme (contract §9)**
- Add `themes/agency-dark.json` to the workstream (if not already shipped by captain)
- `mdslidepal serve --theme agency-dark <in.md>`

**Phase 2.6 — Directory-of-files loader (contract §1)**
- `mdslidepal serve <dir>` concatenates all `*.md` files sorted by filename

**Phase 2.7 — Evaluate Slidev (contract §Notes on Slidev)**
- Spike replacing reveal.js with Slidev. Compare output quality, maintenance burden, divergence risk.

---

## 4. Open questions for the principal

### 4.1 Fixture 08 vs reveal.js native splitter

Contract §2 mandates AST-based slide detection: thematic breaks inside code/lists/blockquotes are NOT slide breaks. reveal.js's native markdown plugin uses a regex splitter (`^\r?\n---\r?\n$`), not an AST. In practice the regex works correctly for the fenced-code case in fixture 08 because fenced code blocks are preserved as-is before the splitter sees them (the markdown is loaded as a raw string and split first, then each chunk is parsed). **However**, the contract's specific acceptance rules — "two adjacent `---` = one empty slide" and "trailing `---` does not create a phantom slide" — are NOT guaranteed by reveal.js's regex. My plan accepts "code block not split" as the Iteration 1 bar and defers strict empty-slide/trailing-`---` semantics to Phase 2 (via the `remark` pre-processor). **Is that acceptable for the Monday deadline?** The alternative is writing a ~50-line regex-based pre-processor Saturday that handles these two edge cases, which I can fit into the budget if it matters.

### 4.2 Inline markdown for true `file://`

Should Iteration 1 ship the `--inline` mode that inlines markdown into the HTML for `file://` compatibility, or is "run `python3 -m http.server 8000` if `file://` fails" an acceptable documented fallback? The latter is what Plan B already says. Inlining costs ~30 lines and a small risk. **Recommend: defer to Iteration 2 stretch unless principal wants it Saturday.**

### 4.3 Where does the `web/` package live?

Plan says `agency/workstreams/mdslidepal/web/`. Alternative is a sibling repo or a top-level `apps/mdslidepal-web/`. The workstream-internal location matches the contract's workstream-level themes and fixtures, and keeps the Plan B relationship clean. **Recommend: workstream-internal unless principal has a reason otherwise.**

### 4.4 Global install

Should Iteration 1 wire up `npm link` or a `pnpm -g install` path so Jordan can run `mdslidepal serve ...` from any directory, or is `pnpm exec mdslidepal serve ...` from the web package directory sufficient for Monday? **Recommend: `pnpm exec` for Monday; global install is Phase 2.**

### 4.5 Theme file location at runtime

`loadTheme()` reads `../../themes/agency-default.json` relative to the web package. That works inside this repo but not if the package is published to npm. For Iteration 1 this is fine (we're not publishing). Phase 2 needs to either bundle themes into the package or read from a configurable path. **Flagging for Phase 2, not blocking Iteration 1.**

---

**End of plan. Total word count: ~2400. Ready for captain reconciliation against mdslidepal-mac plan.**
