# Assets

**Design System:** {{BRAND_NAME}} v{{VERSION}}
**Last Updated:** {{DATE}}

---

## Overview

This document catalogs visual assets included in the design system.

---

## Logos

### Primary Logo

| Variant | File | Usage |
|---------|------|-------|
| Full color | `source/logo.svg` | Default usage |
| Light (on dark) | `source/logo-light.svg` | Dark backgrounds |
| Dark (on light) | `source/logo-dark.svg` | Light backgrounds |
| Icon only | `source/logo-icon.svg` | Favicon, small spaces |

### Logo Usage

| Context | Minimum Size | Clear Space |
|---------|--------------|-------------|
| Web | ??px height | ??px |
| Mobile | ??px height | ??px |
| Favicon | 32x32px | N/A |

---

## Icons

### Icon System

| Property | Value |
|----------|-------|
| Library | [e.g., Lucide, Heroicons, custom] |
| Default size | ??px |
| Stroke width | ??px |

### Icon Sizes

| Size | Value | Usage |
|------|-------|-------|
| XS | 12px | Inline, badges |
| S | 16px | Buttons, inputs |
| M | 20px | Default |
| L | 24px | Navigation |
| XL | 32px | Empty states |

### Custom Icons

| Icon | File | Usage |
|------|------|-------|
| [Icon name] | `source/icons/[name].svg` | [Usage] |

---

## Illustrations

| Name | File | Usage |
|------|------|-------|
| [Illustration name] | `source/illustrations/[name].svg` | [Usage] |

---

## Trust Badges / Badges

| Badge | File | Usage |
|-------|------|-------|
| [Badge name] | `source/badges/[name].svg` | [Usage] |

---

## Images

### Placeholder Images

| Type | Dimensions | File |
|------|------------|------|
| Avatar placeholder | 48x48 | `source/placeholder-avatar.png` |
| Card placeholder | 16:9 | `source/placeholder-card.png` |
| Hero placeholder | 1440x600 | `source/placeholder-hero.png` |

### Product Images

| Type | Dimensions | Notes |
|------|------------|-------|
| Thumbnail | 100x100 | Square crop |
| Card | 300x200 | 3:2 ratio |
| Detail | 600x400 | 3:2 ratio |

---

## Asset Guidelines

### SVG Best Practices

1. **Optimize SVGs** - Run through SVGO before committing
2. **Use currentColor** - For icons that should inherit text color
3. **Remove fixed dimensions** - Use viewBox, not width/height
4. **Clean up** - Remove unnecessary groups, IDs, metadata

### Image Optimization

1. **Format**: Use WebP with PNG fallback
2. **Responsive**: Provide 1x and 2x versions for retina
3. **Lazy load**: Images below the fold
4. **Alt text**: Always provide descriptive alt text

---

## File Inventory

### Source Directory Structure

```
source/
├── logos/
│   ├── logo.svg
│   ├── logo-light.svg
│   └── logo-icon.svg
├── icons/
│   └── [custom-icons].svg
├── illustrations/
│   └── [illustrations].svg
├── badges/
│   └── [badges].svg
└── images/
    └── [images].png
```

### Asset Count

| Type | Count |
|------|-------|
| Logos | ? |
| Icons | ? |
| Illustrations | ? |
| Badges | ? |
| Images | ? |

---

## Source

[Note where these assets came from - Figma export, designer handoff, etc.]

---

**Maintainer:** {{AGENT}}
