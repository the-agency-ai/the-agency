// What Problem: Verify the pre-processor correctly handles edge cases
// from fixture 08 — trailing separators are stripped, code blocks are
// preserved, adjacent separators remain (reveal.js handles them correctly).
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { describe, it, expect } from "vitest";
import { preprocessMarkdown } from "../src/preprocess.js";

describe("preprocessMarkdown", () => {
  it("strips trailing --- at end of file", () => {
    const input = "# Slide 1\n\n---\n\n# Slide 2\n\n---";
    const result = preprocessMarkdown(input);
    expect(result.trimEnd()).toBe("# Slide 1\n\n---\n\n# Slide 2");
    expect(result).not.toMatch(/---\s*$/);
  });

  it("strips trailing --- with trailing whitespace", () => {
    const input = "# Slide 1\n\n---\n\n# Slide 2\n\n---\n  \n";
    const result = preprocessMarkdown(input);
    expect(result.trimEnd()).toBe("# Slide 1\n\n---\n\n# Slide 2");
    expect(result).not.toMatch(/---\s*$/);
  });

  it("strips multiple trailing separators", () => {
    const input = "# Slide 1\n\n---\n\n---";
    const result = preprocessMarkdown(input);
    expect(result.trimEnd()).toBe("# Slide 1");
    expect(result).not.toMatch(/---\s*$/);
  });

  it("does not modify content without trailing separator", () => {
    const input = "# Slide 1\n\n---\n\n# Slide 2\n";
    const result = preprocessMarkdown(input);
    expect(result).toBe(input);
  });

  it("preserves --- inside fenced code blocks", () => {
    const input = "# Slide 1\n\n```yaml\n---\ntitle: test\n---\n```\n";
    const result = preprocessMarkdown(input);
    expect(result).toContain("---\ntitle: test\n---");
  });

  it("preserves adjacent separators (reveal.js handles them correctly)", () => {
    const input = "# Slide 1\n\n---\n\n---\n\n# Slide 2";
    const result = preprocessMarkdown(input);
    // Adjacent separators stay — reveal.js naturally produces one empty slide
    expect(result).toContain("\n---\n\n---\n");
  });
});

describe("SmartyPants", () => {
  it("converts straight double quotes to curly quotes", () => {
    const result = preprocessMarkdown('He said "hello" to her.');
    expect(result).toContain("\u201C");
    expect(result).toContain("\u201D");
    expect(result).not.toContain('"hello"');
  });

  it("converts apostrophes in contractions", () => {
    const result = preprocessMarkdown("It's a beautiful day, isn't it?");
    expect(result).toContain("It\u2019s");
    expect(result).toContain("isn\u2019t");
  });

  it("converts -- to em dash", () => {
    const result = preprocessMarkdown("one -- two");
    expect(result).toContain("\u2014");
    expect(result).not.toContain("--");
  });

  it("converts ... to ellipsis", () => {
    const result = preprocessMarkdown("Wait for it...");
    expect(result).toContain("\u2026");
    expect(result).not.toContain("...");
  });

  it("does NOT apply SmartyPants inside fenced code blocks", () => {
    const input = '```js\nconst x = "hello";\n```';
    const result = preprocessMarkdown(input);
    expect(result).toContain('"hello"');
  });

  it("does NOT apply SmartyPants inside inline code", () => {
    const input = "Run `echo \"hello\"` to test.";
    const result = preprocessMarkdown(input);
    expect(result).toContain('`echo "hello"`');
  });

  it("preserves table separator rows", () => {
    const input = "| A | B |\n|---|---|\n| 1 | 2 |";
    const result = preprocessMarkdown(input);
    expect(result).toContain("|---|---|");
  });

  it("preserves slide break separators", () => {
    const input = "# Slide 1\n\n---\n\n# Slide 2";
    const result = preprocessMarkdown(input);
    expect(result).toContain("\n---\n");
  });
});
