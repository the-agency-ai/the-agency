# Image Test Deck

Testing PNG, SVG, and screenshot rendering in mdslidepal

---

# PNG — Logo Image

A raster PNG image, copied from the fixture corpus:

![The Agency logo](./images/logo.png)

This should render as a visible image, centered on the slide.

---

# SVG — Architecture Diagram

An inline SVG diagram showing the mdslidepal architecture:

![mdslidepal architecture](./images/architecture.svg)

SVG should render crisp at any zoom level.

---

# SVG — Workflow Diagram

A horizontal workflow diagram:

![mdslidepal workflow](./images/workflow.svg)

This tests wide-aspect SVG rendering within the 16:9 slide canvas.

---

# Screenshot — Terminal Output

A simulated terminal screenshot showing mdslidepal in action:

![Terminal running mdslidepal](./images/terminal-screenshot.svg)

Screenshots are a common workshop slide element.

---

# Multiple Images on One Slide

Two images side by side (markdown flow — they'll stack vertically):

![Architecture](./images/architecture.svg)

![Workflow](./images/workflow.svg)

---

# Image with Code

An image alongside a code block:

![Terminal](./images/terminal-screenshot.svg)

```bash
mdslidepal serve workshop.md
# → Opens browser with slides
```

---

# Missing Image Fallback

This references an image that doesn't exist:

![This image is intentionally missing](./images/nonexistent.png)

The browser should show a broken-image icon with the alt text above.

---

# End

8 slides total — testing PNG, SVG, screenshots, multiple images, mixed content, and missing image fallback.
