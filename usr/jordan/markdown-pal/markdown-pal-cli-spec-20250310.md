A companion - if we did not mention and discuss it earlier - is a command line tool that allows agents to edit markdown files based on structure 

Read in a file, capture its structure in memory - perhaps an AST - and then read and edit it by looking at and manipulate its structure and contents 

Thoughts?

That's the mdpal CLI we've been designing — but you're making me think about whether we've been specific enough about what "section-oriented editing" actually means at the command level.
Let me sharpen this. What you're describing is essentially an interactive or stateful session where an agent:

Opens a file and parses it into an AST
Navigates the structure — "show me the headings", "read this section"
Manipulates it structurally — "insert a paragraph after the third item in this list", "move this section before that one", "wrap this in an admonition"
All without re-reading the file each time

The CLI commands we have right now are mostly at the section level — read a section, edit a section, add a comment. But there's a layer below that which is about structural manipulation within a section. Things like:

Insert a paragraph at position N within a section
Add an item to a list
Wrap selected text in an admonition block
Reorder sections
Move a subsection from one parent to another
Insert a code block or table

This is where the AST really earns its keep. The agent isn't doing string manipulation — it's saying "add a list item to the unordered list in the rate-limit-tiers section" and the engine knows what that means structurally.
The ed analogy is apt but incomplete. ed gave you line-oriented commands: print line N, substitute text, append after line. What we want is AST-oriented commands: print node at path, replace node content, insert node after sibling, move node.
Something like:

mdpal open MyDesign.mdpal
mdpal nav                           # show AST structure
mdpal nav architecture              # show children of ## Architecture
mdpal read architecture/paragraph:2 # read second paragraph
mdpal insert architecture --after paragraph:2 --type paragraph "New content here"
mdpal insert architecture --type admonition --admonition-type question "@claude Is this right?"
mdpal move error-handling --after architecture  # reorder sections
mdpal wrap architecture/paragraph:3 --type admonition --admonition-type note

The open command loads the file and holds the AST. Subsequent commands operate on the in-memory structure. A save (or auto-save) writes out the new revision.
This is also where the LSP connection matters. If the engine is running as an LSP server holding the AST, the CLI doesn't need its own stateful session — it sends commands to the server. The GUI and CLI share the same live AST. An agent edits a section via CLI, and the human sees it update in the app.
There's also a question of how deep the structural addressing goes. Section slugs are clear. But within a section — "the second paragraph", "the third list item", "the code block after the table" — you need a way to reference sub-section elements. Could be positional (paragraph:2), could be content-based (paragraph:contains("Redis")), or AST path-based.
For the agent use case, I think positional within a section plus content matching as a fallback is the right balance. The agent reads the section, sees the structure, and references elements by position. If positions shift, content matching catches it — similar to how our comment context field enables staleness detection.
This is absolutely V1 scope — it's the core of what makes the CLI useful for agents rather than just a fancy cat and sed. Should I fold this into the design doc as a deeper treatment of the CLI's structural editing capabilities?