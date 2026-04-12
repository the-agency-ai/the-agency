// What Problem: Export a slide deck to PDF — one page per slide at 1920×1080
// with theme colors, syntax highlighting, and embedded fonts. Contract §7
// specifies File → Export → PDF.
//
// How & Why: Uses SwiftUI ImageRenderer to render each SlideContentView at
// the logical slide size (1920×1080) to a CGImage, then assembles pages
// with PDFKit. ImageRenderer (macOS 13+) gives us exact SwiftUI rendering
// without going through NSPrintOperation. Metadata (title, author) from
// front-matter is embedded in the PDF.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 4

import SwiftUI
import PDFKit

/// Exports a DeckDocument to PDF.
@MainActor
public struct PDFExporter {

    /// Export a deck to PDF at the given URL.
    /// - Parameters:
    ///   - document: The deck to export.
    ///   - theme: The theme to use for rendering.
    ///   - url: The output file URL.
    ///   - includeNotes: If true, append a notes section after the slides.
    ///   - progress: Called with (completed, total) as pages are rendered.
    public static func export(
        document: DeckDocument,
        theme: Theme,
        to url: URL,
        includeNotes: Bool = false,
        progress: ((Int, Int) -> Void)? = nil
    ) throws {
        let pdfDocument = PDFDocument()
        let slideSize = CGSize(
            width: CGFloat(theme.logicalDimensions.width),
            height: CGFloat(theme.logicalDimensions.height)
        )
        let totalPages = document.slides.count
            + (includeNotes ? document.slides.filter { $0.notes != nil }.count : 0)

        // Render each slide to a PDF page
        for (index, slide) in document.slides.enumerated() {
            let view = SlideContentView(slide: slide, sourceURL: document.sourceURL)
                .environment(\.theme, theme)

            if let page = renderViewToPDFPage(view: view, size: slideSize) {
                pdfDocument.insert(page, at: index)
            }

            progress?(index + 1, totalPages)
        }

        // Optionally add notes pages
        if includeNotes {
            var notePageIndex = document.slides.count
            for slide in document.slides {
                guard let notes = slide.notes else { continue }

                let notesView = NotesPageView(
                    slideTitle: slide.title ?? "Slide \(slide.id + 1)",
                    slideIndex: slide.id + 1,
                    notes: notes,
                    theme: theme
                )

                if let page = renderViewToPDFPage(view: notesView, size: slideSize) {
                    pdfDocument.insert(page, at: notePageIndex)
                    notePageIndex += 1
                }

                progress?(notePageIndex, totalPages)
            }
        }

        // Set PDF metadata
        let attrs: [PDFDocumentAttribute: Any] = [
            .titleAttribute: document.title,
            .authorAttribute: document.frontMatter?.author ?? "",
            .creatorAttribute: "mdslidepal-mac",
        ]
        pdfDocument.documentAttributes = attrs

        // Write to disk
        guard pdfDocument.write(to: url) else {
            throw ExportError.writeFailed(url)
        }
    }

    // MARK: - Rendering

    @MainActor
    private static func renderViewToPDFPage<V: View>(view: V, size: CGSize) -> PDFPage? {
        let renderer = ImageRenderer(content:
            view.frame(width: size.width, height: size.height)
        )
        renderer.scale = 2.0  // Retina quality

        guard let cgImage = renderer.cgImage else { return nil }

        // Create a PDFPage from the CGImage
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return PDFPage(image: nsImage)
    }

    // MARK: - Errors

    public enum ExportError: LocalizedError {
        case writeFailed(URL)

        public var errorDescription: String? {
            switch self {
            case .writeFailed(let url):
                return "Failed to write PDF to \(url.lastPathComponent)"
            }
        }
    }
}

/// A page showing speaker notes for PDF export.
private struct NotesPageView: View {
    let slideTitle: String
    let slideIndex: Int
    let notes: String
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Text("Notes — Slide \(slideIndex): \(slideTitle)")
                    .font(.system(size: 36, weight: .bold))
                Spacer()
            }

            Rectangle()
                .fill(Color(hex: theme.colors.border))
                .frame(height: 2)

            // Notes content
            Text(notes)
                .font(.system(size: 28))
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(EdgeInsets(top: 96, leading: 120, bottom: 96, trailing: 120))
        .foregroundColor(Color(hex: theme.colors.foreground))
        .background(Color(hex: theme.colors.background))
    }
}
