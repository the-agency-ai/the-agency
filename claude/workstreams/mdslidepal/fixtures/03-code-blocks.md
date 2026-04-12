# Code block rendering

Fixture 03 tests fenced code blocks with syntax highlighting for the languages a workshop participant is likely to use.

---

# Bash

```bash
#!/bin/bash
echo "Hello, mdslidepal!"
for i in 1 2 3; do
  echo "Slide $i"
done
```

---

# TypeScript

```typescript
interface Slide {
  title: string;
  content: string;
  notes?: string;
}

function render(slide: Slide): HTMLElement {
  const el = document.createElement('section');
  el.innerHTML = slide.content;
  return el;
}
```

---

# Python

```python
def parse_slides(markdown: str) -> list[dict]:
    slides = markdown.split('\n---\n')
    return [{'content': s.strip()} for s in slides]
```

---

# Swift

```swift
struct Slide {
    let title: String
    let content: String
    let notes: String?
}

let deck: [Slide] = []
```

**Acceptance:** each code block must be syntax-highlighted per its language identifier. Plain monospace rendering is an implementation bug.
