# Local image rendering

Fixture 04 tests local image path resolution. The image referenced below must resolve relative to the source `.md` file.

![A sample placeholder image](./images/sample.png)

---

# Image with surrounding content

Text above the image.

![An image that should render below this heading](./images/sample.png)

Text below the image. Both should be visible on the same slide.

---

# Missing image fallback

This references an image that does not exist:

![An image that is missing](./images/missing-on-purpose.png)

**Acceptance:** the first two slides must render the image (any visible image content is acceptable for MVP — path resolution is what we test). The third slide must render a placeholder with the alt text, per the error-handling spec. Silent skip of missing images is an implementation bug.
