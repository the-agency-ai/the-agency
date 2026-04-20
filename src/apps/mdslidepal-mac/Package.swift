// swift-tools-version: 5.9

// What Problem: We need a native macOS slide presentation app that renders
// markdown files as slide decks. This is the SPM package definition for
// mdslidepal-mac — a SwiftUI-first app with AppKit interop for multi-display
// presenter mode.
//
// How & Why: SPM over Xcode project for portability and CLI builds. Two targets:
// a library (testable) and an executable (the app). Dependencies locked per
// contract v1.3: swift-markdown for parsing, HighlightSwift for syntax
// highlighting, Yams for YAML front-matter and per-slide metadata.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1 scaffold

import PackageDescription

let package = Package(
    name: "MdSlidepal",
    platforms: [
        .macOS(.v14)  // Sonoma — per contract §mac
    ],
    products: [
        .library(
            name: "MdSlidepalLib",
            targets: ["MdSlidepalLib"]
        )
    ],
    dependencies: [
        // Markdown parser — Apple's cmark-gfm-backed AST parser (contract §1)
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0"),
        // Syntax highlighter — SwiftUI-native (contract §6, §mac)
        .package(url: "https://github.com/appstefan/HighlightSwift.git", from: "1.0.0"),
        // YAML parser — for front-matter and per-slide metadata (contract §1, §3)
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        // Main app executable
        .executableTarget(
            name: "MdSlidepal",
            dependencies: ["MdSlidepalLib"],
            path: "Sources/MdSlidepal/App"
        ),
        // App library — models, parser, theme, views, services (testable)
        .target(
            name: "MdSlidepalLib",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "HighlightSwift", package: "HighlightSwift"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/MdSlidepalLib",
            resources: [
                .copy("Resources/Themes")
            ]
        ),
        // Tests — executable target (custom runner, no XCTest dependency)
        .executableTarget(
            name: "MdSlidepalTests",
            dependencies: ["MdSlidepalLib"],
            path: "Tests/MdSlidepalTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
