# Typography

**Design System:** {{BRAND_NAME}} v{{VERSION}}
**Last Updated:** {{DATE}}

---

## Font Family

### Primary Font

**{{FONT_FAMILY}}**

| Weight | Value | CSS |
|--------|-------|-----|
| Regular | 400 | `font-normal` |
| Medium | 500 | `font-medium` |
| Semibold | 600 | `font-semibold` |
| Bold | 700 | `font-bold` |

### Fallback Stack

```css
font-family: '{{FONT_FAMILY}}', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

### Font Files

| Weight | File | Status |
|--------|------|--------|
| Regular | `/fonts/{{FONT}}-Regular.woff2` | [ ] Available |
| Medium | `/fonts/{{FONT}}-Medium.woff2` | [ ] Available |
| Semibold | `/fonts/{{FONT}}-Semibold.woff2` | [ ] Available |
| Bold | `/fonts/{{FONT}}-Bold.woff2` | [ ] Available |

---

## Text Styles

### Headings

| Style | Size | Line Height | Weight | Letter Spacing |
|-------|------|-------------|--------|----------------|
| H1 | ??px | ??px | ??? | ??? |
| H2 | ??px | ??px | ??? | ??? |
| H3 | ??px | ??px | ??? | ??? |
| H4 | ??px | ??px | ??? | ??? |
| H5 | ??px | ??px | ??? | ??? |
| H6 | ??px | ??px | ??? | ??? |

### Body Text

| Style | Size | Line Height | Weight | Usage |
|-------|------|-------------|--------|-------|
| Body 1 | ??px | ??px | Regular | Primary content |
| Body 2 | ??px | ??px | Regular | Secondary content |
| Body 3 | ??px | ??px | Regular | Small text |

### Labels & Captions

| Style | Size | Line Height | Weight | Transform |
|-------|------|-------------|--------|-----------|
| Label | ??px | ??px | ??? | uppercase? |
| Caption | ??px | ??px | ??? | |
| Overline | ??px | ??px | ??? | uppercase? |

### Buttons

| Style | Size | Line Height | Weight |
|-------|------|-------------|--------|
| Button Large | ??px | ??px | ??? |
| Button Default | ??px | ??px | ??? |
| Button Small | ??px | ??px | ??? |

---

## Responsive Typography

### Mobile (default)

[Specs above are for mobile]

### Desktop (if different)

| Style | Mobile Size | Desktop Size |
|-------|-------------|--------------|
| H1 | ??px | ??px |
| H2 | ??px | ??px |
| Body 1 | ??px | ??px |

**Note:** If desktop specs are the same as mobile, indicate "Same as mobile" here.

---

## Usage Examples

```jsx
// Heading 1
<h1 className="text-h1 font-semibold text-grey-900">
  Page Title
</h1>

// Body text
<p className="text-body-1 font-normal text-grey-700">
  Body content here.
</p>

// Label
<span className="text-label font-semibold text-grey-600 uppercase">
  Form Label
</span>
```

---

## Font Loading

```css
@font-face {
  font-family: '{{FONT_FAMILY}}';
  src: url('/fonts/{{FONT}}-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: '{{FONT_FAMILY}}';
  src: url('/fonts/{{FONT}}-Medium.woff2') format('woff2');
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: '{{FONT_FAMILY}}';
  src: url('/fonts/{{FONT}}-Semibold.woff2') format('woff2');
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}
```

---

## Source

[Note where these specs came from]

**Verification Status:** [ ] Verified from source / [ ] Approximated

---

**Maintainer:** {{AGENT}}
