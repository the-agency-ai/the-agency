# Effects

**Design System:** {{BRAND_NAME}} v{{VERSION}}
**Last Updated:** {{DATE}}

---

## Box Shadows

### Elevation System

| Level | Token | CSS Value | Usage |
|-------|-------|-----------|-------|
| None | `shadow-none` | none | Flat elements |
| Low | `shadow-low` | 0px 4px 10px rgba(0,0,0,0.1) | Cards, dropdowns |
| Medium | `shadow-medium` | 0px 8px 10px rgba(0,0,0,0.1) | Hover states, popovers |
| High | `shadow-high` | 0px 8px 10px rgba(0,0,0,0.2) | Modals, dialogs |

### Interactive Shadows

| State | Shadow | Usage |
|-------|--------|-------|
| Default | `shadow-low` | Resting state |
| Hover | `shadow-medium` | On hover |
| Active | `shadow-low` | On click |
| Focused | `shadow-low` + focus ring | Keyboard focus |

---

## Borders

### Border Widths

| Token | Value | Usage |
|-------|-------|-------|
| `border-0` | 0px | No border |
| `border` | 1px | Default border |
| `border-2` | 2px | Emphasis border |

### Border Styles

| Style | Usage |
|-------|-------|
| Solid | Default for all borders |
| Dashed | Drop zones, optional fields |

### Border Colors

See `colors.md` for border color tokens.

| Purpose | Token |
|---------|-------|
| Default | `grey-300` |
| Strong | `grey-500` |
| Focus | `primary-500` |
| Error | `error-500` |
| Success | `success-500` |

---

## Focus States

### Focus Ring

```css
/* Default focus ring */
outline: 2px solid [primary-500];
outline-offset: 2px;
```

| Property | Value |
|----------|-------|
| Width | 2px |
| Style | solid |
| Color | primary-500 |
| Offset | 2px |

---

## Dividers

### Horizontal Rule

| Property | Value |
|----------|-------|
| Height | 1px |
| Color | grey-300 |
| Margin | m (24px) vertical |

```jsx
<hr className="border-t border-grey-300 my-m" />
```

---

## Overlays

### Modal Backdrop

| Property | Value |
|----------|-------|
| Color | black |
| Opacity | 50% |

```css
background: rgba(0, 0, 0, 0.5);
```

---

## Transitions

### Duration

| Token | Value | Usage |
|-------|-------|-------|
| `duration-fast` | 150ms | Micro-interactions |
| `duration-default` | 200ms | Most transitions |
| `duration-slow` | 300ms | Page transitions |

### Easing

| Token | Value | Usage |
|-------|-------|-------|
| `ease-default` | ease-in-out | Most transitions |
| `ease-in` | ease-in | Exit animations |
| `ease-out` | ease-out | Enter animations |

### Common Transitions

```css
/* Button hover */
transition: background-color 200ms ease-in-out;

/* Card hover (shadow) */
transition: box-shadow 200ms ease-in-out;

/* Modal enter */
transition: opacity 300ms ease-out, transform 300ms ease-out;
```

---

## Tailwind Configuration

```typescript
boxShadow: {
  'none': 'none',
  'low': '0px 4px 10px 0px rgba(0, 0, 0, 0.1)',
  'medium': '0px 8px 10px 0px rgba(0, 0, 0, 0.1)',
  'high': '0px 8px 10px 0px rgba(0, 0, 0, 0.2)',
},
transitionDuration: {
  'fast': '150ms',
  'default': '200ms',
  'slow': '300ms',
},
```

---

## Usage Examples

```jsx
// Card with shadow
<div className="shadow-low hover:shadow-medium transition-shadow duration-default rounded-m">
  Card content
</div>

// Modal
<div className="shadow-high rounded-l p-l">
  Modal content
</div>

// Focus state
<button className="focus:outline-2 focus:outline-primary-500 focus:outline-offset-2">
  Button
</button>
```

---

## Source

[Note where these specs came from]

**Verification Status:** [ ] Verified from source / [ ] Approximated

---

**Maintainer:** {{AGENT}}
