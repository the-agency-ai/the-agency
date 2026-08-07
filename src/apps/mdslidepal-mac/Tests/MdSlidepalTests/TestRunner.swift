// What Problem: XCTest is not available with CommandLineTools-only installs
// (no full Xcode). We need a test runner that works with just `swift build`.
//
// How & Why: Custom lightweight test harness following the mdpal-app precedent.
// Each test is a throwing closure. Assertions use expect() helpers that throw
// on failure. The runner collects pass/fail counts and exits with appropriate
// exit code.
//
// Build prerequisite: despite the XCTest-free design above, the package no
// longer builds against a CommandLineTools-only toolchain — the HighlightSwift
// dependency uses SwiftUI's @Entry macro, whose SwiftUIMacros plugin ships only
// in the full Xcode SDK. Build and run with:
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run MdSlidepalTests
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1 tests
// Updated: 2026-08-07 — added fixture 04 (images) coverage, closing the last
// gap against the contract's 8 acceptance fixtures; recorded the full-Xcode
// build prerequisite discovered while verifying the Phase 5.1+5.2 graft.

import Foundation
import SwiftUI
import MdSlidepalLib
import Markdown

// MARK: - Test Infrastructure

struct TestFailure: Error {
    let message: String
    let file: String
    let line: Int
}

func expect<T: Equatable>(
    _ actual: T, equals expected: T,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    if actual != expected {
        let msg = message.isEmpty
            ? "Expected \(expected), got \(actual)"
            : "\(message): expected \(expected), got \(actual)"
        throw TestFailure(message: msg, file: file, line: line)
    }
}

func expectTrue(
    _ value: Bool,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    if !value {
        let msg = message.isEmpty ? "Expected true, got false" : message
        throw TestFailure(message: msg, file: file, line: line)
    }
}

func expectFalse(
    _ value: Bool,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    if value {
        let msg = message.isEmpty ? "Expected false, got true" : message
        throw TestFailure(message: msg, file: file, line: line)
    }
}

func expectNil<T>(
    _ value: T?,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    if value != nil {
        let msg = message.isEmpty ? "Expected nil, got \(value!)" : message
        throw TestFailure(message: msg, file: file, line: line)
    }
}

func expectNotNil<T>(
    _ value: T?,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    if value == nil {
        let msg = message.isEmpty ? "Expected non-nil value" : message
        throw TestFailure(message: msg, file: file, line: line)
    }
}

// MARK: - Fixture Loading

func loadFixture(_ name: String) throws -> String {
    // Try bundle resource first
    if let url = Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Fixtures") {
        return try String(contentsOf: url, encoding: .utf8)
    }
    throw TestFailure(message: "Fixture '\(name)' not found", file: #file, line: #line)
}

// MARK: - Test Cases

let allTests: [(String, () throws -> Void)] = [
    // Fixture tests
    ("fixture01_minimal", testFixture01_Minimal),
    ("fixture02_multiSlide", testFixture02_MultiSlide),
    ("fixture03_codeBlocks", testFixture03_CodeBlocks),
    ("fixture04_images", testFixture04_Images),
    ("fixture05_tablesAndLists", testFixture05_TablesAndLists),
    ("fixture06_frontMatter", testFixture06_FrontMatter),
    ("fixture07_speakerNotes", testFixture07_SpeakerNotes),
    ("fixture08_edgeCases", testFixture08_EdgeCases),

    // Front matter unit tests
    ("frontMatter_noFrontMatter", testFrontMatter_NoFrontMatter),
    ("frontMatter_withFrontMatter", testFrontMatter_WithFrontMatter),
    ("frontMatter_emptyFrontMatter", testFrontMatter_Empty),

    // Slide splitter unit tests
    ("splitter_emptyDocument", testSplitter_EmptyDocument),
    ("splitter_singleSlide", testSplitter_SingleSlide),
    ("splitter_twoSlides", testSplitter_TwoSlides),
    ("splitter_trailingBreak", testSplitter_TrailingBreak),
    ("splitter_adjacentBreaks", testSplitter_AdjacentBreaks),
    ("splitter_codeBlockWithBreak", testSplitter_CodeBlockWithBreak),

    // Notes extraction unit tests
    ("notes_withNotes", testNotes_WithNotes),
    ("notes_caseInsensitive", testNotes_CaseInsensitive),
    ("notes_singular", testNotes_Singular),
    ("notes_notFalsePositive", testNotes_NotFalsePositive),

    // Slide metadata unit tests
    ("metadata_validBlock", testMetadata_ValidBlock),
    ("metadata_malformedYAML", testMetadata_MalformedYAML),
    ("metadata_notFirstChild", testMetadata_NotFirstChild),
    ("metadata_unquotedHexValue", testMetadata_UnquotedHexValue),
    ("hero_singleH1IsHero", testHero_singleH1IsHero),
    ("hero_h1PlusSubtitleIsHero", testHero_h1PlusSubtitleIsHero),
    ("hero_multiH3IsNotHero", testHero_multiH3IsNotHero),
    ("hero_h1PlusBodyIsNotHero", testHero_h1PlusBodyIsNotHero),
    ("hero_onlyH6IsNotHero", testHero_onlyH6IsNotHero),

    // ColorHex unit tests
    ("colorHex_validHex", testColorHex_ValidHex),
    ("colorHex_withHash", testColorHex_WithHash),
    ("colorHex_invalidLength", testColorHex_InvalidLength),

    // DeckDocument.title fallback
    ("title_fromFrontMatter", testTitle_FromFrontMatter),
    ("title_fromHeading", testTitle_FromHeading),
    ("title_untitled", testTitle_Untitled),

    // Front-matter error paths
    ("frontMatter_invalidYAML", testFrontMatter_InvalidYAML),
    ("frontMatter_windowsLineEndings", testFrontMatter_WindowsLineEndings),

    // Theme tests
    ("theme_defaultDecodes", testTheme_DefaultDecodes),
    ("theme_darkDecodes", testTheme_DarkDecodes),
    ("theme_loaderDefault", testTheme_LoaderDefault),
    ("theme_loaderDark", testTheme_LoaderDark),
    ("theme_loaderUnknown", testTheme_LoaderUnknown),
    ("theme_bundledConstant", testTheme_BundledConstant),
    ("theme_headingScale", testTheme_HeadingScale),
]

// MARK: - Fixture Tests

func testFixture01_Minimal() throws {
    let source = try loadFixture("01-minimal")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 1, "Fixture 01 slide count")
    try expectNil(doc.frontMatter, "Fixture 01 has no front-matter")
    try expectTrue(doc.diagnostics.isEmpty, "Fixture 01 should have no diagnostics")
    try expect(doc.slides[0].title, equals: "Hello mdslidepal", "Fixture 01 title")
}

func testFixture02_MultiSlide() throws {
    let source = try loadFixture("02-multi-slide")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 3, "Fixture 02 slide count")
    try expect(doc.slides[0].title, equals: "Slide One")
    try expect(doc.slides[1].title, equals: "Slide Two")
    try expect(doc.slides[2].title, equals: "Slide Three")
}

func testFixture03_CodeBlocks() throws {
    let source = try loadFixture("03-code-blocks")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 5, "Fixture 03 slide count")
}

/// Collect every `Markdown.Image` node reachable from a markup subtree.
func collectImages(_ markup: Markup) -> [Markdown.Image] {
    var found: [Markdown.Image] = []
    if let image = markup as? Markdown.Image {
        found.append(image)
    }
    for child in markup.children {
        found.append(contentsOf: collectImages(child))
    }
    return found
}

func testFixture04_Images() throws {
    let source = try loadFixture("04-images")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 3, "Fixture 04 slide count")

    // Every slide carries exactly one block image.
    let perSlide = doc.slides.map { slide in
        slide.markupChildren.flatMap { collectImages($0) }
    }
    try expect(perSlide[0].count, equals: 1, "Slide 1 image count")
    try expect(perSlide[1].count, equals: 1, "Slide 2 image count")
    try expect(perSlide[2].count, equals: 1, "Slide 3 image count")

    // Sources survive parsing as the relative paths the renderer resolves.
    try expect(perSlide[0][0].source, equals: "./images/sample.png")
    try expect(perSlide[1][0].source, equals: "./images/sample.png")
    try expect(
        perSlide[2][0].source, equals: "./images/missing-on-purpose.png",
        "Slide 3 references the deliberately missing image"
    )

    // Alt text must be preserved — it is the placeholder fallback for the
    // missing image on slide 3 (contract §11: no silent skip).
    try expect(
        perSlide[2][0].plainText, equals: "An image that is missing",
        "Missing image must retain alt text for the placeholder"
    )

    // The referenced asset resolves on disk; the missing one does not.
    guard let fixtureURL = Bundle.module.url(
        forResource: "04-images", withExtension: "md", subdirectory: "Fixtures"
    ) else {
        throw TestFailure(
            message: "Fixture '04-images' not found", file: #file, line: #line
        )
    }
    let baseURL = fixtureURL.deletingLastPathComponent()
    try expectTrue(
        FileManager.default.fileExists(
            atPath: baseURL.appendingPathComponent("./images/sample.png").standardized.path
        ),
        "Fixture 04 image asset must ship with the fixture"
    )
    try expectFalse(
        FileManager.default.fileExists(
            atPath: baseURL.appendingPathComponent("./images/missing-on-purpose.png")
                .standardized.path
        ),
        "missing-on-purpose.png must not exist"
    )
}

func testFixture05_TablesAndLists() throws {
    let source = try loadFixture("05-tables-and-lists")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 4, "Fixture 05 slide count")
}

func testFixture06_FrontMatter() throws {
    let source = try loadFixture("06-front-matter")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 3, "Fixture 06 slide count")
    try expectNotNil(doc.frontMatter, "Fixture 06 should have front-matter")
    try expect(doc.frontMatter?.title, equals: "Fixture 06 \u{2014} Front Matter Test")
    try expect(doc.frontMatter?.author, equals: "Jordan Dea-Mattson")
    try expect(doc.frontMatter?.theme, equals: "agency-default")
    try expect(doc.frontMatter?.date, equals: "2026-04-11")
    try expect(doc.slides[0].title, equals: "First slide after front matter")
}

func testFixture07_SpeakerNotes() throws {
    let source = try loadFixture("07-speaker-notes")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 4, "Fixture 07 slide count")
    try expectNotNil(doc.slides[0].notes, "Slide 1 should have speaker notes")
    try expectTrue(
        doc.slides[0].notes?.contains("speaker notes") == true,
        "Slide 1 notes should contain 'speaker notes'"
    )
    try expectNil(doc.slides[1].notes, "Slide 2 should have no notes")
    try expectNotNil(doc.slides[2].notes, "Slide 3 should have speaker notes")
    try expectNotNil(doc.slides[3].notes, "Slide 4 should have speaker notes")
}

func testFixture08_EdgeCases() throws {
    let source = try loadFixture("08-edge-cases")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    // NOTE: Fixture acceptance says 4 slides, but the markdown has 5 ThematicBreaks
    // producing 6 content sections. Escalated to captain as dispatch #217.
    // AST-based parser correctly produces 6:
    //   0: intro (code block), 1: "empty slide follows", 2: empty,
    //   3: "After the empty slide", 4: "trailing ---", 5: acceptance text
    try expect(doc.slides.count, equals: 6, "Fixture 08 slide count (pending fixture clarification)")

    // CRITICAL: code block with --- inside must NOT split
    let slide0Text = doc.slides[0].plainText
    try expectTrue(
        slide0Text.contains("YAML front matter example"),
        "Slide 0 should contain the YAML code block content intact"
    )

    // Empty slide exists (from adjacent --- sequence)
    try expectTrue(
        doc.slides[2].markupChildren.isEmpty,
        "Slide 2 should be the empty divider slide"
    )

    // "After the empty slide" follows the empty one
    try expect(doc.slides[3].title, equals: "After the empty slide")

    // "Edge case — trailing ---" slide
    try expectTrue(
        doc.slides[4].title?.contains("trailing") == true,
        "Slide 4 should be the 'trailing ---' slide"
    )
}

// MARK: - Front Matter Unit Tests

func testFrontMatter_NoFrontMatter() throws {
    let result = FrontMatterExtractor.extract(from: "# Hello\n\nWorld")
    try expectNil(result.frontMatter)
    try expect(result.remainingSource, equals: "# Hello\n\nWorld")
}

func testFrontMatter_WithFrontMatter() throws {
    let source = "---\ntitle: \"Test\"\nauthor: \"Me\"\n---\n# Hello"
    let result = FrontMatterExtractor.extract(from: source)
    try expectNotNil(result.frontMatter)
    try expect(result.frontMatter?.title, equals: "Test")
    try expect(result.frontMatter?.author, equals: "Me")
    try expectTrue(result.remainingSource.contains("# Hello"))
}

func testFrontMatter_Empty() throws {
    let source = "---\n---\n# Hello"
    let result = FrontMatterExtractor.extract(from: source)
    try expectNil(result.frontMatter, "Empty front-matter should not parse")
}

// MARK: - Slide Splitter Unit Tests

func testSplitter_EmptyDocument() throws {
    let doc = Document(parsing: "")
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 1, "Empty document should produce 1 slide")
}

func testSplitter_SingleSlide() throws {
    let doc = Document(parsing: "# Hello\n\nWorld")
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 1)
}

func testSplitter_TwoSlides() throws {
    let doc = Document(parsing: "# A\n\n---\n\n# B")
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 2)
}

func testSplitter_TrailingBreak() throws {
    let doc = Document(parsing: "# A\n\n---\n\n# B\n\n---")
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 2, "Trailing --- should not create a phantom slide")
}

func testSplitter_AdjacentBreaks() throws {
    let doc = Document(parsing: "# A\n\n---\n\n---\n\n# B")
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 3, "Adjacent --- should produce one empty slide")
}

func testSplitter_CodeBlockWithBreak() throws {
    let source = "# Code\n\n```yaml\n---\nkey: value\n---\n```\n\nMore content"
    let doc = Document(parsing: source)
    let slides = SlideSplitter.split(document: doc)
    try expect(slides.count, equals: 1, "--- inside code block should NOT split")
}

// MARK: - Notes Unit Tests

func testNotes_WithNotes() throws {
    let source = "# Slide\n\nContent\n\nNotes:\nThese are notes"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expect(doc.slides.count, equals: 1)
    try expectNotNil(doc.slides[0].notes)
    try expectTrue(doc.slides[0].notes?.contains("These are notes") == true)
}

func testNotes_CaseInsensitive() throws {
    let source = "# Slide\n\nnotes:\nLower case marker"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expectNotNil(doc.slides[0].notes)
}

func testNotes_Singular() throws {
    let source = "# Slide\n\nNote:\nSingular marker"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expectNotNil(doc.slides[0].notes)
}

// MARK: - Theme Tests

func testTheme_DefaultDecodes() throws {
    // Use ThemeLoader which knows the lib bundle location
    let theme = ThemeLoader.shared.load(name: "agency-default")
    try expectNotNil(theme, "agency-default should load from bundle")

    try expect(theme!.name, equals: "agency-default")
    try expect(theme!.logicalDimensions.width, equals: 1920)
    try expect(theme!.logicalDimensions.height, equals: 1080)
    try expect(theme!.colors.background, equals: "#ffffff")
    try expect(theme!.bodySize, equals: 32)
    try expect(theme!.headingScale.h1, equals: 72)
}

func testTheme_DarkDecodes() throws {
    let theme = ThemeLoader.shared.load(name: "agency-dark")
    try expectNotNil(theme, "agency-dark should load from bundle")

    try expect(theme!.name, equals: "agency-dark")
    try expect(theme!.colors.background, equals: "#0a0a0a")
}

func testTheme_LoaderDefault() throws {
    let theme = ThemeLoader.shared.load(name: "agency-default")
    try expectNotNil(theme)
    try expect(theme?.name, equals: "agency-default")
}

func testTheme_LoaderDark() throws {
    let theme = ThemeLoader.shared.load(name: "agency-dark")
    try expectNotNil(theme)
    try expect(theme?.name, equals: "agency-dark")
}

func testTheme_LoaderUnknown() throws {
    let theme = ThemeLoader.shared.load(name: "nonexistent-theme")
    try expectNil(theme)
}

func testTheme_BundledConstant() throws {
    let theme = Theme.agencyDefault
    try expect(theme.name, equals: "agency-default")
    try expect(theme.logicalDimensions.width, equals: 1920)
}

func testTheme_HeadingScale() throws {
    let scale = HeadingScale(h1: 72, h2: 56, h3: 44, h4: 36, h5: 28, h6: 24)
    try expect(scale.size(for: 1), equals: 72)
    try expect(scale.size(for: 3), equals: 44)
    try expect(scale.size(for: 6), equals: 24)
    try expect(scale.size(for: 7), equals: 24)  // Out of range defaults to h6
}

// MARK: - Notes False Positive Test (QG Fix #4)

func testNotes_NotFalsePositive() throws {
    // "Note: see appendix" in a paragraph should still be treated as a notes marker
    // per reveal.js convention — but "Notable:" should NOT trigger
    let source = "# Slide\n\nNotable: this is not a notes marker"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expectNil(doc.slides[0].notes, "Notable: should not trigger notes extraction")
}

// MARK: - Slide Metadata Tests (QG #9)

func testMetadata_ValidBlock() throws {
    let source = "# First\n\n---\n\n<!-- slide:\nbackground: red\ntransition: fade\n-->\n\n# Second"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expect(doc.slides.count, equals: 2)
    try expectNotNil(doc.slides[1].metadata, "Slide 2 should have metadata")
    try expect(doc.slides[1].metadata?.background, equals: "red")
    try expect(doc.slides[1].metadata?.transition, equals: "fade")
}

func testMetadata_MalformedYAML() throws {
    let source = "---\n\n<!-- slide:\n  : invalid yaml [[\n-->\n\n# Content"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    // Should produce a warning but still render
    // Note: the slide should exist even with malformed metadata
    try expectTrue(doc.slides.count >= 1)
}

func testMetadata_NotFirstChild() throws {
    // <!-- slide: --> NOT first after break — should be ignored
    let source = "# Title\n\nSome text\n\n<!-- slide:\n  background: \"#000\"\n-->"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expectNil(doc.slides[0].metadata, "Metadata not first child should be ignored")
}

// MARK: - Hero slide detection

func testHero_singleH1IsHero() throws {
    let doc = DeckParser().parse(source: "# My Talk Title")
    try expectTrue(doc.slides[0].isHero, "Single H1 should be a hero slide")
}

func testHero_h1PlusSubtitleIsHero() throws {
    // Title + subtitle is the canonical cover-slide shape.
    let doc = DeckParser().parse(source: "# My Talk Title\n\n## Subtitle line")
    try expectTrue(doc.slides[0].isHero, "H1 + H2 subtitle should be hero")
}

func testHero_multiH3IsNotHero() throws {
    // Multi-heading section slides must NOT become hero (regression guard
    // from Phase 5.2 review finding).
    let doc = DeckParser().parse(source: "### Section A\n\n### Section B")
    try expectFalse(doc.slides[0].isHero, "Two H3 headings should not be hero")
}

func testHero_h1PlusBodyIsNotHero() throws {
    let doc = DeckParser().parse(source: "# Title\n\nSome body text here.")
    try expectFalse(doc.slides[0].isHero, "H1 with body paragraph is a content slide")
}

func testHero_onlyH6IsNotHero() throws {
    // H6-only slide isn't a cover — tighten avoids boosting H6 to hero.
    let doc = DeckParser().parse(source: "###### Tiny heading")
    try expectFalse(doc.slides[0].isHero, "H6-only slide is not hero")
}

func testMetadata_UnquotedHexValue() throws {
    // Regression: unquoted hex color values (leading `#`) used to be lost to
    // YAML's comment handling. The extractor now quotes them pre-parse.
    let source = "<!-- slide:\nbackground: #ff0000\n-->\n\n# Content"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expectTrue(doc.slides.count >= 1)
    try expectNotNil(doc.slides[0].metadata, "Slide should carry metadata")
    try expect(doc.slides[0].metadata?.background, equals: "#ff0000",
               "Unquoted hex background should be preserved")
}

// MARK: - ColorHex Tests (QG #10)

func testColorHex_ValidHex() throws {
    // Verify colors parse without crashing and produce distinct values
    let red = Color(hex: "ff0000")
    let green = Color(hex: "#00ff00")
    let black = Color(hex: "000000")
    // SwiftUI Color doesn't expose components directly, but we can verify
    // distinct inputs produce distinct colors (not all magenta fallback)
    try expectTrue(red.description != green.description, "Red and green should differ")
    try expectTrue(red.description != black.description, "Red and black should differ")
    try expectTrue(green.description != black.description, "Green and black should differ")
}

func testColorHex_WithHash() throws {
    // Hash prefix should be stripped and produce the same color
    let withHash = Color(hex: "#ffffff")
    let withoutHash = Color(hex: "ffffff")
    try expect(withHash.description, equals: withoutHash.description, "Hash prefix should not change result")
}

func testColorHex_InvalidLength() throws {
    // Invalid inputs should produce magenta fallback, not crash
    let short = Color(hex: "fff")
    let empty = Color(hex: "")
    let invalid = Color(hex: "gggggg")
    // All invalid inputs should produce the same fallback
    try expect(short.description, equals: empty.description, "Invalid inputs should match")
    try expect(empty.description, equals: invalid.description, "Invalid inputs should match")
}

// MARK: - DeckDocument.title Tests (QG #11)

func testTitle_FromFrontMatter() throws {
    let source = "---\ntitle: \"My Deck\"\n---\n# Heading"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expect(doc.title, equals: "My Deck")
}

func testTitle_FromHeading() throws {
    let source = "# First Heading\n\nSome text"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expect(doc.title, equals: "First Heading")
}

func testTitle_Untitled() throws {
    let source = "Just some text with no heading"
    let parser = DeckParser()
    let doc = parser.parse(source: source)
    try expect(doc.title, equals: "Untitled")
}

// MARK: - Front-matter Error Path Tests (QG #11 continued)

func testFrontMatter_InvalidYAML() throws {
    let source = "---\n: invalid [[ yaml\n---\n# Hello"
    let result = FrontMatterExtractor.extract(from: source)
    // Should produce a diagnostic warning, not crash
    try expectNil(result.frontMatter, "Invalid YAML should not produce front-matter")
    try expectTrue(result.diagnostics.count > 0, "Should warn about invalid YAML")
}

func testFrontMatter_WindowsLineEndings() throws {
    let source = "---\r\ntitle: \"Test\"\r\n---\r\n# Hello"
    let result = FrontMatterExtractor.extract(from: source)
    try expectNotNil(result.frontMatter, "Windows line endings should parse")
    try expect(result.frontMatter?.title, equals: "Test")
}

// MARK: - Runner

@main
struct TestMain {
    static func main() {
        var passed = 0
        var failed = 0
        var failures: [(String, String)] = []

        print("Running \(allTests.count) tests...\n")

        for (name, test) in allTests {
            do {
                try test()
                passed += 1
                print("  \u{2713} \(name)")
            } catch let failure as TestFailure {
                failed += 1
                let location = URL(fileURLWithPath: failure.file).lastPathComponent
                failures.append((name, "\(location):\(failure.line): \(failure.message)"))
                print("  \u{2717} \(name): \(failure.message)")
            } catch {
                failed += 1
                failures.append((name, error.localizedDescription))
                print("  \u{2717} \(name): \(error)")
            }
        }

        print("\n\(passed + failed) tests: \(passed) passed, \(failed) failed")

        if !failures.isEmpty {
            print("\nFailures:")
            for (name, msg) in failures {
                print("  - \(name): \(msg)")
            }
        }

        exit(failed > 0 ? 1 : 0)
    }
}
