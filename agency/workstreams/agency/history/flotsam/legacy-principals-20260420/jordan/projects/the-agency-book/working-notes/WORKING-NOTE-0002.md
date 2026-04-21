# THE-AGENCY-BOOK-WORKING-NOTE-0002

**Date:** 2026-01-02 14:57 SGT
**Participants:** Jordan (principal), Housekeeping/Opus 4.5 (agent)
**Subject:** Project Setup Complete - Summary & Tooling

---

## Summary

This note captures the completion of the project setup phase for The Agency Book. In a single session, we:

1. Discussed the vision and structure
2. Created the tooling to support the project
3. Scaffolded the entire project
4. Generated the initial outline

This is The Agency in action - demonstrating exactly what we're writing about.

---

## New Tools Created

| Tool                      | Purpose                                               | Usage                                                       |
| ------------------------- | ----------------------------------------------------- | ----------------------------------------------------------- |
| `./tools/working-note`    | Create numbered working notes for project discussions | `./tools/working-note the-agency-book "Topic"`              |
| `./tools/create-project`  | Scaffold a new principal project                      | `./tools/create-project -t book project-name "Description"` |
| `./tools/archive-chapter` | Version and archive chapter drafts                    | `./tools/archive-chapter the-agency-book 01-introduction`   |

### Tool Design Decisions

**[housekeeping/opus45]** The tools follow existing patterns:

- Auto-numbering (like instructions and artifacts)
- Principal-aware (defaults from environment or whoami)
- Project-aware (places files in correct directories)
- Falls back gracefully (working-note creates at principal root if project doesn't exist yet)

---

## Project Structure Created

```
principals/jordan/projects/the-agency-book/
├── README.md                    # Project overview, goals, status
├── OUTLINE.md                   # v1-r1 with 10 chapters + 3 appendices
├── outline-archive/             # For future outline versions
├── chapters/                    # Ready for chapter drafts
├── research/
│   ├── general/
│   └── by-chapter/
├── resources/
│   ├── general/
│   │   └── the-agency-article-v3.md → (symlink to article)
│   └── by-chapter/
└── working-notes/
    ├── WORKING-NOTE-0001.md     # Initial discussion
    └── WORKING-NOTE-0002.md     # This summary
```

---

## Outline v1-r1 Structure

**Part 1: The Story & Philosophy** (sequential - read in order)

1. Introduction (~2,000-3,000 words)
2. The Agency Story (~3,000-4,000 words)
3. Philosophy & Principles (~2,500-3,500 words)

**Part 2: The Systems** (reference - read as needed) 4. Architecture Overview (~3,000-4,000 words) 5. The Tools (~4,000-5,000 words) 6. Workbench (~3,000-4,000 words) 7. Collaboration (~2,500-3,500 words)

**Part 3: The Practice** (tutorials - sequential for beginners) 8. Getting Started (~4,000-5,000 words) 9. Case Study: Ordinary Folk (~4,000-5,000 words) 10. Advanced Patterns (~3,000-4,000 words)

**Appendices:**

- A: Tool Reference
- B: Template Library
- C: Troubleshooting

**Total target:** ~31,500-42,500 words (100-200 pages)

---

## How It Came Together

### The Process (meta - this IS the case study)

1. **Jordan initiated** with a two-part request:
   - Create a projects structure for principals
   - Set up The Agency Book as the first project

2. **Immediate capture** - We created WORKING-NOTE-0001 at the principal root BEFORE setting up the project, to survive any context compaction

3. **Discussion** - Q&A about structure, audience, timeline, approach

4. **Tool creation on demand** - Needed a working-note tool? Made one.

5. **Plan mode** - Explored existing patterns, designed the structure

6. **Execution** - Created tools, project, moved files, linked resources

7. **This summary** - Captured using the tool we just created

### Time from idea to execution

- First message to project complete: ~45 minutes
- Created 3 new tools
- Scaffolded complete book project
- Generated 10-chapter outline
- Linked source material
- Created 2 working notes

---

## Decisions Made

1. **research/ over knowledge/** - Research is what we gather; knowledge is synthesized
2. **Hybrid book structure** - Sequential narrative + reference sections
3. **Concepts over code** - Process/patterns don't age; code does
4. **Repo as value-add** - Book teaches "why"; repo provides "what"
5. **Symlinks for resources** - Keep things DRY, one source of truth

---

## Action Items

- [x] Create working-note tool
- [x] Create create-project tool
- [x] Create archive-chapter tool
- [x] Scaffold the-agency-book project
- [x] Move WORKING-NOTE-0001 to project
- [x] Link article as resource
- [x] Create OUTLINE.md v1-r1
- [x] Capture this summary

---

## Next Steps

1. **Review outline** - Jordan to approve v1-r1 or suggest changes
2. **Create first chapter** - `mkdir -p chapters/01-introduction`
3. **Start writing** - Begin with Chapter 1 or Chapter 2 (the story)
4. **Gather research** - Pull relevant material into research/

---

## Meta: The Agency in Action

This working note is itself an example of what we're writing about:

| Principle                          | Example                                           |
| ---------------------------------- | ------------------------------------------------- |
| Capture everything                 | Two working notes in one session                  |
| Tool creation on demand            | Three new tools to support the work               |
| Convention over configuration      | Tools auto-detect principal, project              |
| Principal-agent collaboration      | Jordan directs, Opus synthesizes                  |
| Use the system to build the system | Writing a book about The Agency, using The Agency |

When we write Chapter 2 (The Agency Story), this session is source material.

---

_Working note for project: the-agency-book_
