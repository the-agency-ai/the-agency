// What Problem: Render markdown images (![alt](path)) as SwiftUI views.
// Local paths resolve relative to the source .md file. Remote URLs load
// via RemoteImageLoader. Missing images show a placeholder with alt text per
// contract §11.
//
// How & Why: Separate view for block-level images (as opposed to inline
// image references which show alt text only). Handles local file:// paths,
// bounded remote http/https fetches, path traversal refusal (contract §11),
// and graceful fallback to placeholder on any error.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5
// Updated: 2026-04-15 Phase 5.2 — image sizing tuned to logical slide width.
// Updated: 2026-08-07 PR-prep QG — path resolution moved to ImagePathResolver
//   (the containment check was a string prefix test and let sibling directories
//   through), decoding moved behind LocalImageCache instead of re-reading the
//   file on every body evaluation, and the max image box is now derived from the
//   theme's logical dimensions rather than hardcoded 1680×700.
// Updated: 2026-08-12 PR-prep QG wave 4 — remote images moved off AsyncImage onto
//   RemoteImageView/RemoteImageLoader (explicit timeout + response-size ceiling;
//   remote loading itself is required by contract §5 line 219 and is unchanged),
//   and the local decode now passes the deck directory so containment is
//   re-checked on the opened file rather than on the path.
// Updated: 2026-08-12 PR-prep QG — the max-size frame was upscaling small
//   images (a 200×100 logo drew at 1404×702); sizing is now clamped to the
//   image's intrinsic size, and the arithmetic moved to `maxImageSize(for:)` /
//   `displaySize(intrinsic:maxBox:)` so it is testable without a view.

import SwiftUI
import Markdown

/// Loads a remote image under `RemoteImageLoader`'s timeout and size bounds,
/// showing `placeholder` on any failure — the same box the local path shows, so
/// a bounded refusal and a missing file look identical to the audience.
///
/// This replaces `AsyncImage`, which fetches on the shared session with the
/// 60-second default timeout and no response ceiling.
struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let maxBox: CGSize
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loaded: NSImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let loaded {
                let drawn = ImageBlockView.displaySize(intrinsic: loaded.size, maxBox: maxBox)
                SwiftUI.Image(nsImage: loaded)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: drawn.width, maxHeight: drawn.height)
            } else if failed {
                placeholder()
            } else {
                ProgressView()
                    .frame(height: 200)
            }
        }
        // Keyed on the URL so a live-reload that changes the source refetches
        // instead of leaving the previous slide's image on screen.
        .task(id: url) {
            loaded = nil
            failed = false
            switch await RemoteImageLoader.load(url) {
            case .success(let image):
                loaded = image
            case .failure:
                failed = true
            }
        }
    }
}

/// Renders a block-level image from markdown.
public struct ImageBlockView: View {
    let image: Markdown.Image
    let sourceURL: URL?
    @Environment(\.theme) private var theme

    public var body: some View {
        Group {
            if let resolvedURL = resolveImageURL() {
                if resolvedURL.scheme == "http" || resolvedURL.scheme == "https" {
                    // Remote image — loaded, but bounded. See RemoteImageLoader.
                    RemoteImageView(url: resolvedURL, maxBox: maxImageSize) {
                        placeholderView(message: "Failed to load remote image")
                    }
                } else {
                    // Local image
                    if let nsImage = LocalImageCache.image(
                        at: resolvedURL, containedIn: deckDirectory
                    ) {
                        // Clamp against the image's own size. `.resizable()` plus
                        // a max-size frame takes the whole box on offer, which
                        // upscales a small logo to full-slide width.
                        let drawn = Self.displaySize(
                            intrinsic: nsImage.size, maxBox: maxImageSize
                        )
                        SwiftUI.Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: drawn.width, maxHeight: drawn.height)
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

    /// The deck directory a local image must stay inside. Nil for a deck with no
    /// file on disk — which is also the only case where no local path resolves.
    private var deckDirectory: URL? {
        sourceURL?.deletingLastPathComponent()
    }

    /// Largest box an image may occupy: the slide's logical content width
    /// (dimensions minus horizontal padding) and a bounded share of its height.
    /// Derived from the theme rather than hardcoded — per Theme.swift's own
    /// contract that no sizes are baked into views.
    public static func maxImageSize(for theme: Theme) -> CGSize {
        let dims = theme.logicalDimensions
        let padding = theme.slidePadding
        return CGSize(
            width: CGFloat(dims.width - padding.left - padding.right),
            height: CGFloat(dims.height) * maxHeightFraction
        )
    }

    /// Size at which an image of `intrinsic` pixel dimensions should be drawn
    /// inside `maxBox`.
    ///
    /// Shrinks to fit, preserving aspect ratio, and never enlarges. A resizable
    /// SwiftUI image handed `.frame(maxWidth:maxHeight:)` accepts the maximum
    /// offered, so a 200×100 logo was being blown up to the full 1680×702 box.
    public static func displaySize(intrinsic: CGSize, maxBox: CGSize) -> CGSize {
        guard intrinsic.width > 0, intrinsic.height > 0,
              maxBox.width > 0, maxBox.height > 0
        else { return intrinsic }

        let scale = min(1, maxBox.width / intrinsic.width, maxBox.height / intrinsic.height)
        return CGSize(width: intrinsic.width * scale, height: intrinsic.height * scale)
    }

    private var maxImageSize: CGSize { Self.maxImageSize(for: theme) }

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
