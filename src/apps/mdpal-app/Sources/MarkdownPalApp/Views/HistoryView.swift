// What Problem: Reviewers need to see what revisions exist for a bundle
// and when they were created. Phase 1C.5 delivers the minimum: a sheet
// listing revisions (newest-first) with version/revision/timestamp and
// a "latest" marker. No diff-vs-previous, no rollback, no prune — those
// are Phase 2 work.
//
// How & Why: Stateless view over `[RevisionInfo]` + a dismiss handler.
// Testable bits (human-readable row rendering, latest-aware sort) live
// in HistoryRow helpers and a small display-model enum so the view
// layer itself stays thin.
//
// Written: 2026-04-17 during Phase 1C.5 (history drawer UI)

import SwiftUI

/// Per-row display model. Computed from RevisionInfo so tests can
/// assert the formatting contract without wrestling SwiftUI.
public struct HistoryRow: Identifiable, Hashable {
    public let id: String // == revision.versionId
    public let title: String // "v1 r3 — 2026-04-17 10:00"
    public let subtitle: String // filePath
    public let isLatest: Bool

    public init(from revision: RevisionInfo, formatter: DateFormatter = Self.defaultFormatter) {
        self.id = revision.versionId
        self.title = "v\(revision.version) r\(revision.revision) — \(formatter.string(from: revision.timestamp))"
        self.subtitle = revision.filePath
        self.isLatest = revision.latest == true
    }

    /// Shared "yyyy-MM-dd HH:mm" formatter — short enough to fit in a
    /// narrow sheet, zone-aware for local display. Tests inject a UTC
    /// formatter to keep assertions deterministic across timezones.
    public static let defaultFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()
}

/// Sheet showing the bundle's revision history. Newest-first per
/// dispatch #23; `isLatest` gets a visual marker.
public struct HistoryView: View {
    let revisions: [RevisionInfo]
    let onDismiss: () -> Void

    public init(revisions: [RevisionInfo], onDismiss: @escaping () -> Void) {
        self.revisions = revisions
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            List {
                if revisions.isEmpty {
                    ContentUnavailableView(
                        "No revisions",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Save the document to create its first revision.")
                    )
                } else {
                    ForEach(revisions, id: \.versionId) { rev in
                        let row = HistoryRow(from: rev)
                        rowView(row)
                    }
                }
            }
            .navigationTitle("Revision History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
        }
        .frame(minWidth: 420, idealWidth: 480, minHeight: 320, idealHeight: 420)
    }

    @ViewBuilder
    private func rowView(_ row: HistoryRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.title)
                    .font(.body)
                if row.isLatest {
                    Text("latest")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            Text(row.subtitle)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
