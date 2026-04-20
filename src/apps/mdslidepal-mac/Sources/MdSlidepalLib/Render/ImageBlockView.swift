// What Problem: Render markdown images (![alt](path)) as SwiftUI views.
// Local paths resolve relative to the source .md file. Remote URLs load
// via AsyncImage. Missing images show a placeholder with alt text per
// contract §11.
//
// How & Why: Separate view for block-level images (as opposed to inline
// image references which show alt text only). Handles local file:// paths,
// remote http/https via AsyncImage, path traversal refusal (contract §11),
// and graceful fallback to placeholder on any error.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5

import SwiftUI
import Markdown

/// Renders a block-level image from markdown.
struct ImageBlockView: View {
    let image: Markdown.Image
    let sourceURL: URL?
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let resolvedURL = resolveImageURL() {
                if resolvedURL.scheme == "http" || resolvedURL.scheme == "https" {
                    // Remote image
                    AsyncImage(url: resolvedURL) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 600)
                        case .failure:
                            placeholderView(message: "Failed to load remote image")
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        @unknown default:
                            placeholderView(message: "Unknown image state")
                        }
                    }
                } else {
                    // Local image
                    if let nsImage = NSImage(contentsOf: resolvedURL) {
                        SwiftUI.Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 600)
                    } else {
                        placeholderView(message: "Missing image")
                    }
                }
            } else {
                placeholderView(message: "Invalid image path")
            }
        }
        .accessibilityLabel(image.plainText)
    }

    /// Resolve the image source URL relative to the markdown file.
    private func resolveImageURL() -> URL? {
        guard let source = image.source, !source.isEmpty else { return nil }

        // Remote URL?
        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            return URL(string: source)
        }

        // Local path — resolve relative to the source .md file
        // When sourceURL is nil, refuse to resolve local paths (no unvalidated fallback)
        guard let baseURL = sourceURL?.deletingLastPathComponent() else {
            return nil
        }

        let resolved = baseURL.appendingPathComponent(source).standardized

        // Path traversal check (contract §11): refuse if resolved path
        // escapes the source directory
        let basePath = baseURL.standardized.path
        let resolvedPath = resolved.path
        guard resolvedPath.hasPrefix(basePath) else {
            // Path traversal attempt — refuse
            return nil
        }

        return resolved
    }

    /// Placeholder for missing/failed images showing alt text.
    private func placeholderView(message: String) -> some View {
        VStack(spacing: 8) {
            SwiftUI.Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: theme.colors.muted))
            Text(image.plainText.isEmpty ? message : image.plainText)
                .font(.system(size: CGFloat(theme.bodySize) * 0.75))
                .foregroundColor(Color(hex: theme.colors.muted))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: theme.colors.subtle))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: theme.colors.border), lineWidth: 1)
        )
    }
}
