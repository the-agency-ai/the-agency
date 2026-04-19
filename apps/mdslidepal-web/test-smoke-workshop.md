# mdslidepal-web Smoke Test Protocol

**When:** Sunday evening before the Monday workshop
**Who:** Jordan (principal)
**Duration:** ~10 minutes

## Prerequisites

- [ ] Node 20+ installed (`node --version`)
- [ ] pnpm installed (`pnpm --version`)
- [ ] Dependencies installed (`cd apps/mdslidepal-web && pnpm install`)
- [ ] TypeScript compiled (`pnpm run build`)

## Test 1: Sample workshop deck

```bash
cd apps/mdslidepal-web
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/plan-b/sample-workshop.md
```

- [ ] Browser opens automatically
- [ ] Slides render with white background, dark text
- [ ] Arrow keys navigate between slides
- [ ] `f` enters fullscreen
- [ ] `Esc` exits fullscreen
- [ ] Code blocks have syntax highlighting (not plain monospace)
- [ ] Progress bar visible at bottom

## Test 2: Fixtures

Run each fixture and verify:

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/01-minimal.md
# → 1 slide, heading "Hello mdslidepal" visible
```

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/02-multi-slide.md
# → 3 slides with correct headings
```

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/03-code-blocks.md
# → Code blocks syntax-highlighted per language
```

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/04-images.md
# → sample.png renders; missing image shows broken-image icon + alt text
```

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/05-tables-and-lists.md
# → Tables with borders, nested lists indented, task checkboxes visible
```

```bash
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/08-edge-cases.md
# → Code block --- does NOT split slide; adjacent --- produces one empty slide
```

## Test 3: Offline (airplane mode)

- [ ] Enable airplane mode (wifi off, bluetooth off)
- [ ] Run `node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/plan-b/sample-workshop.md`
- [ ] Verify slides render fully (all CSS, JS loaded from local files)
- [ ] Navigate all slides
- [ ] Re-enable wifi

## Test 4: Port conflict

```bash
# Terminal 1:
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/01-minimal.md

# Terminal 2 (while terminal 1 is running):
node dist/bin/mdslidepal.js serve ../../agency/workstreams/mdslidepal/fixtures/02-multi-slide.md
# → Should auto-increment to port 8001
```

- [ ] Second instance starts on port 8001 (or next available)
- [ ] Both decks accessible simultaneously

## Fallback: Plan B

If mdslidepal-web is broken:

```bash
cd agency/workstreams/mdslidepal/plan-b
python3 -m http.server 8000
# Open http://localhost:8000/reveal-js-template.html
```

Or double-click `plan-b/reveal-js-template.html` directly in Finder.
