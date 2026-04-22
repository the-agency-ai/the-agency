# THE-BOOK-WORKING-NOTE-0001

**Date:** 2026-01-02 14:05 SGT
**Participants:** Jordan (principal), Housekeeping/Opus 4.5 (agent)
**Subject:** Project Structure & The Agency Book - Initial Discussion

---

## Discussion Summary

### Part 1: Principal Projects Structure

**[jordan]** Principals should be able to have projects. Structure:

```
principals/{PrincipalName}/projects/{PROJECTNAME}/
```

With appropriate files, READMEs, and resources/ tied to that project.

### Part 2: The Agency Book Project

**[jordan]** We are going to write a book: "The Agency - The Guide" (or "The Agency Guide" or something catchy).

**Goals:**

- Get it done before we announce The Agency Starter
- Use the article we captured as a starting point (goes in resources/)
- Generate an outline collaboratively (Jordan, Opus 4.5)
- Write chapters iteratively

**Versioning & Archival:**

- When a new version of a chapter is ready, archive the existing one
- All feedback inline in current draft, tagged: `[housekeeping]`, `[opus45]`, `[jordan]`
- Outline versioned starting with v1, revision 1
- Individual chapters versioned separately

**Structure Questions Raised:**

**[jordan]** Do we have a knowledge/ or research/ for material going into?

**[jordan]** resources/ should have both a general bucket and chapter-specific directories?

### Book Content Vision

**[jordan]** The end result is a book that:

1. Tells The Agency Story
2. Introduces The Agency - process, patterns, workflows
3. Documents the systems, services, and tools
4. Shows how it all fits together
5. Covers the starter packs
6. How to use Workbench
7. Shows how to kick off a project using it
8. Uses Ordinary Folk as a case study

### Working Notes System

**[jordan]** Consistently capture "working notes" where we discuss about the book, capturing that as knowledge:

- Separate files for conversations
- Clearly show sequence, date/time, participants
- Example: THE-BOOK-WORKING-NOTE-0001

---

## Agent Feedback & Suggestions

**[housekeeping/opus45]**

### On Project Structure

I like this evolution. Currently we have:

- `principals/{name}/instructions/` - directives
- `principals/{name}/artifacts/` - deliverables
- `principals/{name}/resources/` - reference material

Adding `projects/` makes sense for larger, sustained efforts that span multiple instructions and produce multiple artifacts. A project would be a container that groups related work.

### On Book Structure

Proposed structure for the book project:

```
principals/jordan/projects/the-agency-book/
├── README.md                    # Project overview, status, how to contribute
├── OUTLINE.md                   # Current outline (v1-r1, etc.)
├── outline-archive/             # Previous outline versions
├── chapters/
│   ├── 00-introduction/
│   │   ├── draft.md            # Current working draft
│   │   └── archive/            # Previous versions
│   ├── 01-the-agency-story/
│   │   ├── draft.md
│   │   └── archive/
│   └── ...
├── research/                    # Background material, notes, references
│   ├── general/                 # Cross-cutting research
│   └── by-chapter/              # Chapter-specific research
│       ├── 01-the-agency-story/
│       └── ...
├── resources/                   # Source material, images, diagrams
│   ├── general/                 # Cross-cutting resources
│   └── by-chapter/              # Chapter-specific resources
│       ├── 01-the-agency-story/
│       └── ...
└── working-notes/               # Our discussions (this file and future ones)
    └── THE-BOOK-WORKING-NOTE-0001.md
```

### On knowledge/ vs research/

I'd suggest `research/` over `knowledge/` for this project because:

- "Research" implies gathering and analysis (what we're doing)
- "Knowledge" is what we already have (that's in KNOWLEDGE.md files)
- Research becomes knowledge after it's synthesized

### On Working Notes

Love this pattern. It creates an audit trail of decisions and captures the collaborative thinking process. This could be valuable content for the book itself - "how we wrote this book."

### Questions for Jordan

1. **Chapter granularity**: Should chapters be standalone (can be read independently) or sequential (builds on previous)?

2. **Target audience**: Developers already using Claude Code? Teams considering AI-augmented development? Both?

3. **Length target**: Quick guide (50-100 pages) or comprehensive manual (200+ pages)?

4. **Code examples**: Inline snippets, or appendix with full files, or links to repo?

---

## Next Steps

1. ✅ Capture this working note (done - you're reading it)
2. Discuss structure and answer questions
3. Enter plan mode to formalize the project structure
4. Create the project scaffolding
5. Move this working note to its proper home
6. Link the article as first resource
7. Generate initial outline

---

## Discussion Continued (14:12 SGT)

### Jordan's Answers to Questions

**[jordan]** On chapter structure:

> I think that there should be a sequential flow, but some will - like workbench and its pieces - also serve as "reference material."

**[housekeeping/opus45]** This is a hybrid approach - a narrative spine with reference appendices. The book tells a story (sequential) but also works as a handbook (reference). We could structure it as:

- **Part 1: The Story & Philosophy** (read sequentially)
- **Part 2: The Systems** (can be read as needed, reference-style)
- **Part 3: The Practice** (tutorials, sequential for beginners, reference for experienced)

**[jordan]** On target audience:

> I think any team or individual who is using Claude Code today and wants a more structured, and scalable process, as well as teams looking to make the jump to AI Augmented development. For the latter, this says, "Yes, you can! And this is how!"

**[housekeeping/opus45]** Two audiences, one book. We write for the newcomer but don't bore the experienced. The philosophy/story sections serve both. The how-to sections can have "quick start" paths for the impatient and deeper dives for the thorough.

**[jordan]** On length:

> I am thinking between 100 and 200. Will self-publish via Amazon (my friend Andrew McGlinchey has experience and can guide us). But we are going to do it fast, because I want to launch and announce The Agency between mid- and late-January and want the book there!

**[housekeeping/opus45]**

- **Timeline:** ~2-3 weeks to draft, review, and publish
- **Target:** 100-200 pages = ~25,000-50,000 words
- **Pace:** If we have ~10 chapters, that's 2,500-5,000 words per chapter
- **Strategy:** Write fast, iterate fast, use The Agency itself to accelerate

This IS the case study. We're writing a book about The Agency, using The Agency. Meta and powerful.

**[jordan]** On code examples:

> I think we have patterns and examples and we also have a link to the repo (see if we can gate it to paid access - buy the book and we add you; just an idea). Code in a book gets old. Process, patterns, practices, workflows...they don't.

**[housekeeping/opus45]**

- Focus on **concepts over code**
- Patterns are timeless; syntax is ephemeral
- Repo access as value-add is smart - creates community, ensures readers have working examples
- Book teaches the "why" and "how to think"; repo provides the "what"

### Action Items Confirmed

**[jordan]**

> Yes, give us the tool. And add all of this to the working notes and as an example of how The Agency works!

**[housekeeping/opus45]** This working note IS the example. We just demonstrated:

1. **Principal-Agent collaboration** - Jordan directs, I synthesize and propose
2. **Capture-as-you-go** - Nothing lost to context compaction
3. **Attributed discussion** - Clear who said what
4. **Iterative refinement** - Questions → Answers → Synthesis
5. **Tool creation on demand** - Need a tool? Make one.

---

## Completed Next Steps

1. ✅ Capture initial discussion (done)
2. ✅ Capture Jordan's answers (done - this section)
3. ✅ Create `./tools/working-note` tool
4. ✅ Enter plan mode for project structure
5. ✅ Create the project scaffolding
6. ✅ Move this working note to its proper home
7. ✅ Link the article as first resource
8. ✅ Generate initial outline (v1-r1)

---

## Meta: This Is The Agency In Action

This working note demonstrates exactly what we're writing about:

- A principal (Jordan) and agent (Housekeeping/Opus 4.5) collaborating
- Real-time capture of decisions and rationale
- Tool creation to support the process
- Using the system to build the system

When we write the book, this note becomes source material for a chapter on "How We Built This."

---

_Note: This file has been moved to its proper home in the project working-notes directory._
