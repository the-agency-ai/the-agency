# Tailwind Configuration

**Design System:** {{BRAND_NAME}} v{{VERSION}}
**Last Updated:** {{DATE}}

---

## Complete Theme Extension

Copy this into your `tailwind.config.ts`:

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      // ============================================
      // FONT FAMILY
      // ============================================
      fontFamily: {
        sans: [
          '{{FONT_FAMILY}}',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
      },

      // ============================================
      // COLORS
      // ============================================
      colors: {
        // Primary
        'primary': {
          100: '#??????',
          300: '#??????',
          500: '#??????',
          700: '#??????',
          900: '#??????',
        },
        // Secondary
        'secondary': {
          100: '#??????',
          500: '#??????',
          900: '#??????',
        },
        // Grey scale
        'grey': {
          100: '#??????',
          200: '#??????',
          300: '#??????',
          400: '#??????',
          500: '#??????',
          600: '#??????',
          700: '#??????',
          800: '#??????',
          900: '#??????',
        },
        // Semantic
        'success': {
          100: '#??????',
          500: '#??????',
          700: '#??????',
        },
        'warning': {
          100: '#??????',
          500: '#??????',
          700: '#??????',
        },
        'error': {
          100: '#??????',
          500: '#??????',
          700: '#??????',
        },
        'info': {
          100: '#??????',
          500: '#??????',
          700: '#??????',
        },
        // Special
        'off-white': '#??????',
      },

      // ============================================
      // TYPOGRAPHY
      // ============================================
      fontSize: {
        // Headings
        'h1': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'h2': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'h3': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'h4': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'h5': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'h6': ['??px', { lineHeight: '??px', letterSpacing: '0' }],

        // Body
        'body-1': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'body-2': ['??px', { lineHeight: '??px', letterSpacing: '0' }],
        'body-3': ['??px', { lineHeight: '??px', letterSpacing: '0' }],

        // Labels
        'label': ['??px', { lineHeight: '??px', letterSpacing: '0.04em' }],
        'caption': ['??px', { lineHeight: '??px', letterSpacing: '0' }],

        // Buttons
        'button-lg': ['??px', { lineHeight: '1.2', letterSpacing: '0' }],
        'button': ['??px', { lineHeight: '1.2', letterSpacing: '0' }],
        'button-sm': ['??px', { lineHeight: '1.2', letterSpacing: '0' }],
      },

      // ============================================
      // SPACING
      // ============================================
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

      // ============================================
      // BORDER RADIUS
      // ============================================
      borderRadius: {
        'xs': '2px',
        's': '4px',
        'm': '8px',
        'l': '16px',
        'xl': '20px',
      },

      // ============================================
      // BOX SHADOW
      // ============================================
      boxShadow: {
        'low': '0px 4px 10px 0px rgba(0, 0, 0, 0.1)',
        'medium': '0px 8px 10px 0px rgba(0, 0, 0, 0.1)',
        'high': '0px 8px 10px 0px rgba(0, 0, 0, 0.2)',
      },

      // ============================================
      // TRANSITIONS
      // ============================================
      transitionDuration: {
        'fast': '150ms',
        'default': '200ms',
        'slow': '300ms',
      },
    },
  },
  plugins: [],
};

export default config;
```

---

## Usage Examples

### Typography

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

### Colors

```jsx
// Text
<p className="text-grey-900">Primary text</p>
<p className="text-grey-700">Secondary text</p>

// Backgrounds
<div className="bg-off-white">Page background</div>
<div className="bg-white">Card surface</div>

// Actions
<button className="bg-primary-500 hover:bg-primary-700 text-white">
  Primary Action
</button>

// Semantic
<div className="bg-success-100 text-success-700 border border-success-500">
  Success message
</div>
```

### Spacing

```jsx
// Card padding
<div className="p-m">24px padding</div>

// Section spacing
<section className="py-xxl px-m">
  48px vertical, 24px horizontal
</section>

// Gaps
<div className="flex gap-s">16px gap</div>
```

### Effects

```jsx
// Card with shadow
<div className="shadow-low hover:shadow-medium transition-shadow duration-default rounded-m">
  Card content
</div>

// Modal
<div className="shadow-high rounded-l p-l">
  Modal content
</div>
```

---

## Semantic Aliases (Optional)

For convenience, add semantic aliases:

```typescript
colors: {
  // ... existing colors ...

  // Semantic aliases
  'text-primary': '#??????',      // grey-900
  'text-secondary': '#??????',    // grey-700
  'text-disabled': '#??????',     // grey-500

  'bg-page': '#??????',           // off-white
  'bg-surface': '#FFFFFF',        // white
  'bg-muted': '#??????',          // grey-200

  'border-default': '#??????',    // grey-300
  'border-strong': '#??????',     // grey-500

  'action-primary': '#??????',    // primary-500
  'action-success': '#??????',    // success-500
  'action-error': '#??????',      // error-500
}
```

---

## Font Loading

Add to your `globals.css`:

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

## Notes

- **Hex values marked with `#??????` need to be filled in** - See `colors.md`
- **Font sizes marked with `??px` need to be filled in** - See `typography.md`
- Run `./tools/designsystem-validate` to check for missing values

---

## Verification Status

- [ ] All color hex values verified
- [ ] All typography values verified
- [ ] Config compiles without errors
- [ ] Font files available

---

**Maintainer:** {{AGENT}}
