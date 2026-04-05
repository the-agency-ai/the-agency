// What Problem: The detail pane needs to display a section's content with
// its heading, metadata (version hash, child count), and associated comments
// and flags. This is the primary reading/review surface.
//
// How & Why: Vertical ScrollView with the section heading, content body,
// flag banner (if flagged), and comment thread. Content is plain text for
// Phase 1 — Markdown rendering comes later. Comments show type, author,
// staleness indicator, and resolution state.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import SwiftUI

/// Detail view showing a section's content and review state.
public struct SectionReaderView: View {
    let section: Section
    let comments: [Comment]
    let flag: Flag?

    public init(section: Section, comments: [Comment], flag: Flag?) {
        self.section = section
        self.comments = comments
        self.flag = flag
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                sectionHeader

                // Flag banner
                if let flag = flag {
                    flagBanner(flag)
                }

                Divider()

                // Section content
                Text(section.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Children summary
                if !section.children.isEmpty {
                    childrenSummary
                }

                // Comments
                if !comments.isEmpty {
                    Divider()
                    commentsSection
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(section.heading)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.heading)
                .font(.largeTitle.bold())

            HStack(spacing: 12) {
                Label(section.slug, systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("v: \(section.versionHash)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("H\(section.level)", systemImage: "text.header.level.\(min(section.level, 3))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Flag Banner

    private func flagBanner(_ flag: Flag) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Flagged for discussion")
                    .font(.subheadline.bold())

                if let note = flag.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("by \(flag.author) \(flag.timestamp.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.opacity(0.1))
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Children Summary

    private var childrenSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Subsections")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(section.children) { child in
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(child.heading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.5))
        )
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comments")
                    .font(.headline)
                let unresolvedCount = comments.filter { !$0.isResolved }.count
                if unresolvedCount > 0 {
                    Text("\(unresolvedCount) unresolved")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            ForEach(comments) { comment in
                CommentView(
                    comment: comment,
                    isStale: comment.isStale(currentSectionHash: section.versionHash)
                )
            }
        }
    }
}

/// A single comment in the thread.
struct CommentView: View {
    let comment: Comment
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Comment header
            HStack(spacing: 6) {
                commentTypeIcon
                    .foregroundStyle(commentTypeColor)

                Text(comment.type.rawValue.capitalized)
                    .font(.caption.bold())
                    .foregroundStyle(commentTypeColor)

                Text("by \(comment.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if comment.priority == .high {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .help("High priority")
                }

                if isStale {
                    Label("Stale", systemImage: "clock.arrow.circlepath")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .help("Section has changed since this comment was written")
                }

                Spacer()

                Text(comment.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Comment text
            Text(comment.text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Context (collapsed by default in future; shown for now)
            if !comment.context.isEmpty {
                Text(comment.context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary.opacity(0.5))
                    )
            }

            // Resolution
            if let resolution = comment.resolution {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Resolved by \(resolution.resolvedBy):")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                Text(resolution.response)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(comment.isResolved ? .green.opacity(0.05) : .blue.opacity(0.05))
                .stroke(comment.isResolved ? .green.opacity(0.2) : .blue.opacity(0.2), lineWidth: 1)
        )
    }

    private var commentTypeIcon: some View {
        Image(systemName: iconName)
            .font(.caption)
    }

    private var iconName: String {
        switch comment.type {
        case .question: return "questionmark.circle"
        case .suggestion: return "lightbulb"
        case .note: return "note.text"
        case .directive: return "arrow.right.circle"
        case .decision: return "checkmark.seal"
        }
    }

    private var commentTypeColor: Color {
        switch comment.type {
        case .question: return .purple
        case .suggestion: return .blue
        case .note: return .gray
        case .directive: return .orange
        case .decision: return .green
        }
    }
}
