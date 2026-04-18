# Building a Claude Code-Friendly Design System in Figma

**Date:** 2026-01-13
**Author:** housekeeping
**Related:** REQUEST-jordan-0042, ordinaryfolk-003 extraction

---

## Introduction

This guide shows designers how to structure Figma files so Claude Code can automatically extract and implement design systems. Following these practices reduces handoff time from hours to minutes and dramatically improves implementation accuracy.

We discovered these patterns while building the hybrid extraction workflow for the Ordinary Folk / Health OS design system. The insights here come from real extraction attempts, failures, and successes.

---

## How Claude Code Extracts Design Systems

Claude Code uses two methods to extract design data from Figma:

### Method 1: Figma REST API

```bash
./tools/figma-extract <file-key> --name=brand --version=001
```

**What the API provides:**
- All colors used in the document (exact hex values)
- All fonts used (with usage counts)
- Published styles (if any exist)
- Document structure

**What the API cannot provide:**
- Token names (unless styles are published)
- Semantic organization (which colors are "primary" vs "error")
- Typography specs (font sizes, line heights, weights)
- Usage guidelines

### Method 2: Claude Reads PDFs

Designers export documentation pages from Figma as PDFs. Claude reads them natively and extracts:

- Token names and organization
- Complete typography specifications
- Usage guidelines and context
- Semantic meaning ("use blue-600 for primary actions")

### The Hybrid Approach

The best results come from combining both methods:

```
┌─────────────────────────────────────────────────────────────┐
│                    HYBRID WORKFLOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Figma API                    PDF Documentation             │
│  ─────────                    ─────────────────             │
│  • 69 exact hex values        • Token names                 │
│  • 3 fonts + usage counts     • Organization                │
│  • All colors actually used   • Typography specs            │
│  • Fast (10 seconds)          • Usage guidelines            │
│                                                             │
│                         ↓                                   │
│                                                             │
│              Claude Merges Both Sources                     │
│              ─────────────────────────                      │
│              • Exact hex + semantic names                   │
│              • Complete typography with specs               │
│              • Production-ready Tailwind config             │
│              • Undocumented colors flagged                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Result:** Complete, accurate design system in ~30 minutes vs ~2.5 hours manual.

---

## The Gap We Discovered

When we extracted the Ordinary Folk design system, we found:

| Source | Colors Found | Text Styles | What We Got |
|--------|--------------|-------------|-------------|
| **Figma API (published styles)** | 2 | 0 | Almost nothing |
| **Figma API (document parsing)** | 69 | 3 fonts | Raw data, no names |
| **Designer PDF** | ~50 named | 20+ styled | Names, specs, no exact hex |

**The problem:** Designers created excellent documentation but didn't publish styles to the Figma library. The API could see the colors in the document but didn't know what to call them.

**The solution:** Combine API data (exact values) with PDF data (names and specs).

---

## The Ideal: Publish Styles to Figma Library

The single most impactful thing a designer can do is **publish styles to the Figma library**.

```
How: Figma > Select element > Right panel > Style icon > Create style > Publish
```

### Why This Matters

When styles are published:

| Without Published Styles | With Published Styles |
|--------------------------|----------------------|
| API returns unnamed hex values | API returns `blue-600: #4675E4` |
| Manual matching required | Automatic extraction |
| 30+ minute process | 5 minute process |
| Risk of mismatched names | 100% accurate |

### Publishing Color Styles

For each color in your palette:

1. Create a rectangle with the color fill
2. Select it
3. Click the style icon (4 dots) in the Fill section
4. Click "+" to create a new style
5. Name it with a dev-friendly token: `blue/600` or `of-black/900`
6. Publish to team library

**Naming convention:**
```
✓ blue/600
✓ of-black/900
✓ green/success
✓ warm/cream

✗ Primary Blue
✗ Blue - Main
✗ #4675E4
```

### Publishing Text Styles

For each text style:

1. Create a text element with the correct formatting
2. Select it
3. Click the style icon in the Text section
4. Create and name: `Headers/H1`, `Body/Body 2`, `UI/Button`
5. Publish to team library

### Publishing Effect Styles

For shadows, blurs, and effects:

1. Apply the effect to an element
2. Create an effect style
3. Name it: `Shadows/Card`, `Shadows/Modal`
4. Publish

**If designers do nothing else, publishing styles eliminates 90% of extraction friction.**

---

## When Published Styles Aren't Possible

Reality: Many designers don't publish styles consistently. Here's how to structure Figma files for hybrid extraction:

### 1. Create Dedicated Documentation Pages

Structure your Figma file with clear documentation:

```
📄 Cover
📄 Colors           ← Document all colors here
📄 Typography       ← Document all text styles here
📄 Spacing          ← Document spacing scale
📄 Effects          ← Document shadows, borders
📄 Components       ← Component library
📄 [Design pages...]
```

### 2. Structure the Colors Page

**Critical insight:** The Figma API extracts colors from actual fills, not from screenshots or images.

**Do this:**
```
┌─────────────────────────────────────────────────────────────┐
│  NEUTRALS                                                   │
│                                                             │
│  ┌────────┐  OF Black 900 - Primary text                   │
│  │████████│  Name for dev: of-black-900                    │
│  └────────┘                                                │
│                                                             │
│  ┌────────┐  OF Black 800 - Secondary dark                 │
│  │████████│  Name for dev: of-black-800                    │
│  └────────┘                                                │
│                                                             │
│  [Continue for all colors...]                              │
└─────────────────────────────────────────────────────────────┘
```

**Key requirements:**
- Color swatch is a rectangle with the ACTUAL color fill
- Token name is clearly visible next to the swatch
- Dev-friendly name is specified (kebab-case, no spaces)
- Colors are grouped by category

**What we found in ordinaryfolk-001:**
The PDF showed beautiful color swatches with names like "OF BLK 900" - but the hex values were approximate because we had to eyeball them from the visual. The API gave us exact hex (#141414 vs the approximated #1A1A1A).

### 3. Structure the Typography Page

Show every text style with complete specifications:

```
┌─────────────────────────────────────────────────────────────┐
│  HEADERS                                                    │
│                                                             │
│  H1                                                         │
│  Regular 34 / Auto / 0% sentence case                       │
│                                                             │
│  The quick brown fox jumps over the lazy dog               │
│  (This text is actually rendered in H1 style)              │
│                                                             │
│  ─────────────────────────────────────────                 │
│                                                             │
│  H2                                                         │
│  Medium 22 / 28 / 0% sentence case                         │
│                                                             │
│  The quick brown fox jumps over the lazy dog               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Include for each style:**

| Property | Example | Notes |
|----------|---------|-------|
| Style name | H1, Body 2, Button | Clear, consistent naming |
| Font family | Graphik | Don't assume - specify it |
| Font weight | Semibold (600) | Include numeric value |
| Font size | 16px | In pixels |
| Line height | 20px or Auto | Pixels or "Auto" |
| Letter spacing | 0% or 4% | As percentage |
| Text transform | sentence case, Title Case, ALL CAPS | Specify explicitly |

**The format we found most extractable:**
```
Semibold 16 / 20 / 0% sentence case
[weight] [size] / [line-height] / [letter-spacing] [transform]
```

### 4. Use Consistent, Dev-Friendly Naming

Names should map directly to code:

| Design Token | Code Equivalent |
|--------------|-----------------|
| OF Black 900 | `of-black-900` |
| Blue 600 | `blue-600` |
| H1 | `text-h1` |
| Body 1 | `text-body-1` |
| Button Primary | `btn-primary` |

**Naming rules:**
- Use kebab-case (hyphens, not spaces)
- Use numbers for scales (100-900)
- Be consistent within categories
- Avoid special characters

**Bad naming (hard to extract):**
```
✗ Primary Blue (spaces)
✗ blue_primary (underscores)
✗ BLUE-600 (inconsistent caps)
✗ Blue - Main Action (too verbose)
```

**Good naming (easy to extract):**
```
✓ blue-600
✓ of-black-900
✓ green-success
✓ text-body-2
```

### 5. Keep All Colors IN the Document

**Critical insight:** The API can only extract colors that exist as fills in the Figma document.

**Problem scenario:**
- Designer documents colors in a PDF or external style guide
- Colors are described but not used in Figma
- API extraction finds nothing

**Solution:**
Create a frame (can be hidden) containing rectangles filled with every color:

```
┌─────────────────────────────────────────────────────────────┐
│  COLOR TOKENS (Hidden frame for API extraction)             │
│                                                             │
│  ■ ■ ■ ■ ■ ■ ■ ■  (blacks)                                 │
│  ■ ■ ■ ■ ■ ■ ■ ■  (greys)                                  │
│  ■ ■ ■ ■ ■ ■ ■ ■  (blues)                                  │
│  ■ ■ ■ ■ ■ ■ ■ ■  (greens)                                 │
│  ■ ■ ■ ■ ■ ■ ■ ■  (etc.)                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

This ensures the API finds all your palette colors, even if some aren't used in actual designs yet.

### 6. Make Documentation Export-Ready

Design documentation frames for clean PDF export:

**Frame naming:**
```
DS-Colors-Neutrals
DS-Colors-Brand
DS-Colors-Semantic
DS-Typography-Headers
DS-Typography-Body
DS-Typography-UI
DS-Spacing
DS-Effects
```

**Frame sizing:**
- Use consistent dimensions (e.g., 1440px wide)
- Ensure all content fits without scrolling
- Leave margins for PDF export

**Export process:**
1. Select documentation frames
2. File > Export frames to PDF
3. Save to project's `source/` directory

---

## What We Extract and How We Use It

### From the API (Exact Data)

```bash
./tools/figma-extract abc123xyz --name=brand --version=001
```

**Output:**
```
Embedded Design Data (from document):
  - 69 unique colors
  - 3 fonts

  Top fonts:
       418 uses: Graphik
       338 uses: Poppins
         1 uses: Roboto
```

This tells us:
- Exactly what colors exist (hex values)
- What fonts are used and how heavily
- Which colors might be undocumented (in designs but not in style guide)

### From the PDF (Semantic Data)

Claude reads the PDF and extracts:

```markdown
## Neutrals

### OF Ink (OF Black)
- OF BLK 900: Primary text, headings
- OF BLK 800: Secondary dark text
- OF BLK 700: Tertiary dark
- OF BLK 600: Muted dark

### Typography
- H1: Regular 34/Auto/0% sentence case
- H2: Medium 22/28/0% sentence case
...
```

This tells us:
- What to call each color
- How they're organized
- When to use each one
- Complete typography specs

### The Merged Result

Combining both sources:

```markdown
| Token | Tailwind Name | Hex (API) | Usage (PDF) |
|-------|---------------|-----------|-------------|
| OF BLK 900 | `of-black-900` | `#141414` | Primary text |
| OF BLK 800 | `of-black-800` | `#2F2F2F` | Secondary dark |
```

**Plus discovery of undocumented colors:**
```markdown
## Undocumented Colors (API Only)

These colors appear in the Figma document but aren't in the design system PDF:

| Hex | Category | Notes |
|-----|----------|-------|
| #EBE3D7 | Warm | Likely Health OS accent |
| #D7A492 | Warm | Peach tone |
```

---

## The Discovery Bonus

A major benefit of API extraction: **finding colors designers forgot to document**.

In the Ordinary Folk extraction:
- PDF documented ~50 colors
- API found 69 colors in the actual document
- **20+ colors were being used but never documented**

These included the distinctive Health OS warm palette:
- `#EBE3D7` - warm-cream
- `#F8F3ED` - warm-light
- `#D0B895` - sand
- `#B89460` - caramel
- `#A37E49` - bronze
- `#D7A492` - peach

Without API extraction, developers would have been guessing at these colors or asking "what color is this?" repeatedly.

---

## Time and Accuracy Comparison

| Approach | Time | Accuracy | Notes |
|----------|------|----------|-------|
| Published styles | 5 min | 100% | Ideal but rare |
| Hybrid (API + PDF) | 30 min | 95%+ | Best practical option |
| PDF only | 2-3 hours | 80% | Hex values approximated |
| No documentation | Not feasible | - | Too many questions |

---

## Checklist for Designers

Before handoff to development, verify:

### Colors
- [ ] All palette colors exist as actual fills in the document
- [ ] Colors are named with dev-friendly tokens (kebab-case)
- [ ] Colors are grouped by category (Neutrals, Brand, Semantic)
- [ ] "Name for dev use" is specified for each color
- [ ] No orphan colors (used in designs but not in palette)

### Typography
- [ ] All text styles documented with complete specs
- [ ] Font weight specified numerically (400, 500, 600)
- [ ] Line height specified (px value or "Auto")
- [ ] Letter spacing specified (percentage)
- [ ] Text transform specified (sentence case, Title Case, ALL CAPS)
- [ ] Example text rendered in each style

### Spacing
- [ ] Spacing scale documented (4, 8, 12, 16, 24, 32, 48, 64)
- [ ] Components use spacing tokens consistently

### Effects
- [ ] Shadows documented with values
- [ ] Border radii documented

### Export
- [ ] Documentation pages are cleanly exportable as PDF
- [ ] Frames are named consistently (DS-Colors-*, DS-Typography-*, etc.)

### Ideal (If Possible)
- [ ] Color styles published to team library
- [ ] Text styles published to team library
- [ ] Effect styles published to team library

---

## Example: Before and After

### Before (Hard to Extract)

```
Problems:
- Colors shown as screenshots, not actual fills
- Names inconsistent: "Primary Blue", "blue_main", "BLUE-600"
- Typography specs in external PDF, not in Figma
- Some colors used in designs but never documented
- No dev-friendly names specified
```

**Result:** 2-3 hours of manual work, 80% accuracy, many follow-up questions

### After (Easy to Extract)

```
Improvements:
- Colors as actual fills in documented frames
- Consistent naming: blue-600, blue-700, blue-800
- Typography on dedicated Figma page with full specs
- Color token frame ensures all colors are in document
- "Name for dev use" specified for every token
- Styles published to Figma library
```

**Result:** 5-30 minutes, 95-100% accuracy, minimal follow-up

---

## Quick Reference for Designers

### Must Do
1. Use actual color fills (not screenshots) in documentation
2. Specify dev-friendly names (kebab-case, no spaces)
3. Include complete typography specs (size, weight, line-height, spacing, transform)
4. Keep all palette colors in the Figma document

### Should Do
1. Create dedicated documentation pages
2. Group colors by category
3. Use consistent naming conventions
4. Make documentation frames PDF-exportable

### Ideal
1. Publish all styles to Figma library
2. Review for undocumented colors before handoff
3. Include usage guidelines

---

## Summary

**For designers building Claude Code-friendly design systems:**

1. **Publish styles** - The single biggest impact
2. **Use actual fills** - Not screenshots or images
3. **Name consistently** - Dev-friendly, kebab-case tokens
4. **Document completely** - Full specs for every style
5. **Keep colors in document** - API extracts from fills

**The payoff:**
- 5-30 minute extraction vs 2-3 hours
- Accurate hex values on first try
- Discovery of undocumented colors
- Production-ready Tailwind config
- Fewer "what color is this?" questions
- Faster, higher-fidelity implementation

---

## Tools and Resources

- `./tools/figma-extract` - Extracts design tokens from Figma API
- `./tools/designsystem-add` - Creates design system scaffold
- `./tools/designsystem-validate` - Validates completeness
- `EXTRACTION-GUIDE.md` - Technical extraction workflow
- `design-system` agent template - Specialized Claude agent for extraction
