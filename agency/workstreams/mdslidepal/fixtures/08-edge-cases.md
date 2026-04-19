# Edge case — `---` inside a fenced code block

The code block below contains `---` on its own line. It must NOT be treated as a slide break.

```yaml
---
title: "YAML front matter example"
author: "Someone"
---
key: value
```

If you see this as a single slide with the code block intact, AST-based slide detection is working correctly.

---

# Edge case — empty slide follows

The next slide intentionally has no content.

---

---

# After the empty slide

This is the slide that follows the empty one.

The contract says two adjacent `---` produce ONE empty slide (not two), so the slide before this one should be a single blank slide.

---

# Edge case — trailing `---`

A trailing `---` at end of file should not create a phantom empty final slide.

The slide containing this line should be the LAST slide in the deck.

---

**Acceptance:**
- Fenced code block content must be preserved intact; the `---` inside must NOT split the slide
- There should be exactly one empty slide (from the `---\n\n---` sequence), not zero and not two
- There should be no phantom empty slide after the final `---`
- Total slide count for this fixture: **4** (intro, empty divider, "After the empty slide", "Edge case — trailing `---`")
