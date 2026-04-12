# mdslidepal — Plan B (Workshop Safety Net)

**This directory exists so Jordan can present at Republic Polytechnic on Monday 13 April 2026 even if mdslidepal-web is not finished.**

## TL;DR

If mdslidepal-web is not working by Sunday night, come here, follow the setup once, and open `reveal-js-template.html` in a browser. That is your workshop deck.

## First-time setup (5 minutes)

Vendor reveal.js locally so the deck works offline. Two paths — pick whichever works on your machine:

### Path A — via `curl` (no npm needed)

```bash
cd claude/workstreams/mdslidepal/plan-b
curl -L https://github.com/hakimel/reveal.js/archive/refs/tags/5.2.1.tar.gz | tar xz
mv reveal.js-5.2.1 reveal.js
```

### Path B — via `npm`

```bash
cd claude/workstreams/mdslidepal/plan-b
npm init -y
npm install reveal.js@5
cp -r node_modules/reveal.js ./reveal.js
rm -rf node_modules package.json package-lock.json
```

### Verify

```bash
ls reveal.js/dist/reveal.js
# Should show the file exists
```

## Using the template

**Quickest:** double-click `reveal-js-template.html` in Finder. It will open in your default browser. Press `f` to go fullscreen. Use arrow keys to navigate.

**If `file://` is blocked** (some locked-down systems refuse to load `.md` files via `file://`):

```bash
cd claude/workstreams/mdslidepal/plan-b
python3 -m http.server 8000
```

Then open http://localhost:8000/reveal-js-template.html in your browser.

## Customising the deck content

`sample-workshop.md` is the deck that renders. Edit it directly — save, refresh the browser, the deck updates.

Markdown dialect:
- `---` on its own line = slide break
- `# Heading` at the top of each slide
- Standard CommonMark + GFM (tables, task lists, strikethrough)
- Fenced code blocks with language hints — syntax highlighted automatically
- `Notes:` marker at the bottom of a slide = speaker notes (press `s` in the browser to open presenter view)

## Keyboard shortcuts (in the browser)

| Key | Action |
|---|---|
| `→` / `Space` | Next slide |
| `←` | Previous slide |
| `Home` / `End` | First / last slide |
| `f` | Toggle fullscreen |
| `Esc` / `o` | Slide overview |
| `s` | Open presenter view (second window with notes + next-slide preview) |
| `b` / `.` | Black screen toggle |
| `?` | Keyboard shortcut help |

## Plan C — Marp CLI (third safety net)

If Plan B itself fails for any reason, install Marp CLI as a second fallback:

```bash
npm install -g @marp-team/marp-cli
cd claude/workstreams/mdslidepal/plan-b
marp sample-workshop.md --html -o deck.html
open deck.html
```

Marp is an entirely separate tool. If reveal.js is somehow broken, Marp is your escape hatch.

## Relationship to mdslidepal-web

mdslidepal-web Iteration 1 aims to replace this template with a `mdslidepal serve sample-workshop.md` command that does the same thing plus: better theming, tighter integration with the-agency framework, the agency brand. The `sample-workshop.md` file is the same file the web agent will use as its primary acceptance test, so whatever polish it needs for the workshop gets inherited by the MVP.

**Plan B is not a placeholder. Plan B is a guaranteed fallback.** Use it if you need it, ignore it if you don't, and feel safe knowing it's here.
