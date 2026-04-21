# UI Development Knowledge Base

**Purpose:** Reference material for agents implementing user interfaces from design mockups.

**Target Audience:** All agents working on UI implementation (web, mobile, desktop).

---

## Contents

| File | Purpose | When to Use |
|------|---------|-------------|
| **figma-workflow.md** | Working with Figma designs | Starting any Figma-to-code task |
| **high-fidelity-implementation.md** | Achieving pixel-perfect results | Implementing visual designs |
| **responsive-design.md** | Multi-device implementation | Building responsive interfaces |
| **visual-qa-checklist.md** | Visual quality assurance | Reviewing completed implementations |
| **tailwind-patterns.md** | Common Tailwind CSS patterns | Working with Tailwind-based projects |

---

## Quick Reference

### The Three Rules of High-Fidelity UI

1. **Never infer what can be specified**
   - Always request exact measurements from Figma
   - Use design tokens, not magic values
   - Document assumptions explicitly

2. **Structure before style**
   - Build semantic HTML first
   - Ensure accessibility from the start
   - Then apply visual styling

3. **Validate continuously**
   - Screenshot and compare frequently
   - Test at all breakpoints
   - Check all interaction states

### Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Guessing spacing values | Use Figma Dev Mode for exact measurements |
| Ignoring mobile viewport | Always implement mobile-first |
| Skipping interaction states | Design hover, focus, active, disabled states |
| Copy-pasting without understanding | Understand the layout system before implementing |
| Single breakpoint testing | Test at 375px, 768px, 1024px, 1440px minimum |

---

## Stack Assumptions

This knowledge base assumes you're working with:
- **React** or similar component-based framework
- **Tailwind CSS** for styling (or similar utility-first approach)
- **TypeScript** for type safety
- **Modern browsers** (last 2 versions)

Adapt patterns as needed for your specific stack.

---

## Contributing

If you discover a pattern that works well or solve a tricky UI problem:
1. Document it clearly
2. Add concrete examples
3. Submit to the knowledge base
4. Reference it in your WORKLOG

Good knowledge:
- ✅ Specific and actionable
- ✅ Includes code examples
- ✅ Explains the "why" not just the "what"
- ✅ Portable across projects

Bad knowledge:
- ❌ Vague generalizations
- ❌ Project-specific hacks
- ❌ Outdated patterns
- ❌ "It depends" without guidance

---

**Last Updated:** 2026-01-13
**Maintainer:** housekeeping agent
