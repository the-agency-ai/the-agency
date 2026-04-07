// What Problem: Iteration 1.1 requires tests for: parsing simple documents into
// correct tree structures, nested heading parent/child relationships, slug
// computation edge cases, version hash stability, and serialize round-trip.
//
// How & Why: Using Swift Testing framework (not XCTest) because this system has
// CommandLineTools only — XCTest module isn't available without full Xcode.
// Testing.framework ships with CommandLineTools on Swift 6.x via the external
// swiftlang/swift-testing package. Tests exercise the MarkdownParser directly —
// no mocks for engine core (per A&D §14). Each test is focused on one behavior.
// Fixture documents are inline strings for determinism.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)
// Updated: 2026-04-07 — converted from XCTest to Swift Testing framework
// Updated: 2026-04-07 — QG: strengthened assertions, added coverage tests

import Testing
@testable import MarkdownPalEngine

// MARK: - Basic Parsing

@Test func parseSimpleDocument() throws {
    let parser = MarkdownParser()
    let content = """
    # Introduction

    This is the introduction.

    # Methods

    Here are the methods.

    # Conclusion

    The end.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.level == 0)
    #expect(tree.root.heading == "")
    #expect(tree.root.children.count == 3)

    #expect(tree.root.children[0].heading == "Introduction")
    #expect(tree.root.children[0].level == 1)
    #expect(tree.root.children[0].content == "This is the introduction.")

    #expect(tree.root.children[1].heading == "Methods")
    #expect(tree.root.children[1].level == 1)
    #expect(tree.root.children[1].content == "Here are the methods.")

    #expect(tree.root.children[2].heading == "Conclusion")
    #expect(tree.root.children[2].level == 1)
    #expect(tree.root.children[2].content == "The end.")
}

@Test func parsePreambleContent() throws {
    let parser = MarkdownParser()
    let content = """
    Some preamble text before any heading.

    More preamble.

    # First Section

    Section content.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.content.contains("Some preamble text"))
    #expect(tree.root.content.contains("More preamble"))
    #expect(tree.root.children.count == 1)
    #expect(tree.root.children[0].heading == "First Section")
    #expect(tree.root.children[0].content == "Section content.")
}

@Test func parseNoHeadings() throws {
    let parser = MarkdownParser()
    let content = """
    Just some text with no headings.

    More text here.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.children.isEmpty)
    #expect(tree.root.content.contains("Just some text"))
}

@Test func parseEmptyString() throws {
    let parser = MarkdownParser()
    let tree = try parser.parse("")

    #expect(tree.root.children.isEmpty)
    #expect(tree.root.content == "")
    #expect(tree.root.heading == "")
    #expect(tree.root.level == 0)
    #expect(tree.originalSource == "")
}

// MARK: - Nested Headings

@Test func parseNestedHeadings() throws {
    let parser = MarkdownParser()
    let content = """
    # Top Level

    Top level content.

    ## Child Section

    Child content.

    ## Another Child

    More child content.

    # Second Top

    Second top content.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.children.count == 2)

    let first = tree.root.children[0]
    #expect(first.heading == "Top Level")
    #expect(first.level == 1)
    #expect(first.children.count == 2)

    #expect(first.children[0].heading == "Child Section")
    #expect(first.children[0].level == 2)
    #expect(first.children[0].content == "Child content.")

    #expect(first.children[1].heading == "Another Child")
    #expect(first.children[1].level == 2)

    let second = tree.root.children[1]
    #expect(second.heading == "Second Top")
    #expect(second.level == 1)
    #expect(second.children.isEmpty)
}

@Test func parseDeeplyNested() throws {
    let parser = MarkdownParser()
    let content = """
    # Level 1

    L1 content.

    ## Level 2

    L2 content.

    ### Level 3

    L3 content.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.children.count == 1)
    let l1 = tree.root.children[0]
    #expect(l1.heading == "Level 1")
    #expect(l1.children.count == 1)

    let l2 = l1.children[0]
    #expect(l2.heading == "Level 2")
    #expect(l2.children.count == 1)

    let l3 = l2.children[0]
    #expect(l3.heading == "Level 3")
    #expect(l3.content == "L3 content.")
    #expect(l3.children.isEmpty)
}

@Test func parseLevelSkipping() throws {
    let parser = MarkdownParser()
    let content = """
    # H1

    H1 content.

    ### H3 (skipped H2)

    H3 content.

    ## H2 after H3

    H2 content.
    """

    let tree = try parser.parse(content)

    #expect(tree.root.children.count == 1)
    let h1 = tree.root.children[0]
    #expect(h1.heading == "H1")
    // H3 should be a child of H1 (since H1 level < H3 level)
    #expect(h1.children.count == 2)
    #expect(h1.children[0].heading == "H3 (skipped H2)")
    #expect(h1.children[0].level == 3)
    #expect(h1.children[1].heading == "H2 after H3")
    #expect(h1.children[1].level == 2)
}

@Test func parseHeadingsOnlyNoContent() throws {
    let parser = MarkdownParser()
    let content = """
    # A

    # B

    # C
    """

    let tree = try parser.parse(content)

    #expect(tree.root.children.count == 3)
    #expect(tree.root.children[0].heading == "A")
    #expect(tree.root.children[0].content == "")
    #expect(tree.root.children[1].heading == "B")
    #expect(tree.root.children[1].content == "")
    #expect(tree.root.children[2].heading == "C")
    #expect(tree.root.children[2].content == "")
}

// MARK: - Slug Computation

@Test func slugBasic() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "Introduction") == "introduction")
    #expect(parser.slug(for: "Getting Started") == "getting-started")
}

@Test func slugSpecialChars() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "Hello, World!") == "hello-world")
    #expect(parser.slug(for: "Q&A Section") == "q-a-section")
    #expect(parser.slug(for: "Price: $100") == "price-100")
}

@Test func slugConsecutiveHyphens() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "A --- B") == "a-b")
    #expect(parser.slug(for: "Hello   World") == "hello-world")
}

@Test func slugTrimHyphens() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "---Hello---") == "hello")
    #expect(parser.slug(for: " Hello ") == "hello")
}

@Test func slugCodeInHeading() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "The `parse` method") == "the-parse-method")
}

@Test func slugFormattingStripped() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "**Bold** heading") == "bold-heading")
    #expect(parser.slug(for: "*Italic* heading") == "italic-heading")
}

@Test func slugEmptyString() {
    let parser = MarkdownParser()
    #expect(parser.slug(for: "") == "")
}

@Test func slugAllSpecialChars() {
    let parser = MarkdownParser()
    // All special chars → hyphens → collapsed → trimmed → empty
    #expect(parser.slug(for: "!!!") == "")
    #expect(parser.slug(for: "---") == "")
}

// MARK: - Version Hash

@Test func versionHashStability() {
    let content = "Some section content here."
    let hash1 = VersionHash.compute(content)
    let hash2 = VersionHash.compute(content)
    #expect(hash1 == hash2)
}

@Test func versionHashDifference() {
    let hash1 = VersionHash.compute("Content A")
    let hash2 = VersionHash.compute("Content B")
    #expect(hash1 != hash2)
}

@Test func versionHashLength() {
    let hash = VersionHash.compute("test content")
    #expect(hash.count == 12)
    #expect(hash.allSatisfy { $0.isHexDigit })
}

@Test func versionHashEmpty() {
    let hash = VersionHash.compute("")
    #expect(hash.count == 12)
}

// MARK: - Serialize Round-Trip

@Test func serializeRoundTrip() throws {
    let parser = MarkdownParser()
    let content = """
    # Introduction

    This is the introduction.

    ## Sub Section

    Sub content here.

    # Conclusion

    The end.
    """

    let tree = try parser.parse(content)
    let serialized = try parser.serialize(tree)

    // Serialized output should contain the content
    #expect(serialized.contains("# Introduction"))
    #expect(serialized.contains("This is the introduction."))
    #expect(serialized.contains("## Sub Section"))
    #expect(serialized.contains("Sub content here."))
    #expect(serialized.contains("# Conclusion"))
    #expect(serialized.contains("The end."))
    #expect(serialized.hasSuffix("\n"))

    // Re-parse the serialized output — structure preserved
    let tree2 = try parser.parse(serialized)

    #expect(tree2.root.children.count == tree.root.children.count)
    #expect(tree2.root.children[0].heading == "Introduction")
    #expect(tree2.root.children[0].children.count == 1)
    #expect(tree2.root.children[0].children[0].heading == "Sub Section")
    #expect(tree2.root.children[1].heading == "Conclusion")
}

@Test func serializeRoundTripPreamble() throws {
    let parser = MarkdownParser()
    let content = """
    Preamble text.

    # Section

    Content.
    """

    let tree = try parser.parse(content)
    let serialized = try parser.serialize(tree)

    // Serialized string contains preamble and section
    #expect(serialized.contains("Preamble text."))
    #expect(serialized.contains("# Section"))
    #expect(serialized.contains("Content."))

    let tree2 = try parser.parse(serialized)

    #expect(tree2.root.content.contains("Preamble"))
    #expect(tree2.root.children.count == 1)
    #expect(tree2.root.children[0].heading == "Section")
}

@Test func serializeEmptyDocument() throws {
    let parser = MarkdownParser()
    let tree = try parser.parse("")
    let serialized = try parser.serialize(tree)
    #expect(serialized == "")
}

// MARK: - Metadata Block

@Test func findMetadataBlock() {
    let parser = MarkdownParser()
    let content = """
    # Document

    Content here.

    <!-- begin:markdown-pal-meta
    ```yaml
    comments: []
    flags: []
    ```
    end:markdown-pal-meta -->
    """

    let range = parser.findMetadataBlock(in: content)
    #expect(range != nil)

    if let range = range {
        let yaml = String(content[range.contentRange])
        #expect(yaml.contains("comments: []"))
        #expect(yaml.contains("flags: []"))

        // outerRange should span the full block
        let outer = String(content[range.outerRange])
        #expect(outer.hasPrefix("<!-- begin:markdown-pal-meta"))
        #expect(outer.hasSuffix("end:markdown-pal-meta -->"))
    }
}

@Test func noMetadataBlock() {
    let parser = MarkdownParser()
    let content = """
    # Document

    Just content, no metadata.
    """

    let range = parser.findMetadataBlock(in: content)
    #expect(range == nil)
}

@Test func malformedMetadataBlockBeginOnly() {
    let parser = MarkdownParser()
    let content = """
    # Document

    <!-- begin:markdown-pal-meta
    some content but no end marker
    """

    let range = parser.findMetadataBlock(in: content)
    #expect(range == nil)
}

@Test func metadataBlockWithoutFencedCode() {
    let parser = MarkdownParser()
    let content = """
    <!-- begin:markdown-pal-meta
    comments: []
    flags: []
    end:markdown-pal-meta -->
    """

    let range = parser.findMetadataBlock(in: content)
    #expect(range != nil)

    if let range = range {
        // Fallback path: treat inner content as YAML
        let yaml = String(content[range.contentRange])
        #expect(yaml.contains("comments: []"))
    }
}

@Test func writeMetadataBlockNew() {
    let parser = MarkdownParser()
    let content = """
    # Document

    Content here.
    """

    let yaml = "comments: []\nflags: []"
    let result = parser.writeMetadataBlock(yaml, into: content)

    #expect(result.contains("<!-- begin:markdown-pal-meta"))
    #expect(result.contains("```yaml"))
    #expect(result.contains("comments: []"))
    #expect(result.contains("flags: []"))
    #expect(result.contains("```"))
    #expect(result.contains("end:markdown-pal-meta -->"))

    // Only one metadata block
    let beginCount = result.components(separatedBy: "<!-- begin:markdown-pal-meta").count - 1
    #expect(beginCount == 1)
}

@Test func writeMetadataBlockReplace() {
    let parser = MarkdownParser()
    let content = """
    # Document

    Content here.

    <!-- begin:markdown-pal-meta
    ```yaml
    comments: []
    ```
    end:markdown-pal-meta -->
    """

    let yaml = "comments:\n  - id: 1\nflags: []"
    let result = parser.writeMetadataBlock(yaml, into: content)

    #expect(result.contains("id: 1"))
    #expect(result.contains("flags: []"))
    // Should not have double metadata blocks
    let beginCount = result.components(separatedBy: "<!-- begin:markdown-pal-meta").count - 1
    #expect(beginCount == 1)
}

// MARK: - SectionInfo

@Test func sectionInfoFromTree() throws {
    let parser = MarkdownParser()
    let content = """
    # Heading

    Content here.

    ## Sub Heading

    Sub content.
    """

    let tree = try parser.parse(content)
    let info = tree.root.toSectionInfo(parser: parser)

    #expect(info.heading == "")
    #expect(info.level == 0)
    #expect(info.children.count == 1)

    let child = info.children[0]
    #expect(child.heading == "Heading")
    #expect(child.slug == "heading")
    #expect(child.level == 1)
    #expect(child.children.count == 1)

    let grandchild = child.children[0]
    #expect(grandchild.heading == "Sub Heading")
    #expect(grandchild.slug == "sub-heading")
    #expect(grandchild.level == 2)
}

// MARK: - EngineError

@Test func engineErrorEquality() {
    let err1 = EngineError.sectionNotFound(slug: "foo", available: ["bar", "baz"])
    let err2 = EngineError.sectionNotFound(slug: "foo", available: ["bar", "baz"])
    let err3 = EngineError.sectionNotFound(slug: "qux", available: [])

    #expect(err1 == err2)
    #expect(err1 != err3)
}

@Test func engineErrorVersionConflict() {
    let err = EngineError.versionConflict(
        slug: "intro",
        expected: "abc123",
        actual: "def456",
        currentContent: "some content"
    )
    // Verify pattern matching works
    if case .versionConflict(let slug, let expected, let actual, _) = err {
        #expect(slug == "intro")
        #expect(expected == "abc123")
        #expect(actual == "def456")
    } else {
        Issue.record("Expected versionConflict case")
    }
}

// MARK: - Original Source Preservation

@Test func originalSourcePreserved() throws {
    let parser = MarkdownParser()
    let content = "# Hello\n\nWorld.\n"
    let tree = try parser.parse(content)
    #expect(tree.originalSource == content)
}
