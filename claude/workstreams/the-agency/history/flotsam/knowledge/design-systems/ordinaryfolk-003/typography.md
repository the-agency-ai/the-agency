# Typography System

**Source:** API extraction + OF_APP_DS_text_styles.pdf
**Method:** Hybrid (font usage from API, complete specs from PDF)

---

## Summary

| Source | What It Provides |
|--------|------------------|
| Figma API | Font families, usage counts |
| Designer PDF | Sizes, weights, line heights, letter spacing |

---

## Font Families (from API)

| Font | Usage Count | Role |
|------|-------------|------|
| **Graphik** | 418 instances | Primary (all UI text) |
| Poppins | 338 instances | Secondary (marketing?) |
| Roboto | 1 instance | Fallback/system |

**Primary Font:** Graphik

**Weights Used:**
- Regular (400)
- Medium (500)
- Semibold (600)

**Fallback Stack:**
```css
font-family: 'Graphik', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

---

## Headers (Mobile)

| Style | Weight | Size | Line Height | Letter Spacing | Transform | Tailwind Class |
|-------|--------|------|-------------|----------------|-----------|----------------|
| H1 | Regular (400) | 34px | Auto | 0% | sentence case | `text-4xl font-normal` |
| H2 | Medium (500) | 22px | 28px | 0% | sentence case | `text-[22px] leading-7 font-medium` |
| H3 | Regular (400) | 22px | 28px | 0% | sentence case | `text-[22px] leading-7 font-normal` |
| H4 | Semibold (600) | 18px | Auto | 0% | sentence case | `text-lg font-semibold` |
| H5 | Semibold (600) | 16px | Auto | 0% | sentence case | `text-base font-semibold` |
| H6 | Medium (500) | 14px | Auto | 0% | sentence case | `text-sm font-medium` |

### Header Classes

```jsx
// H1 - Hero headlines
<h1 className="font-normal text-[34px]">

// H2 - Section headers
<h2 className="font-medium text-[22px] leading-7">

// H3 - Subsection headers
<h3 className="font-normal text-[22px] leading-7">

// H4 - Card headers
<h4 className="font-semibold text-lg">

// H5 - Small headers
<h5 className="font-semibold text-base">

// H6 - Micro headers
<h6 className="font-medium text-sm">
```

---

## Subheads

| Style | Weight | Size | Line Height | Letter Spacing | Tailwind Class |
|-------|--------|------|-------------|----------------|----------------|
| Subhead 1 | Semibold (600) | 14px | Auto | 4% | `text-sm font-semibold tracking-wide` |
| Labels (Subhead 2) | Semibold (600) | 12px | Auto | 4% | `text-xs font-semibold tracking-wide` |

```jsx
// Subhead 1 - Section labels
<span className="font-semibold text-sm tracking-wide">

// Labels - Form labels, tags
<label className="font-semibold text-xs tracking-wide">
```

---

## Body Text

| Style | Weight | Size | Line Height | Letter Spacing | Tailwind Class |
|-------|--------|------|-------------|----------------|----------------|
| Body 1 | Regular (400) | 18px | 24px | 0% | `text-lg leading-6 font-normal` |
| Body 1 Semibold | Semibold (600) | 18px | 24px | 0% | `text-lg leading-6 font-semibold` |
| Body 2 | Regular (400) | 16px | 20px | 0% | `text-base leading-5 font-normal` |
| Body 2 Semibold | Semibold (600) | 16px | 20px | 0% | `text-base leading-5 font-semibold` |
| Body 3 | Regular (400) | 14px | 18px | 0% | `text-sm leading-[18px] font-normal` |
| Body 3 Semibold | Semibold (600) | 14px | 18px | 0% | `text-sm leading-[18px] font-semibold` |
| Body 4 | Regular (400) | 12px | 16px | 0% | `text-xs leading-4 font-normal` |
| Body 4 Semibold | Semibold (600) | 12px | 16px | 0% | `text-xs leading-4 font-semibold` |
| Body 5 | Regular (400) | 10px | 14px | 0% | `text-[10px] leading-[14px] font-normal` |
| Body 5 Semibold | Semibold (600) | 10px | 14px | 0% | `text-[10px] leading-[14px] font-semibold` |

### Body Classes

```jsx
// Body 1 - Large body (emphasis)
<p className="text-lg leading-6">
<p className="text-lg leading-6 font-semibold">

// Body 2 - Default body (most content)
<p className="text-base leading-5">
<p className="text-base leading-5 font-semibold">

// Body 3 - Secondary body
<p className="text-sm leading-[18px]">

// Body 4 - Small text
<p className="text-xs leading-4">

// Body 5 - Micro text (use sparingly)
<p className="text-[10px] leading-[14px]">
```

---

## Buttons

| Style | Weight | Size | Line Height | Letter Spacing | Transform | Tailwind Class |
|-------|--------|------|-------------|----------------|-----------|----------------|
| Button 1 / Form / Tabs | Semibold (600) | 16px | Auto | 0% | Title Case | `text-base font-semibold` |
| Button 2 / Form / Tabs | Semibold (600) | 14px | Auto | 0% | Title Case | `text-sm font-semibold` |

```jsx
// Button 1 - Primary buttons, main CTAs
<button className="font-semibold text-base">

// Button 2 - Secondary buttons
<button className="font-semibold text-sm">
```

---

## Tables

| Style | Weight | Size | Line Height | Letter Spacing | Transform | Tailwind Class |
|-------|--------|------|-------------|----------------|-----------|----------------|
| Table 1 | Regular (400) | 14px | Auto | 5% | ALL CAPS | `text-sm font-normal tracking-wider uppercase` |
| Table 2 | Regular (400) | 12px | Auto | 5% | ALL CAPS | `text-xs font-normal tracking-wider uppercase` |

```jsx
// Table 1 - Table headers
<th className="text-sm tracking-wider uppercase">

// Table 2 - Small table headers
<th className="text-xs tracking-wider uppercase">
```

---

## Typography Scale Summary

| Role | Size | Line Height | Weight | Use Case |
|------|------|-------------|--------|----------|
| Hero | 34px | Auto | Regular | Main page headlines |
| Section Header | 22px | 28px | Medium | Page sections |
| Card Header | 18px | Auto | Semibold | Card titles |
| Body Large | 18px | 24px | Regular | Emphasis paragraphs |
| **Body Default** | 16px | 20px | Regular | Most content |
| Body Small | 14px | 18px | Regular | Secondary info |
| Caption | 12px | 16px | Regular | Metadata, timestamps |
| Micro | 10px | 14px | Regular | Legal, fine print |

---

## Usage Guidelines

### Hierarchy Rules

1. **One H1 per page** - Hero/main headline only
2. **H2 for sections** - Major page divisions
3. **H3-H4 for subsections** - Card headers, feature blocks
4. **Body 2 for default** - Most paragraph text
5. **Body 3-4 for secondary** - Captions, metadata

### Weight Usage

- **Regular (400)** - Default body text, H1, H3
- **Medium (500)** - H2, H6 (slight emphasis)
- **Semibold (600)** - H4, H5, buttons, labels, emphasis

### Accessibility

- Minimum body text: 14px (Body 3)
- Avoid Body 5 (10px) for essential content
- Ensure sufficient color contrast

---

## Font Files

**Location:** `apps/public/health-os/public/fonts/`

```
fonts/
├── Graphik-Light.otf      (300)
├── Graphik-Regular.otf    (400)
├── Graphik-RegularItalic.otf (400 italic)
├── Graphik-Medium.otf     (500)
├── Graphik-Semibold.otf   (600)
└── Graphik-Bold.otf       (700)
```

### CSS @font-face

```css
@font-face {
  font-family: 'Graphik';
  src: url('/fonts/Graphik-Regular.otf') format('opentype');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Graphik';
  src: url('/fonts/Graphik-Medium.otf') format('opentype');
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Graphik';
  src: url('/fonts/Graphik-Semibold.otf') format('opentype');
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}
```

---

## Tailwind Config

See `tailwind-config.md` for ready-to-use configuration.
