// What Problem: When the markdown references local images like
// ![alt](./images/sample.png), we need to find those references and copy
// the image files into the output directory so they resolve correctly.
//
// How & Why: Regex scan of the markdown for image references, then copy
// each referenced file to the output. We resolve paths relative to the
// source markdown file's directory. Missing images get a warning on stderr
// but don't fail the build (per contract error handling — missing images
// show alt text via browser default broken-image behavior).
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { copyFile, mkdir } from "node:fs/promises";
import { resolve, dirname, basename, join, relative, isAbsolute } from "node:path";
import { existsSync } from "node:fs";

/**
 * Scan markdown for local image references and return the list of
 * { src, dest } pairs for copying.
 *
 * @param markdown The markdown content
 * @param markdownDir The directory containing the source markdown file
 * @param outputDir The output directory to copy images into
 */
export function findImageRefs(
  markdown: string,
  markdownDir: string
): string[] {
  // Match ![alt](path) or ![alt](path "title") — stop at space before title
  const imagePattern = /!\[[^\]]*\]\(([^\s)]+)(?:\s+"[^"]*")?\)/g;
  const refs: string[] = [];
  let match;

  while ((match = imagePattern.exec(markdown)) !== null) {
    const src = match[1]!;
    // Skip remote URLs
    if (src.startsWith("http://") || src.startsWith("https://") || src.startsWith("data:")) {
      continue;
    }
    refs.push(src);
  }

  return refs;
}

/**
 * Copy local images referenced in the markdown to the output directory.
 * Preserves the relative path structure so markdown references still work.
 *
 * @param imageRefs Array of image paths (relative to markdown file)
 * @param markdownDir Directory containing the source markdown file
 * @param outputDir The output directory
 * @returns Array of successfully copied image paths
 */
export async function copyImages(
  imageRefs: string[],
  markdownDir: string,
  outputDir: string
): Promise<string[]> {
  const copied: string[] = [];

  for (const ref of imageRefs) {
    // Reject absolute paths and paths that escape the source directory
    if (isAbsolute(ref)) {
      console.error(`[mdslidepal] warning: skipping absolute image path: ${ref}`);
      continue;
    }

    const srcPath = resolve(markdownDir, ref);

    // Validate source stays within or under markdownDir
    const relToSource = relative(markdownDir, srcPath);
    if (relToSource.startsWith("..")) {
      console.error(`[mdslidepal] warning: skipping image outside source directory: ${ref}`);
      continue;
    }

    if (!existsSync(srcPath)) {
      console.error(`[mdslidepal] warning: image not found: ${ref} (resolved to ${srcPath})`);
      continue;
    }

    // Validate destination stays within outputDir
    const destPath = resolve(outputDir, ref);
    const relToDest = relative(outputDir, destPath);
    if (relToDest.startsWith("..")) {
      console.error(`[mdslidepal] warning: skipping image that would escape output directory: ${ref}`);
      continue;
    }
    const destDir = dirname(destPath);

    await mkdir(destDir, { recursive: true });
    await copyFile(srcPath, destPath);
    copied.push(ref);
  }

  return copied;
}
