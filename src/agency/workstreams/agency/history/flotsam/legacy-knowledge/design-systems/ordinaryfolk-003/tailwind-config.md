# Tailwind Configuration

**Source:** Merged from API hex values + PDF token names
**Status:** Ready to use

---

## Complete Theme Extension

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  theme: {
    extend: {
      colors: {
        // === NEUTRALS ===
        'of-black': {
          900: '#141414', // Primary text
          800: '#2F2F2F', // Secondary dark
          700: '#454545', // Tertiary dark
          600: '#595959', // Muted dark
        },
        'of-grey': {
          900: '#302D28', // Dark borders
          800: '#616161', // Secondary text
          700: '#737373', // Placeholder
          600: '#898683', // Disabled text
          500: '#969290', // Light borders
          400: '#ABA8A6', // Disabled borders
          300: '#CEC9C6', // Default borders
          200: '#E0DDDA', // Subtle backgrounds
        },
        'off-white': '#F7F6F5',

        // === BRAND COLORS ===
        'blue': {
          900: '#003534',
          700: '#2458CE',
          600: '#4675E4', // Primary action
          500: '#366EFF', // Hover
          400: '#406AFF',
          300: '#DBEBFD',
          200: '#DBEBFD',
          100: '#DBEBFD',
        },
        'green': {
          900: '#003633',
          700: '#01743B',
          600: '#3D9974', // Success
          400: '#5CA983',
          300: '#AEEB90',
          200: '#C2F0AC',
          100: '#DBFDCB',
        },

        // === SEMANTIC COLORS ===
        'purple': {
          400: '#9747FF',
          300: '#A269FF',
          200: '#A269FF',
          100: '#A269FF',
        },
        'red': {
          400: '#EB4646', // Error
          300: '#EB4A4A',
          200: '#EB4A4A',
          100: '#EB4A4A',
        },
        'orange': {
          400: '#FF7628', // Warning
          300: '#FF8951',
          200: '#F4BD98',
          100: '#F4BD98',
        },
        'yellow': {
          400: '#FEFEB9',
          300: '#FEFEB9',
          200: '#FEFEB9',
          100: '#FEFEB9',
        },

        // === HEALTH OS ACCENTS ===
        'warm': {
          cream: '#EBE3D7',
          light: '#F8F3ED',
          sand: '#D0B895',
          caramel: '#B89460',
          bronze: '#A37E49',
          peach: '#D7A492',
        },
      },

      fontFamily: {
        sans: ['Graphik', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        display: ['Poppins', 'Graphik', 'sans-serif'],
      },

      fontSize: {
        // Headers
        'h1': ['34px', { lineHeight: 'auto', fontWeight: '400' }],
        'h2': ['22px', { lineHeight: '28px', fontWeight: '500' }],
        'h3': ['22px', { lineHeight: '28px', fontWeight: '400' }],
        'h4': ['18px', { lineHeight: 'auto', fontWeight: '600' }],
        'h5': ['16px', { lineHeight: 'auto', fontWeight: '600' }],
        'h6': ['14px', { lineHeight: 'auto', fontWeight: '500' }],

        // Body
        'body-1': ['18px', { lineHeight: '24px', fontWeight: '400' }],
        'body-1-bold': ['18px', { lineHeight: '24px', fontWeight: '600' }],
        'body-2': ['16px', { lineHeight: '20px', fontWeight: '400' }],
        'body-2-bold': ['16px', { lineHeight: '20px', fontWeight: '600' }],
        'body-3': ['14px', { lineHeight: '18px', fontWeight: '400' }],
        'body-3-bold': ['14px', { lineHeight: '18px', fontWeight: '600' }],
        'body-4': ['12px', { lineHeight: '16px', fontWeight: '400' }],
        'body-4-bold': ['12px', { lineHeight: '16px', fontWeight: '600' }],
        'body-5': ['10px', { lineHeight: '14px', fontWeight: '400' }],

        // UI
        'subhead-1': ['14px', { lineHeight: 'auto', fontWeight: '600', letterSpacing: '0.04em' }],
        'label': ['12px', { lineHeight: 'auto', fontWeight: '600', letterSpacing: '0.04em' }],
        'button-1': ['16px', { lineHeight: 'auto', fontWeight: '600' }],
        'button-2': ['14px', { lineHeight: 'auto', fontWeight: '600' }],
        'table-1': ['14px', { lineHeight: 'auto', fontWeight: '400', letterSpacing: '0.05em' }],
        'table-2': ['12px', { lineHeight: 'auto', fontWeight: '400', letterSpacing: '0.05em' }],
      },

      fontWeight: {
        normal: '400',
        medium: '500',
        semibold: '600',
      },

      letterSpacing: {
        wide: '0.04em',   // 4% - subheads, labels
        wider: '0.05em',  // 5% - tables
      },
    },
  },
}

export default config
```

---

## Usage Examples

### Colors

```jsx
// Text
<p className="text-of-black-900">Primary text</p>
<p className="text-of-grey-800">Secondary text</p>
<p className="text-of-grey-700">Placeholder</p>

// Backgrounds
<div className="bg-off-white">Page background</div>
<div className="bg-of-grey-200">Subtle surface</div>
<div className="bg-warm-cream">Health OS warm bg</div>

// Interactive
<button className="bg-blue-600 hover:bg-blue-700">Primary</button>
<div className="text-green-600">Success message</div>
<div className="text-red-400">Error message</div>
<div className="text-orange-400">Warning message</div>
```

### Typography

```jsx
// Headers
<h1 className="text-h1">Hero headline</h1>
<h2 className="text-h2">Section header</h2>
<h4 className="text-h4">Card header</h4>

// Body
<p className="text-body-2">Default paragraph text</p>
<p className="text-body-2-bold">Emphasized text</p>
<p className="text-body-3">Secondary text</p>

// UI Elements
<label className="text-label uppercase">Form label</label>
<button className="text-button-1">Primary Button</button>
<th className="text-table-1 uppercase">Table Header</th>
```

---

## Semantic Aliases (Optional)

Add these for clearer intent:

```typescript
// In your tailwind.config.ts, add to colors:
colors: {
  // ...existing colors...

  // Semantic aliases
  primary: '#4675E4',      // blue-600
  'primary-hover': '#2458CE', // blue-700
  success: '#3D9974',      // green-600
  error: '#EB4646',        // red-400
  warning: '#FF7628',      // orange-400

  'text-primary': '#141414',   // of-black-900
  'text-secondary': '#616161', // of-grey-800
  'text-muted': '#898683',     // of-grey-600

  'bg-page': '#F7F6F5',        // off-white
  'bg-surface': '#FFFFFF',     // white
  'bg-subtle': '#E0DDDA',      // of-grey-200

  'border-default': '#CEC9C6', // of-grey-300
  'border-strong': '#969290',  // of-grey-500
}
```
