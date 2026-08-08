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
    try String(contentsOf: fixtureURL(named: name), encoding: .utf8)
}

/// On-disk URL of a fixture .md — needed by tests that exercise path resolution
/// relative to the source document.
func fixtureURL(named name: String) throws -> URL {
    guard let url = Bundle.module.url(
        forResource: name, withExtension: "md", subdirectory: "Fixtures"
    ) else {
        throw TestFailure(message: "Fixture '\(name)' not found", file: #file, line: #line)
    }
    return url
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

    // Image path resolution — contract §11 containment
    ("imagePath_resolvesRelativeToSource", testImagePath_resolvesRelativeToSource),
    ("imagePath_refusesParentTraversal", testImagePath_refusesParentTraversal),
    ("imagePath_refusesSiblingPrefixEscape", testImagePath_refusesSiblingPrefixEscape),
    ("imagePath_refusesLocalPathWithNoBase", testImagePath_refusesLocalPathWithNoBase),
    ("imagePath_emptyAndNilSources", testImagePath_emptyAndNilSources),
    ("imagePath_remoteURLsPassThrough", testImagePath_remoteURLsPassThrough),
    ("imagePath_containmentAllowsBaseItself", testImagePath_containmentAllowsBaseItself),

    // FontResolver
    ("font_systemFamiliesResolveToSystem", testFont_systemFamiliesResolveToSystem),
    ("font_genericsAreSkippedNotResolved", testFont_genericsAreSkippedNotResolved),
    ("font_unresolvableNamesFallBackToSystem", testFont_unresolvableNamesFallBackToSystem),
    ("font_emptyAndDegenerateStacks", testFont_emptyAndDegenerateStacks),
    ("font_quotedNamesAreUnquoted", testFont_quotedNamesAreUnquoted),
    ("font_firstResolvableWins", testFont_firstResolvableWins),
    ("font_resolutionIsStableAcrossCalls", testFont_resolutionIsStableAcrossCalls),

    // HTML text helpers
    ("html_lineBreakOnlyIsCaseInsensitive", testHTML_lineBreakOnlyIsCaseInsensitive),
    ("html_lineBreakOnlyAcceptsRunsAndWhitespace", testHTML_lineBreakOnlyAcceptsRunsAndWhitespace),
    ("html_lineBreakCount", testHTML_lineBreakCount),
    ("html_stripTags", testHTML_stripTags),

    // DeckController — single owner of open/reload/export + presentation wiring
    ("controller_loadsMarkdownSource", testController_loadsMarkdownSource),
    ("controller_windowTitleTracksDocument", testController_windowTitleTracksDocument),
    ("controller_openMissingFileReportsError", testController_openMissingFileReportsError),
    ("controller_openFixtureLoadsSlides", testController_openFixtureLoadsSlides),
    ("controller_failedOpenLeavesCurrentDocumentIntact", testController_failedOpenLeavesCurrentDocumentIntact),
    ("controller_reopeningSameFileIsStable", testController_reopeningSameFileIsStable),
    ("controller_presentationCoordinatorIsWired", testController_presentationCoordinatorIsWired),
    ("controller_presentationTeardownFiresOnce", testController_presentationTeardownFiresOnce),
    ("controller_commandHandlersInstallOnlyOnce", testController_commandHandlersInstallOnlyOnce),

    // ColorHex validating parser
    ("colorHex_validatingAcceptsThreeSixAndEightDigits", testColorHex_validatingAcceptsThreeSixAndEightDigits),
    ("colorHex_validatingRejectsMalformed", testColorHex_validatingRejectsMalformed),
    ("colorHex_shorthandExpandsLikeCSS", testColorHex_shorthandExpandsLikeCSS),
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

    // Resolution goes through the production resolver, not a re-implementation,
    // so deleting or breaking ImagePathResolver fails this test.
    let fixtureURL = try fixtureURL(named: "04-images")
    guard let present = ImagePathResolver.resolve(
        source: perSlide[0][0].source, relativeTo: fixtureURL
    ) else {
        throw TestFailure(
            message: "Resolver refused the fixture's own image",
            file: #file, line: #line
        )
    }
    try expectTrue(
        FileManager.default.fileExists(atPath: present.path),
        "Fixture 04 image asset must ship with the fixture and resolve"
    )

    // The missing image still resolves to a legal in-deck path — it is the file
    // that is absent, which is what drives the placeholder rather than a refusal.
    guard let missing = ImagePathResolver.resolve(
        source: perSlide[2][0].source, relativeTo: fixtureURL
    ) else {
        throw TestFailure(
            message: "Missing image should resolve to a path, not be refused",
            file: #file, line: #line
        )
    }
    try expectFalse(
        FileManager.default.fileExists(atPath: missing.path),
        "missing-on-purpose.png must not exist"
    )
}

// MARK: - Image path resolution (contract §11)

func testImagePath_resolvesRelativeToSource() throws {
    let base = try fixtureURL(named: "04-images")
    let resolved = ImagePathResolver.resolve(source: "./images/sample.png", relativeTo: base)
    try expectNotNil(resolved, "In-deck relative path must resolve")
    try expectTrue(
        resolved?.path.hasSuffix("Fixtures/images/sample.png") == true,
        "Resolved path should sit under the fixture directory"
    )
}

func testImagePath_refusesParentTraversal() throws {
    let base = try fixtureURL(named: "04-images")
    try expectNil(
        ImagePathResolver.resolve(source: "../secret.png", relativeTo: base),
        "../ escape must be refused"
    )
    try expectNil(
        ImagePathResolver.resolve(source: "./images/../../secret.png", relativeTo: base),
        "Embedded ../.. escape must be refused"
    )
}

func testImagePath_refusesSiblingPrefixEscape() throws {
    // A bare hasPrefix containment test accepts this: the deck directory
    // "Fixtures" is a string prefix of the sibling "Fixtures-private".
    let base = URL(fileURLWithPath: "/tmp/decks/Fixtures/slides.md")
    try expectNil(
        ImagePathResolver.resolve(source: "../Fixtures-private/secret.png", relativeTo: base),
        "Sibling directory sharing a name prefix must not be treated as in-deck"
    )
}

func testImagePath_refusesLocalPathWithNoBase() throws {
    try expectNil(
        ImagePathResolver.resolve(source: "./images/sample.png", relativeTo: nil),
        "With no source URL there is nothing to contain against — refuse"
    )
}

func testImagePath_emptyAndNilSources() throws {
    let base = try fixtureURL(named: "04-images")
    try expectNil(ImagePathResolver.resolve(source: nil, relativeTo: base))
    try expectNil(ImagePathResolver.resolve(source: "", relativeTo: base))
}

func testImagePath_remoteURLsPassThrough() throws {
    let base = try fixtureURL(named: "04-images")
    try expect(
        ImagePathResolver.resolve(
            source: "https://example.com/a.png", relativeTo: base
        )?.absoluteString,
        equals: "https://example.com/a.png"
    )
    // Remote sources need no base — containment does not apply to them.
    try expect(
        ImagePathResolver.resolve(
            source: "http://example.com/a.png", relativeTo: nil
        )?.absoluteString,
        equals: "http://example.com/a.png"
    )
}

func testImagePath_containmentAllowsBaseItself() throws {
    let base = URL(fileURLWithPath: "/tmp/decks/talk")
    try expectTrue(
        ImagePathResolver.isContained(base, in: base),
        "The base directory is contained in itself"
    )
    try expectFalse(
        ImagePathResolver.isContained(URL(fileURLWithPath: "/tmp/decks"), in: base),
        "A parent is not contained in its child"
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
    // Invalid inputs produce the magenta fallback, not a crash. Note "fff" is
    // no longer in this set — 3-digit CSS shorthand is now a supported form.
    let tooShort = Color(hex: "ff")
    let empty = Color(hex: "")
    let invalid = Color(hex: "gggggg")

    try expect(tooShort.description, equals: empty.description, "Invalid inputs should match")
    try expect(empty.description, equals: invalid.description, "Invalid inputs should match")

    // And the fallback must be distinguishable from a real color — otherwise
    // this test would pass for an implementation that returned one value for
    // everything, valid or not.
    try expectTrue(
        empty.description != Color(hex: "ff0000").description,
        "Fallback must differ from a successfully parsed color"
    )
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

// MARK: - FontResolver

func testFont_systemFamiliesResolveToSystem() throws {
    try expect(
        FontResolver.resolution(for: "system-ui, -apple-system, sans-serif"),
        equals: .system
    )
    try expect(FontResolver.resolution(for: "-apple-system"), equals: .system)
    // bodyfont is the token the shared theme JSON emits for body copy.
    try expect(FontResolver.resolution(for: "bodyfont"), equals: .system)
}

func testFont_genericsAreSkippedNotResolved() throws {
    // A stack of nothing but CSS generics names a category, not a font, so it
    // must reach the system fallback rather than trying Font.custom("serif").
    try expect(FontResolver.resolution(for: "sans-serif, serif, monospace"), equals: .system)
}

func testFont_unresolvableNamesFallBackToSystem() throws {
    try expect(
        FontResolver.resolution(for: "Nonexistent Family, AlsoFake"),
        equals: .system
    )
}

func testFont_emptyAndDegenerateStacks() throws {
    try expect(FontResolver.resolution(for: ""), equals: .system)
    try expect(FontResolver.resolution(for: ",,,"), equals: .system)
    try expect(FontResolver.resolution(for: "   "), equals: .system)
}

func testFont_quotedNamesAreUnquoted() throws {
    // Helvetica is present on every macOS install; the quotes and surrounding
    // whitespace must be stripped before the family is probed.
    try expect(
        FontResolver.resolution(for: "'Helvetica', sans-serif"),
        equals: .family("Helvetica")
    )
    try expect(
        FontResolver.resolution(for: "\"Helvetica\""),
        equals: .family("Helvetica")
    )
}

func testFont_firstResolvableWins() throws {
    // The unresolvable name is skipped and the real one is chosen.
    try expect(
        FontResolver.resolution(for: "NoSuchFont, Helvetica"),
        equals: .family("Helvetica")
    )
}

func testFont_resolutionIsStableAcrossCalls() throws {
    // Results are memoized; a second call must agree with the first.
    let stack = "'Helvetica', sans-serif"
    try expect(FontResolver.resolution(for: stack), equals: FontResolver.resolution(for: stack))
}

// MARK: - HTMLText

func testHTML_lineBreakOnlyIsCaseInsensitive() throws {
    for spelling in ["<br>", "<BR>", "<br/>", "<br />", "<br   />", "<Br/>"] {
        try expectTrue(
            HTMLText.isLineBreakOnly(spelling),
            "\(spelling) should count as a line-break-only block"
        )
    }
}

func testHTML_lineBreakOnlyAcceptsRunsAndWhitespace() throws {
    try expectTrue(HTMLText.isLineBreakOnly("  <br>\n<br />  "))
    try expectFalse(HTMLText.isLineBreakOnly("<br>text"))
    try expectFalse(HTMLText.isLineBreakOnly("<div></div>"))
    try expectFalse(HTMLText.isLineBreakOnly(""))
}

func testHTML_lineBreakCount() throws {
    try expect(HTMLText.lineBreakCount("<br>"), equals: 1)
    try expect(HTMLText.lineBreakCount("<br><BR/><br />"), equals: 3)
    // Never zero — a break-only block always contributes some space.
    try expect(HTMLText.lineBreakCount("no breaks"), equals: 1)
}

func testHTML_stripTags() throws {
    try expect(HTMLText.stripTags("<div>hello</div>"), equals: "hello")
    try expect(HTMLText.stripTags("plain"), equals: "plain")
}

// MARK: - ColorHex validating parser

func testColorHex_validatingAcceptsThreeSixAndEightDigits() throws {
    try expectNotNil(Color(validatingHex: "#fff"), "3-digit shorthand is valid")
    try expectNotNil(Color(validatingHex: "#ffffff"), "6-digit is valid")
    try expectNotNil(Color(validatingHex: "#ff0000cc"), "8-digit RGBA is valid")
    try expectNotNil(Color(validatingHex: "ff0000"), "leading # is optional")
}

func testColorHex_validatingRejectsMalformed() throws {
    try expectNil(Color(validatingHex: "red"), "named colors are not hex")
    try expectNil(Color(validatingHex: "#ff"), "2 digits is not a valid length")
    try expectNil(Color(validatingHex: "#fffff"), "5 digits is not a valid length")
    try expectNil(Color(validatingHex: "#gggggg"), "non-hex digits are rejected")
    try expectNil(Color(validatingHex: ""), "empty string is not a color")
}

func testColorHex_shorthandExpandsLikeCSS() throws {
    // #abc means #aabbcc — the two forms must produce the same color.
    try expect(
        Color(validatingHex: "#abc")?.description,
        equals: Color(validatingHex: "#aabbcc")?.description
    )
}

// MARK: - DeckController (single owner of the document lifecycle)

func testController_loadsMarkdownSource() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.deckState.load(from: "# Only slide")
        try expect(controller.deckState.document.slides.count, equals: 1)
        try expectNil(controller.errorMessage, "A clean load reports no error")
    }
}

func testController_windowTitleTracksDocument() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.deckState.load(from: "# My Deck")
        // One format string, one place — the delegate no longer builds its own.
        try expect(controller.windowTitle, equals: "mdslidepal \u{2014} My Deck")
    }
}

func testController_openMissingFileReportsError() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.openFile(url: URL(fileURLWithPath: "/nonexistent/nope.md"))
        try expectNotNil(
            controller.errorMessage,
            "Opening a missing file must surface an error, not fail silently"
        )
    }
}

func testController_openFixtureLoadsSlides() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let url = try fixtureURL(named: "02-multi-slide")
        controller.openFile(url: url)
        try expectNil(controller.errorMessage, "Opening a real fixture should succeed")
        try expectTrue(
            controller.deckState.document.slides.count > 1,
            "Multi-slide fixture should yield several slides"
        )
        try expect(controller.deckState.document.sourceURL, equals: url)
    }
}

func testController_failedOpenLeavesCurrentDocumentIntact() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let good = try fixtureURL(named: "02-multi-slide")
        controller.openFile(url: good)
        let slideCount = controller.deckState.document.slides.count

        // A failed open must not disturb the document that is still loaded and
        // still being watched — releasing its security-scoped access here is what
        // silently killed live-reload.
        controller.openFile(url: URL(fileURLWithPath: "/nonexistent/nope.md"))

        try expectNotNil(controller.errorMessage, "Failed open reports an error")
        try expect(
            controller.deckState.document.sourceURL, equals: good,
            "The previously open document stays open"
        )
        try expect(controller.deckState.document.slides.count, equals: slideCount)
    }
}

func testController_reopeningSameFileIsStable() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let url = try fixtureURL(named: "01-minimal")
        controller.openFile(url: url)
        controller.openFile(url: url)
        controller.openFile(url: url)

        try expectNil(controller.errorMessage, "Repeated opens of the same file are fine")
        try expect(controller.deckState.document.sourceURL, equals: url)
    }
}

func testController_presentationCoordinatorIsWired() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        // The coordinator must reach DeckState, or presentation-mode key handling
        // silently does nothing — the defect that left Phase 3 unreachable.
        try expectNotNil(
            controller.presentation.deckState,
            "PresentationCoordinator must be connected to the deck"
        )
        try expectFalse(controller.presentation.isPresenting)
    }
}

func testController_presentationTeardownFiresOnce() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        var endedCount = 0
        controller.presentation.onPresentationEnded = { endedCount += 1 }

        controller.presentation.startPresentation()
        try expectTrue(controller.presentation.isPresenting)

        controller.presentation.stopPresentation()
        try expectFalse(controller.presentation.isPresenting)
        try expect(endedCount, equals: 1, "Teardown fires once per presentation")

        // Escape, the End button and the menu can all land here; the second
        // call must not re-run teardown (which would close windows twice).
        controller.presentation.stopPresentation()
        try expect(endedCount, equals: 1, "Repeat stop must be a no-op")
    }
}

func testController_commandHandlersInstallOnlyOnce() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.deckState.load(from: "# One\n\n---\n\n# Two\n\n---\n\n# Three")
        controller.installCommandHandlers()
        controller.installCommandHandlers()  // idempotent

        // A single .nextSlide post must advance exactly one slide. Duplicate
        // subscriptions would advance two and skip a slide.
        controller.deckState.firstSlide()
        NotificationCenter.default.post(name: .nextSlide, object: nil)
        try expect(
            controller.deckState.selectedSlideIndex, equals: 1,
            "One command, one handler — duplicate observers would skip a slide"
        )
    }
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
