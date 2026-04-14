// What Problem: Contract §11 requires non-modal alerts for parsing errors.
// Diagnostics (invalid YAML, missing images, etc.) should surface in a
// banner above the preview pane, not as blocking modal dialogs.
//
// How & Why: A collapsible banner at the top of the preview area showing
// warning/error count. Expands to show individual diagnostics. Auto-hides
// when there are no diagnostics. Uses the theme's accent/muted colors.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 2

import SwiftUI

/// Non-modal diagnostics banner shown above the slide preview.
struct DiagnosticsBanner: View {
    let diagnostics: [Diagnostic]
    @State private var isExpanded = false
    @Environment(\.theme) private var theme

    var body: some View {
        if !diagnostics.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                // Summary bar
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: hasErrors ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                            .foregroundColor(hasErrors ? .red : .orange)
                        Text(summaryText)
                            .font(.caption)
                            .foregroundColor(Color(hex: theme.colors.foreground))
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(Color(hex: theme.colors.muted))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                // Expanded detail
                if isExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(diagnostics) { diag in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: diag.severity == .error ? "xmark.circle" : "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundColor(diag.severity == .error ? .red : .orange)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(diag.message)
                                        .font(.caption)
                                    if let idx = diag.slideIndex {
                                        Text("Slide \(idx + 1)")
                                            .font(.caption2)
                                            .foregroundColor(Color(hex: theme.colors.muted))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            }
            .background(Color(hex: theme.colors.subtle).opacity(0.95))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(hex: theme.colors.border)),
                alignment: .bottom
            )
        }
    }

    private var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }

    private var summaryText: String {
        let errors = diagnostics.filter { $0.severity == .error }.count
        let warnings = diagnostics.filter { $0.severity == .warning }.count
        var parts: [String] = []
        if errors > 0 { parts.append("\(errors) error\(errors == 1 ? "" : "s")") }
        if warnings > 0 { parts.append("\(warnings) warning\(warnings == 1 ? "" : "s")") }
        return parts.joined(separator: ", ")
    }
}
