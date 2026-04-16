# Tailwind CSS Patterns

Common Tailwind patterns for building high-quality user interfaces.

---

## Layout Patterns

### Centered Container

```jsx
<div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  {/* Content is centered and never too wide */}
</div>
```

**Variants:**
```jsx
// Narrow container (blog posts, articles)
<div className="max-w-3xl mx-auto px-4">

// Medium container (forms, dashboards)
<div className="max-w-5xl mx-auto px-4">

// Wide container (landing pages)
<div className="max-w-7xl mx-auto px-4">

// Full bleed (hero sections)
<div className="w-full px-4">
```

### Full Height Section

```jsx
<section className="min-h-screen flex items-center justify-center">
  {/* Vertically and horizontally centered */}
</section>
```

### Sticky Header

```jsx
<header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b">
  {/* Stays at top when scrolling */}
</header>
```

### Grid Layouts

```jsx
// Equal columns
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {items.map(item => <Card key={item.id} />)}
</div>

// Asymmetric columns (sidebar + main)
<div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
  <aside className="lg:col-span-1">{/* Sidebar */}</aside>
  <main className="lg:col-span-3">{/* Main content */}</main>
</div>

// Auto-fit columns (responsive without breakpoints)
<div className="grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-6">
  {items.map(item => <Card key={item.id} />)}
</div>
```

### Flexbox Layouts

```jsx
// Space between items
<div className="flex items-center justify-between">
  <div>Left</div>
  <div>Right</div>
</div>

// Centered content
<div className="flex items-center justify-center min-h-screen">
  <div>Centered</div>
</div>

// Even spacing
<div className="flex gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

// Wrap items
<div className="flex flex-wrap gap-4">
  {tags.map(tag => <Tag key={tag} />)}
</div>
```

---

## Component Patterns

### Button (Primary)

```jsx
<button className="
  px-6 py-3
  bg-primary text-white
  font-semibold text-base
  rounded-lg
  hover:bg-primary-dark
  focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
  active:scale-95
  disabled:opacity-50 disabled:cursor-not-allowed
  transition-all duration-150
">
  Button Text
</button>
```

### Button (Secondary)

```jsx
<button className="
  px-6 py-3
  bg-transparent text-primary
  font-semibold text-base
  border-2 border-primary rounded-lg
  hover:bg-primary hover:text-white
  focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
  active:scale-95
  disabled:opacity-50 disabled:cursor-not-allowed
  transition-all duration-150
">
  Button Text
</button>
```

### Button (Ghost)

```jsx
<button className="
  px-6 py-3
  bg-transparent text-text
  font-semibold text-base
  rounded-lg
  hover:bg-gray-100
  focus:outline-none focus:ring-2 focus:ring-gray-300
  active:scale-95
  disabled:opacity-50 disabled:cursor-not-allowed
  transition-all duration-150
">
  Button Text
</button>
```

### Input Field

```jsx
<input
  type="text"
  placeholder="Enter text..."
  className="
    w-full h-12 px-4
    text-base leading-normal
    bg-white text-text placeholder:text-gray-400
    border border-gray-300 rounded-lg
    focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
    disabled:bg-gray-100 disabled:cursor-not-allowed
    transition-colors duration-200
  "
/>
```

### Textarea

```jsx
<textarea
  placeholder="Enter text..."
  rows={4}
  className="
    w-full px-4 py-3
    text-base leading-relaxed
    bg-white text-text placeholder:text-gray-400
    border border-gray-300 rounded-lg
    focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
    disabled:bg-gray-100 disabled:cursor-not-allowed
    resize-none
    transition-colors duration-200
  "
/>
```

### Select Dropdown

```jsx
<select className="
  w-full h-12 px-4
  text-base
  bg-white text-text
  border border-gray-300 rounded-lg
  focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
  disabled:bg-gray-100 disabled:cursor-not-allowed
  transition-colors duration-200
  appearance-none
  cursor-pointer
">
  <option>Option 1</option>
  <option>Option 2</option>
</select>
```

### Checkbox

```jsx
<label className="flex items-center gap-3 cursor-pointer">
  <input
    type="checkbox"
    className="
      w-5 h-5
      text-primary
      border-gray-300 rounded
      focus:ring-2 focus:ring-primary focus:ring-offset-2
      cursor-pointer
    "
  />
  <span className="text-base text-text">Label text</span>
</label>
```

### Radio Button

```jsx
<label className="flex items-center gap-3 cursor-pointer">
  <input
    type="radio"
    name="group"
    className="
      w-5 h-5
      text-primary
      border-gray-300
      focus:ring-2 focus:ring-primary focus:ring-offset-2
      cursor-pointer
    "
  />
  <span className="text-base text-text">Label text</span>
</label>
```

### Card

```jsx
<article className="
  p-6
  bg-white
  border border-gray-200 rounded-xl
  shadow-sm
  hover:shadow-md hover:-translate-y-1
  transition-all duration-300
">
  <h3 className="text-xl font-semibold mb-2">Card Title</h3>
  <p className="text-gray-600">Card description goes here.</p>
</article>
```

### Badge

```jsx
<span className="
  inline-flex items-center
  px-3 py-1
  text-sm font-medium
  bg-primary/10 text-primary
  rounded-full
">
  Badge Text
</span>
```

**Variants:**
```jsx
// Success
<span className="px-3 py-1 text-sm font-medium bg-green-100 text-green-700 rounded-full">

// Warning
<span className="px-3 py-1 text-sm font-medium bg-yellow-100 text-yellow-700 rounded-full">

// Error
<span className="px-3 py-1 text-sm font-medium bg-red-100 text-red-700 rounded-full">

// Info
<span className="px-3 py-1 text-sm font-medium bg-blue-100 text-blue-700 rounded-full">
```

### Alert

```jsx
<div className="
  p-4
  bg-blue-50 border-l-4 border-blue-500
  rounded-lg
">
  <div className="flex items-start gap-3">
    <InfoIcon className="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" />
    <div>
      <h4 className="font-semibold text-blue-900">Alert Title</h4>
      <p className="text-sm text-blue-700 mt-1">Alert message goes here.</p>
    </div>
  </div>
</div>
```

### Modal Overlay

```jsx
<div className="
  fixed inset-0 z-50
  bg-black/50 backdrop-blur-sm
  flex items-center justify-center
  p-4
">
  <div className="
    bg-white rounded-2xl
    max-w-lg w-full
    p-6
    shadow-2xl
  ">
    {/* Modal content */}
  </div>
</div>
```

### Tooltip

```jsx
<div className="relative group">
  <button>Hover me</button>
  <div className="
    absolute bottom-full left-1/2 -translate-x-1/2 mb-2
    px-3 py-2
    bg-gray-900 text-white text-sm
    rounded-lg
    opacity-0 group-hover:opacity-100
    pointer-events-none
    transition-opacity duration-200
  ">
    Tooltip text
  </div>
</div>
```

### Skeleton Loader

```jsx
<div className="animate-pulse space-y-4">
  <div className="h-4 bg-gray-200 rounded w-3/4"></div>
  <div className="h-4 bg-gray-200 rounded"></div>
  <div className="h-4 bg-gray-200 rounded w-5/6"></div>
</div>
```

---

## Navigation Patterns

### Horizontal Nav

```jsx
<nav className="flex items-center gap-8">
  <a href="/" className="text-text hover:text-primary transition-colors">
    Home
  </a>
  <a href="/about" className="text-text hover:text-primary transition-colors">
    About
  </a>
  <a href="/contact" className="text-text hover:text-primary transition-colors">
    Contact
  </a>
</nav>
```

### Vertical Sidebar Nav

```jsx
<nav className="flex flex-col gap-2">
  <a href="/" className="
    flex items-center gap-3
    px-4 py-3
    text-text
    rounded-lg
    hover:bg-gray-100
    transition-colors
  ">
    <HomeIcon className="w-5 h-5" />
    <span>Home</span>
  </a>
  {/* More items */}
</nav>
```

### Tabs

```jsx
<div className="border-b border-gray-200">
  <nav className="flex gap-6">
    <button className="
      pb-3 px-1
      text-primary border-b-2 border-primary
      font-medium
    ">
      Tab 1
    </button>
    <button className="
      pb-3 px-1
      text-gray-500 border-b-2 border-transparent
      font-medium
      hover:text-text hover:border-gray-300
      transition-colors
    ">
      Tab 2
    </button>
  </nav>
</div>
```

### Breadcrumbs

```jsx
<nav className="flex items-center gap-2 text-sm">
  <a href="/" className="text-gray-500 hover:text-text">Home</a>
  <span className="text-gray-400">/</span>
  <a href="/category" className="text-gray-500 hover:text-text">Category</a>
  <span className="text-gray-400">/</span>
  <span className="text-text font-medium">Current Page</span>
</nav>
```

---

## Typography Patterns

### Heading Hierarchy

```jsx
<h1 className="text-5xl font-bold leading-tight tracking-tight text-text">
  H1 Heading
</h1>

<h2 className="text-4xl font-semibold leading-snug tracking-tight text-text">
  H2 Heading
</h2>

<h3 className="text-3xl font-semibold leading-normal text-text">
  H3 Heading
</h3>

<h4 className="text-2xl font-semibold leading-normal text-text">
  H4 Heading
</h4>

<h5 className="text-xl font-semibold leading-normal text-text">
  H5 Heading
</h5>

<h6 className="text-lg font-semibold leading-normal text-text">
  H6 Heading
</h6>
```

### Body Text

```jsx
<p className="text-base leading-relaxed text-text">
  Regular body text with comfortable line height for readability.
</p>

<p className="text-sm leading-normal text-gray-600">
  Smaller body text for secondary content.
</p>

<p className="text-lg leading-relaxed text-text">
  Larger body text for emphasis or lead paragraphs.
</p>
```

### Text Utilities

```jsx
// Truncate with ellipsis
<p className="truncate">Very long text that will be cut off with...</p>

// Line clamp (multiple lines)
<p className="line-clamp-3">
  Long text that will be truncated after 3 lines...
</p>

// Uppercase
<span className="uppercase tracking-wider text-xs font-semibold">Label</span>

// Link
<a href="#" className="text-primary hover:underline">Link text</a>
```

---

## Image Patterns

### Aspect Ratio Image

```jsx
<div className="aspect-video relative overflow-hidden rounded-lg">
  <img
    src={src}
    alt={alt}
    className="absolute inset-0 w-full h-full object-cover"
  />
</div>
```

**Common aspect ratios:**
```jsx
aspect-square    // 1:1
aspect-video     // 16:9
aspect-[4/3]     // 4:3
aspect-[21/9]    // 21:9
```

### Image with Overlay

```jsx
<div className="relative overflow-hidden rounded-lg group">
  <img src={src} alt={alt} className="w-full h-full object-cover" />
  <div className="
    absolute inset-0
    bg-black/50
    opacity-0 group-hover:opacity-100
    transition-opacity duration-300
  ">
    <div className="flex items-center justify-center h-full">
      <span className="text-white font-semibold">View Details</span>
    </div>
  </div>
</div>
```

### Avatar

```jsx
<img
  src={avatarSrc}
  alt="User name"
  className="w-10 h-10 rounded-full object-cover"
/>

// With ring
<img
  src={avatarSrc}
  alt="User name"
  className="w-10 h-10 rounded-full object-cover ring-2 ring-white"
/>

// Initials fallback
<div className="
  w-10 h-10 rounded-full
  bg-primary text-white
  flex items-center justify-center
  font-semibold text-sm
">
  JD
</div>
```

---

## Animation Patterns

### Hover Lift

```jsx
<div className="
  transition-all duration-300
  hover:-translate-y-2 hover:shadow-lg
">
  {/* Content */}
</div>
```

### Fade In

```jsx
<div className="
  opacity-0 animate-in fade-in duration-500
">
  {/* Content fades in */}
</div>
```

### Slide In

```jsx
<div className="
  -translate-x-full animate-in slide-in-from-left duration-500
">
  {/* Content slides in from left */}
</div>
```

### Scale on Hover

```jsx
<button className="
  transition-transform duration-200
  hover:scale-105
  active:scale-95
">
  {/* Button scales up on hover, down on click */}
</button>
```

### Rotate on Hover

```jsx
<div className="
  transition-transform duration-300
  hover:rotate-6
">
  {/* Rotates slightly on hover */}
</div>
```

### Pulse

```jsx
<div className="animate-pulse">
  {/* Pulses opacity (good for loading states) */}
</div>
```

### Spin

```jsx
<div className="animate-spin">
  <LoaderIcon />
</div>
```

---

## State Patterns

### Loading State

```jsx
<button
  disabled={isLoading}
  className="
    px-6 py-3
    bg-primary text-white
    rounded-lg
    disabled:opacity-50 disabled:cursor-not-allowed
  "
>
  {isLoading ? (
    <div className="flex items-center gap-2">
      <LoaderIcon className="w-5 h-5 animate-spin" />
      <span>Loading...</span>
    </div>
  ) : (
    <span>Submit</span>
  )}
</button>
```

### Error State (Input)

```jsx
<div>
  <input
    type="email"
    className={`
      w-full h-12 px-4
      border rounded-lg
      ${error
        ? 'border-red-500 focus:ring-red-500'
        : 'border-gray-300 focus:ring-primary'
      }
    `}
  />
  {error && (
    <p className="mt-2 text-sm text-red-600">
      {error}
    </p>
  )}
</div>
```

### Empty State

```jsx
<div className="
  flex flex-col items-center justify-center
  py-12 px-4
  text-center
">
  <EmptyIcon className="w-16 h-16 text-gray-300 mb-4" />
  <h3 className="text-lg font-semibold text-text mb-2">
    No items found
  </h3>
  <p className="text-gray-600 mb-6">
    Get started by creating your first item.
  </p>
  <button className="px-6 py-3 bg-primary text-white rounded-lg">
    Create Item
  </button>
</div>
```

---

## Form Patterns

### Form Layout

```jsx
<form className="space-y-6">
  <div>
    <label className="block text-sm font-medium text-text mb-2">
      Email
    </label>
    <input
      type="email"
      className="w-full h-12 px-4 border border-gray-300 rounded-lg"
    />
  </div>

  <div>
    <label className="block text-sm font-medium text-text mb-2">
      Password
    </label>
    <input
      type="password"
      className="w-full h-12 px-4 border border-gray-300 rounded-lg"
    />
  </div>

  <button className="w-full h-12 bg-primary text-white rounded-lg">
    Submit
  </button>
</form>
```

### Inline Form

```jsx
<form className="flex gap-2">
  <input
    type="email"
    placeholder="Enter email"
    className="flex-1 h-12 px-4 border border-gray-300 rounded-lg"
  />
  <button className="px-6 h-12 bg-primary text-white rounded-lg">
    Subscribe
  </button>
</form>
```

---

## Utility Patterns

### Visually Hidden (Accessibility)

```jsx
<span className="sr-only">
  This text is hidden visually but read by screen readers
</span>
```

### Focus Ring

```jsx
<button className="
  focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2
">
  Button with accessible focus ring
</button>
```

### Backdrop Blur

```jsx
<div className="bg-white/80 backdrop-blur-md">
  {/* Blurred background effect */}
</div>
```

### Gradient Background

```jsx
<div className="bg-gradient-to-r from-purple-500 to-pink-500">
  {/* Gradient from left to right */}
</div>

<div className="bg-gradient-to-br from-blue-400 via-purple-500 to-pink-500">
  {/* Complex gradient with three stops */}
</div>
```

### Dark Mode Support

```jsx
<div className="
  bg-white dark:bg-gray-900
  text-text dark:text-white
  border-gray-200 dark:border-gray-700
">
  {/* Adapts to dark mode */}
</div>
```

---

## Performance Patterns

### Will Change (Optimize Animations)

```jsx
<div className="will-change-transform hover:scale-110">
  {/* Hints browser to optimize for transform */}
</div>
```

### GPU Acceleration

```jsx
<div className="transform-gpu translate-z-0">
  {/* Forces GPU rendering */}
</div>
```

---

## Common Combinations

### Hero Section

```jsx
<section className="
  min-h-screen
  flex items-center justify-center
  bg-gradient-to-br from-blue-500 to-purple-600
  text-white
  px-4
">
  <div className="max-w-4xl text-center">
    <h1 className="text-5xl font-bold mb-6">
      Welcome to Our Product
    </h1>
    <p className="text-xl mb-8 text-white/90">
      Build amazing things with our platform
    </p>
    <button className="
      px-8 py-4
      bg-white text-blue-600
      font-semibold text-lg
      rounded-lg
      hover:bg-gray-100
      transition-colors
    ">
      Get Started
    </button>
  </div>
</section>
```

### Feature Card Grid

```jsx
<section className="py-16 px-4">
  <div className="max-w-7xl mx-auto">
    <h2 className="text-4xl font-bold text-center mb-12">Features</h2>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
      {features.map(feature => (
        <div key={feature.id} className="
          p-6
          bg-white
          border border-gray-200 rounded-xl
          shadow-sm
          hover:shadow-lg
          transition-shadow duration-300
        ">
          <feature.icon className="w-12 h-12 text-primary mb-4" />
          <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
          <p className="text-gray-600">{feature.description}</p>
        </div>
      ))}
    </div>
  </div>
</section>
```

---

**Related:**
- figma-workflow.md - Extracting design values
- high-fidelity-implementation.md - Applying patterns precisely
- responsive-design.md - Making patterns responsive
