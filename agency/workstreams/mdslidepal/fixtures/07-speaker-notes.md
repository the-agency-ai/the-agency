# Slide with speaker notes

This is the main content visible to the audience.

Notes:
These are speaker notes. They should only appear in the presenter view.
They can span multiple lines and include **markdown** like *emphasis* and `inline code`.

---

# Slide without notes

Just main content. No notes block here.

---

# Slide with notes after code block

```bash
echo "example code"
```

Notes:
Remember to explain what this code does before advancing. This is a reveal.js-style bare `Notes:` marker — everything from the marker to the end of the slide is speaker notes.

---

# Final slide

Closing content.

Notes:
Thank the audience.

**Acceptance:**
- Mac MVP must render four slides where "Notes:" content is visible only in the presenter view, never in the main slide view
- Web MVP defers speaker notes entirely (per scope reduction); rendering them anywhere (main view or presenter view) is acceptable for MVP, but rendering them IN the main view is still a bug
- The `Notes:` marker is case-insensitive and bare (no HTML comment wrapper)
