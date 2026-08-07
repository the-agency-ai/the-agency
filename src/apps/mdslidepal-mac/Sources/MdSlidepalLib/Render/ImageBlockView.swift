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
// Updated: 2026-04-15 Phase 5.2 — image sizing tuned to logical slide width.
// Updated: 2026-08-07 PR-prep QG — path resolution moved to ImagePathResolver
//   (the containment check was a string prefix test and let sibling directories
//   through), decoding moved behind LocalImageCache instead of re-reading the
//   file on every body evaluation, and the max image box is now derived from the
//   theme's logical dimensions rather than hardcoded 1680×700.

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
                                .frame(
                                    maxWidth: maxImageSize.width,
                                    maxHeight: maxImageSize.height
                                )
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
                    if let nsImage = LocalImageCache.image(at: resolvedURL) {
                        SwiftUI.Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxWidth: maxImageSize.width,
                                maxHeight: maxImageSize.height
                            )
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
    ///
    /// Delegates to `ImagePathResolver` so the contract §11 containment rule
    /// lives in one testable place rather than inside a view body.
    private func resolveImageURL() -> URL? {
        ImagePathResolver.resolve(source: image.source, relativeTo: sourceURL)
    }

    /// Largest box an image may occupy: the slide's logical content width
    /// (dimensions minus horizontal padding) and a bounded share of its height.
    /// Derived from the theme rather than hardcoded — per Theme.swift's own
    /// contract that no sizes are baked into views.
    private var maxImageSize: CGSize {
        let dims = theme.logicalDimensions
        let padding = theme.slidePadding
        return CGSize(
            width: CGFloat(dims.width - padding.left - padding.right),
            height: CGFloat(dims.height) * Self.maxHeightFraction
        )
    }

    /// Images are capped at this share of the slide height so a tall image
    /// cannot crowd out a heading and its surrounding body text.
    private static let maxHeightFraction: CGFloat = 0.65

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
