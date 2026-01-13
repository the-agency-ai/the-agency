# Ordinary Folk Design System (v003)

**Method:** Hybrid extraction (API + PDF)
**Extracted:** 2026-01-13

---

## Quick Reference

| File | Contents | Status |
|------|----------|--------|
| [colors.md](colors.md) | 69 colors with token names | **Complete** |
| [typography.md](typography.md) | 20+ text styles with specs | **Complete** |
| [spacing.md](spacing.md) | Spacing scale | Template |
| [effects.md](effects.md) | Shadows, borders | Template |
| [assets.md](assets.md) | Logos, icons | Not extracted |
| [tailwind-config.md](tailwind-config.md) | Tailwind theme | **Complete** |

---

## What Makes This Different

This design system was created using the **hybrid workflow**:

| Source | What It Provided |
|--------|------------------|
| **Figma API** | 69 exact hex colors, 3 fonts with usage counts |
| **PDF (colors)** | Token names, organization, usage guidelines |
| **PDF (typography)** | Complete specs: sizes, weights, line-heights |
| **Claude** | Merged sources, generated Tailwind config |

**Result:** Complete, production-ready design tokens in ~30 minutes.

---

## Source

- **Figma File:** NOAH-APP (Health OS)
- **File Key:** `qaWYnSjA1EiarqNwMHM2zK`
- **PDFs:** `OF_DS_colours.pdf`, `OF_APP_DS_text_styles.pdf`

---

## Extraction Summary

| Type | API Data | PDF Data | Merged Result |
|------|----------|----------|---------------|
| Colors | 69 hex values | ~50 token names | Named palette + undocumented colors |
| Fonts | 3 families, usage counts | Weight/size specs | Complete typography system |
| Text Styles | 0 published | 20+ styles | Full spec table with Tailwind classes |

---

## Key Findings

### Colors
- **Core palette:** ~50 tokens (OF Black, OF Grey, Blue, Green, etc.)
- **Health OS accents:** Warm creams, peach, bronze (found in API)
- **Undocumented:** 20+ colors used but not in design system PDF

### Typography
- **Primary font:** Graphik (418 uses)
- **Secondary:** Poppins (338 uses) - likely marketing
- **Styles:** H1-H6, Body 1-5, Buttons, Tables, Labels

---

## Usage

```bash
# Copy the tailwind config
cat tailwind-config.md

# Validate completeness
./tools/designsystem-validate /Users/jdm/code/the-agency/claude/knowledge/design-systems/ordinaryfolk-003
```

---

## Comparison: v001 vs v003

| Aspect | v001 (Manual) | v003 (Hybrid) |
|--------|---------------|---------------|
| Time | ~2.5 hours | ~30 minutes |
| Hex accuracy | Approximate (visual) | Exact (API) |
| Coverage | Curated palette | All colors used |
| Typography | Complete | Complete |
| Discoverability | None | Found 20+ undocumented colors |
