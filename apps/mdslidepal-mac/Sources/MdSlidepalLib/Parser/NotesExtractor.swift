// What Problem: Extract speaker notes from slides using the reveal.js bare
// marker convention: a line starting with "Note:" or "Notes:" (case-insensitive).
// Everything from the marker through end of slide becomes speaker notes,
// rendered only in presenter view (contract §4).
//
// How & Why: For each slide, scan markup children for a Paragraph whose
// text starts with the Notes: marker. From that node onward, collect all
// remaining nodes as notes content (raw markdown text). Remove those nodes
// from the slide's visible children. The notes are stored as raw markdown
// for separate rendering in the presenter view.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.6

import Foundation
import Markdown

public struct NotesExtractor {

    /// Process slides to extract speaker notes.
    /// Returns updated slides with notes attached and notes-content nodes removed.
    public static func extract(from slides: [Slide]) -> [Slide] {
        slides.map { extractNotes(from: $0) }
    }

    private static func extractNotes(from slide: Slide) -> Slide {
        let children = slide.markupChildren

        // Find the index of the paragraph containing the Notes: marker
        var notesStartIndex: Int? = nil
        for (index, child) in children.enumerated() {
            if let paragraph = child as? Paragraph {
                let text = paragraph.plainText.trimmingCharacters(in: .whitespaces)
                if isNotesMarker(text) {
                    notesStartIndex = index
                    break
                }
            }
        }

        guard let startIndex = notesStartIndex else {
            return slide
        }

        // Everything from the notes marker onward becomes notes
        let visibleChildren = Array(children[..<startIndex])
        let notesChildren = Array(children[startIndex...])

        // Convert notes children to raw markdown text
        let notesText = extractNotesText(
            from: notesChildren,
            markerParagraphIndex: 0
        )

        return Slide(
            id: slide.id,
            markupChildren: visibleChildren,
            metadata: slide.metadata,
            notes: notesText.isEmpty ? nil : notesText
        )
    }

    /// Check if a paragraph text is a Notes: marker (case-insensitive).
    /// The marker must be "Note:" or "Notes:" optionally followed by content
    /// on the same line. But the paragraph must START with just the marker
    /// pattern — "Note: see appendix" is a valid marker (content becomes notes),
    /// matching the reveal.js convention where everything after "Notes:" is notes.
    private static func isNotesMarker(_ text: String) -> Bool {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespaces)
        return lowered == "note:" || lowered == "notes:"
            || lowered.hasPrefix("notes:\n") || lowered.hasPrefix("note:\n")
            || lowered.hasPrefix("notes: ") || lowered.hasPrefix("note: ")
    }

    /// Convert notes markup children to raw markdown text.
    /// The first paragraph (the marker) has its "Notes:" prefix stripped.
    private static func extractNotesText(
        from children: [Markup],
        markerParagraphIndex: Int
    ) -> String {
        var parts: [String] = []

        for (index, child) in children.enumerated() {
            if index == markerParagraphIndex {
                // Strip the "Notes:" or "Note:" prefix from the marker paragraph
                let text = child.format()
                let stripped = stripNotesPrefix(text)
                if !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(stripped.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else {
                parts.append(child.format())
            }
        }

        return parts.joined(separator: "\n\n")
    }

    /// Strip "Notes:" or "Note:" prefix from a line.
    private static func stripNotesPrefix(_ text: String) -> String {
        let patterns = ["notes:", "note:", "Notes:", "Note:"]
        for pattern in patterns {
            if text.hasPrefix(pattern) {
                return String(text.dropFirst(pattern.count))
            }
        }
        // Try case-insensitive
        let lowered = text.lowercased()
        if lowered.hasPrefix("notes:") {
            return String(text.dropFirst(6))
        }
        if lowered.hasPrefix("note:") {
            return String(text.dropFirst(5))
        }
        return text
    }
}
