// What Problem: When the app is NOT running against the real `mdpal` CLI —
// either because MDPAL_MOCK=1 was set (tests / developer previews) or
// because cliNotFound fell back to Mock (no binary on PATH) — the user
// needs to know. Otherwise they'll think their edits are hitting a real
// bundle when they're only mutating in-memory mock data.
//
// How & Why: Thin, non-intrusive top banner. Renders only for non-real
// resolutions; .real produces an empty view so production feels clean.
// Text derivation is on `CLIServiceFactory.Resolution.bannerMessage`
// (pure function, unit-testable); this view is just presentation.
//
// Phase 1C.1. Deferred since 1B.6 when CLIServiceFactory landed but no UI
// consumer existed.
//
// Written: 2026-04-17 during Phase 1C.1

import SwiftUI

/// Non-intrusive banner surfaced at the top of the main window whenever
/// the app is running against Mock (explicitly requested OR fallback).
/// Renders as an EmptyView in the .real case so the main UI isn't
/// interrupted in production.
public struct CLIServiceBanner: View {
    let resolution: CLIServiceFactory.Resolution

    public init(resolution: CLIServiceFactory.Resolution) {
        self.resolution = resolution
    }

    public var body: some View {
        if let message = resolution.bannerMessage {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 4) {
                    if let title = resolution.bannerTitle {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(iconColor)
                    }
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .overlay(alignment: .top) {
                Rectangle().fill(iconColor).frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(iconColor).frame(height: 3)
            }
        }
    }

    /// .mockRequested is a deliberate user choice → neutral info icon.
    /// .mockFallback is an environment issue → yellow warning icon.
    /// .pancake is a normal mode for plain .md → blue document icon.
    private var iconName: String {
        switch resolution {
        case .mockRequested: return "info.circle"
        case .mockFallback: return "exclamationmark.triangle"
        case .pancake: return "doc.text"
        case .real: return "" // unreachable — bannerMessage returns nil
        }
    }

    private var iconColor: Color {
        switch resolution {
        case .mockRequested: return .accentColor
        case .mockFallback: return .orange
        case .pancake: return .blue
        case .real: return .clear
        }
    }

    private var backgroundColor: Color {
        switch resolution {
        case .mockRequested: return Color.accentColor.opacity(0.18)
        case .mockFallback: return Color.orange.opacity(0.28)
        case .pancake: return Color.blue.opacity(0.18)
        case .real: return Color.clear
        }
    }
}
