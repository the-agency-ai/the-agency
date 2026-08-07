// What Problem: Phase 2.3 shows a diff when a versionConflict or
// bundleConflict is surfaced. The user needs to see what the CLI already
// has vs. what they wrote so they can decide whether to reload-and-remerge
// or retry. Phase 2.2 showed the title "Section was modified" but without
// the substance.
//
// How & Why:
// - Pure presenter — takes [DiffLine] from LineDiff and renders a unified
//   diff view. Monospace font. +/-/space prefix per line. Additions
//   highlighted green; removals red; unchanged neutral. Minimal scroll +
//   line-number gutter.
// - Sheet-presented from the alert's "Show Diff" action. The alert itself
//   stays small — users who don't care about the diff dismiss the alert
//   without ever opening the sheet.
// - No wrapping: long lines scroll horizontally. Markdown is typically
//   hard-wrapped at ~80-100 cols so this is fine for V1; if long prose
//   lines become a problem, wrap-toggle lands later.
//
// Written: 2026-04-19 during mdpal-app Phase 2.3

import SwiftUI

/// Simple unified-diff presentation. Takes pending + current strings,
/// computes the diff internally, renders a scrollable list with +/-/space
/// prefixes. Sheet-presented from conflict alerts.
public struct DiffView: View {
    public let pending: String
    public let current: String
    public let title: String
    public let onDismiss: () -> Void

    @State private var lines: [DiffLine] = []
    @State private var stats: DiffStats = DiffStats([])

    public init(
        pending: String,
        current: String,
        title: String = "Review changes",
        onDismiss: @escaping () -> Void
    ) {
        self.pending = pending
        self.current = current
        self.title = title
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            diffBody
            Divider()
            footer
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            let computed = computeLineDiff(pending: pending, current: current)
            lines = computed
            stats = DiffStats(computed)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(statsSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var statsSummary: String {
        if stats.isIdentical {
            return "No changes — pending and current are identical."
        }
        var parts: [String] = []
        if stats.pendingOnly > 0 {
            parts.append("\(stats.pendingOnly) line\(stats.pendingOnly == 1 ? "" : "s") only in your edit")
        }
        if stats.currentOnly > 0 {
            parts.append("\(stats.currentOnly) line\(stats.currentOnly == 1 ? "" : "s") only in current")
        }
        return parts.joined(separator: " · ")
    }

    private var diffBody: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    diffRow(for: line)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func diffRow(for line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(lineNumberLabel(for: line))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            Text(prefix(for: line) + line.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(textColor(for: line))
                .padding(.horizontal, 4)
                .background(backgroundColor(for: line))
        }
    }

    private func prefix(for line: DiffLine) -> String {
        switch line.kind {
        case .unchanged:   return "  "
        case .pendingOnly: return "- "
        case .currentOnly: return "+ "
        }
    }

    private func lineNumberLabel(for line: DiffLine) -> String {
        let pending = line.pendingLineNumber.map { "\($0)" } ?? " "
        let current = line.currentLineNumber.map { "\($0)" } ?? " "
        return "\(pending) | \(current)"
    }

    private func textColor(for line: DiffLine) -> Color {
        switch line.kind {
        case .unchanged:   return .primary
        case .pendingOnly: return .red
        case .currentOnly: return .green
        }
    }

    private func backgroundColor(for line: DiffLine) -> Color {
        switch line.kind {
        case .unchanged:   return .clear
        case .pendingOnly: return Color.red.opacity(0.08)
        case .currentOnly: return Color.green.opacity(0.08)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done", action: onDismiss)
                .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
}

#if DEBUG
struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(
            pending: "line one\nline two\nline three",
            current: "line one\nline 2\nline three\nline four",
            onDismiss: {})
    }
}
#endif
