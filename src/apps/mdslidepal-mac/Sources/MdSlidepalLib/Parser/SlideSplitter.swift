// What Problem: Split a parsed Markdown.Document into slides by detecting
// ThematicBreak nodes at the document top level (contract §2). Thematic
// breaks inside code blocks, lists, block quotes, or HTML blocks are NOT
// slide breaks — the AST walk guarantees this automatically because we
// only iterate document.children (top-level nodes).
//
// How & Why: AST-based detection per contract. Iterate document.children,
// accumulate nodes into a current slide. When a ThematicBreak is encountered,
// emit the current slide and start a new one. Handle degenerate cases:
// - Empty document → one placeholder slide
// - Lone ThematicBreak → one empty slide
// - Two adjacent ThematicBreaks → one empty slide (collapse)
// - Trailing ThematicBreak → absorbed (no phantom final slide)
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.4

import Foundation
import Markdown

public struct SlideSplitter {

    /// Split a Markdown Document into slides based on top-level ThematicBreak nodes.
    public static func split(document: Document) -> [Slide] {
        let children = Array(document.children)

        // Empty document → one placeholder slide
        if children.isEmpty {
            return [Slide(id: 0, markupChildren: [])]
        }

        var slides: [Slide] = []
        var currentChildren: [Markup] = []
        var slideIndex = 0

        for child in children {
            if child is ThematicBreak {
                // Emit current slide (may be empty)
                slides.append(Slide(
                    id: slideIndex,
                    markupChildren: currentChildren
                ))
                slideIndex += 1
                currentChildren = []
            } else {
                currentChildren.append(child)
            }
        }

        // Emit the last slide (if there's content after the last break)
        if !currentChildren.isEmpty {
            slides.append(Slide(
                id: slideIndex,
                markupChildren: currentChildren
            ))
        }

        // Handle degenerate cases:
        // - If only breaks were found and no content after last break,
        //   we may have trailing empty slides
        // - Collapse adjacent empty slides (two adjacent --- → one empty slide)
        // - Absorb trailing ThematicBreak (no phantom final slide)
        slides = collapseEmptySlides(slides)

        // If everything was absorbed, return one empty placeholder
        if slides.isEmpty {
            return [Slide(id: 0, markupChildren: [])]
        }

        // Re-index slides
        return slides.enumerated().map { index, slide in
            Slide(
                id: index,
                markupChildren: slide.markupChildren,
                metadata: slide.metadata,
                notes: slide.notes
            )
        }
    }

    /// Collapse adjacent empty slides and remove trailing empty slides.
    ///
    /// Contract §2:
    /// - Two adjacent `---` → one empty slide (not two)
    /// - Trailing `---` → no phantom final slide
    private static func collapseEmptySlides(_ slides: [Slide]) -> [Slide] {
        var result: [Slide] = []
        var previousWasEmpty = false

        for slide in slides {
            let isEmpty = slide.markupChildren.isEmpty

            if isEmpty {
                if previousWasEmpty {
                    // Adjacent empty slides — collapse (skip this one)
                    continue
                }
                previousWasEmpty = true
                result.append(slide)
            } else {
                previousWasEmpty = false
                result.append(slide)
            }
        }

        // Remove trailing empty slide (absorb trailing ThematicBreak)
        if let last = result.last, last.markupChildren.isEmpty, result.count > 1 {
            result.removeLast()
        }

        return result
    }
}
