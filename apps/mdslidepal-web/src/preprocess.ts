// What Problem: reveal.js's native markdown plugin uses a regex splitter
// (^\r?\n---\r?\n$), not an AST. A trailing --- at the end of a file creates
// a phantom empty final slide. We also apply SmartyPants typography for
// professional-looking slides.
//
// How & Why: A pre-processor that: (1) strips trailing slide separators,
// (2) applies SmartyPants typography (curly quotes, em dashes, ellipsis).
// Fenced code blocks and inline code are protected from SmartyPants via
// a placeholder extraction approach. Markdown link syntax is also protected
// to avoid mangling URLs and link titles.
//
// This is Decision 1 from the reconciliation — keeping the gap between
// reveal.js regex splitting and contract behavior as small as possible.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

/**
 * Pre-process markdown to normalize slide separators and apply
 * typographic enhancements for reveal.js.
 *
 * 1. Trailing --- at end of file is stripped (no phantom final slide)
 * 2. SmartyPants: straight quotes → curly quotes, -- → em dash, ... → ellipsis
 * 3. Fenced code blocks, inline code, and markdown links are protected
 */
export function preprocessMarkdown(markdown: string): string {
  let processed = markdown;

  // Collapse adjacent separators (---\n\n---\n\n--- → single ---) per contract Decision 1
  // Match sequences of two or more --- separated by blank lines
  while (/\n---\s*\n\s*\n---\s*\n/.test(processed)) {
    processed = processed.replace(/\n---\s*\n\s*\n---/g, "\n---");
  }

  // Strip trailing separator(s) at end of file.
  // Handles both LF and CRLF line endings.
  while (true) {
    const stripped = processed.replace(/\r?\n---\s*$/, "");
    if (stripped === processed) break;
    processed = stripped;
  }

  // SmartyPants: apply typographic quotes outside protected regions
  processed = applySmartyPants(processed);

  return processed;
}

/**
 * Apply SmartyPants-style typographic transformations.
 * Protects fenced code blocks, inline code, and markdown link/image syntax.
 */
function applySmartyPants(text: string): string {
  // Extract protected regions and replace with placeholders
  const placeholders: string[] = [];

  function protect(match: string): string {
    const idx = placeholders.length;
    placeholders.push(match);
    return `\x00PH${idx}\x00`;
  }

  let processed = text;

  // 1. Protect fenced code blocks (``` or ~~~, including unclosed at EOF)
  // Single regex handles both closed and unclosed fences to prevent double-matching
  processed = processed.replace(/^(```|~~~)[^\n]*\n[\s\S]*?(?:\n\1\s*$|$)/gm, protect);

  // 2. Protect inline code spans (single and double backtick)
  processed = processed.replace(/``[^`]+``|`[^`]+`/g, protect);

  // 3. Protect markdown links and images: [text](url) and [text](url "title")
  processed = processed.replace(/!?\[[^\]]*\]\([^)]*\)/g, protect);

  // 4. Apply SmartyPants to the remaining text
  processed = smartyPantsSegment(processed);

  // 5. Restore protected regions
  processed = processed.replace(/\x00PH(\d+)\x00/g, (_m, idx) => {
    return placeholders[parseInt(idx, 10)]!;
  });

  return processed;
}

/**
 * Apply typographic replacements to a text segment (no code or links).
 */
function smartyPantsSegment(text: string): string {
  // Process line-by-line to protect table separator rows and slide breaks
  const lines = text.split("\n");
  const processed = lines.map((line) => {
    // Skip table separator rows (|---|---|) and slide breaks (---)
    if (/^\s*\|[-:| ]+\|\s*$/.test(line)) return line;
    if (/^\s*---+\s*$/.test(line)) return line;
    return smartyPantsLine(line);
  });
  return processed.join("\n");
}

function smartyPantsLine(text: string): string {
  let result = text;

  // Em dash: -- → — (only inline with adjacent text)
  result = result.replace(/(\w)---(\w)/g, "$1\u2014$2");
  result = result.replace(/(\w)--(\w)/g, "$1\u2014$2");
  result = result.replace(/(\w)-- /g, "$1\u2014 ");
  result = result.replace(/ --(\w)/g, " \u2014$1");
  result = result.replace(/ -- /g, " \u2014 ");

  // Ellipsis: ... → …
  result = result.replace(/\.\.\./g, "\u2026");

  // Double quotes: "text" → \u201Ctext\u201D
  // Opening: after whitespace, start of line, or start of string
  result = result.replace(/(^|[\s(\[{])"(?=\S)/gm, "$1\u201C");
  // Closing: before whitespace, punctuation, end of line, or end of string
  result = result.replace(/"(?=[\s.,;:!?\])}]|$)/gm, "\u201D");
  // Any remaining straight double quotes → closing (best guess)
  result = result.replace(/"/g, "\u201D");

  // Single quotes / apostrophes:
  // Apostrophes in contractions: letter'letter → letter\u2019letter
  result = result.replace(/(\w)'(\w)/g, "$1\u2019$2");
  // Opening single quote: after whitespace
  result = result.replace(/(^|[\s(\[{])'(?=\S)/gm, "$1\u2018");
  // Closing single quote
  result = result.replace(/'(?=[\s.,;:!?\])}]|$)/gm, "\u2019");
  // Any remaining straight single quotes → closing (apostrophe)
  result = result.replace(/'/g, "\u2019");

  return result;
}
