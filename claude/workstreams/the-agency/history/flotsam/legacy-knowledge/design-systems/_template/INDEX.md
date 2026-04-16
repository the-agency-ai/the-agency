# {{BRAND_NAME}} Design System v{{VERSION}}

**Version:** {{VERSION}}
**Last Updated:** {{DATE}}
**Primary Application:** {{APPLICATION}}

---

## Directory Structure

```
{{BRAND_NAME}}-{{VERSION}}/
├── INDEX.md              # This file - overview
├── GAPS.md               # Missing information tracker
├── GAP-RESOLUTION.md     # How to fill gaps
├── colors.md             # Color palette
├── typography.md         # Font family, text styles
├── spacing.md            # Padding and radius systems
├── effects.md            # Shadows, borders
├── assets.md             # SVGs, logos, images
├── tailwind-config.md    # Tailwind CSS configuration
└── source/               # Original source materials
```

---

## Contents

### Design Tokens

| File | Purpose | Status |
|------|---------|--------|
| `colors.md` | Color palette with semantic names | TODO |
| `typography.md` | Font family, text styles | TODO |
| `spacing.md` | Padding scale, radius system | TODO |
| `effects.md` | Shadows, borders | TODO |
| `assets.md` | SVGs, logos, usage patterns | TODO |
| `tailwind-config.md` | Ready-to-use Tailwind theme | TODO |

### Meta Documentation

| File | Purpose |
|------|---------|
| `GAPS.md` | Summary of missing information |
| `GAP-RESOLUTION.md` | Instructions to fill each gap |

---

## Quick Reference

### Font

**{{FONT_FAMILY}}** - Primary font family

### Base Colors

| Role | Token | Usage |
|------|-------|-------|
| Primary Text | `text-primary` | Main body text |
| Secondary Text | `text-secondary` | Subdued text |
| Borders | `border-default` | Standard borders |
| Background | `bg-page` | Page background |
| Accent | `action-primary` | Primary actions, links |

### Spacing Scale

```
[Define your spacing scale here]
XS: ?px   S: ?px   M: ?px   L: ?px   XL: ?px
```

### Border Radius

```
[Define your radius scale here]
S: ?px   M: ?px   L: ?px
```

### Shadows

```
[Define your shadow system here]
Low:    [shadow definition]
Medium: [shadow definition]
High:   [shadow definition]
```

---

## Usage Guidelines

1. **Always use semantic tokens** - Never use raw hex values in code
2. **Check GAPS.md** - Know what's approximate before implementing
3. **Mobile-first** - Start with mobile specs, scale up

---

## Current Gaps

See `GAPS.md` for full list and `GAP-RESOLUTION.md` for resolution instructions.

| Gap | Priority | Status |
|-----|----------|--------|
| [List critical gaps here] | | |

---

## Source Materials

Original exports are in `source/` directory:

| File | Contents |
|------|----------|
| [List source files] | |

---

**Maintainer:** {{AGENT}}
