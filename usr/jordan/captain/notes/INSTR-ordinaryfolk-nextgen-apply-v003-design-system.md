# Instructions: Apply ordinaryfolk-003 Design System

**To:** Agent working on Health OS UI in ordinaryfolk-nextgen
**From:** housekeeping
**Date:** 2026-01-13
**Priority:** High

---

## Context

We've created an improved design system (`ordinaryfolk-003`) using a hybrid extraction method that combines:
- **Exact hex values** from Figma API
- **Token names and specs** from designer PDFs

This is more accurate than the original `ordinaryfolk-001` which used approximate hex values from visual inspection.

---

## Source Files

The new design system is located in your project at:
```
claude/knowledge/design-systems/ordinaryfolk-003/
├── colors.md           # 69 colors with exact hex
├── typography.md       # 20+ text styles with complete specs
├── tailwind-config.md  # Ready-to-use Tailwind config
└── INDEX.md            # Overview and comparison
```

---

## Tasks

### 1. Update Tailwind Config

Copy the color and typography configuration from `ordinaryfolk-003/tailwind-config.md` into your project's `tailwind.config.ts`.

Key additions:
- `of-black` scale (900-600) with exact values
- `of-grey` scale (900-200) with exact values
- `warm` palette (cream, light, sand, caramel, bronze, peach) - **NEW**
- Custom `fontSize` entries for all text styles (h1-h6, body-1 through body-5, etc.)

### 2. Key Color Updates

These hex values are now **exact** (from API) vs approximate (from PDF):

| Token | Old (v001) | New (v003) | Notes |
|-------|------------|------------|-------|
| of-black-900 | #1A1A1A | #141414 | Primary text |
| of-grey-800 | #4F4F4F | #616161 | Secondary text |
| of-grey-300 | #D6D6D6 | #CEC9C6 | Borders |
| off-white | #FAFAFA | #F7F6F5 | Page background |

### 3. New Health OS Warm Palette

Add these warm accent colors that weren't in v001:

```typescript
'warm': {
  cream: '#EBE3D7',    // Warm backgrounds
  light: '#F8F3ED',    // Light warm bg
  sand: '#D0B895',     // Warm accent
  caramel: '#B89460',  // Warm mid-tone
  bronze: '#A37E49',   // Warm dark
  peach: '#D7A492',    // Soft accent
}
```

Use these for the distinctive Health OS warm feel.

### 4. Typography Classes

The new config includes custom fontSize entries. You can use:

```jsx
<h1 className="text-h1">          // 34px, Regular
<h2 className="text-h2">          // 22px/28px, Medium
<p className="text-body-2">       // 16px/20px, Regular (default)
<p className="text-body-2-bold">  // 16px/20px, Semibold
<label className="text-label">    // 12px, Semibold, tracking-wide
<button className="text-button-1"> // 16px, Semibold
```

### 5. Verify Font Setup

Confirm Graphik fonts are loaded:
```
apps/public/health-os/public/fonts/
├── Graphik-Regular.otf    (400)
├── Graphik-Medium.otf     (500)
├── Graphik-Semibold.otf   (600)
```

---

## Validation

After applying changes:

1. Check that primary text uses `text-of-black-900` (#141414)
2. Check that page backgrounds use `bg-off-white` (#F7F6F5)
3. Check that warm sections use `bg-warm-cream` (#EBE3D7)
4. Verify buttons use `bg-blue-600` (#4675E4)

---

## Reference

For complete details, read:
- `ordinaryfolk-003/colors.md` - Full color palette with usage guidelines
- `ordinaryfolk-003/typography.md` - All text styles with Tailwind classes
- `ordinaryfolk-003/tailwind-config.md` - Complete config to copy

---

## Questions?

If colors in the designs don't match anything in the palette, check the "Undocumented Colors" section in `colors.md`. These are colors found in the Figma document but not in the design system PDF - they may be intentional accents or candidates for cleanup.
