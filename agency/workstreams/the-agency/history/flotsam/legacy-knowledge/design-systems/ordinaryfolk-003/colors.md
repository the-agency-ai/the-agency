# Color Palette

**Source:** API extraction + OF_DS_colours.pdf
**Method:** Hybrid (exact hex from API, token names from PDF)

---

## Summary

| Source | Count | What It Provides |
|--------|-------|------------------|
| Figma API | 69 unique colors | Exact hex values |
| Designer PDF | ~50 tokens | Names, organization, intent |

---

## Neutrals

### OF Ink (OF Black)

Primary text and dark UI elements.

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| OF BLK 900 | `of-black-900` | `#141414` | Primary text, headings |
| OF BLK 800 | `of-black-800` | `#2F2F2F` | Secondary dark text |
| OF BLK 700 | `of-black-700` | `#454545` | Tertiary dark |
| OF BLK 600 | `of-black-600` | `#595959` | Muted dark |

### OF Dark Grey

Secondary text and medium UI elements.

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| OF Grey 900 | `of-grey-900` | `#302D28` | Dark borders, icons |
| OF Grey 800 | `of-grey-800` | `#616161` | Secondary text |
| OF Grey 700 | `of-grey-700` | `#737373` | Placeholder text |
| OF Grey 600 | `of-grey-600` | `#898683` | Disabled text |

### OF Light Grey

Borders, backgrounds, subtle UI elements.

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| OF Grey 500 | `of-grey-500` | `#969290` | Light borders |
| OF Grey 400 | `of-grey-400` | `#ABA8A6` | Disabled borders |
| OF Grey 300 | `of-grey-300` | `#CEC9C6` | Default borders |
| OF Grey 200 | `of-grey-200` | `#E0DDDA` | Subtle backgrounds |

### Paper

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| Off White | `off-white` | `#F7F6F5` | Page background |
| White | `white` | `#FFFFFF` | Card backgrounds |

---

## Brand Colors

### Blue (Primary)

Primary actions, links, interactive elements.

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| BLUE 900 | `blue-900` | `#003534` | Darkest blue/teal |
| BLUE 700 | `blue-700` | `#2458CE` | Dark blue |
| BLUE 600 | `blue-600` | `#4675E4` | **Primary action** |
| BLUE 500 | `blue-500` | `#366EFF` | Hover state |
| BLUE 400 | `blue-400` | `#406AFF` | Light accent |
| BLUE 300 | `blue-300` | `#DBEBFD` | Background tint |
| BLUE 200 | `blue-200` | `#DBEBFD` | Subtle highlight |
| BLUE 100 | `blue-100` | `#DBEBFD` | Lightest background |

### Green (Success)

Success states, positive actions, health indicators.

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| GREEN 900 | `green-900` | `#003633` | Darkest green |
| GREEN 700 | `green-700` | `#01743B` | Dark green |
| GREEN 600 | `green-600` | `#3D9974` | **Success state** |
| GREEN 400 | `green-400` | `#5CA983` | Light success |
| GREEN 300 | `green-300` | `#AEEB90` | Success background |
| GREEN 200 | `green-200` | `#C2F0AC` | Subtle success |
| GREEN 100 | `green-100` | `#DBFDCB` | Lightest success |

---

## Semantic Colors

### Purple (Info)

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| PURPLE 400 | `purple-400` | `#9747FF` | Info accent |
| PURPLE 300 | `purple-300` | `#A269FF` | Light info |
| PURPLE 200 | `purple-200` | `#A269FF` | Info background |
| PURPLE 100 | `purple-100` | `#A269FF` | Lightest info |

### Red (Error)

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| RED 400 | `red-400` | `#EB4646` | **Error state** |
| RED 300 | `red-300` | `#EB4A4A` | Light error |
| RED 200 | `red-200` | `#EB4A4A` | Error background |
| RED 100 | `red-100` | `#EB4A4A` | Lightest error |

### Orange (Warning)

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| ORANGE 400 | `orange-400` | `#FF7628` | **Warning state** |
| ORANGE 300 | `orange-300` | `#FF8951` | Light warning |
| ORANGE 200 | `orange-200` | `#F4BD98` | Warning background |
| ORANGE 100 | `orange-100` | `#F4BD98` | Lightest warning |

### Yellow (Highlight)

| Token | Tailwind Name | Hex (API) | Usage |
|-------|---------------|-----------|-------|
| YELLOW 400 | `yellow-400` | `#FEFEB9` | Highlight accent |
| YELLOW 300 | `yellow-300` | `#FEFEB9` | Light highlight |
| YELLOW 200 | `yellow-200` | `#FEFEB9` | Highlight background |
| YELLOW 100 | `yellow-100` | `#FEFEB9` | Lightest highlight |

---

## Health OS Accent Colors

Additional colors found in API not in standard PDF palette:

| Hex (API) | Suggested Token | Visual | Usage |
|-----------|-----------------|--------|-------|
| `#EBE3D7` | `warm-cream` | Warm beige | Warm backgrounds |
| `#ECE3D7` | `warm-cream-alt` | Warm beige | Gradient variant |
| `#F8F3ED` | `warm-light` | Light cream | Light warm bg |
| `#D0B895` | `sand` | Sand/tan | Warm accent |
| `#B89460` | `caramel` | Caramel | Warm mid-tone |
| `#A37E49` | `bronze` | Bronze | Warm dark |
| `#D7A492` | `peach` | Peach | Soft accent |
| `#4F0E38` | `deep-plum` | Deep plum | Dark accent |
| `#FF0099` | `hot-pink` | Hot pink | Accent (dev?) |
| `#FF35DD` | `magenta` | Magenta | Accent (dev?) |
| `#FF4EBE` | `pink` | Pink | Accent |

---

## Undocumented Colors (API Only)

These colors appear in the Figma document but aren't in the design system PDF.
Review and either add to palette or remove from designs.

| Hex | Visual Category | Notes |
|-----|-----------------|-------|
| `#000000` | Black | True black (consider using OF BLK 900) |
| `#0008FF` | Blue | Bright blue (dev marker?) |
| `#0015FF` | Blue | Bright blue variant |
| `#0022FF` | Blue | Bright blue variant |
| `#0800FF` | Blue | Bright blue variant |
| `#010DEE` | Blue | Electric blue |
| `#2C3CEE` | Blue | Mid blue |
| `#1D1B20` | Dark | Near-black |
| `#C5C5C5` | Grey | Mid grey |
| `#D9D9D9` | Grey | Light grey |
| `#DBDBDB` | Grey | Light grey |
| `#E5E5E5` | Grey | Light grey |
| `#E6E4E1` | Grey | Warm light grey |
| `#E8E8E8` | Grey | Light grey |
| `#EAEAEA` | Grey | Light grey |
| `#ECEBE9` | Grey | Warm light grey |
| `#EEEAEA` | Grey | Light grey |
| `#F0EFEF` | Grey | Very light grey |
| `#F7F7F7` | Grey | Near white |
| `#F8F8F9` | Grey | Near white |
| `#FEFEFE` | White | Near white |
| `#FF0000` | Red | Pure red (dev marker?) |

---

## Usage Guidelines

### Text Colors
```
Primary text:     of-black-900 (#141414)
Secondary text:   of-grey-800 (#616161)
Placeholder:      of-grey-700 (#737373)
Disabled:         of-grey-600 (#898683)
```

### Background Colors
```
Page background:  off-white (#F7F6F5)
Card background:  white (#FFFFFF)
Subtle surface:   of-grey-200 (#E0DDDA)
Warm surface:     warm-cream (#EBE3D7)
```

### Interactive States
```
Primary button:   blue-600 (#4675E4)
Primary hover:    blue-700 (#2458CE)
Success:          green-600 (#3D9974)
Error:            red-400 (#EB4646)
Warning:          orange-400 (#FF7628)
```

---

## Tailwind Config

See `tailwind-config.md` for ready-to-use configuration.
