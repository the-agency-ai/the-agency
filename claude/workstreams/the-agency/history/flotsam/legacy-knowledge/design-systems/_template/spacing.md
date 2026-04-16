# Spacing System

**Design System:** {{BRAND_NAME}} v{{VERSION}}
**Last Updated:** {{DATE}}

---

## Spacing Scale

Base unit: **?px**

| Token | Value | Tailwind | Usage |
|-------|-------|----------|-------|
| `xxxs` | 4px | `p-1` | Minimal spacing |
| `xxs` | 8px | `p-2` | Tight spacing |
| `xs` | 12px | `p-3` | Small spacing |
| `s` | 16px | `p-4` | Default spacing |
| `m` | 24px | `p-6` | Medium spacing |
| `l` | 32px | `p-8` | Large spacing |
| `xl` | 40px | `p-10` | Extra large |
| `xxl` | 48px | `p-12` | Section spacing |
| `xxxl` | 64px | `p-16` | Major sections |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 2px | Subtle rounding |
| `radius-s` | 4px | Buttons, inputs |
| `radius-m` | 8px | Cards |
| `radius-l` | 16px | Modals |
| `radius-xl` | 20px | Large containers |
| `radius-full` | 9999px | Pills, avatars |

---

## Component Spacing

### Cards

| Property | Value |
|----------|-------|
| Padding | ?? (use `m` or `l`) |
| Gap between cards | ?? |
| Border radius | ?? |

### Buttons

| Property | Value |
|----------|-------|
| Horizontal padding | ?? |
| Vertical padding | ?? |
| Gap (icon + text) | ?? |

### Form Inputs

| Property | Value |
|----------|-------|
| Height | ??px |
| Horizontal padding | ?? |
| Label gap | ?? |
| Field gap | ?? |

### Lists

| Property | Value |
|----------|-------|
| Item gap | ?? |
| Nested indent | ?? |

---

## Layout Spacing

### Page Container

| Viewport | Max Width | Horizontal Padding |
|----------|-----------|-------------------|
| Mobile | 100% | ?? |
| Tablet | ??px | ?? |
| Desktop | ??px | ?? |

### Section Spacing

| Context | Value |
|---------|-------|
| Between sections | ?? |
| Section padding (vertical) | ?? |
| Section padding (horizontal) | ?? |

---

## Grid System

| Property | Value |
|----------|-------|
| Columns | 12 |
| Gutter width | ?? |
| Margin (mobile) | ?? |
| Margin (desktop) | ?? |

---

## Usage Examples

```jsx
// Card with standard spacing
<div className="p-m rounded-radius-m">
  Card content
</div>

// Section spacing
<section className="py-xxl px-m">
  Section content
</section>

// Flex with gaps
<div className="flex gap-s">
  <Item />
  <Item />
</div>
```

---

## Tailwind Configuration

```typescript
spacing: {
  'xxxs': '4px',
  'xxs': '8px',
  'xs': '12px',
  's': '16px',
  'm': '24px',
  'l': '32px',
  'xl': '40px',
  'xxl': '48px',
  'xxxl': '64px',
},
borderRadius: {
  'xs': '2px',
  's': '4px',
  'm': '8px',
  'l': '16px',
  'xl': '20px',
},
```

---

## Source

[Note where these specs came from]

**Verification Status:** [ ] Verified from source / [ ] Approximated

---

**Maintainer:** {{AGENT}}
