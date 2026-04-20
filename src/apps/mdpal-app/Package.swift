// swift-tools-version: 5.9

// What Problem: We need a macOS native SwiftUI app for section-oriented
// Markdown review. This is the app package — independent from the engine.
// The app communicates with the engine exclusively via CLI commands (JSON)
// and ISCP dispatches. No direct library linking.
//
// How & Why: Swift Package Manager for the app scaffold. SPM over Xcode
// project because it's portable, version-controllable, and builds from
// the command line. The app uses DocumentGroup with ReferenceFileDocument
// for SwiftUI document lifecycle. Phase 1 uses mock data while the real
// CLI is being built by mdpal-cli.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import PackageDescription

let package = Package(
    name: "MarkdownPalApp",
    platforms: [
        .macOS(.v14)  // Sonoma — per PVR decision
    ],
    products: [
        .library(
            name: "MarkdownPalAppLib",
            targets: ["MarkdownPalAppLib"]
        )
    ],
    targets: [
        // Main app executable
        .executableTarget(
            name: "MarkdownPalApp",
            dependencies: ["MarkdownPalAppLib"],
            path: "Sources/MarkdownPalApp",
            exclude: ["Models", "Views", "Services"],
            sources: ["App.swift"]
        ),
        // App library — models, views, services (testable)
        .target(
            name: "MarkdownPalAppLib",
            path: "Sources/MarkdownPalApp",
            exclude: ["App.swift"],
            sources: ["Models", "Views", "Services"]
        ),
        // Test runner (executable — XCTest not available without full Xcode)
        .executableTarget(
            name: "MarkdownPalAppTests",
            dependencies: ["MarkdownPalAppLib"],
            path: "Tests/MarkdownPalAppTests"
        )
    ]
)
