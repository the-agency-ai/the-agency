// What Problem: XCTest is not available with CommandLineTools-only installs
// (no full Xcode). We need a test runner that works with just `swift build`.
//
// How & Why: Custom lightweight test harness following the mdpal-app precedent.
// Each test is a throwing closure. Assertions use expect() helpers that throw
// on failure. The runner collects pass/fail counts and exits with appropriate
// exit code.
//
// HOW TO RUN — use the script, not `swift test`:
//
//   ./scripts/test.sh
//
// `swift test` builds this target, finds no .testTarget in the package, runs
// zero tests and exits 0. The script sets DEVELOPER_DIR, builds, runs the real
// runner and propagates its exit code.
//
// Build prerequisite: despite the XCTest-free design above, the package no
// longer builds against a CommandLineTools-only toolchain — the HighlightSwift
// dependency uses SwiftUI's @Entry macro, whose SwiftUIMacros plugin ships only
// in the full Xcode SDK. The equivalent by hand is:
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run MdSlidepalTests
//
// ADDING A TEST: append it to `allTests` below AND bump the count in
// runnerRegistrationCountIsPinned. A test function that is never registered
// never runs, and nothing else notices.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1 tests
// Updated: 2026-08-07 — added fixture 04 (images) coverage, closing the last
// gap against the contract's 8 acceptance fixtures; recorded the full-Xcode
// build prerequisite discovered while verifying the Phase 5.1+5.2 graft.

import AppKit
import Foundation
import PDFKit
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

/// Assert non-nil and hand back the value, so a test can keep going with it
/// instead of force-unwrapping after an expectNotNil.
func expectUnwrapped<T>(
    _ value: T?,
    _ what: String = "value",
    file: String = #file, line: Int = #line
) throws -> T {
    guard let value else {
        throw TestFailure(message: "Expected \(what) to be non-nil", file: file, line: line)
    }
    return value
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
    // Named for the gap: fixture 05 asks for clickable autolinks and we do not
    // produce them. See the test's header comment.
    ("fixture05_autolinksAreNotYetLinkified", testFixture05_AutolinksAreNotYetLinkified),
    ("fixture06_frontMatter", testFixture06_FrontMatter),
    ("fixture07_speakerNotes", testFixture07_SpeakerNotes),
    ("fixture07_notesAreStrippedFromTheSlideBody", testFixture07_NotesAreStrippedFromTheSlideBody),
    ("fixture08_edgeCases", testFixture08_EdgeCases),
    // Named for the dispute, not for the behavior: the fixture says 4 slides and
    // the parser says 6. Dispatch #217 is still open.
    ("fixture08_slideCountPendingDispatch217", testFixture08_SlideCountPendingDispatch217),
    ("fixture08_emptySourceYieldsOneUntitledSlide", testFixture08_EmptySourceYieldsOneUntitledSlide),

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
    ("hero_singleH2IsHero", testHero_singleH2IsHero),
    ("hero_firstHeadingBelowH2IsNotHero", testHero_firstHeadingBelowH2IsNotHero),
    ("hero_zeroHeadingsIsNotHero", testHero_zeroHeadingsIsNotHero),
    ("hero_threeHeadingsIsNotHero", testHero_threeHeadingsIsNotHero),

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
    ("controller_reopeningAFileKeepsItReadable", testController_reopeningAFileKeepsItReadable),
    ("controller_presentationCoordinatorIsWired", testController_presentationCoordinatorIsWired),
    ("controller_presentationTeardownFiresOnce", testController_presentationTeardownFiresOnce),
    ("controller_commandHandlersInstallOnlyOnce", testController_commandHandlersInstallOnlyOnce),

    // ColorHex validating parser
    ("colorHex_validatingAcceptsThreeSixAndEightDigits", testColorHex_validatingAcceptsThreeSixAndEightDigits),
    ("colorHex_validatingRejectsMalformed", testColorHex_validatingRejectsMalformed),
    ("colorHex_shorthandExpandsLikeCSS", testColorHex_shorthandExpandsLikeCSS),
    ("colorHex_validatingTrimsBeforeStrippingHash", testColorHex_validatingTrimsBeforeStrippingHash),

    // HTMLText — QG defect fixes
    ("html_lineBreakOnlyIsLinearOnPathologicalInput", testHTML_lineBreakOnlyIsLinearOnPathologicalInput),
    ("html_stripTagsRemovesCommentsScriptsAndStyles", testHTML_stripTagsRemovesCommentsScriptsAndStyles),
    ("html_lineBreakCountIsATrueCount", testHTML_lineBreakCountIsATrueCount),

    // LocalImageCache — bounded, mtime-keyed decode cache
    ("imageCache_unchangedFileReturnsTheSameInstance", testImageCache_unchangedFileReturnsTheSameInstance),
    ("imageCache_touchedFileIsRedecoded", testImageCache_touchedFileIsRedecoded),
    ("imageCache_missingAndNonImageFilesReturnNil", testImageCache_missingAndNonImageFilesReturnNil),

    // ImageBlockView sizing — never upscale past native resolution
    ("imageSizing_smallImageIsNotUpscaled", testImageSizing_smallImageIsNotUpscaled),
    ("imageSizing_largeImageScalesDownPreservingAspect", testImageSizing_largeImageScalesDownPreservingAspect),
    ("imageSizing_maxBoxDerivesFromTheme", testImageSizing_maxBoxDerivesFromTheme),

    // ImagePathResolver — scheme comparison is case-insensitive
    ("imagePath_remoteSchemeIsCaseInsensitive", testImagePath_remoteSchemeIsCaseInsensitive),

    // DeckController — error clearing and launch-argument handling
    ("controller_successfulOpenClearsPriorError", testController_successfulOpenClearsPriorError),
    ("controller_launchIgnoresOSInjectedFlags", testController_launchIgnoresOSInjectedFlags),
    ("controller_launchWithNoArgumentsShowsWelcomeDeck", testController_launchWithNoArgumentsShowsWelcomeDeck),
    ("controller_launchWithFileArgumentOpensIt", testController_launchWithFileArgumentOpensIt),
    ("controller_launchWithBadPathReportsAndStillShowsWelcome", testController_launchWithBadPathReportsAndStillShowsWelcome),
    ("controller_launchWithUnreadablePathStillShowsWelcome", testController_launchWithUnreadablePathStillShowsWelcome),

    // LocalImageCache — decompression-bomb budget (QG wave 2, item A)
    ("imageBudget_pixelBombIsRefusedWithoutDecoding", testImageBudget_pixelBombIsRefusedWithoutDecoding),
    ("imageBudget_oversizedFileIsRefused", testImageBudget_oversizedFileIsRefused),
    ("imageBudget_normalImageStillLoads", testImageBudget_normalImageStillLoads),

    // Main window hosting — SwiftUI toolbar bridging (QG wave 2, item B)
    ("deckWindow_hostsViaContentViewController", testDeckWindow_hostsViaContentViewController),
    ("deckWindow_minContentSizeConstrainsTheWindow", testDeckWindow_minContentSizeConstrainsTheWindow),
    ("deckWindow_opensAtTheDefaultContentSize", testDeckWindow_opensAtTheDefaultContentSize),

    // Menu key equivalents — contract §10 (QG wave 2, item C)
    ("menu_slideNavigationKeyEquivalentsAreModified", testMenu_slideNavigationKeyEquivalentsAreModified),
    ("menu_slideNavigationUsesArrowAndHomeEndKeys", testMenu_slideNavigationUsesArrowAndHomeEndKeys),

    // Presentation window teardown re-entrancy (QG wave 2, item D)
    ("presentation_closingWindowIsReleasedBeforeTeardown", testPresentation_closingWindowIsReleasedBeforeTeardown),

    // Borderless audience window key eligibility (QG wave 2, item E)
    ("presentation_audienceWindowCanBecomeKey", testPresentation_audienceWindowCanBecomeKey),

    // Slide body layout — contract §11 no-crop overflow (QG wave 2, item F)
    ("slide_bodyLayoutIsTopAligned", testSlide_bodyLayoutIsTopAligned),
    ("slide_bodyContentRendersFromTheTop", testSlide_bodyContentRendersFromTheTop),

    // YAML hex pre-quoting (QG wave 2, item G)
    ("metadata_hexQuotingTable", testMetadata_hexQuotingTable),
    ("metadata_hexQuotingRoundTripsThroughYaml", testMetadata_hexQuotingRoundTripsThroughYaml),

    // Gap-closing wave 3 — the runner itself
    ("runnerRegistrationCountIsPinned", testRunner_registrationCountIsPinned),

    // DeckController.reload() — had no coverage at all
    ("controller_reloadPreservesSlidePosition", testController_reloadPreservesSlidePosition),
    ("controller_reloadClampsPositionWhenDeckShrinks", testController_reloadClampsPositionWhenDeckShrinks),
    ("controller_reloadWithNoSourceURLIsANoOp", testController_reloadWithNoSourceURLIsANoOp),
    ("controller_reloadOfDeletedFileReportsError", testController_reloadOfDeletedFileReportsError),

    // Command bus — five of six commands had never been posted
    ("controller_navigationCommandsMoveTheSelection", testController_navigationCommandsMoveTheSelection),
    ("controller_reloadDeckCommandRereadsTheFile", testController_reloadDeckCommandRereadsTheFile),
    ("controller_exportPDFCommandWritesAPDF", testController_exportPDFCommandWritesAPDF),
    ("controller_doesNotHandleStartPresentation", testController_doesNotHandleStartPresentation),

    // PresentationWindowManager — 211 lines with no tests
    ("windowManager_startPresentationCommandStartsTheCoordinator", testWindowManager_startPresentationCommandStartsTheCoordinator),
    ("windowManager_installsTheCoordinatorTeardownCallback", testWindowManager_installsTheCoordinatorTeardownCallback),
    ("windowManager_doubleStartThenOneStopEndsPresentation", testWindowManager_doubleStartThenOneStopEndsPresentation),
    ("windowManager_stopOnAFreshManagerIsSafe", testWindowManager_stopOnAFreshManagerIsSafe),

    // Slide background fallback — was unreachable from a test
    ("slide_invalidBackgroundFallsBackToTheTheme", testSlide_invalidBackgroundFallsBackToTheTheme),

    // FontResolver — parsing pinned without depending on host font inventory
    ("font_candidateListStripsQuotesGenericsAndBlanks", testFont_candidateListStripsQuotesGenericsAndBlanks),
    ("font_stackWalkUsesTheFirstRegisteredFamily", testFont_stackWalkUsesTheFirstRegisteredFamily),
    ("font_postScriptRetryDropsSpaces", testFont_postScriptRetryDropsSpaces),

    // Contract §11 image diagnostics (QG wave 4, item C)
    ("imageDiagnostics_missingLocalImageWarns", testImageDiagnostics_missingLocalImageWarns),
    ("imageDiagnostics_containmentRefusalIsDistinctFromMissing",
     testImageDiagnostics_containmentRefusalIsDistinctFromMissing),
    ("imageDiagnostics_presentImagesYieldNoDiagnostics",
     testImageDiagnostics_presentImagesYieldNoDiagnostics),

    // Containment against the opened file, not the path (QG wave 4, item A)
    ("containedRead_inDeckImageStillLoads", testContainedRead_inDeckImageStillLoads),
    ("containedRead_symlinkSwappedAfterResolveIsRefused",
     testContainedRead_symlinkSwappedAfterResolveIsRefused),
    ("containedRead_hardlinkOutOfDeckIsRefused", testContainedRead_hardlinkOutOfDeckIsRefused),

    // Remote image timeout and response-size bounds (QG wave 4, item B)
    ("remoteImage_sessionCarriesAnExplicitTimeout", testRemoteImage_sessionCarriesAnExplicitTimeout),
    ("remoteImage_declaredLengthOverTheCapIsRefused",
     testRemoteImage_declaredLengthOverTheCapIsRefused),
    ("remoteImage_receivedBytesOverTheCapIsRefused",
     testRemoteImage_receivedBytesOverTheCapIsRefused),
    ("remoteImage_badStatusAndNonImagePayloadAreRefused",
     testRemoteImage_badStatusAndNonImagePayloadAreRefused),
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

/// Fixture 03's acceptance criterion is per-language syntax highlighting, and
/// the only thing that drives it is the fence's language hint. A slide count
/// passes with every hint stripped, so the languages themselves are the assertion.
func testFixture03_CodeBlocks() throws {
    let source = try loadFixture("03-code-blocks")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 5, "Fixture 03 slide count")

    let blocks = collectNodes(CodeBlock.self, in: doc)
    try expect(
        blocks.map { $0.language ?? "<none>" },
        equals: ["bash", "typescript", "python", "swift"],
        "Every fence must keep its language hint, in deck order"
    )
    for block in blocks {
        try expectFalse(
            block.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "The \(block.language ?? "<none>") block must carry code"
        )
    }
    // Content survived the fence, not just the hint.
    try expectTrue(blocks[0].code.contains("echo \"Hello, mdslidepal!\""))
    try expectTrue(blocks[3].code.contains("struct Slide"))
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

/// Deepest chain of nested lists under a node — 1 for a flat list, 3 for a list
/// whose items contain lists whose items contain lists.
func listNestingDepth(_ markup: Markup) -> Int {
    let isList = markup is UnorderedList || markup is OrderedList
    let deepestChild = markup.children.map { listNestingDepth($0) }.max() ?? 0
    return (isList ? 1 : 0) + deepestChild
}

/// Fixture 05 exists for the GFM extensions CommonMark lacks — tables, nested
/// lists, task lists, strikethrough, autolinks. A slide count verifies none of
/// them: the fixture would pass with every extension disabled and the whole file
/// rendered as literal text.
func testFixture05_TablesAndLists() throws {
    let source = try loadFixture("05-tables-and-lists")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    try expect(doc.slides.count, equals: 4, "Fixture 05 slide count")

    // Slide 0 — a GFM table, not a run of pipe characters.
    let tables = collectNodes(Markdown.Table.self, in: doc)
    try expect(tables.count, equals: 1, "One table in the fixture")
    let table = tables[0]
    try expect(
        Array(table.head.cells).map(\.plainText),
        equals: ["Feature", "Web MVP", "Mac MVP"],
        "Three header columns"
    )
    try expect(Array(table.body.rows).count, equals: 5, "Five body rows")
    for row in table.body.rows {
        try expect(Array(row.cells).count, equals: 3, "Every body row has three cells")
    }

    // Slide 1 — Fruit > Apples > Gala is three levels of list.
    let depth = doc.slides[1].markupChildren.map { listNestingDepth($0) }.max() ?? 0
    try expect(depth, equals: 3, "Nested lists must survive to depth 3")

    // Slide 2 — task list checkboxes, not literal "[x]" text.
    let items = doc.slides[2].markupChildren.flatMap { collectNodes(ListItem.self, in: $0) }
    try expect(items.count, equals: 5, "Five task-list items")
    try expect(
        items.filter { $0.checkbox == .checked }.count, equals: 3, "Three checked"
    )
    try expect(
        items.filter { $0.checkbox == .unchecked }.count, equals: 2, "Two unchecked"
    )
    try expectTrue(
        items.allSatisfy { $0.checkbox != nil },
        "Every item on the task-list slide is a checkbox item, not a plain bullet"
    )

    // Slide 3 — strikethrough and an autolink.
    let struck = doc.slides[3].markupChildren.flatMap { collectNodes(Strikethrough.self, in: $0) }
    try expect(struck.count, equals: 1, "One strikethrough span")
    // The node's own plainText keeps the `~~` delimiters, so read the text
    // children — that is what the renderer strikes through.
    try expect(
        collectNodes(Markdown.Text.self, in: struck[0]).map(\.string).joined(),
        equals: "strikethrough text"
    )

    // Autolinks: see fixture05_autolinksAreNotYetLinkified — the acceptance
    // criterion is currently unmet, and that test says so out loud.
}

/// GAP — fixture 05 asks for clickable autolinks; bare URLs are not linkified.
///
/// swift-markdown attaches exactly three GFM extensions to its cmark-gfm parser
/// (table, strikethrough, tasklist — CommonMarkConverter.swift) and offers no
/// option to add "autolink", so a bare `https://…` stays a Text node. Producing a
/// Link would mean post-processing text runs in our own parser, and the renderer
/// would need more than InlineContentView's `Text` concatenation to make one
/// actually clickable.
///
/// Pinned as its own named test rather than asserted inside
/// fixture05_tablesAndLists so the gap is visible in runner output instead of
/// being absent from it. Flip both halves when autolinks are implemented.
func testFixture05_AutolinksAreNotYetLinkified() throws {
    let doc = DeckParser().parse(source: try loadFixture("05-tables-and-lists"))
    let slide = doc.slides[3]

    let links = slide.markupChildren.flatMap { collectNodes(Markdown.Link.self, in: $0) }
    try expect(links.count, equals: 0, "Today a bare URL produces no Link node")

    // The URL is at least still on the slide as text — it is unlinked, not lost.
    try expectTrue(
        slide.plainText.contains("https://github.com/the-agency-ai/the-agency"),
        "The URL must survive into the rendered text"
    )

    // An explicit inline link is unaffected — the gap is autolinking, not links.
    let explicitDoc = DeckParser().parse(source: "[the agency](https://example.com/deck)")
    let explicit = explicitDoc.slides[0].markupChildren
        .flatMap { collectNodes(Markdown.Link.self, in: $0) }
    try expect(explicit.count, equals: 1, "Explicit links still parse")
    try expect(explicit[0].destination, equals: "https://example.com/deck")
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

/// Fixture 07's acceptance criterion is not "notes are extracted" — it is that
/// notes content is visible ONLY in the presenter view and "never in the main
/// slide view". Extraction without removal satisfies every assertion above and
/// still prints the speaker's private text on the screen behind them.
func testFixture07_NotesAreStrippedFromTheSlideBody() throws {
    let doc = DeckParser().parse(source: try loadFixture("07-speaker-notes"))

    // Phrases that appear only inside a Notes: block in the fixture.
    let notesOnlyPhrases = [
        0: "These are speaker notes",
        2: "Remember to explain what this code does",
        3: "Thank the audience",
    ]

    for (index, phrase) in notesOnlyPhrases.sorted(by: { $0.key < $1.key }) {
        let slide = doc.slides[index]
        let notes = try expectUnwrapped(slide.notes, "slide \(index) notes")
        try expectTrue(
            notes.contains(phrase),
            "Slide \(index) notes must carry \(quoted(phrase))"
        )
        try expectFalse(
            slide.plainText.contains(phrase),
            "Slide \(index) body must NOT contain the notes text \(quoted(phrase))"
        )
    }

    // The marker itself must not survive into the body either.
    for (index, slide) in doc.slides.enumerated() {
        try expectFalse(
            slide.plainText.lowercased().contains("notes:"),
            "Slide \(index) body still shows a Notes: marker"
        )
    }

    // …while the audience-facing content is untouched.
    try expectTrue(
        doc.slides[0].plainText.contains("This is the main content visible to the audience"),
        "Stripping notes must not take the slide's own content with it"
    )
    try expectTrue(
        doc.slides[2].plainText.contains("echo \"example code\""),
        "The code block above the notes marker stays"
    )
}

/// UNRESOLVED — ISCP dispatch #217, still open.
///
/// The fixture's stated acceptance is **4** slides ("intro, empty divider,
/// 'After the empty slide', 'Edge case — trailing ---'"). The parser produces
/// **6**, because the markdown carries 5 top-level ThematicBreaks and the
/// acceptance text counts neither the "empty slide follows" section nor the
/// trailing acceptance block as slides:
///   0: intro (code block), 1: "empty slide follows", 2: empty,
///   3: "After the empty slide", 4: "trailing ---", 5: acceptance text
///
/// This test pins what the code does today. It is NOT agreement with the code —
/// the fixture and the implementation still disagree, and until #217 is answered
/// we do not know which one is wrong. The separate name keeps the dispute
/// visible in the runner output instead of hiding it inside a green
/// `fixture08_edgeCases`; the behavioral assertions that both readings agree on
/// live in that test.
func testFixture08_SlideCountPendingDispatch217() throws {
    let doc = DeckParser().parse(source: try loadFixture("08-edge-cases"))
    try expect(
        doc.slides.count, equals: 6,
        "Parser says 6, fixture acceptance says 4 — unresolved, see dispatch #217"
    )
}

/// Parsing an empty document through the full pipeline — fixture 08's territory,
/// and the shape a brand-new file has in the editor the app is watching.
func testFixture08_EmptySourceYieldsOneUntitledSlide() throws {
    let doc = DeckParser().parse(source: "")

    try expect(doc.slides.count, equals: 1, "An empty file is one empty slide, not zero")
    try expectTrue(doc.slides[0].markupChildren.isEmpty, "…with no content on it")
    try expectNil(doc.slides[0].title)
    try expectNil(doc.slides[0].notes)
    try expectNil(doc.frontMatter)
    try expect(doc.title, equals: "Untitled", "No heading and no front matter")
    try expectTrue(
        doc.diagnostics.isEmpty,
        "An empty file is not an error: \(doc.diagnostics.map(\.message))"
    )
}

func testFixture08_EdgeCases() throws {
    let source = try loadFixture("08-edge-cases")
    let parser = DeckParser()
    let doc = parser.parse(source: source)

    // Slide count is asserted by fixture08_slideCountPendingDispatch217, which
    // carries the open dispute. Everything below holds either way.

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

/// Quotes and surrounding whitespace come off before the family is probed.
///
/// Asserted against the candidate list, not against a resolution: the previous
/// version expected `.family("Helvetica")`, which is a claim about this Mac's
/// font inventory rather than about the parser. The equivalent resolution
/// assertions live in font_stackWalkUsesTheFirstRegisteredFamily, against a
/// probe whose inventory the test controls.
func testFont_quotedNamesAreUnquoted() throws {
    try expect(
        FontResolver.candidateFamilies(in: "'Helvetica' , sans-serif"),
        equals: ["Helvetica"]
    )
    try expect(FontResolver.candidateFamilies(in: "\"Helvetica\""), equals: ["Helvetica"])
    try expect(
        FontResolver.candidateFamilies(in: "  \" Helvetica Neue \"  "),
        equals: ["Helvetica Neue"],
        "Whitespace inside the quotes comes off too"
    )
}

/// Unresolvable names are skipped and the first that resolves is chosen. Which
/// families exist is the probe's business — see
/// font_stackWalkUsesTheFirstRegisteredFamily for the ordering assertions.
func testFont_firstResolvableWins() throws {
    try expect(
        FontResolver.candidateFamilies(in: "NoSuchFont, Helvetica"),
        equals: ["NoSuchFont", "Helvetica"],
        "Both names reach the walk, in stack order"
    )
    try expect(
        FontResolver.resolution(for: "NoSuchFont, Helvetica", probe: { $0 == "Helvetica" }),
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
    // A true count: no breaks means zero. The one-unit-minimum a break-only
    // block needs is clamped by HTMLBlockView, not baked into the counter.
    try expect(HTMLText.lineBreakCount("no breaks"), equals: 0)
}

func testHTML_stripTags() throws {
    try expect(HTMLText.stripTags("<div>hello</div>"), equals: "hello")
    try expect(HTMLText.stripTags("plain"), equals: "plain")
}

/// The line-break-only pattern must stay linear. `\A(\s*<br\s*/?>\s*)+\z` gives
/// each repetition an ambiguous leading *and* trailing `\s*`, so a run of spaces
/// between two `<br>`s can be split many ways and a non-matching suffix forces
/// the engine to try all of them — exponential backtracking on attacker-supplied
/// slide HTML.
func testHTML_lineBreakOnlyIsLinearOnPathologicalInput() throws {
    let pathological = String(repeating: "<br>            ", count: 10) + "X"
    let start = Date()
    let result = HTMLText.isLineBreakOnly(pathological)
    let elapsed = Date().timeIntervalSince(start)

    try expectFalse(result, "A trailing non-break character means this is not break-only")
    try expectTrue(
        elapsed < 1.0,
        "isLineBreakOnly must not backtrack exponentially (took \(elapsed)s)"
    )

    // Behavior for valid inputs is unchanged by the rewrite.
    for spelling in ["<br>", "<BR>", "<br/>", "<br />", "  <br>  <br>  "] {
        try expectTrue(HTMLText.isLineBreakOnly(spelling), "\(spelling) is break-only")
    }
    for other in ["<br>x", "<div>", ""] {
        try expectFalse(HTMLText.isLineBreakOnly(other), "\(other) is not break-only")
    }
}

/// `<[^>]+>` stops at the first `>`, so a comment or a script body containing one
/// leaks its remainder onto the slide.
func testHTML_stripTagsRemovesCommentsScriptsAndStyles() throws {
    try expect(
        HTMLText.stripTags("<!-- draft: ARR > 2M -->"), equals: "",
        "An HTML comment must be removed through its full `-->`"
    )
    try expect(
        HTMLText.stripTags("<script>alert(1)</script>"), equals: "",
        "Script contents are not slide text"
    )
    try expect(
        HTMLText.stripTags("<style>body > p { color: red }</style>"), equals: "",
        "Style contents are not slide text"
    )
    try expect(HTMLText.stripTags("<b>bold</b>"), equals: "bold", "Ordinary tags still strip")
}

/// A function named "count" must report the count. Clamping belongs at the call
/// site that needs a minimum, not inside the measurement.
func testHTML_lineBreakCountIsATrueCount() throws {
    try expect(HTMLText.lineBreakCount(""), equals: 0)
    try expect(HTMLText.lineBreakCount("<br>"), equals: 1)
    try expect(HTMLText.lineBreakCount("<br><BR/>"), equals: 2)
}

/// URL schemes are case-insensitive. A `hasPrefix("http://")` test drops
/// `HTTP://…` into the local-path branch, where containment then refuses it.
func testImagePath_remoteSchemeIsCaseInsensitive() throws {
    for source in ["http://example.com/a.png", "HTTP://example.com/a.png"] {
        let resolved = ImagePathResolver.resolve(source: source, relativeTo: nil)
        try expectNotNil(resolved, "\(source) must be treated as remote")
        try expect(resolved?.absoluteString, equals: source)
    }
    for source in ["https://example.com/a.png", "HtTpS://example.com/a.png"] {
        let resolved = ImagePathResolver.resolve(source: source, relativeTo: nil)
        try expectNotNil(resolved, "\(source) must be treated as remote")
    }
}

// MARK: - LocalImageCache

/// Copy fixture 04's shipped PNG into a scratch directory the test can touch.
func makeScratchImage() throws -> URL {
    let fixture = try fixtureURL(named: "04-images")
    guard let source = ImagePathResolver.resolve(
        source: "./images/sample.png", relativeTo: fixture
    ) else {
        throw TestFailure(message: "Fixture image did not resolve", file: #file, line: #line)
    }
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdslidepal-imgcache-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let dest = dir.appendingPathComponent("sample.png")
    try FileManager.default.copyItem(at: source, to: dest)
    return dest
}

func testImageCache_unchangedFileReturnsTheSameInstance() throws {
    let url = try makeScratchImage()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    guard let first = LocalImageCache.image(at: url),
          let second = LocalImageCache.image(at: url) else {
        throw TestFailure(message: "Scratch image failed to decode", file: #file, line: #line)
    }
    try expectTrue(
        ObjectIdentifier(first) == ObjectIdentifier(second),
        "An unchanged file must be decoded once, not on every body evaluation"
    )
}

func testImageCache_touchedFileIsRedecoded() throws {
    let url = try makeScratchImage()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    guard let first = LocalImageCache.image(at: url) else {
        throw TestFailure(message: "Scratch image failed to decode", file: #file, line: #line)
    }
    // Live reload: the editor rewrites the file, so the mtime moves forward and
    // the cache must miss.
    try FileManager.default.setAttributes(
        [.modificationDate: Date().addingTimeInterval(120)], ofItemAtPath: url.path
    )
    guard let second = LocalImageCache.image(at: url) else {
        throw TestFailure(message: "Touched image failed to decode", file: #file, line: #line)
    }
    try expectTrue(
        ObjectIdentifier(first) != ObjectIdentifier(second),
        "A newer modification date must miss the cache"
    )
}

func testImageCache_missingAndNonImageFilesReturnNil() throws {
    try expectNil(
        LocalImageCache.image(at: URL(fileURLWithPath: "/nonexistent/nope.png")),
        "A missing file is not an image"
    )

    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdslidepal-imgcache-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    let text = dir.appendingPathComponent("notes.txt")
    try "this is not an image".write(to: text, atomically: true, encoding: .utf8)

    try expectNil(LocalImageCache.image(at: text), "A text file is not an image")
}

// MARK: - ImageBlockView sizing

/// Re-decode the default theme with a different slide padding. Theme has no
/// public memberwise init, and it is Codable, so a JSON round-trip is the
/// supported way to vary one token.
func themeWithHorizontalPadding(_ value: Int) throws -> Theme {
    let data = try JSONEncoder().encode(Theme.agencyDefault)
    guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          var padding = object["slide_padding"] as? [String: Any] else {
        throw TestFailure(message: "Theme JSON shape unexpected", file: #file, line: #line)
    }
    padding["left"] = value
    padding["right"] = value
    object["slide_padding"] = padding
    let mutated = try JSONSerialization.data(withJSONObject: object)
    return try JSONDecoder().decode(Theme.self, from: mutated)
}

/// `.resizable()` accepts the whole box a max-size frame offers, so a small
/// image was being enlarged past its native resolution.
func testImageSizing_smallImageIsNotUpscaled() throws {
    let box = CGSize(width: 1680, height: 702)
    let drawn = ImageBlockView.displaySize(intrinsic: CGSize(width: 200, height: 100), maxBox: box)
    try expect(drawn.width, equals: 200, "A 200pt-wide image must draw 200pt wide")
    try expect(drawn.height, equals: 100)
}

func testImageSizing_largeImageScalesDownPreservingAspect() throws {
    let box = CGSize(width: 1680, height: 702)
    let drawn = ImageBlockView.displaySize(intrinsic: CGSize(width: 3360, height: 1404), maxBox: box)
    try expect(drawn.width, equals: 1680)
    try expect(drawn.height, equals: 702)

    // A wide image is bounded by width, a tall one by height — aspect preserved
    // in both directions.
    let tall = ImageBlockView.displaySize(intrinsic: CGSize(width: 702, height: 1404), maxBox: box)
    try expect(tall.height, equals: 702)
    try expect(tall.width, equals: 351)
}

func testImageSizing_maxBoxDerivesFromTheme() throws {
    let box = ImageBlockView.maxImageSize(for: Theme.agencyDefault)
    let dims = Theme.agencyDefault.logicalDimensions
    let padding = Theme.agencyDefault.slidePadding
    try expect(box.width, equals: CGFloat(dims.width - padding.left - padding.right))
    try expectTrue(box.height > 0 && box.height < CGFloat(dims.height))

    // Change the theme's padding and the box must follow — no hardcoded 1680.
    let narrow = try themeWithHorizontalPadding(padding.left + 100)
    let narrowBox = ImageBlockView.maxImageSize(for: narrow)
    try expect(
        narrowBox.width, equals: box.width - 200,
        "Widening the padding by 100 a side must narrow the image box by 200"
    )
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
    // Non-nil first. Comparing two Optionals' `.description` is satisfied by
    // nil == nil, so the old version of this test passed for an initializer that
    // rejected every input it was given.
    let shorthand = try expectUnwrapped(Color(validatingHex: "#abc"), "#abc")
    let longhand = try expectUnwrapped(Color(validatingHex: "#aabbcc"), "#aabbcc")

    // #abc means #aabbcc — the two forms must produce the same color.
    try expect(shorthand.description, equals: longhand.description)

    // And the expansion is doubling, not truncation or zero-padding: a near-miss
    // longhand must NOT come out the same color.
    let nearMiss = try expectUnwrapped(Color(validatingHex: "#aabbcd"), "#aabbcd")
    try expectTrue(
        shorthand.description != nearMiss.description,
        "#abc expands to #aabbcc, so it must differ from #aabbcd"
    )
    try expectTrue(
        shorthand.description != Color(validatingHex: "#a0b0c0")?.description,
        "…and from the zero-padded reading of the same digits"
    )
}

/// Trimming has to happen before the `#` is stripped, or a leading space keeps
/// the `#` in the "hex digits" and the whole color is rejected.
func testColorHex_validatingTrimsBeforeStrippingHash() throws {
    try expectNotNil(Color(validatingHex: " #ff0000"), "leading space must be tolerated")
    try expectNotNil(Color(validatingHex: "  #abc  "), "surrounding space must be tolerated")
    try expect(
        Color(validatingHex: " #ff0000")?.description,
        equals: Color(validatingHex: "#ff0000")?.description
    )
    try expect(
        Color(validatingHex: "  #abc  ")?.description,
        equals: Color(validatingHex: "#abc")?.description
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

/// The alert binds to `errorMessage != nil`. A success that does not clear the
/// message leaves the alert stuck on screen for the rest of the session.
func testController_successfulOpenClearsPriorError() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.openFile(url: URL(fileURLWithPath: "/nonexistent/nope.md"))
        try expectNotNil(controller.errorMessage, "Failed open reports an error")

        controller.openFile(url: try fixtureURL(named: "01-minimal"))
        try expectNil(
            controller.errorMessage,
            "A successful open must clear the stale error, or the alert never dismisses"
        )
    }
}

/// A Finder launch hands the app OS-injected flags, not paths. Treating argv[1]
/// as a path unconditionally pops "No such file: -psn_0_123" on every launch.
func testController_launchIgnoresOSInjectedFlags() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.loadInitialDeck(arguments: ["app", "-psn_0_123"])
        try expectNil(
            controller.errorMessage,
            "An OS-injected flag is not a file path and must not raise an error"
        )
        try expect(
            controller.deckState.document.title, equals: "Welcome to mdslidepal",
            "A flag-only launch shows the welcome deck"
        )
    }
}

func testController_launchWithNoArgumentsShowsWelcomeDeck() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.loadInitialDeck(arguments: ["app"])
        try expectNil(controller.errorMessage)
        try expect(controller.deckState.document.title, equals: "Welcome to mdslidepal")
        try expectNil(controller.deckState.document.sourceURL)
    }
}

func testController_launchWithFileArgumentOpensIt() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let url = try fixtureURL(named: "02-multi-slide")
        controller.loadInitialDeck(arguments: ["app", url.path])
        try expectNil(controller.errorMessage)
        try expect(controller.deckState.document.sourceURL, equals: url)
    }
}

/// A bad path must report the error *and* still leave a usable document. The
/// unconditional `return` left an empty window behind the alert.
func testController_launchWithBadPathReportsAndStillShowsWelcome() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.loadInitialDeck(arguments: ["app", "/nope/x.md"])
        try expectNotNil(controller.errorMessage, "A named-but-missing file is an error")
        try expect(
            controller.deckState.document.title, equals: "Welcome to mdslidepal",
            "The welcome deck still loads — no empty window behind the alert"
        )
    }
}

/// The path exists but is not readable as markdown (a directory here). openFile
/// fails, and the unconditional `return` used to leave an empty document with no
/// welcome deck behind the alert.
func testController_launchWithUnreadablePathStillShowsWelcome() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdslidepal-launch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        controller.loadInitialDeck(arguments: ["app", dir.path])

        try expectNotNil(controller.errorMessage, "An unreadable path is an error")
        try expect(
            controller.deckState.document.title, equals: "Welcome to mdslidepal",
            "A failed open must still fall through to the welcome deck"
        )
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
        // A private center, not `.default`. The process-global one carries every
        // other observer in the runner — notably PresentationWindowManager's
        // `.startPresentation` subscription — which makes any test that posts on
        // it order-dependent.
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        controller.deckState.load(from: "# One\n\n---\n\n# Two\n\n---\n\n# Three")
        controller.installCommandHandlers()
        controller.installCommandHandlers()  // idempotent

        // A single .nextSlide post must advance exactly one slide. Duplicate
        // subscriptions would advance two and skip a slide.
        controller.deckState.firstSlide()
        center.post(name: .nextSlide, object: nil)
        try expect(
            controller.deckState.selectedSlideIndex, equals: 1,
            "One command, one handler — duplicate observers would skip a slide"
        )
    }
}

// MARK: - QG wave 2 — A. Decompression-bomb budget

/// Build a PNG that *declares* `pixels` x `pixels` in its IHDR but carries a
/// 16x16 image's worth of data, padded with a junk ancillary chunk so ImageIO
/// considers the file substantial enough to describe.
///
/// This is the shape of the real attack: a few hundred KB on disk, gigabytes
/// decoded. A genuine 30000x30000 PNG of one flat colour compresses to about
/// this size; synthesising it here avoids deflating 2.7 GB of zeroes in a test.
func makeDeclaredSizeBomb(pixels: UInt32, padBytes: Int) throws -> URL {
    func crc32(_ bytes: [UInt8]) -> UInt32 {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1) }
            table[i] = c
        }
        var c: UInt32 = 0xFFFF_FFFF
        for b in bytes { c = table[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }
    func be(_ v: UInt32) -> [UInt8] {
        [UInt8((v >> 24) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 8) & 0xFF), UInt8(v & 0xFF)]
    }
    func chunk(_ type: String, _ payload: [UInt8]) -> [UInt8] {
        let t = Array(type.utf8)
        return be(UInt32(payload.count)) + t + payload + be(crc32(t + payload))
    }

    let template = try makeScratchImage()
    defer { try? FileManager.default.removeItem(at: template.deletingLastPathComponent()) }
    var bytes = [UInt8](try Data(contentsOf: template))

    // PNG layout: 8-byte signature, then the IHDR chunk — 4 length, 4 type,
    // 13 payload (width, height, then bit depth and friends), 4 CRC.
    guard bytes.count > 33 else {
        throw TestFailure(message: "Template PNG is too small to patch", file: #file, line: #line)
    }
    var header = Array(bytes[16..<29])
    header.replaceSubrange(0..<4, with: be(pixels))
    header.replaceSubrange(4..<8, with: be(pixels))
    bytes.replaceSubrange(16..<29, with: header)
    bytes.replaceSubrange(29..<33, with: be(crc32(Array("IHDR".utf8) + header)))

    if padBytes > 0 {
        let junk = Array("padding\u{0}".utf8) + [UInt8](repeating: 0x41, count: padBytes)
        bytes.insert(contentsOf: chunk("tEXt", junk), at: bytes.count - 12)
    }

    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdslidepal-bomb-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let out = dir.appendingPathComponent("bomb.png")
    try Data(bytes).write(to: out)
    return out
}

/// A 30000x30000 image is ~3.6 GB decoded and NSImage(contentsOf:) accepts it
/// without complaint — on the main thread, inside a SwiftUI view body, from a
/// path an untrusted Markdown file chose. The header says how big it is; the
/// cache must read that and refuse before decoding anything.
func testImageBudget_pixelBombIsRefusedWithoutDecoding() throws {
    let url = try makeDeclaredSizeBomb(pixels: 30000, padBytes: 2_000_000)
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    // The dimensions are readable from the header alone.
    try expect(
        LocalImageCache.pixelDimensions(at: url), equals: CGSize(width: 30000, height: 30000),
        "ImageIO reports the declared size without decoding"
    )
    // And the file really is small — this is a bomb, not a big image.
    let bytes = try expectUnwrapped(LocalImageCache.fileByteSize(at: url), "file size")
    try expectTrue(bytes < 8 * 1024 * 1024, "The bomb is only \(bytes) bytes on disk")

    try expect(
        LocalImageCache.refusal(for: url),
        equals: .tooManyPixels(pixels: 900_000_000, limit: LocalImageCache.ImageBudget.default.maxPixels),
        "Refusal must name the pixel budget, not a decode failure"
    )

    // Decoding this file takes seconds and hundreds of MB. Refusing it must be
    // a header read — so the call has to return promptly.
    let start = Date()
    let image = LocalImageCache.image(at: url)
    let elapsed = Date().timeIntervalSince(start)
    try expectNil(image, "An over-budget image must not load")
    try expectTrue(
        elapsed < 1.0,
        "Refusal must come from the header, not from a decode attempt (took \(elapsed)s)"
    )
}

func testImageBudget_oversizedFileIsRefused() throws {
    let url = try makeScratchImage()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    let bytes = try expectUnwrapped(LocalImageCache.fileByteSize(at: url), "file size")
    let budget = LocalImageCache.ImageBudget(maxFileBytes: bytes - 1, maxPixels: .max)

    try expect(
        LocalImageCache.refusal(for: url, budget: budget),
        equals: .fileTooLarge(bytes: bytes, limit: bytes - 1)
    )
    try expectNil(
        LocalImageCache.image(at: url, budget: budget),
        "A file over the byte budget must not be read"
    )

    // The byte budget is checked before the pixel budget, and before the cache:
    // a permissive earlier load must not let a tighter caller through.
    try expectNotNil(LocalImageCache.image(at: url), "Default budget still loads it")
    try expectNil(
        LocalImageCache.image(at: url, budget: budget),
        "A cached entry must not bypass a tighter budget"
    )
}

func testImageBudget_normalImageStillLoads() throws {
    let url = try makeScratchImage()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

    try expectNil(LocalImageCache.refusal(for: url), "A 16x16 PNG is within budget")
    try expectNotNil(LocalImageCache.image(at: url), "A normal small image still loads")
    try expect(
        LocalImageCache.pixelDimensions(at: url), equals: CGSize(width: 16, height: 16)
    )

    // A pixel budget below the real image refuses it — proving the pixel path is
    // load-bearing and not just the byte path in disguise.
    let tight = LocalImageCache.ImageBudget(maxFileBytes: .max, maxPixels: 100)
    try expect(
        LocalImageCache.refusal(for: url, budget: tight),
        equals: .tooManyPixels(pixels: 256, limit: 100)
    )
    try expectNil(LocalImageCache.image(at: url, budget: tight))
}

// MARK: - QG wave 2 — B. Main window hosting

/// SwiftUI publishes `.toolbar` content to the NSWindow toolbar only when the
/// view is hosted by an NSHostingController installed as `contentViewController`.
/// With `contentView = NSHostingView(rootView:)` the toolbar — the Open button
/// and the `N / M` slide counter, the app's only slide-position indicator — has
/// nowhere to go and never appears.
func testDeckWindow_hostsViaContentViewController() throws {
    try MainActor.assumeIsolated {
        let window = DeckWindowFactory.makeMainWindow(controller: DeckController())
        let hosted = try expectUnwrapped(window.contentViewController, "contentViewController")
        try expectTrue(
            String(describing: type(of: hosted)).hasPrefix("NSHostingController"),
            "The window's content must be an NSHostingController, got \(type(of: hosted))"
        )
        try expectTrue(
            window.styleMask.contains(.titled),
            "A toolbar needs a titled window"
        )
    }
}

/// `.frame(minWidth:minHeight:)` constrains SwiftUI's layout, not the window.
/// Without `contentMinSize` the resize handles let the user drag the window down
/// to nothing and the sidebar and preview collapse into each other.
func testDeckWindow_minContentSizeConstrainsTheWindow() throws {
    try MainActor.assumeIsolated {
        let window = DeckWindowFactory.makeMainWindow(controller: DeckController())
        try expect(
            window.contentMinSize, equals: DeckWindowFactory.minContentSize,
            "The window must carry the same minimum the SwiftUI frame declares"
        )
        try expect(
            DeckWindowFactory.minContentSize, equals: CGSize(width: 800, height: 500)
        )
    }
}

/// Installing a `contentViewController` makes AppKit resize the window to the
/// controller's fitting size, which for this view is the SwiftUI minimum — the
/// app started up at 800x500 instead of the intended 1200x800. The content size
/// has to be reasserted after the controller goes in.
func testDeckWindow_opensAtTheDefaultContentSize() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        let window = DeckWindowFactory.makeMainWindow(controller: controller)
        try expect(
            window.contentRect(forFrameRect: window.frame).size,
            equals: DeckWindowFactory.defaultContentSize,
            "A fresh window opens at its default size, not shrunk to the minimum"
        )
        try expect(
            DeckWindowFactory.defaultContentSize, equals: CGSize(width: 1200, height: 800)
        )

        // NSHostingController also defaults to `sizingOptions =
        // .preferredContentSize`, which republishes the SwiftUI fitting size to
        // the window on every content change — loading the initial deck snapped
        // the real app back to its 800x500 minimum a moment after launch. That
        // resize needs an on-screen window and a real layout pass, so it is not
        // reproducible here; it was verified against the running app via the
        // accessibility API. What this test can pin is that the deck load itself
        // leaves the window alone.
        controller.deckState.load(from: "# A deck\n\nSome body text.")
        window.contentView?.layoutSubtreeIfNeeded()
        try expect(
            window.contentRect(forFrameRect: window.frame).size,
            equals: DeckWindowFactory.defaultContentSize,
            "Loading a deck must not resize the window to the SwiftUI fitting size"
        )
    }
}

// MARK: - QG wave 2 — C. Menu key equivalents

/// Main-menu key equivalents are matched in NSApplication.sendEvent, before the
/// key window's responder chain runs. A bare arrow in the Presentation menu is
/// therefore unreachable by the sidebar list, any scroll view, or any future
/// text field. Contract §10 scopes bare Arrow/Home/End to presentation mode,
/// which PresentationCoordinator's local monitor serves.
func testMenu_slideNavigationKeyEquivalentsAreModified() throws {
    try MainActor.assumeIsolated {
        for spec in PresentationMenuSpec.navigationCommands {
            try expectFalse(
                spec.modifiers.isEmpty,
                "\(spec.title) must not claim a bare key equivalent app-wide"
            )
            try expectTrue(
                spec.modifiers.contains(.command),
                "\(spec.title) should be a Command chord"
            )
            let item = spec.makeItem(action: nil, target: nil)
            try expectTrue(
                item.keyEquivalentModifierMask.contains(.command),
                "The built menu item for \(spec.title) must carry the modifier"
            )
            try expectFalse(item.keyEquivalent.isEmpty, "\(spec.title) needs a key equivalent")
        }
    }
}

func testMenu_slideNavigationUsesArrowAndHomeEndKeys() throws {
    let expected = [
        NSRightArrowFunctionKey, NSLeftArrowFunctionKey,
        NSHomeFunctionKey, NSEndFunctionKey
    ].map { String(Character(UnicodeScalar($0)!)) }
    try expect(
        PresentationMenuSpec.navigationCommands.map(\.keyEquivalent), equals: expected,
        "Next / Previous / First / Last, in menu order"
    )
}

// MARK: - QG wave 2 — D. Presentation teardown re-entrancy

/// `windowWillClose` arrives *inside* `-[NSWindow close]`. Calling
/// stopPresentation() from there fires onPresentationEnded -> closeWindows() ->
/// close() on the very window AppKit is still closing. Dropping the reference
/// first is what breaks the cycle.
func testPresentation_closingWindowIsReleasedBeforeTeardown() throws {
    try MainActor.assumeIsolated {
        let rect = NSRect(x: 0, y: 0, width: 100, height: 100)
        let audience = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        let presenter = NSWindow(contentRect: rect, styleMask: [.titled], backing: .buffered, defer: false)

        let afterPresenterCloses = PresentationWindowManager.releasingClosingWindow(
            presenter, audience: audience, presenter: presenter
        )
        try expectNil(
            afterPresenterCloses.presenter,
            "The window already inside its close cycle must not be closed again"
        )
        try expectTrue(
            afterPresenterCloses.audience === audience,
            "The other window still needs an explicit close"
        )

        let afterAudienceCloses = PresentationWindowManager.releasingClosingWindow(
            audience, audience: audience, presenter: presenter
        )
        try expectNil(afterAudienceCloses.audience)
        try expectTrue(afterAudienceCloses.presenter === presenter)

        // An unrelated window (or none at all) leaves both references intact.
        let unrelated = NSWindow(contentRect: rect, styleMask: [.titled], backing: .buffered, defer: false)
        let untouched = PresentationWindowManager.releasingClosingWindow(
            unrelated, audience: audience, presenter: presenter
        )
        try expectTrue(untouched.audience === audience && untouched.presenter === presenter)

        let none = PresentationWindowManager.releasingClosingWindow(
            nil, audience: audience, presenter: presenter
        )
        try expectTrue(none.audience === audience && none.presenter === presenter)
    }
}

// MARK: - QG wave 2 — E. Borderless audience window key eligibility

/// NSWindow returns false from canBecomeKey when the style mask lacks `.titled`,
/// so makeKeyAndOrderFront leaves the deck window holding the keyboard behind a
/// full-screen audience view. It only looks like it works because the coordinator
/// installs an application-wide event monitor.
func testPresentation_audienceWindowCanBecomeKey() throws {
    try MainActor.assumeIsolated {
        let rect = NSRect(x: 0, y: 0, width: 640, height: 360)

        // Baseline: this is what a plain borderless NSWindow does.
        let plain = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        try expectFalse(plain.canBecomeKey, "A plain borderless NSWindow cannot become key")

        let audience = PresentationWindowManager.makeAudienceWindow(contentRect: rect, screen: nil)
        try expectTrue(audience.canBecomeKey, "The audience window must be able to take the keyboard")
        try expectTrue(audience.canBecomeMain, "…and to become the main window")
        try expectFalse(
            audience.styleMask.contains(.titled),
            "It is still borderless — the subclass is what makes it keyable"
        )
    }
}

// MARK: - QG wave 2 — F. Body slide layout

func testSlide_bodyLayoutIsTopAligned() throws {
    try expect(
        SlideContentView.bodyAlignment, equals: Alignment.topLeading,
        "Body slides read from the top-left, as the file header describes"
    )
}

/// The layout assertion that actually looks at pixels: render a short body slide
/// and find the first row carrying ink. Top-aligned, it is near the top of the
/// slide; vertically centred, it sits around the middle — and an over-long slide
/// then loses its opening lines off the top, which contract §11 forbids
/// ("allow vertical scroll … but NOT paginate and NOT crop").
func testSlide_bodyContentRendersFromTheTop() throws {
    try MainActor.assumeIsolated {
        let doc = DeckParser().parse(source: "# Top heading\n\nOne short line of body text.")
        let slide = doc.slides[0]
        try expectFalse(slide.isHero, "H1 plus a paragraph is a body slide, not a hero")

        let renderer = ImageRenderer(
            content: SlideContentView(slide: slide).environment(\.theme, Theme.agencyDefault)
        )
        renderer.scale = 0.1
        guard let rendered = renderer.cgImage else {
            throw TestFailure(message: "ImageRenderer produced no image", file: #file, line: #line)
        }

        let width = rendered.width
        let height = rendered.height
        var gray = [UInt8](repeating: 0xFF, count: width * height)
        guard let context = CGContext(
            data: &gray, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw TestFailure(message: "Could not build a grayscale context", file: #file, line: #line)
        }
        context.draw(rendered, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Row 0 of a CGBitmapContext's buffer is the top of the drawn image.
        var firstInkRow: Int?
        for row in 0..<height where gray[(row * width)..<((row + 1) * width)].contains(where: { $0 < 0x80 }) {
            firstInkRow = row
            break
        }
        let inkRow = try expectUnwrapped(firstInkRow, "a rendered slide should have dark text on it")
        try expectTrue(
            inkRow < height / 3,
            "Body content must start in the top third; first ink row was \(inkRow) of \(height)"
        )
    }
}

// MARK: - QG wave 2 — G. YAML hex pre-quoting

func testMetadata_hexQuotingTable() throws {
    let cases: [(name: String, input: String, expected: String)] = [
        ("six digits", "background: #ff0000", "background: \"#ff0000\""),
        ("three-digit shorthand", "background: #fff", "background: \"#fff\""),
        ("eight-digit rgba", "background: #ff0000cc", "background: \"#ff0000cc\""),
        // Two digits is not a valid CSS colour. Quoting it anyway is the chosen
        // behaviour: the author's text survives into SlideMetadata.background,
        // where Color(validatingHex:) rejects it and the slide falls back to the
        // theme. Left unquoted it became a YAML comment and the key read nil —
        // a typo that reported nothing at all.
        ("two digits are preserved, not swallowed", "background: #ff", "background: \"#ff\""),
        ("indented key under a nested mapping",
         "layout:\n  background: #abcdef", "layout:\n  background: \"#abcdef\""),
        ("hyphenated key", "brand-color: #123456", "brand-color: \"#123456\""),
        ("already quoted is left alone",
         "background: \"#ff0000\"", "background: \"#ff0000\""),
        ("single-quoted is left alone",
         "background: '#ff0000'", "background: '#ff0000'"),
        ("trailing comment survives",
         "background: #ff0000 # brand red", "background: \"#ff0000\" # brand red"),
        ("block-sequence item", "- #ff0000", "- \"#ff0000\""),
        ("indented sequence item under a key",
         "colors:\n  - #ff0000\n  - #00ff00",
         "colors:\n  - \"#ff0000\"\n  - \"#00ff00\""),
        ("flow collection", "colors: [#ff0000, #00ff00]", "colors: [\"#ff0000\", \"#00ff00\"]"),
        ("single-element flow collection", "colors: [#fff]", "colors: [\"#fff\"]"),
        // The too-broad half of the old pattern: its `[^:\r\n#]+` key group
        // matched inside a literal block scalar and rewrote opaque text.
        ("literal block scalar is opaque",
         "caption: |\n  foo: #abc\n  bar\nbackground: #fff",
         "caption: |\n  foo: #abc\n  bar\nbackground: \"#fff\""),
        ("folded block scalar is opaque",
         "caption: >\n  foo: #abc\nbackground: #fff",
         "caption: >\n  foo: #abc\nbackground: \"#fff\""),
        ("full-line comment untouched", "# just a comment", "# just a comment"),
        ("non-hex value untouched", "transition: fade", "transition: fade"),
        ("a # mid-value is not a colour", "title: My # 1 deck", "title: My # 1 deck"),
        ("empty value untouched", "layout:", "layout:"),
        ("CRLF line endings survive",
         "background: #ff0000\r\ntransition: fade\r\n",
         "background: \"#ff0000\"\r\ntransition: fade\r\n"),
    ]

    // Collect every mismatch rather than stopping at the first: a table this
    // wide is only useful if one broken row does not hide the other nineteen.
    var mismatches: [String] = []
    for testCase in cases {
        let actual = SlideMetadataExtractor.quoteUnquotedHexValues(in: testCase.input)
        if actual != testCase.expected {
            mismatches.append(
                "\(testCase.name): expected \(quoted(testCase.expected)), got \(quoted(actual))"
            )
        }
    }
    if !mismatches.isEmpty {
        throw TestFailure(
            message: "\(mismatches.count)/\(cases.count) rows wrong:\n    - "
                + mismatches.joined(separator: "\n    - "),
            file: #file, line: #line
        )
    }
}

/// Render newlines and tabs visibly so a table mismatch is readable on one line.
private func quoted(_ string: String) -> String {
    "\"" + string
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t") + "\""
}

/// The pre-pass exists to survive Yams. Pin the end-to-end result too, so a
/// rewrite that produces plausible-looking YAML but does not parse is caught.
func testMetadata_hexQuotingRoundTripsThroughYaml() throws {
    let cases: [(source: String, expected: String)] = [
        ("background: #ff0000", "#ff0000"),
        ("background: #fff", "#fff"),
        ("background: #ff", "#ff"),
        ("background: #ff0000 # brand red", "#ff0000"),
        ("background: \"#00ff00\"", "#00ff00"),
    ]
    var mismatches: [String] = []
    for testCase in cases {
        let markdown = "<!-- slide:\n\(testCase.source)\n-->\n\n# Content"
        let doc = DeckParser().parse(source: markdown)
        let actual = doc.slides[0].metadata?.background
        if actual != testCase.expected {
            mismatches.append(
                "`\(testCase.source)` -> \(actual.map { "\"\($0)\"" } ?? "nil"), "
                    + "expected \"\(testCase.expected)\""
            )
        }
    }
    if !mismatches.isEmpty {
        throw TestFailure(
            message: "\(mismatches.count)/\(cases.count) did not survive Yams:\n    - "
                + mismatches.joined(separator: "\n    - "),
            file: #file, line: #line
        )
    }
}

// MARK: - Gap-closing wave 3 — helpers

/// Every node of a given type reachable from a markup subtree, in document order.
func collectNodes<T: Markup>(_ type: T.Type, in markup: Markup) -> [T] {
    var found: [T] = []
    if let match = markup as? T { found.append(match) }
    for child in markup.children {
        found.append(contentsOf: collectNodes(type, in: child))
    }
    return found
}

/// Every node of a given type across a whole deck, in slide then document order.
func collectNodes<T: Markup>(_ type: T.Type, in document: DeckDocument) -> [T] {
    document.slides.flatMap { slide in
        slide.markupChildren.flatMap { collectNodes(type, in: $0) }
    }
}

/// Write a scratch .md file in its own directory. The caller removes the
/// directory; returning the file keeps `deletingLastPathComponent()` correct.
func makeScratchDeck(_ contents: String, name: String = "deck.md") throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdslidepal-deck-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent(name)
    try contents.write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// A deck of `count` slides, each with a distinct H1.
func numberedDeck(_ count: Int) -> String {
    (1...count).map { "# Slide \($0)" }.joined(separator: "\n\n---\n\n")
}

// MARK: - Gap-closing wave 3 — runner registration

/// `swift test` runs nothing here (the tests are an executableTarget, and the
/// package declares no testTarget), and a test that is written but never added
/// to `allTests` is invisible in exactly the same way. Pinning the count makes a
/// dropped registration a failure instead of a silently smaller run.
///
/// When you add a test, add it to `allTests` and bump this number in the same
/// edit. That is the point: the number is a second place that has to change.
func testRunner_registrationCountIsPinned() throws {
    try expect(
        allTests.count, equals: 141,
        "allTests has changed size — add the new test's registration, then bump this pin"
    )
    // Names must be unique too: a copy-pasted registration that reuses a name
    // makes the runner output lie about which test failed.
    try expect(
        Set(allTests.map(\.0)).count, equals: allTests.count,
        "Two registrations share a name"
    )
}

// MARK: - Gap-closing wave 3 — DeckController.reload()

/// The whole point of reload: an edit that does not change the slide count must
/// leave the presenter looking at the same slide.
func testController_reloadPreservesSlidePosition() throws {
    try MainActor.assumeIsolated {
        let url = try makeScratchDeck(numberedDeck(4))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let controller = DeckController()
        controller.openFile(url: url)
        controller.deckState.selectedSlideIndex = 2

        try (numberedDeck(3) + "\n\n---\n\n# Slide 4 rewritten")
            .write(to: url, atomically: true, encoding: .utf8)
        controller.reload()

        try expectNil(controller.errorMessage, "A good reload reports no error")
        try expect(controller.deckState.document.slides.count, equals: 4)
        try expect(
            controller.deckState.selectedSlideIndex, equals: 2,
            "Same slide count — the position must survive the reload"
        )
        try expect(
            controller.deckState.document.slides[3].title, equals: "Slide 4 rewritten",
            "The reload must actually pick up the new content"
        )
    }
}

/// Deleting slides above the caret used to send the presenter back to slide 1:
/// the restore was conditional on the old index still fitting, so it simply did
/// not happen and `load`'s reset to 0 stood. Clamp to the last surviving slide.
func testController_reloadClampsPositionWhenDeckShrinks() throws {
    try MainActor.assumeIsolated {
        let url = try makeScratchDeck(numberedDeck(5))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let controller = DeckController()
        controller.openFile(url: url)
        controller.deckState.selectedSlideIndex = 4

        try numberedDeck(2).write(to: url, atomically: true, encoding: .utf8)
        controller.reload()

        try expect(controller.deckState.document.slides.count, equals: 2)
        try expect(
            controller.deckState.selectedSlideIndex, equals: 1,
            "A shrunk deck clamps to its last slide, not back to the first"
        )
        // The invariant the rest of the app depends on: the index addresses a
        // real slide, so `currentSlide` is non-nil.
        try expectNotNil(controller.deckState.currentSlide, "The selection must address a slide")
    }
}

/// The welcome deck has no file behind it. Reload must do nothing at all —
/// not clear the document, not raise an error.
func testController_reloadWithNoSourceURLIsANoOp() throws {
    try MainActor.assumeIsolated {
        let controller = DeckController()
        controller.deckState.load(from: numberedDeck(3))
        controller.deckState.selectedSlideIndex = 1
        try expectNil(controller.deckState.document.sourceURL)

        controller.reload()

        try expectNil(controller.errorMessage, "Nothing to reload is not an error")
        try expect(controller.deckState.document.slides.count, equals: 3)
        try expect(controller.deckState.selectedSlideIndex, equals: 1)
    }
}

func testController_reloadOfDeletedFileReportsError() throws {
    try MainActor.assumeIsolated {
        let url = try makeScratchDeck(numberedDeck(2))
        let dir = url.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: dir) }

        let controller = DeckController()
        controller.openFile(url: url)
        try expectNil(controller.errorMessage)

        try FileManager.default.removeItem(at: url)
        controller.reload()

        let message = try expectUnwrapped(controller.errorMessage, "reload error message")
        try expectTrue(
            message.hasPrefix("Reload failed:"),
            "A vanished file must be reported as a reload failure, got: \(message)"
        )
        try expect(
            controller.deckState.document.slides.count, equals: 2,
            "The last good document stays on screen behind the alert"
        )
    }
}

/// Replaces a test that asserted only `errorMessage == nil` and
/// `sourceURL == url` — both of which hold with the entire security-scoped
/// access transfer deleted. Open A, open B, come back to A, and prove A is
/// still readable afterwards by editing it and reloading.
func testController_reopeningAFileKeepsItReadable() throws {
    try MainActor.assumeIsolated {
        let a = try makeScratchDeck("# A one\n\n---\n\n# A two", name: "a.md")
        let b = try makeScratchDeck("# B one", name: "b.md")
        defer {
            try? FileManager.default.removeItem(at: a.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: b.deletingLastPathComponent())
        }

        let controller = DeckController()
        controller.openFile(url: a)
        controller.openFile(url: b)
        try expect(controller.deckState.document.slides.count, equals: 1, "B has one slide")

        controller.openFile(url: a)
        try expectNil(controller.errorMessage)
        try expect(controller.deckState.document.sourceURL, equals: a)
        try expect(controller.deckState.document.slides.count, equals: 2, "A has two slides")

        // The claim on A survived the round trip through B: the file still reads.
        try "# A one\n\n---\n\n# A two\n\n---\n\n# A three"
            .write(to: a, atomically: true, encoding: .utf8)
        controller.reload()

        try expectNil(controller.errorMessage, "Reload after reopening must succeed")
        try expect(
            controller.deckState.document.slides.count, equals: 3,
            "The edited content must load — a revoked claim would fail the read"
        )
        try expect(controller.deckState.document.slides[2].title, equals: "A three")
    }
}

// MARK: - Gap-closing wave 3 — the command bus

/// Only `.nextSlide` was ever posted, so five of the six commands were wired by
/// inspection alone. Each of these posts is a menu item.
///
/// A private NotificationCenter, not `.default`: the process-global center is
/// shared with every other controller and window manager alive in the runner, so
/// tests that post on it are order-dependent by construction.
func testController_navigationCommandsMoveTheSelection() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        controller.deckState.load(from: numberedDeck(3))
        controller.installCommandHandlers()

        center.post(name: .lastSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 2, "Last of three slides")

        center.post(name: .previousSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 1)

        center.post(name: .firstSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 0)

        center.post(name: .nextSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 1)

        // The ends do not run off: previous at the first slide and next at the
        // last both stay put.
        center.post(name: .firstSlide, object: nil)
        center.post(name: .previousSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 0, "No slide -1")
        center.post(name: .lastSlide, object: nil)
        center.post(name: .nextSlide, object: nil)
        try expect(controller.deckState.selectedSlideIndex, equals: 2, "No slide 4")
    }
}

func testController_reloadDeckCommandRereadsTheFile() throws {
    try MainActor.assumeIsolated {
        let url = try makeScratchDeck(numberedDeck(2))
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        controller.installCommandHandlers()
        controller.openFile(url: url)

        try numberedDeck(4).write(to: url, atomically: true, encoding: .utf8)
        center.post(name: .reloadDeck, object: nil)

        try expect(
            controller.deckState.document.slides.count, equals: 4,
            "File → Reload must go through the controller's reload"
        )
    }
}

/// `.exportPDF` reaches `presentExportPanel()`, which asks its destination
/// provider where to write and then exports there. Substituting the provider is
/// what makes the command testable at all — the real one puts an NSSavePanel on
/// screen and waits for a human.
func testController_exportPDFCommandWritesAPDF() throws {
    try MainActor.assumeIsolated {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mdslidepal-export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        controller.deckState.load(from: "# Export me\n\n---\n\n# Second slide")
        controller.installCommandHandlers()

        var suggestedName: String?
        var destination: URL?
        controller.exportDestinationProvider = { name, completion in
            suggestedName = name
            let url = dir.appendingPathComponent("out.pdf")
            destination = url
            completion(url)
        }

        center.post(name: .exportPDF, object: nil)

        try expect(
            suggestedName, equals: "Export me.pdf",
            "The panel is seeded with the deck title"
        )
        let out = try expectUnwrapped(destination, "export destination")
        try expectNil(controller.errorMessage, "A good export reports no error")
        try expectTrue(
            FileManager.default.fileExists(atPath: out.path),
            "The .exportPDF command must actually produce the file"
        )
        let pdf = try expectUnwrapped(PDFDocument(url: out), "the written file as a PDF")
        try expect(pdf.pageCount, equals: 2, "One page per slide")

        // Cancelling writes nothing and reports nothing.
        let cancelled = dir.appendingPathComponent("cancelled.pdf")
        controller.exportDestinationProvider = { _, completion in completion(nil) }
        center.post(name: .exportPDF, object: nil)
        try expectFalse(FileManager.default.fileExists(atPath: cancelled.path))
        try expectNil(controller.errorMessage, "Cancelling is not an error")
    }
}

/// Pins the invariant DeckController's own comment states: it deliberately does
/// NOT subscribe to `.startPresentation`, because starting the coordinator
/// without opening windows leaves it presenting nothing while its key monitor
/// eats Escape. PresentationWindowManager owns that command.
func testController_doesNotHandleStartPresentation() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        controller.installCommandHandlers()

        center.post(name: .startPresentation, object: nil)

        try expectFalse(
            controller.presentation.isPresenting,
            "Handling .startPresentation here half-starts presentation mode"
        )
    }
}

// MARK: - Gap-closing wave 3 — PresentationWindowManager

/// The manager is the only subscriber to `.startPresentation`, and the command
/// has to reach the coordinator or the Present menu item does nothing.
func testWindowManager_startPresentationCommandStartsTheCoordinator() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        let manager = PresentationWindowManager(controller: controller, notificationCenter: center)
        defer { manager.stop() }

        try expectFalse(controller.presentation.isPresenting)

        center.post(name: .startPresentation, object: nil)

        try expectTrue(
            controller.presentation.isPresenting,
            "Present must start the coordinator"
        )
        try expectTrue(manager.isShowingWindows, "…and put the audience window up")
    }
}

/// Teardown hangs off the coordinator, not off `stop()`, so that Escape and the
/// presenter's End button — which call the coordinator directly — close the
/// windows too. If the callback is not installed, Escape leaves them on screen.
func testWindowManager_installsTheCoordinatorTeardownCallback() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        let manager = PresentationWindowManager(controller: controller, notificationCenter: center)
        defer { manager.stop() }

        try expectNotNil(
            controller.presentation.onPresentationEnded,
            "The manager must hook the coordinator's teardown"
        )

        manager.start()
        try expectTrue(manager.isShowingWindows)

        // The Escape path: the coordinator is stopped directly, and the windows
        // must come down anyway.
        controller.presentation.stopPresentation()
        try expectFalse(
            manager.isShowingWindows,
            "Escape must tear the windows down through the teardown callback"
        )
    }
}

/// start() guards on `isShowingWindows`, so a second Present is a no-op and one
/// stop() is enough to leave both halves of the state off. A missing guard would
/// open a second audience window that the single stop never closes.
func testWindowManager_doubleStartThenOneStopEndsPresentation() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        let manager = PresentationWindowManager(controller: controller, notificationCenter: center)
        defer { manager.stop() }

        manager.start()
        manager.start()
        manager.stop()

        try expectFalse(manager.isShowingWindows, "No windows left on screen")
        try expectFalse(controller.presentation.isPresenting, "…and not still presenting")
    }
}

func testWindowManager_stopOnAFreshManagerIsSafe() throws {
    try MainActor.assumeIsolated {
        let center = NotificationCenter()
        let controller = DeckController(notificationCenter: center)
        let manager = PresentationWindowManager(controller: controller, notificationCenter: center)

        manager.stop()
        manager.stop()

        try expectFalse(manager.isShowingWindows)
        try expectFalse(controller.presentation.isPresenting)
    }
}

// MARK: - Gap-closing wave 3 — slide background fallback

/// `slideBackground` was a private computed property on a SwiftUI view: nothing
/// could reach it, so swapping `Color(validatingHex:)` back for `Color(hex:)` —
/// which paints a typo'd background magenta — broke no test.
func testSlide_invalidBackgroundFallsBackToTheTheme() throws {
    let theme = Theme.agencyDefault
    let themeBackground = Color(hex: theme.colors.background).description
    let magenta = Color(red: 1.0, green: 0.0, blue: 1.0).description

    for bad in ["not-a-color", "#ff", "", "#gggggg"] {
        let metadata = SlideMetadata(background: bad)
        let resolved = SlideContentView.background(for: metadata, theme: theme).description
        try expect(
            resolved, equals: themeBackground,
            "background: \(quoted(bad)) must fall back to the theme"
        )
        try expectTrue(
            resolved != magenta,
            "…and must not be the magenta debug color Color(hex:) returns"
        )
    }

    // Absent metadata is the ordinary case and lands on the theme too.
    try expect(
        SlideContentView.background(for: nil, theme: theme).description,
        equals: themeBackground
    )

    // And a valid value is honored, so the fallback is not swallowing everything.
    try expect(
        SlideContentView.background(for: SlideMetadata(background: "#ff0000"), theme: theme)
            .description,
        equals: Color(red: 1.0, green: 0.0, blue: 0.0).description,
        "A parseable background must be used"
    )
    try expectTrue(
        SlideContentView.background(for: SlideMetadata(background: "#ff0000"), theme: theme)
            .description != themeBackground,
        "…and must differ from the theme background"
    )
}

// MARK: - Gap-closing wave 3 — FontResolver parsing, independent of host fonts

/// The candidate list is pure string work. Testing it separately is what lets
/// the resolution tests stop depending on which fonts this Mac happens to have.
func testFont_candidateListStripsQuotesGenericsAndBlanks() throws {
    try expect(
        FontResolver.candidateFamilies(in: "'Helvetica Neue' , \"SF Pro\", sans-serif"),
        equals: ["Helvetica Neue", "SF Pro"],
        "Quotes and padding come off; the generic is dropped"
    )
    try expect(FontResolver.candidateFamilies(in: ",, ,"), equals: [])
    try expect(FontResolver.candidateFamilies(in: "serif, monospace, cursive, fantasy"), equals: [])
    try expect(
        FontResolver.candidateFamilies(in: "system-ui, -apple-system"),
        equals: ["system-ui", "-apple-system"],
        "System tokens are candidates — the walk decides what they mean"
    )
    try expect(
        FontResolver.candidateFamilies(in: "Iowan Old Style"), equals: ["Iowan Old Style"],
        "Case and internal spaces are preserved"
    )
}

/// The stack walk, pinned against a known inventory instead of the host's.
func testFont_stackWalkUsesTheFirstRegisteredFamily() throws {
    let installed: Set<String> = ["Ledger Sans", "Fallback Face"]
    let probe: (String) -> Bool = { installed.contains($0) }

    try expect(
        FontResolver.resolution(for: "NoSuchFont, Ledger Sans", probe: probe),
        equals: .family("Ledger Sans"),
        "An unresolvable name is skipped and the next one wins"
    )
    try expect(
        FontResolver.resolution(for: "'Ledger Sans', Fallback Face", probe: probe),
        equals: .family("Ledger Sans"),
        "Quotes must be stripped before the family is probed"
    )
    try expect(
        FontResolver.resolution(for: "\"Ledger Sans\"", probe: probe),
        equals: .family("Ledger Sans")
    )
    try expect(
        FontResolver.resolution(for: "Nope, AlsoNope", probe: probe), equals: .system,
        "Nothing resolves — system font"
    )
    // A system token short-circuits before anything is probed, even when a
    // registered family follows it.
    var probed: [String] = []
    try expect(
        FontResolver.resolution(for: "system-ui, Ledger Sans", probe: {
            probed.append($0)
            return installed.contains($0)
        }),
        equals: .system
    )
    try expect(probed, equals: [], "A system token must not reach the font probe")
}

/// Entirely uncovered before: family names carry spaces ("Helvetica Neue"),
/// PostScript names do not ("HelveticaNeue"), and this retry is what lets a theme
/// that names the display family resolve at all.
///
/// Note the reach of the rule, which the source comment overstated with an
/// "SF Mono" → "SFMono-Regular" example: removing spaces cannot add a style
/// suffix, so it only recovers PostScript names that ARE the despaced family.
func testFont_postScriptRetryDropsSpaces() throws {
    let installed: Set<String> = ["HelveticaNeue"]
    let probe: (String) -> Bool = { installed.contains($0) }

    try expect(
        FontResolver.resolution(for: "Helvetica Neue", probe: probe),
        equals: .family("HelveticaNeue"),
        "The despaced PostScript name is tried before giving up"
    )
    // The retry only fires when despacing changes the name — a spaceless name
    // that failed is not probed twice.
    var probeCount = 0
    try expect(
        FontResolver.resolution(for: "Nope", probe: { _ in probeCount += 1; return false }),
        equals: .system
    )
    try expect(probeCount, equals: 1, "A name with no spaces is probed exactly once")

    // And the retry does not invent a family: if neither form is registered the
    // stack falls through to the next candidate.
    try expect(
        FontResolver.resolution(for: "No Such Face, Helvetica Neue", probe: probe),
        equals: .family("HelveticaNeue")
    )
    // Despacing cannot conjure a style suffix — "SF Mono" reaches "SFMono", and
    // nothing further.
    var seen: [String] = []
    try expect(
        FontResolver.resolution(for: "SF Mono", probe: { seen.append($0); return false }),
        equals: .system
    )
    try expect(seen, equals: ["SF Mono", "SFMono"], "Exactly two forms are probed")
}

// MARK: - Gap-closing wave 3 — isHero boundaries

/// A single H2 is the "section title" cover shape; `first.level <= 2` admits it.
func testHero_singleH2IsHero() throws {
    let doc = DeckParser().parse(source: "## Part Two")
    try expectTrue(doc.slides[0].isHero, "A lone H2 is a cover slide")
}

/// The rule is about the FIRST heading, not the largest: `### Section` followed
/// by `# Title` is a content slide even though an H1 is present.
func testHero_firstHeadingBelowH2IsNotHero() throws {
    let doc = DeckParser().parse(source: "### Section\n\n# Title")
    try expectFalse(
        doc.slides[0].isHero,
        "The first heading is H3, so this is not a cover slide"
    )
    // Order is what decides it — the same two headings the other way round are.
    let flipped = DeckParser().parse(source: "# Title\n\n### Section")
    try expectTrue(flipped.slides[0].isHero, "H1 then H3 is a title plus subtitle")
}

func testHero_zeroHeadingsIsNotHero() throws {
    try expectFalse(
        DeckParser().parse(source: "Just a paragraph.").slides[0].isHero,
        "No heading, no cover slide"
    )
    // An empty slide (the `---\n\n---` divider) has no headings either.
    let empty = DeckParser().parse(source: "# A\n\n---\n\n---\n\n# B")
    try expectTrue(empty.slides[1].markupChildren.isEmpty, "Slide 1 is the empty divider")
    try expectFalse(empty.slides[1].isHero, "An empty slide is not a hero slide")
}

/// Two headings is a title plus subtitle; three is an agenda.
func testHero_threeHeadingsIsNotHero() throws {
    try expectFalse(
        DeckParser().parse(source: "# Title\n\n## One\n\n## Two").slides[0].isHero,
        "Three headings is a content slide"
    )
    try expectTrue(
        DeckParser().parse(source: "# Title\n\n## One").slides[0].isHero,
        "Two is still a cover"
    )
}

// MARK: - QG wave 4 — C. Contract §11 image diagnostics

/// A scratch directory the test owns; caller removes it.
func makeScratchDir(_ tag: String) throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdslidepal-\(tag)-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

/// The PNG that ships with fixture 04 — a real, small, decodable image.
func sampleImageURL() throws -> URL {
    let fixture = try fixtureURL(named: "04-images")
    guard let url = ImagePathResolver.resolve(
        source: "./images/sample.png", relativeTo: fixture
    ) else {
        throw TestFailure(message: "Fixture image did not resolve", file: #file, line: #line)
    }
    return url
}

/// Write `markdown` as deck.md inside a fresh directory and return the deck dir.
func makeImageDeck(_ markdown: String, tag: String) throws -> URL {
    let dir = try makeScratchDir(tag)
    try markdown.write(
        to: dir.appendingPathComponent("deck.md"), atomically: true, encoding: .utf8
    )
    return dir
}

/// Load a deck from disk through the production path and hand back its diagnostics.
func diagnostics(loadingDeckIn dir: URL) throws -> [Diagnostic] {
    try MainActor.assumeIsolated {
        let state = DeckState()
        try state.load(from: dir.appendingPathComponent("deck.md"))
        return state.document.diagnostics
    }
}

/// Contract §11: "Missing local image → render placeholder box with alt text; **warn**".
/// The placeholder renders; the warning was never produced.
func testImageDiagnostics_missingLocalImageWarns() throws {
    let dir = try makeImageDeck(
        "# Slide\n\n![a missing picture](./images/nope.png)\n", tag: "imgdiag-missing"
    )
    defer { try? FileManager.default.removeItem(at: dir) }

    let diags = try diagnostics(loadingDeckIn: dir)
    try expect(diags.count, equals: 1, "One missing image, one warning: \(diags.map(\.message))")
    let diag = try expectUnwrapped(diags.first, "diagnostic")
    try expect(diag.severity, equals: .warning, "A missing image warns, it does not error")
    try expectTrue(
        diag.message.contains("nope.png"),
        "The warning must name the path that is missing: \(quoted(diag.message))"
    )
    try expect(diag.slideIndex, equals: 0, "…and the slide it is on")
}

/// Contract §11 line 300 is a different error class from line 295: a refusal is a
/// security decision, a missing file is a typo. Collapsing both into `nil` inside
/// `resolve()` made them indistinguishable to every caller.
func testImageDiagnostics_containmentRefusalIsDistinctFromMissing() throws {
    let dir = try makeImageDeck(
        "# Slide\n\n![escaping](../outside-the-deck.png)\n", tag: "imgdiag-escape"
    )
    defer { try? FileManager.default.removeItem(at: dir) }

    let refusals = try diagnostics(loadingDeckIn: dir)
    try expect(refusals.count, equals: 1, "One refusal: \(refusals.map(\.message))")
    let refusal = try expectUnwrapped(refusals.first, "refusal diagnostic")
    try expect(refusal.severity, equals: .warning)
    try expectTrue(
        refusal.message.lowercased().contains("outside")
            || refusal.message.lowercased().contains("refus"),
        "A containment refusal must say so: \(quoted(refusal.message))"
    )

    // The distinguishing assertion: the same deck with a missing-but-legal path
    // must not produce the same message.
    let missingDir = try makeImageDeck(
        "# Slide\n\n![missing](./nope.png)\n", tag: "imgdiag-escape-control"
    )
    defer { try? FileManager.default.removeItem(at: missingDir) }
    let missing = try expectUnwrapped(
        try diagnostics(loadingDeckIn: missingDir).first, "missing-file diagnostic"
    )
    try expectTrue(
        refusal.message != missing.message,
        "A refusal and a typo must not read the same: \(quoted(missing.message))"
    )
}

/// The negative case — the pass must be silent when every image is there, or the
/// diagnostics banner becomes noise the presenter learns to ignore.
func testImageDiagnostics_presentImagesYieldNoDiagnostics() throws {
    let dir = try makeImageDeck("# Slide\n\n![present](./sample.png)\n", tag: "imgdiag-clean")
    defer { try? FileManager.default.removeItem(at: dir) }
    try FileManager.default.copyItem(
        at: try sampleImageURL(), to: dir.appendingPathComponent("sample.png")
    )

    let diags = try diagnostics(loadingDeckIn: dir)
    try expectTrue(diags.isEmpty, "A clean deck must warn about nothing: \(diags.map(\.message))")

    // Remote images are not probed at parse time — no network at load — so they
    // must not be reported as missing either.
    let remoteDir = try makeImageDeck(
        "# Slide\n\n![remote](https://example.com/a.png)\n", tag: "imgdiag-remote"
    )
    defer { try? FileManager.default.removeItem(at: remoteDir) }
    try expectTrue(
        try diagnostics(loadingDeckIn: remoteDir).isEmpty,
        "A remote URL is not a missing local file"
    )
}

// MARK: - QG wave 4 — A. TOCTOU and hardlink containment

/// A deck directory and an out-of-deck directory under one scratch root, plus a
/// resolved image URL the deck legitimately points at.
struct ContainmentScratch {
    let root: URL
    let deck: URL
    let outside: URL
    /// The deck's markdown file — the base every image resolves against.
    var markdown: URL { deck.appendingPathComponent("deck.md") }
}

func makeContainmentScratch(_ tag: String) throws -> ContainmentScratch {
    let root = try makeScratchDir(tag)
    let deck = root.appendingPathComponent("deck")
    let outside = root.appendingPathComponent("outside")
    for dir in [deck, outside] {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    try "# Slide\n\n![i](./img.png)\n".write(
        to: deck.appendingPathComponent("deck.md"), atomically: true, encoding: .utf8
    )
    return ContainmentScratch(root: root, deck: deck, outside: outside)
}

/// The contained read is what the cache and the view go through, so the ordinary
/// case has to keep working — a refusal that refuses everything is not a fix.
func testContainedRead_inDeckImageStillLoads() throws {
    let scratch = try makeContainmentScratch("contained-ok")
    defer { try? FileManager.default.removeItem(at: scratch.root) }
    try FileManager.default.copyItem(
        at: try sampleImageURL(), to: scratch.deck.appendingPathComponent("img.png")
    )

    let resolved = try expectUnwrapped(
        ImagePathResolver.resolve(source: "./img.png", relativeTo: scratch.markdown),
        "resolved in-deck image"
    )

    switch ImagePathResolver.readContained(at: resolved, in: scratch.deck) {
    case .success(let data):
        try expectTrue(data.count > 0, "A contained image reads its bytes")
        try expect(
            data, equals: try Data(contentsOf: try sampleImageURL()),
            "…and they are the file's own bytes"
        )
    case .failure(let why):
        throw TestFailure(
            message: "A contained image must load, got \(why)", file: #file, line: #line
        )
    }

    try expectNotNil(
        LocalImageCache.image(at: resolved, containedIn: scratch.deck),
        "The cache must still decode a normal in-deck image"
    )
}

/// TOCTOU: `resolve()` symlink-resolves and containment-checks a *path*, then
/// hands it to a reader that opens that path by name some time later. Between the
/// two, the entry can become a symlink pointing anywhere. Containment therefore
/// has to be re-established against the OPENED file (its `F_GETPATH`), not
/// against a name.
func testContainedRead_symlinkSwappedAfterResolveIsRefused() throws {
    let scratch = try makeContainmentScratch("contained-toctou")
    defer { try? FileManager.default.removeItem(at: scratch.root) }

    let inDeck = scratch.deck.appendingPathComponent("img.png")
    let secret = scratch.outside.appendingPathComponent("secret.png")
    try FileManager.default.copyItem(at: try sampleImageURL(), to: inDeck)
    try FileManager.default.copyItem(at: try sampleImageURL(), to: secret)
    // Distinguish the two files by content while keeping both decodable PNGs:
    // trailing bytes after IEND are ignored by ImageIO.
    try (Data(contentsOf: secret) + Data("SECRET".utf8)).write(to: secret)

    // Time of check.
    let resolved = try expectUnwrapped(
        ImagePathResolver.resolve(source: "./img.png", relativeTo: scratch.markdown),
        "resolved in-deck image"
    )

    // …and the swap, before time of use.
    try FileManager.default.removeItem(at: inDeck)
    try FileManager.default.createSymbolicLink(at: inDeck, withDestinationURL: secret)

    // The hole this closes is real: opening the checked path by name now yields
    // the out-of-deck file's bytes.
    try expect(
        try Data(contentsOf: resolved), equals: try Data(contentsOf: secret),
        "Precondition: reading the resolved path by name follows the swapped symlink"
    )

    switch ImagePathResolver.readContained(at: resolved, in: scratch.deck) {
    case .success:
        throw TestFailure(
            message: "A symlink swapped to an out-of-deck target must be refused",
            file: #file, line: #line
        )
    case .failure(let why):
        guard case .escapedContainment = why else {
            throw TestFailure(
                message: "Expected .escapedContainment, got \(why)", file: #file, line: #line
            )
        }
    }

    try expectNil(
        LocalImageCache.image(at: resolved, containedIn: scratch.deck),
        "The cache must not decode a file the containment check refused"
    )
}

/// A hardlink inside the deck pointing at a file elsewhere passes every
/// path-based test there is — the link IS in the deck, and it is not a symlink,
/// so `F_GETPATH` can legitimately report the in-deck name. The only honest
/// signal is the link count: a deck asset with more than one name cannot be
/// proven to live only inside the deck.
func testContainedRead_hardlinkOutOfDeckIsRefused() throws {
    let scratch = try makeContainmentScratch("contained-hardlink")
    defer { try? FileManager.default.removeItem(at: scratch.root) }

    let secret = scratch.outside.appendingPathComponent("secret.png")
    try FileManager.default.copyItem(at: try sampleImageURL(), to: secret)
    let inDeck = scratch.deck.appendingPathComponent("img.png")
    try FileManager.default.linkItem(at: secret, to: inDeck)

    let resolved = try expectUnwrapped(
        ImagePathResolver.resolve(source: "./img.png", relativeTo: scratch.markdown),
        "a hardlink resolves to an in-deck path — that is the bypass"
    )
    try expectTrue(
        ImagePathResolver.isContained(resolved, in: scratch.deck.resolvingSymlinksInPath()),
        "Precondition: path-based containment accepts the hardlink"
    )

    switch ImagePathResolver.readContained(at: resolved, in: scratch.deck) {
    case .success:
        throw TestFailure(
            message: "A multiply-linked deck asset must be refused",
            file: #file, line: #line
        )
    case .failure(let why):
        guard case .multiplyLinked = why else {
            throw TestFailure(
                message: "Expected .multiplyLinked, got \(why)", file: #file, line: #line
            )
        }
    }

    try expectNil(
        LocalImageCache.image(at: resolved, containedIn: scratch.deck),
        "The cache must refuse it too"
    )
}

// MARK: - QG wave 4 — B. Remote image bounds

/// Contract §5 line 219 requires remote images to load. The defect was not that
/// they load — it is that `AsyncImage` loads them on the shared session with the
/// default 60-second request timeout and no ceiling on the response, so one slow
/// or enormous URL stalls a slide mid-talk. The session must carry an explicit,
/// presentation-sized timeout.
func testRemoteImage_sessionCarriesAnExplicitTimeout() throws {
    let bounds = RemoteImageBounds.default
    let session = RemoteImageLoader.makeSession(bounds: bounds)

    try expect(
        session.configuration.timeoutIntervalForRequest, equals: bounds.timeout,
        "The configured timeout must be the one the bounds declare"
    )
    try expectTrue(
        bounds.timeout < URLSessionConfiguration.default.timeoutIntervalForRequest,
        "A presenter cannot wait out the 60s default mid-slide"
    )
    try expectTrue(bounds.timeout > 0, "Zero is not a timeout")

    // A custom bound must be honoured too — otherwise the default just happens
    // to be right and the plumbing is untested.
    let tight = RemoteImageBounds(timeout: 2, maxResponseBytes: 1024)
    try expect(
        RemoteImageLoader.makeSession(bounds: tight).configuration.timeoutIntervalForRequest,
        equals: 2
    )
}

/// A `Content-Length` above the cap is refused before a byte of the body is read.
func testRemoteImage_declaredLengthOverTheCapIsRefused() throws {
    let bounds = RemoteImageBounds(timeout: 5, maxResponseBytes: 1000)

    try expectNil(
        RemoteImageLoader.refusal(forDeclaredLength: 1000, bounds: bounds),
        "Exactly the limit is allowed"
    )
    try expect(
        RemoteImageLoader.refusal(forDeclaredLength: 1001, bounds: bounds),
        equals: .tooLarge(bytes: 1001, limit: 1000)
    )
    try expectNil(
        RemoteImageLoader.refusal(forDeclaredLength: nil, bounds: bounds),
        "An absent Content-Length is not a refusal — the stream cap catches it"
    )
    try expectNil(
        RemoteImageLoader.refusal(forDeclaredLength: -1, bounds: bounds),
        "URLResponse reports unknown length as -1, which is also not a refusal"
    )
}

/// …and a server that lies about (or omits) the length is stopped by the count of
/// bytes actually received, which is the bound that cannot be spoofed.
func testRemoteImage_receivedBytesOverTheCapIsRefused() throws {
    let bounds = RemoteImageBounds(timeout: 5, maxResponseBytes: 1000)

    try expectNil(RemoteImageLoader.refusal(forReceivedByteCount: 999, bounds: bounds))
    try expectNil(RemoteImageLoader.refusal(forReceivedByteCount: 1000, bounds: bounds))
    try expect(
        RemoteImageLoader.refusal(forReceivedByteCount: 1001, bounds: bounds),
        equals: .tooLarge(bytes: 1001, limit: 1000)
    )

    // The default cap is a real number, not Int.max wearing a hat.
    try expectTrue(
        RemoteImageBounds.default.maxResponseBytes > 0
            && RemoteImageBounds.default.maxResponseBytes < Int.max,
        "The default response cap must actually bound something"
    )
}

/// The remaining two ways a fetch fails that are decidable without a network:
/// a non-2xx status, and a body that is not an image.
func testRemoteImage_badStatusAndNonImagePayloadAreRefused() throws {
    try expectNil(RemoteImageLoader.refusal(forStatusCode: 200))
    try expectNil(RemoteImageLoader.refusal(forStatusCode: 204))
    try expect(RemoteImageLoader.refusal(forStatusCode: 404), equals: .httpStatus(404))
    try expect(RemoteImageLoader.refusal(forStatusCode: 500), equals: .httpStatus(500))

    try expectNil(
        RemoteImageLoader.decode(Data("<html>not an image</html>".utf8)),
        "HTML is not an image — the placeholder is the right answer"
    )
    try expectNotNil(
        RemoteImageLoader.decode(try Data(contentsOf: try sampleImageURL())),
        "A real PNG decodes"
    )
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
