# GFM tables

Fixture 05 tests GFM features that CommonMark does not include: tables, task lists, strikethrough, autolinks.

| Feature | Web MVP | Mac MVP |
|---|---|---|
| Slide breaks | ✓ | ✓ |
| Themes | 1 (default) | 2 (default + dark) |
| Speaker notes | Phase 2 | ✓ |
| PDF export | Phase 2 | ✓ |
| Front-matter | Phase 2 | ✓ |

---

# Nested lists

- Fruit
  - Apples
    - Gala
    - Fuji
  - Oranges
- Vegetables
  - Carrots
  - Broccoli

---

# Task lists

- [x] Write the spec
- [x] Run MAR
- [x] Apply fixes
- [ ] Spin implementation agents
- [ ] Reconcile plans

---

# Strikethrough and autolinks

You should see ~~strikethrough text~~ here.

And an autolink: https://github.com/the-agency-ai/the-agency should render as a clickable link.

**Acceptance:** tables must render with borders or similar visual separation. Nested lists must preserve indentation. Task list checkboxes must render as checked/unchecked UI (not raw `[x]`/`[ ]` text). Strikethrough must visibly strike. Autolinks must be clickable.
