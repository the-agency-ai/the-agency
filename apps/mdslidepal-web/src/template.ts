// What Problem: We need to generate the index.html that loads reveal.js with
// the markdown plugin, referencing the deck markdown file and theme CSS. This
// is a direct derivative of the Plan B template with parameterized paths.
//
// How & Why: A pure function that returns an HTML string with template
// substitutions. No template engine dependency — tagged template literals are
// sufficient for 4 substitutions. Preserves all reveal.js initialization
// parameters from Plan B exactly.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

export interface TemplateParams {
  title: string;
  themeCssHref: string;
  deckMdHref: string;
  revealJsPath: string;
  /** Slide width in pixels (default: 1920) */
  width?: number;
  /** Slide height in pixels (default: 1080) */
  height?: number;
}

/**
 * Generate the index.html content for a reveal.js slide deck.
 */
export function renderTemplate(params: TemplateParams): string {
  const { title, themeCssHref, deckMdHref, revealJsPath, width = 1920, height = 1080 } = params;

  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>${escapeHtml(title)}</title>

    <link rel="stylesheet" href="${escapeAttr(revealJsPath)}/dist/reset.css" />
    <link rel="stylesheet" href="${escapeAttr(revealJsPath)}/dist/reveal.css" />
    <link rel="stylesheet" href="${escapeAttr(revealJsPath)}/dist/theme/white.css" id="theme" />
    <link rel="stylesheet" href="${escapeAttr(revealJsPath)}/plugin/highlight/monokai.css" />
    <link rel="stylesheet" href="${escapeAttr(themeCssHref)}" />
    <style>
      /* Slide number — bottom left corner, large and readable */
      .reveal .slide-number {
        display: none !important; /* hide default, use custom */
      }
      #slide-counter {
        position: fixed;
        left: 24px;
        bottom: 20px;
        font-size: 22px;
        font-weight: 600;
        color: #444;
        font-family: system-ui, -apple-system, sans-serif;
        z-index: 100;
      }
    </style>
  </head>
  <body>
    <div class="reveal">
      <div class="slides">
        <section
          data-markdown="${escapeAttr(deckMdHref)}"
          data-separator="^\\r?\\n---\\r?\\n$"
          data-separator-vertical="^\\r?\\n----\\r?\\n$"
          data-separator-notes="^Notes?:"
          data-charset="utf-8"
        ></section>
      </div>
    </div>

    <script src="${escapeAttr(revealJsPath)}/dist/reveal.js"></script>
    <script src="${escapeAttr(revealJsPath)}/plugin/markdown/markdown.js"></script>
    <script src="${escapeAttr(revealJsPath)}/plugin/highlight/highlight.js"></script>
    <script src="${escapeAttr(revealJsPath)}/plugin/notes/notes.js"></script>

    <div id="slide-counter"></div>
    <script>
      Reveal.initialize({
        hash: true,
        width: ${Number(width) || 1920},
        height: ${Number(height) || 1080},
        margin: 0.04,
        minScale: 0.2,
        maxScale: 2.0,
        transition: "none",
        controls: true,
        progress: true,
        center: true,
        slideNumber: false,
        plugins: [RevealMarkdown, RevealHighlight, RevealNotes],
      }).then(() => {
        const counter = document.getElementById("slide-counter");
        function updateCounter() {
          const current = Reveal.getIndices().h + 1;
          const total = Reveal.getTotalSlides();
          counter.textContent = current + " of " + total;
        }
        updateCounter();
        Reveal.on("slidechanged", updateCounter);
      });
    </script>
  </body>
</html>
`;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** Escape a string for use in an HTML attribute value (double-quoted). */
function escapeAttr(str: string): string {
  return escapeHtml(str);
}
