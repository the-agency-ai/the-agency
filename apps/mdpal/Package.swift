// swift-tools-version: 6.0
// What Problem: Markdown Pal needs a Swift package manifest that defines
// the engine library and CLI executable as separate targets, with proper
// dependency management for Markdown parsing, CLI argument parsing, and YAML.
//
// How & Why: Two targets — MarkdownPalEngine (library) and mdpal (executable).
// The engine is a library so the test target can import it directly. The CLI
// links the engine and adds ArgumentParser for command-line interface.
// swift-markdown for AST parsing, Yams for YAML metadata, ArgumentParser for CLI.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import PackageDescription

let package = Package(
    name: "MarkdownPal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MarkdownPalEngine",
            targets: ["MarkdownPalEngine"]
        ),
        .executable(
            name: "mdpal",
            targets: ["mdpal"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "MarkdownPalEngine",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .executableTarget(
            name: "mdpal",
            dependencies: [
                "MarkdownPalEngine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "MarkdownPalEngineTests",
            dependencies: [
                "MarkdownPalEngine",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
        // mdpalCLITests — will be added when CLI command tests exist
    ]
)
