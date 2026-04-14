// What Problem: We need to orchestrate the full build pipeline: read markdown,
// load theme, emit CSS, render HTML template, copy vendored reveal.js, copy
// source markdown and images into a self-contained output directory.
//
// How & Why: A single async function that calls the other modules in sequence.
// The output directory is completely self-contained — it can be zipped, emailed,
// opened from file://, or served by any static file server. reveal.js is copied
// from node_modules (installed via pnpm) into the output. The markdown is
// pre-processed to normalize slide separators before being written to the output.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { readFile, writeFile, mkdir, cp } from "node:fs/promises";
import { resolve, dirname, basename, join } from "node:path";
import { existsSync } from "node:fs";
import { loadTheme, themeToCss } from "./theme.js";
import { renderTemplate } from "./template.js";
import { findImageRefs, copyImages } from "./assets.js";
import { preprocessMarkdown } from "./preprocess.js";

export interface BuildOptions {
  /** Path to the input markdown file */
  inputPath: string;
  /** Output directory path */
  outputDir: string;
  /** Theme name (default: "agency-default") */
  themeName?: string;
  /** Override themes directory */
  themesDir?: string;
}

export interface BuildResult {
  /** Path to the output index.html */
  indexPath: string;
  /** Path to the output directory */
  outputDir: string;
  /** Number of slides (estimated from separator count) */
  slideCount: number;
  /** Images copied */
  imagesCopied: string[];
}

/**
 * Build a self-contained reveal.js slide deck from a markdown file.
 */
export async function buildOutput(options: BuildOptions): Promise<BuildResult> {
  const {
    inputPath,
    outputDir,
    themeName = "agency-default",
    themesDir,
  } = options;

  const resolvedInput = resolve(inputPath);
  const markdownDir = dirname(resolvedInput);

  // 1. Read the input markdown
  const rawMarkdown = await readFile(resolvedInput, "utf-8");

  // 2. Pre-process markdown (normalize separators)
  const markdown = preprocessMarkdown(rawMarkdown);

  // 3. Load and render theme
  const theme = await loadTheme(themeName, themesDir);
  const themeCss = themeToCss(theme);

  // 4. Find local image references
  const imageRefs = findImageRefs(rawMarkdown, markdownDir);

  // 5. Create output directory structure
  await mkdir(outputDir, { recursive: true });

  // 6. Write pre-processed markdown to output
  const deckFilename = "deck.md";
  await writeFile(join(outputDir, deckFilename), markdown, "utf-8");

  // 7. Write theme CSS
  await writeFile(join(outputDir, "theme.css"), themeCss, "utf-8");

  // 8. Copy vendored reveal.js from node_modules
  const revealSrc = resolveRevealJsPath();
  const revealDest = join(outputDir, "reveal.js");
  if (!existsSync(revealDest)) {
    await mkdir(revealDest, { recursive: true });
  }
  // Copy dist/ and plugin/ directories
  await cp(join(revealSrc, "dist"), join(revealDest, "dist"), { recursive: true });
  await cp(join(revealSrc, "plugin"), join(revealDest, "plugin"), { recursive: true });

  // 9. Copy images
  const imagesCopied = await copyImages(imageRefs, markdownDir, outputDir);

  // 10. Render and write index.html
  const title = extractTitle(rawMarkdown) ?? basename(resolvedInput, ".md");
  const html = renderTemplate({
    title,
    themeCssHref: "./theme.css",
    deckMdHref: `./${deckFilename}`,
    revealJsPath: "./reveal.js",
    width: theme.logical_dimensions?.width ?? 1920,
    height: theme.logical_dimensions?.height ?? 1080,
  });
  const indexPath = join(outputDir, "index.html");
  await writeFile(indexPath, html, "utf-8");

  // Estimate slide count from separators
  const slideCount = (markdown.match(/^\r?\n---\r?\n$/gm)?.length ?? 0) + 1;

  return { indexPath, outputDir, slideCount, imagesCopied };
}

/**
 * Find reveal.js in node_modules. Searches up from this file's location.
 */
function resolveRevealJsPath(): string {
  // Try from the package's own node_modules first
  const candidates = [
    resolve(import.meta.dirname, "..", "node_modules", "reveal.js"),
    resolve(import.meta.dirname, "..", "..", "node_modules", "reveal.js"),
    resolve(import.meta.dirname, "..", "..", "..", "node_modules", "reveal.js"),
  ];

  for (const candidate of candidates) {
    if (existsSync(join(candidate, "dist", "reveal.js"))) {
      return candidate;
    }
  }

  throw new Error(
    "Could not find reveal.js in node_modules. Run 'pnpm install' in the mdslidepal-web directory."
  );
}

/**
 * Extract a title from the first H1 in the markdown.
 * Only searches the first slide (before the first ---) to avoid
 * matching headings inside code blocks on later slides.
 */
function extractTitle(markdown: string): string | undefined {
  // Only look at content before the first slide separator
  const firstSlide = markdown.split(/\n---\n/)[0] ?? markdown;
  const match = firstSlide.match(/^#\s+(.+)$/m);
  return match?.[1]?.trim();
}
