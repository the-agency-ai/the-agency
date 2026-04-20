// What Problem: Verify that buildOutput produces the expected output
// directory structure with all required files.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { buildOutput } from "../src/build.js";
import { existsSync } from "node:fs";
import { readFile, rm, mkdtemp } from "node:fs/promises";
import { resolve, join } from "node:path";
import { tmpdir } from "node:os";

const fixturesDir = resolve(
  import.meta.dirname,
  "..",
  "..",
  "..",
  "claude",
  "workstreams",
  "mdslidepal",
  "fixtures"
);

const themesDir = resolve(
  import.meta.dirname,
  "..",
  "..",
  "..",
  "claude",
  "workstreams",
  "mdslidepal",
  "themes"
);

describe("buildOutput", () => {
  let outputDir: string;

  beforeEach(async () => {
    outputDir = await mkdtemp(join(tmpdir(), "mdslidepal-test-"));
  });

  afterEach(async () => {
    if (existsSync(outputDir)) {
      await rm(outputDir, { recursive: true });
    }
  });

  it("creates output directory with required files", async () => {
    const result = await buildOutput({
      inputPath: join(fixturesDir, "01-minimal.md"),
      outputDir,
      themesDir,
    });

    expect(existsSync(join(outputDir, "index.html"))).toBe(true);
    expect(existsSync(join(outputDir, "deck.md"))).toBe(true);
    expect(existsSync(join(outputDir, "theme.css"))).toBe(true);
    expect(existsSync(join(outputDir, "reveal.js", "dist", "reveal.js"))).toBe(true);
    expect(existsSync(join(outputDir, "reveal.js", "plugin", "markdown", "markdown.js"))).toBe(true);
    expect(existsSync(join(outputDir, "reveal.js", "plugin", "highlight", "highlight.js"))).toBe(true);
  });

  it("generates correct index.html structure", async () => {
    await buildOutput({
      inputPath: join(fixturesDir, "01-minimal.md"),
      outputDir,
      themesDir,
    });

    const html = await readFile(join(outputDir, "index.html"), "utf-8");
    expect(html).toContain('data-markdown="./deck.md"');
    expect(html).toContain('href="./theme.css"');
    expect(html).toContain('src="./reveal.js/dist/reveal.js"');
    expect(html).toContain("width: 1920");
    expect(html).toContain("height: 1080");
    expect(html).toContain("RevealMarkdown");
    expect(html).toContain("RevealHighlight");
  });

  it("counts slides correctly for multi-slide fixture", async () => {
    const result = await buildOutput({
      inputPath: join(fixturesDir, "02-multi-slide.md"),
      outputDir,
      themesDir,
    });

    expect(result.slideCount).toBe(3);
  });

  it("copies local images for image fixture", async () => {
    const result = await buildOutput({
      inputPath: join(fixturesDir, "04-images.md"),
      outputDir,
      themesDir,
    });

    expect(result.imagesCopied).toContain("./images/sample.png");
    expect(existsSync(join(outputDir, "images", "sample.png"))).toBe(true);
  });

  it("warns but doesn't fail on missing images", async () => {
    const result = await buildOutput({
      inputPath: join(fixturesDir, "04-images.md"),
      outputDir,
      themesDir,
    });

    // missing-on-purpose.png should NOT be in imagesCopied
    expect(result.imagesCopied).not.toContain("./images/missing-on-purpose.png");
    // But the build should still succeed
    expect(existsSync(join(outputDir, "index.html"))).toBe(true);
  });
});
