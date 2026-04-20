# markdown-pal Design Discussion

> **Status:** Active
> **Date:** 2025-03-10
> **Participants:** @human (Jordan), @claude
> **Purpose:** High-level design for markdown-pal, a tool for viewing, editing, and commenting on Markdown-based artifacts generated and consumed by Claude Desktop and Claude Code.

---

## Opening

**@human:**
This is a chat where we will put together a high-level design for the design-markdown-pal. It is a tool for viewing, editing, and commenting on markdown based artifacts that are generated and consumed by Claude Desktop and Claude Code. Before you start, wait for me to add the appropriate knowledge from a discussion I had with Perplexity.

**@claude:**
Sounds good! I'm ready to dive into the design for markdown-pal whenever you are. Go ahead and share the knowledge from your Perplexity discussion, and we'll use that as a foundation to put together the high-level design.

---

## Review of Prior Research

**@human:**
Take a look at the project knowledge and let's discuss things further.

**@claude:**
I've read through all four project documents. Here's my understanding of where things stand:

**The app in a nutshell:** A native SwiftUI multi-platform Markdown editor/viewer designed specifically as a companion tool for Claude Desktop and Claude Code workflows — editing specs, plans, and other artifacts that flow back and forth with Claude.

**Key decisions already made:**

- Build a **new SwiftUI app** (not a fork of MacDown or MarkEdit) using `DocumentGroup` for multi-platform support (macOS, iPadOS, iOS)
- Use **swift-markdown** (Apple) for parsing and **MarkdownUI** for SwiftUI rendering — no WKWebView dependency
- Plain `.md` files on disk, no proprietary vault or database — so Claude Code can operate on the same files directly
- Claude integration is primarily through UX affordances (copy, open in Finder, prompt templates) rather than deep SDK coupling

**The staged roadmap:**

- **V1** — Solid editor/viewer: side-by-side editing + live preview, file-based, minimal Claude affordances (copy markdown, open in Finder)
- **V2** — Review & commenting: inline comments tied to Markdown structure, diff view for pasting Claude's suggested edits, configurable prompt templates
- **V3** — Deeper Claude integration: dedicated Claude pane, prompt recipes per project, hooks into Claude Desktop/Code when available, collaboration exports

**Open questions I see:**

1. **Document model design** — the last conversation ended with a suggestion to nail down `MarkdownDocument`, `Comment`, and metadata structures so V2/V3 don't break V1 files
2. **Comment anchoring strategy** — tying comments to AST nodes (headings, paragraphs) vs. line ranges vs. paragraph IDs
3. **Claude integration specifics** — how "Send to Claude" actually works mechanically (clipboard? URL scheme? local API?)
4. **Editor component** — stock `TextEditor` is pretty limited; whether/when to invest in a richer text editing component with syntax highlighting

Where would you like to dig in first?

---

## Core Feature Priorities

**@human:**
Viewing. Editing. Commenting.

Commenting is important: we want a way to drive a feedback loop with Claude / Claude Code around artifacts to refine them. We will want a way to do this in a token efficient way.

**@claude:**
Great framing. The commenting-driven feedback loop is really the core differentiator — this isn't just another Markdown editor, it's a **review interface** for Claude-generated artifacts.

**The problem:** If you send an entire document back to Claude every time you want feedback on one paragraph, you're burning tokens unnecessarily. And if Claude sends back a whole revised document when it only changed three lines, same issue.

**A token-efficient commenting model might look like:**

Rather than full-document round-trips, you work at the level of **targeted selections + structured comments**. Something like: "Here's paragraph 3 of the doc (with a bit of surrounding context), and here's my comment: 'This section contradicts the decision we made in the architecture doc.'" Claude responds with a scoped revision or explanation, not a full rewrite.

This means the **comment anchoring strategy** matters a lot — not just for UI, but for how you construct efficient prompts. If comments are anchored to AST nodes (a heading, a list item, a specific paragraph), you can extract just that subtree plus minimal context and send it to Claude.

**Three modes of interaction I'm seeing:**

1. **Viewing** — render the Markdown beautifully, let you read and navigate
2. **Editing** — direct text manipulation of the `.md` file
3. **Commenting** — attach feedback to specific parts of the document, then use those comments to drive scoped, token-efficient exchanges with Claude

A few things I'd want to think through together:

- **Comment granularity** — do you anchor to paragraphs, heading-scoped sections, or arbitrary selections?
- **The round-trip format** — what does the "package" look like that goes to Claude and comes back?
- **Who initiates** — is it always the human commenting and asking Claude to revise, or could Claude Code also attach comments that the human then reviews and accepts/rejects?

---

## Templates and Document Homes

**@human:**
We will also want to have the concept of templates that can start-off an artifact. And we also want the concept of document homes, so that we can indicate where artifacts will be found in a repo.

**@claude:**
**Templates** make a lot of sense — if you're repeatedly generating the same kinds of artifacts with Claude (design docs, runbooks, API specs, test plans), you want a starting structure that's consistent and that Claude already understands.

**Document homes** solve the "where does this thing live" problem. If Claude Code is generating or editing artifacts, it needs to know where to put them and where to find them.

**The lifecycle of an artifact becomes:**

1. Create from template (human or Claude)
2. Claude fills it in / human drafts it
3. Human reviews in the app, leaves section-scoped comments
4. Comments get packaged with minimal context and sent to Claude
5. Claude returns scoped revisions
6. Human accepts/rejects in a diff-like view
7. Repeat 3–6 until the artifact is solid

---

## Answering Open Questions

**@human:**

RE: Your Questions

- Document model design — How do you suggest we tackle this?
- Comment anchoring strategy — I am thinking AST nodes
- Claude integration specifics — We should explore this. But if we tell Claude to give us a URL to an artifact or hand it one, that is a good start, right?
- Editor component — Yes, we will want to do so.

Imagine the above interaction around your questions as a model of the commenting and feedback loop? We should have a way to indicate a block of questions which you want us to answer and respond to?

Comment granularity: I think we want an AST model, but also need to be able to go for an arbitrary text block?

The round-trip format: I think this is aligned with your thinking on "rich comments" that can be token efficient.

Who initiates: This could be a human writing up a design spec that they are going to send to Claude Code (perhaps in collaboration with Claude Desktop) or it could be a plan that Claude Code generated that I want to review and comment on and refine before we "make it so". Claude can comment. Humans can comment.

**@claude:**
This is really clarifying. And I love that you called out our own interaction as a model — that "block of questions with responses" pattern is exactly the kind of structured commenting flow the app should support.

**AST-anchored comments with arbitrary selection fallback:** AST nodes as the primary anchor makes sense — a comment on "the paragraph under `## Authentication`" survives edits much better than "line 47." The model could be: **anchor to the nearest AST node, then optionally store a text range within that node.**

**The "question block" pattern:** What you described — a block of questions that the reviewer answers inline — is a distinct comment type worth designing for explicitly. This suggests comments aren't just flat text — they have **types**: a note, a question (expecting a response), a suggested edit (expecting accept/reject), maybe a directive.

**Bi-directional flow:** The app needs to be a **neutral review surface** — it doesn't matter whether the human or Claude authored the content or the comments.

**So the emerging concept model is something like:**

- **Template** — defines the skeleton and expected sections for an artifact type
- **Document Home** — maps artifact types to repo locations
- **Artifact** — a plain `.md` file, always valid Markdown
- **Comment** — anchored to an AST node, has a type (note/question/suggestion/directive), has an author (human or Claude)
- **Review Session** — a collection of comments on an artifact
- **Prompt Package** — the token-efficient payload: scoped section context + relevant comments

---

## Metadata In-File vs. Sidecar

**@human:**
How about instead of a sidecar file, we define a section at the end of the document for the content? Then we don't have to manage shipping the sidecars around?

Do we want to define / incorporate non-standard markdown (for example for comments, questions, and say diagrams) in the model?

**@claude:**
**Comments at the end of the document:** This is cleaner than sidecars for exactly the reason you said — one file to move around, no sync issues. And since Claude Code is already reading/writing the `.md` file, it can natively read and write comments without needing to know about a separate format.

**Non-standard Markdown extensions:** You could lean on conventions that already exist in the ecosystem — things like GitHub-flavored admonitions (`> [!NOTE]`, `> [!WARNING]`), or task lists, or fenced code blocks with language hints (` ```mermaid `).

For things that don't have existing conventions — like a "question block expecting a response" or a "directive to Claude" — something like:

```
> [!QUESTION] @claude
> Does this authentication flow handle token refresh correctly?
```

That renders as a blockquote in any Markdown viewer, but your app and Claude parse the `[!QUESTION]` tag and `@claude` addressee to give it special treatment.

**The principle:** use existing Markdown conventions and GitHub-flavored extensions where they exist, define new admonition-style blocks where they don't, and keep everything valid Markdown that renders acceptably in any viewer.

---

## Metadata Block Design

**@human:**
I think this makes more sense: `<!-- begin:markdown-pal-meta -->` ... `<!-- end:markdown-pal-meta -->` so it's bounded. But what are the pros and cons of this approach?

I think we go for "render harmlessly."

Perhaps our comment block has unresolved and resolved sections?

I would like you to consider this interaction, how we have iterated on this, and how it could have been built around a design artifact using this application and conventions, and how that might influence the design.

**@claude:**
**This conversation as a markdown-pal workflow:**

We'd have started with a template. Then the review loop we've been doing would look like: I read the doc, I drop `[!QUESTION]` blocks under several sections. You respond inline to each one. As decisions crystallize, they move from question blocks into the actual document content. The resolved Q&A threads slide down into the metadata section.

The thing that jumps out is: **the comment/question flow is iterative and convergent.** Early on there are lots of open questions and the document is thin. Over time, questions resolve into decisions, the document body gets richer, and the comment section shifts from mostly-unresolved to mostly-resolved.

**Pros of `<!-- begin/end:markdown-pal-meta -->`:**

- Single file, no sync issues
- Invisible in standard renderers
- Bounded and parseable
- Claude can read/write natively
- Git-friendly — comments show up in diffs

**Cons:**

- File size grows with comment history
- Merge conflicts if two parties add comments simultaneously
- Parsing fragility if hand-edited
- Token cost of carrying resolved comments

Most cons are manageable. Token/bloat handled by unresolved/resolved split with pruning.

---

## CLI Tool and Section-Oriented Editing

**@human:**
In addition to the app for humans, we need a CLI for Claude Code and Claude to operate on these? Think along the lines of SED or the early-Unix ED. Anything like that we might leverage? Doesn't seem that difficult to build.

What, if any role, might MCP play?

We need to think of a way that doesn't force Claude or Claude Code to read the file over and over again just to work on it.

**@claude:**
**A CLI tool for Claude Code:** The operations are pretty bounded:

```
mdpal read "## Authentication" my-design.md
mdpal comment --type question --section "## Authentication" "Does this handle refresh tokens?" my-design.md
mdpal comments --unresolved my-design.md
mdpal resolve 3 --response "Yes, covered in step 4" my-design.md
mdpal sections my-design.md
mdpal edit --section "## Authentication" --content "new content..." my-design.md
```

**MCP's role:** Instead of (or in addition to) a CLI, you could expose the same operations as an **MCP server**. Claude Desktop and Claude Code both support MCP, so your app could run a local MCP server. The advantage over a CLI: Claude discovers the tools via MCP and uses them naturally. And the MCP server can maintain state.

**Avoiding repeated full-file reads:** The MCP server (or a daemon behind the CLI) solves this by **holding the parsed AST in memory**. Claude requests just the section it needs, or just the unresolved comments. Claude sends back a scoped edit or comment. The server applies it to the in-memory model and writes to disk. Claude never reads the full file.

**The architecture becomes three interfaces to the same artifact model:**

- **The app** — human GUI
- **The CLI** (`mdpal`) — scriptable interface for Claude Code
- **The MCP server** — Claude's native interface, stateful, token-efficient

---

## Dual UX/AX Design Principle

**@human:**
Another design principle guiding us: we need both human centric and agent centric user experience.

So, it is a section-oriented editor we need to build in a command line tool.

We need a mechanism to "force a context refresh" when we drift from the original document.

**@claude:**
**The context refresh problem:** Claude reads a section, does some reasoning, proposes an edit. But the section has changed since Claude read it. You need something like a **version or hash per section.** When Claude reads a section, it gets the content plus a version token. When Claude submits an edit, it includes that token. If the section has changed, the operation is rejected and the current content is returned.

This is optimistic concurrency control — the same pattern as ETags in HTTP.

**The dual UX principle applied:**

- **Templates** need to work for both audiences
- **Comments** need to be authorable and readable by both
- **Document homes** are discoverable by both
- **The metadata block format** needs to be something Claude can read and write fluently

---

## Self-Contained Comments

**@human:**
Comments should probably include the section / text block to which they are applied?

Also, a sed approach requires streaming the entire document to perform operations, doesn't it.

**@claude:**
**Comments including their target content:** Important for two reasons. First, token efficiency: when Claude reads a comment, it gets the relevant context right there without needing to separately read the section. Second, **staleness detection**: if the comment includes the text it was written against, you can diff against current content and see whether the comment is still relevant.

```yaml
- id: 1
  type: question
  author: claude
  section: authentication
  version: a3f2b1
  date: 2025-03-10
  context: |
    The user authenticates via OAuth2 and receives
    a bearer token that expires after 24 hours.
  text: "Does this handle token refresh?"
```

**`sed` and the streaming problem:** Exactly. `sed` processes the entire file linearly. A section-oriented editor with an in-memory AST flips this: the document is parsed once, operations are O(section) not O(document).

---

## LSP Server

**@human:**
Hmmmm....should we consider a Language Server (LSP) for this "language"? We can wrap that as an MCP?

**@claude:**
The appeal is that LSP is the standard interface between editors and language intelligence. If the section-oriented document engine is exposed as an LSP server:

- **The GUI app** connects to it as an LSP client
- **VS Code and other editors** get the same intelligence without custom plugin work
- **The MCP server wraps the LSP** — or they share the same engine

The architecture:

- **LSP** is the editor protocol layer — diagnostics, navigation, hover info, code actions
- **MCP** is the agent protocol layer — read section, add comment, edit section
- **CLI** is a thin client

The LSP gives you: diagnostics flagging stale comments, code actions for resolving comments, go-to-definition on section slugs.

**@human:**
Oh, I still want our markdown powered editor. I want that user experience. But we can build it on an LSP perhaps?

We could port marksman into whatever language we settle on (Swift?)

I think V1 is the core engine + editor UX + CLI?

**@claude:**
Yes. The editor isn't an afterthought bolted onto an LSP — it's the primary human experience. But building it *on top of* an LSP means the editor's intelligence comes from the same engine that powers the CLI and eventually MCP.

**V1 scope refined:**

- **Core engine** — Section-oriented document model, YAML metadata block parsing, comment CRUD, slug-based section addressing, version hashing, template and document home support
- **Editor UX** — SwiftUI app with `DocumentGroup`, side-by-side edit + preview, section navigation, comment rendering, inline admonitions, basic review workflow
- **CLI** — `mdpal` commands for sections, read, edit, comment, resolve, create from template
- **LSP** — Even in V1, the engine is designed as a server that the editor connects to

---

## First Design Artifact

**@human:**
Where do you think we stand in terms of making this design concrete?

**@claude:**
**Things that feel solid:**

- Single `.md` file with metadata in a bounded HTML comment block at the end
- Section-oriented model
- AST-anchored comments with optional sub-range
- Comment types: question, suggestion, note, directive
- Unresolved/resolved split in the metadata block
- Templates and document homes as first-class concepts
- Three interfaces: GUI app, CLI (`mdpal`), MCP server — shared model
- Optimistic concurrency via section version hashes
- Design principle: valid Markdown everywhere
- Design principle: human-centric and agent-centric UX
- Token efficiency through section-scoped operations

**Things that need to be made concrete:**

- The exact artifact file format
- The document model in Swift
- The CLI command surface
- The MCP tool surface
- Template format
- Document home config
- The prompt packaging logic

I think the most useful next step is to **write this very design as a concrete artifact using the format we've been designing.**

**@human:**
Yes, let's do that and we can try manipulating it manually.

*[Claude creates `design-markdown-pal.md` — the first design artifact using its own conventions]*

---

## CLI Simulation and Format Testing

*[Claude builds a simulated `mdpal.sh` CLI tool and runs operations against the design document]*

**Key findings from the simulation:**

1. **Section boundary:** The reader must stop at `<!-- begin:markdown-pal-meta -->`
2. **Special characters:** Pipe-delimited format + shell tools = escaping hell. Real argument for YAML.
3. **Code block awareness:** Must skip headings inside fenced code blocks. Needs proper AST parsing, not regex.
4. **Section identity:** Need a canonical way to reference sections — slugs.
5. **Meta block format:** Pipe-delimited is fragile in practice.

**@claude:**
The pipe-delimited format is too fragile. YAML inside the meta block handles multiline, special characters, and nesting naturally. And the `sed` failure makes the case for a section-oriented editor — line-oriented tools break on structured content.

---

## YAML Metadata and Versioning

**@human:**
The metablock can be handled as a code block, right? So YAML probably makes sense?

Leading Zeros in Version and Revision? How about V0001.00003.2025-03-10-1628?

**@claude:**
**YAML in a fenced code block inside HTML comments:** Standard renderers either hide it (HTML comment) or render it as a YAML code block — harmless either way.

**Versioning — tightened proposal:** `V0001.0003.20250310T1628Z`

- 4 digits each for version and revision (consistent)
- ISO 8601 compact datetime with timezone
- Fixed-width, sortable, globally unique

---

## File Naming Convention

**@human:**
We should have a file naming feature, that takes a name prefix (MarkdownPalDesign) and updates the name using our version naming convention?

In terms of your critiques, remember we are building for both Human/User Experience (HCI/UX) and Agent Experience (AX).

**@claude:**
**File naming:** `{Prefix}-{VersionId}.md`

Example: `MarkdownPalDesign-V0001.0003.20250310T1628Z.md`

For **agents**: Claude Code can `ls docs/design/` and immediately see which artifacts exist and how current they are — without reading any files. Significant token efficiency gain.

For **humans**: Sortable and scannable in Finder.

**UX and AX design principle:** Every piece of information has **one canonical representation** that both audiences consume. No divergence between "display version" and "real version."

---

## Bundle Architecture

**@human:**
An idea. Just like Mac OS X applications are actually directories, how about a MarkdownPal document is actually a directory, with all revisions in it? Can be a directory with a name and then each version. Can have a symlink to the latest.

**@claude:**
**The concept:**

```
docs/design/MarkdownPalDesign.mdpal/
├── latest.md → V0001.0003.20250310T1628Z.md   (symlink)
├── V0001.0003.20250310T1628Z.md                (current)
├── V0001.0002.20250310T1422Z.md                (previous)
├── V0001.0001.20250310T1000Z.md                (earlier)
└── .mdpal/
    └── config.yaml                              (bundle config)
```

**Why a bundle:**

- Keeps the document home clean — one entry per artifact
- Version history is intrinsic — don't need git to see evolution
- OS-native packaging — macOS/iOS treat package UTTypes as single documents
- Agent-friendly — Claude Code can `ls` inside or follow `latest.md`
- Comment resolution across revisions — old revisions are frozen snapshots

**iOS/iPadOS:** iOS handles document packages (`UTType` with `isPackage = true`). Pages, Numbers, Keynote all use package formats.

**@human:**
Yes, resolution of a comment becomes visible in the next version. Yes, revisions should be prunable. Let's make this approach V1.

---

## Design Document Updates

*[Claude produces `MarkdownPalDesign-V0001.0003.20250310T1730Z.md` — comprehensive design document incorporating all decisions: bundle architecture, versioning, comment resolution across revisions, pruning, UX/AX design section, updated appendices, and reviewer comments (r001-r009) addressed to @claude-code]*

---

## Review by Claude Code

**@human:**
Claude Code is reviewing it right now.

**@claude:**
This is a real end-to-end test of the workflow — a design document about a review tool, being reviewed by the tool's intended user (Claude Code), using the conventions the document defines.

The bundle feasibility hinges on:

- **r004 (DocumentGroup + package UTType)** — most uncertain. SwiftUI's document APIs were designed for single files initially.
- **r006 (git integration)** — could go either way. Tracking every revision in git is redundant.
- **r001 (symlink fallback)** — probably solvable but good to confirm.

---

## Structural Editing CLI

**@human:**
A companion - if we did not mention and discuss it earlier - is a command line tool that allows agents to edit markdown files based on structure. Read in a file, capture its structure in memory - perhaps an AST - and then read and edit it by looking at and manipulating its structure and contents.

**@claude:**
That's the `mdpal` CLI — but you're making me think about whether we've been specific enough about structural manipulation *within* a section. Things like:

- Insert a paragraph at position N within a section
- Add an item to a list
- Wrap selected text in an admonition block
- Reorder sections
- Move a subsection from one parent to another

The `ed` analogy is apt but incomplete. What we want is **AST-oriented commands**:

```
mdpal open MyDesign.mdpal
mdpal nav                           # show AST structure
mdpal nav architecture              # show children of ## Architecture
mdpal read architecture/paragraph:2 # read second paragraph
mdpal insert architecture --after paragraph:2 --type paragraph "New content here"
mdpal insert architecture --type admonition --admonition-type question "@claude Is this right?"
mdpal move error-handling --after architecture  # reorder sections
mdpal wrap architecture/paragraph:3 --type admonition --admonition-type note
```

The `open` command loads the file and holds the AST. Subsequent commands operate on the in-memory structure. A `save` writes out the new revision.

For sub-section element addressing: **positional within a section plus content matching as a fallback** — `paragraph:2` or `paragraph:contains("Redis")`.

This is V1 scope — it's the core of what makes the CLI useful for agents rather than just a fancy `cat` and `sed`.

---

## Summary of Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Editor base | New SwiftUI app | Existing editors too constrained for review workflows |
| Metadata storage | YAML in HTML comment fences at end of file | Single file, invisible in renderers, Claude-friendly |
| Metadata format | YAML (not pipe-delimited) | Pipe-delimited broke during prototyping |
| Comment anchoring | AST nodes with optional sub-range | Survives edits, enables structural operations |
| Comment types | question, suggestion, note, directive, decision | Each type has different expected responses |
| Markdown extensions | GFM-style admonitions (`[!QUESTION]`, etc.) | Valid Markdown, render as blockquotes anywhere |
| Architecture | Core engine + LSP + GUI + CLI + MCP | Shared model, different surfaces for humans and agents |
| Editing model | Section-oriented (not line-oriented) | `sed` fails on structured content |
| Versioning | `V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z` | Fixed-width, sortable, one canonical form for UX and AX |
| File organization | `.mdpal` bundle directories | Clean document homes, intrinsic version history, OS-native packages |
| Comment resolution | Appears in next revision | Old revisions are frozen snapshots, natural audit trail |
| Revision management | Prunable with metadata merge-forward | Prevents unbounded growth while preserving history |
| Concurrency | Optimistic via section version hashes | Compare-and-swap, no locks |
| Token efficiency | Section-scoped operations, self-contained comments | Agents never read full files for scoped work |
| Design principle | Human UX and Agent AX as co-equal concerns | One canonical representation, symmetric operations |
