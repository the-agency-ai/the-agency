# PVR Transcript: Markdown Pal

**Date:** 2026-03-29
**Principal:** jordan
**Agent:** markdown-pal

---

## Item 1: Core Value Proposition

**@agent:** The seed doc positions Markdown Pal as: "A section-oriented editing and review tool that supports both human and agent workflows over shared Markdown artifacts." The key insight is: the document IS the review artifact. Comments, decisions, and review state live inside the .md file as YAML metadata — not in a separate system. Three distinctive elements: (1) Section-oriented — operations target headings/sections, not lines. The AST is the API. (2) Dual-audience (UX + AX) — same document model, same operations, different surfaces (GUI for humans, CLI/MCP for agents). (3) Token-efficient — agents read only the section they need, comments carry their own context. My read: This is a strong, focused value prop. It's not "another Markdown editor" — it's a review tool that happens to edit Markdown. The agent-native angle is the differentiator. Does this positioning still feel right? Is "section-oriented review tool for design artifacts" the right frame, or has your thinking shifted since the original seed was written?

**@jordan:** Yes, that is correct.

**@agent:** So the core value prop is confirmed as-is: section-oriented review tool for design artifacts, dual-audience (human + agent), document-is-the-artifact. No repositioning needed. Decision: Core value prop stands as written in the seed doc. Agreed on Item 1? Ready for Item 2?

**@jordan:** Could be for any markdown file on which we want to comment and iterate. Could be a plan, a PVR, an A&D, etc. not just design artifacts. This probably means we will also need diff capabilities, which we did not highlight or call out earlier.

**@agent:** So two refinements: (1) Broader scope — not "design artifacts" but any Markdown artifact in the AIADLC: plans, PVRs, A&Ds, requests, runbooks, specs, etc. The tool serves The Agency's full document lifecycle. (2) Diff is a first-class capability — needs to be called out explicitly, not buried. When you're iterating on an artifact, seeing what changed between revisions is fundamental to the review workflow. The revised value prop would be something like: "A section-oriented review tool for Markdown artifacts — supporting structured commenting, diffing, and iteration across both human and agent workflows in the AI-Augmented Development Life Cycle." Does that capture it?

**@jordan:** 1. And could even go further: could be an article or report or chapter in a book.

**@agent:** So you're saying it's not even limited to AIADLC artifacts — it's for any Markdown file that benefits from structured review. Articles, reports, book chapters, blog posts. The AIADLC workflow is the primary use case, but the tool itself is general-purpose. Is that right?

**@jordan:** And while not called out previously, we will want a structured view of the document that allows us to quickly and easily navigate the document.

**@agent:** So two things: (1) General-purpose scope — any Markdown file that needs structured review, not just AIADLC artifacts. (2) Structured navigation — an outline/tree view of the document's heading structure that lets you jump around quickly. This is a core UX feature, not a nice-to-have. The seed doc does mention "section navigation sidebar" in the GUI spec, but you're elevating it — this is fundamental to the experience, not just a sidebar feature. Is that the right read?

**@jordan:** And the diff capability.

**@agent:** Right — three additions to the value prop: (1) General-purpose — any Markdown file, not just AIADLC artifacts. (2) Structured navigation — first-class outline/tree view for quick document traversal. (3) Diff — first-class capability for seeing what changed between revisions. So the revised core value prop: "A section-oriented Markdown review tool — supporting structured navigation, commenting, diffing, and iteration across both human and agent workflows. Works with any Markdown file that benefits from structured review." Does that capture it?

**@jordan:** And the ability to easily see and compare different versions of a document.

**@agent:** So diffing and version comparison are related but distinct: Diff — see what changed between two revisions. Version comparison — browse and compare different versions side by side, understand how the document evolved over time. The seed doc's .mdpal bundle already stores revisions and mentions a "version history browser" — but you're saying this needs to be elevated as a core capability. Is that right? Easy version browsing and comparison is part of the core value prop, not just an implementation detail of the bundle format?

**@jordan:** And version comparison is where we can leverage AI capabilities. We could say, "Tell me what changed between these two versions of the document..."

**@agent:** Now that's interesting. So it's not just mechanical diffing — it's intelligent version comparison. An agent can look at two revisions and give you a semantic summary: "The authentication section was rewritten to use OAuth2 instead of API keys, three open questions were resolved, and a new section on rate limiting was added." That's a qualitatively different capability from diff -u. The section-oriented AST makes this possible — the agent can reason about structural changes (sections added/removed/moved) not just text changes. Is that the complete picture, or is there more to add before we lock Item 1?

**@jordan:** That captures a lot of it. Token Economics was what drove the original thinking. Because I was seeing again and again that Claude Code was completely rewriting the document when it could have edited it for me.

**@agent:** So the origin story is token economics — you kept watching Claude Code rewrite entire documents when it only needed to change a section. That's wasteful in tokens, slow, and error-prone. The core frustration: there's no tool that lets an agent do scoped edits on structured Markdown. So agents fall back to rewriting the whole file. That makes token efficiency not just a feature — it's the founding motivation. Is that the right framing of where this started?

**@jordan:** Yes, it is.

**@agent:** Decision — Item 1: Core Value Proposition. Origin: Token economics. Value prop: section-oriented Markdown review tool supporting structured navigation, commenting, diffing, AI-powered version comparison, dual-audience workflows, token-efficient operations. Scope: general-purpose. Founding motivation: token efficiency. Agreed on Item 1? Ready for Item 2?

**@jordan:** Item 1 is ready. Onto Item 2.

---

## Item 2: Target Users & Use Cases

**@agent:** From the seed doc and our Item 1 discussion, I see three user profiles: (1) Human principal + AI agent pair — the primary use case. A human and Claude iterating on an artifact together. (2) Agent-to-agent — multiple agents reviewing each other's work. (3) Human solo — someone writing/reviewing Markdown who just wants structured navigation, commenting, and version comparison. Are all three equally important, or is there a clear priority order?

**@jordan:** Yes, correct, but usually it is human:agent or agent:agent collaboration.

**@agent:** So the primary users are collaborative pairs — human:agent and agent:agent — working together on a shared document. Human solo use is supported but not the driving design case. Is that right?

**@jordan:** Correct. The article and chapter would likely involve AI Augmentation.

**@agent:** Makes sense — even the "general-purpose" use cases still involve a human and agent collaborating. Pure solo human editing isn't really the target. Decision — Item 2. Agreed on Item 2? Ready for Item 3?

**@jordan:** A cornerstone is AI Augmented workflows. If someone wants to use it to just edit stuff, it can.

**@agent:** So the cornerstone positioning is: Markdown Pal is built for AI-augmented workflows. That's the design center. If someone happens to use it as a plain editor, fine — but every design decision is made through the lens of human:agent and agent:agent collaboration. Is that the right emphasis?

**@jordan:** Correct.

**@agent:** Decision — Item 2: Target Users & Use Cases (revised). Cornerstone: AI-augmented workflows. Primary users: human:agent pairs and agent:agent pairs. Also works as a standalone editor, but that's not the design driver. Agreed on Item 2? Ready for Item 3?

**@jordan:** Agreed. Onto Item 3.

---

## Item 3: Platform Priority

**@agent:** The seed doc describes V1 as shipping everything simultaneously: core engine + GUI app + CLI + LSP foundation. Given the cornerstone is AI-augmented workflows, there's a sequencing question. CLI-first: fastest path to agent value. App-first: humans get the structured navigation UX. Simultaneous: as the seed doc proposes. What's your instinct on sequencing?

**@jordan:** Yes, I think we get the CLI first. It has value for agents dealing with .MD files. But I think we can pursue in parallel.

**@agent:** So CLI is the priority — it delivers agent value immediately — but app development can happen in parallel, not blocked on CLI completion. Is that right?

**@jordan:** Yes.

**@agent:** Decision — Item 3: Platform Priority. Lead: CLI-first. Parallel: SwiftUI app development proceeds in parallel. Agreed on Item 3? Ready for Item 4?

**@jordan:** I think it is: Engine + LSP, then we do CLI and App in parallel.

**@agent:** So the sequencing is: (1) Core engine + LSP server first — the foundation that everything else talks to. (2) CLI and App in parallel — both are clients of the engine/LSP. That makes more sense architecturally — the engine is the brain, CLI and app are just different surfaces on top of it. Is that right?

**@jordan:** Correct. That works.

**@agent:** Decision — Item 3: Platform Priority (revised). Phase 1: Core engine + LSP server. Phase 2: CLI and SwiftUI app in parallel. Agreed on Item 3? Ready for Item 4?

**@jordan:** Complete. Onto Item 4.

---

## Item 4: Bundle Format (.mdpal)

**@agent:** The seed doc proposes a .mdpal bundle — a directory the OS presents as a single document, containing versioned revisions. Benefits: clean document homes, intrinsic version history, OS-native packaging, agent-friendly. Open concerns from the seed (r001, r004, r006): symlinks on non-POSIX filesystems, SwiftUI DocumentGroup + package UTType, git repo bloat. The big question: is the bundle format the right call, or is it over-engineering? Where do you stand on bundles?

**@jordan:** We are doing macOS. Bottom line. We are building with Swift.

**@agent:** So the platform concerns around symlinks and filesystem compatibility are moot — we're on macOS, it's POSIX, symlinks work. Swift has full FileWrapper/bundle API support natively. The feasibility concerns shrink significantly. Is that right?

**@jordan:** And maybe iOS.

**@agent:** Right — macOS primary, iOS possible. Both Apple platforms with full symlink and bundle support. The git concern (r006) still stands though — repos could bloat with every revision tracked. Do you have a view on that?

**@jordan:** We are talking about files that are maybe 20-30K. How will that give you repo bloat?!?

**@agent:** Ha — fair point. Even 50 revisions is ~1MB of plain text. Git handles that effortlessly. So r006 is a non-issue. Is that right?

**@jordan:** For now. Let's not make problems that may not exist.

**@agent:** Exactly. Decision — Item 4: Bundle Format. Go. Confirmed. macOS (possibly iOS). Git: track everything normally. Don't solve problems that don't exist yet. Agreed on Item 4? Ready for Item 5?

**@jordan:** Agreed. Move to Item 5.

---

## Item 5: Agent Interface Priority (CLI / MCP / LSP)

*In progress*
