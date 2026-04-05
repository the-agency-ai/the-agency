// What Problem: The sidebar needs to show a hierarchical list of document
// sections with visual indicators for flags and unresolved comments. Section
// level (h1, h2, h3...) determines indentation. This is the primary
// navigation surface for the app.
//
// How & Why: SwiftUI List with selection binding. Indentation based on
// section level. Badges for unresolved comment counts. Flag icons for
// flagged sections. The list is flat (not tree-based) because the engine
// returns sections in document order with level info — visual hierarchy
// via indentation is simpler than nested OutlineGroup for V1.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import SwiftUI

/// Sidebar view showing all sections in document order.
public struct SectionListView: View {
    let sections: [SectionInfo]
    let flags: [Flag]
    let commentCounts: [String: Int]
    @Binding var selectedSlug: String?

    public init(sections: [SectionInfo], flags: [Flag],
                commentCounts: [String: Int], selectedSlug: Binding<String?>) {
        self.sections = sections
        self.flags = flags
        self.commentCounts = commentCounts
        self._selectedSlug = selectedSlug
    }

    public var body: some View {
        List(sections, selection: $selectedSlug) { section in
            SectionRowView(
                section: section,
                isFlagged: flaggedSlugs.contains(section.slug),
                unresolvedCount: commentCounts[section.slug] ?? 0
            )
            .tag(section.slug)
        }
        .listStyle(.sidebar)
        .navigationTitle("Sections")
    }

    private var flaggedSlugs: Set<String> {
        Set(flags.map(\.sectionSlug))
    }
}

/// A single row in the section list.
public struct SectionRowView: View {
    let section: SectionInfo
    let isFlagged: Bool
    let unresolvedCount: Int

    public var body: some View {
        HStack(spacing: 6) {
            // Indentation based on heading level
            // Level 1 = no indent, Level 2 = 1 indent, etc.
            if section.level > 1 {
                Spacer()
                    .frame(width: CGFloat((section.level - 1) * 16))
            }

            // Section heading
            VStack(alignment: .leading, spacing: 2) {
                Text(section.heading)
                    .font(fontForLevel(section.level))
                    .lineLimit(1)

                // Version hash as subtle metadata
                Text(section.versionHash)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Flag indicator
            if isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .help("Flagged for discussion")
            }

            // Unresolved comment badge
            if unresolvedCount > 0 {
                Text("\(unresolvedCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.blue))
                    .help("\(unresolvedCount) unresolved comment\(unresolvedCount == 1 ? "" : "s")")
            }
        }
        .padding(.vertical, 2)
    }

    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .headline
        case 2: return .subheadline
        default: return .body
        }
    }
}
