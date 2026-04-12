// What Problem: Test coverage for HTML template generation,
// including XSS prevention and attribute escaping.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1 (QG coverage)

import { describe, it, expect } from "vitest";
import { renderTemplate } from "../src/template.js";

const defaultParams = {
  title: "Test Deck",
  themeCssHref: "./theme.css",
  deckMdHref: "./deck.md",
  revealJsPath: "./reveal.js",
};

describe("renderTemplate", () => {
  it("generates valid HTML with required elements", () => {
    const html = renderTemplate(defaultParams);
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("<title>Test Deck</title>");
    expect(html).toContain('data-markdown="./deck.md"');
    expect(html).toContain("RevealMarkdown");
    expect(html).toContain("RevealHighlight");
  });

  it("escapes title with special HTML characters", () => {
    const html = renderTemplate({
      ...defaultParams,
      title: '<script>alert("xss")</script>',
    });
    expect(html).toContain("&lt;script&gt;");
    expect(html).not.toContain("<script>alert");
  });

  it("escapes single quotes in title", () => {
    const html = renderTemplate({
      ...defaultParams,
      title: "It's a test",
    });
    expect(html).toContain("It&#39;s a test");
  });

  it("uses custom width and height", () => {
    const html = renderTemplate({
      ...defaultParams,
      width: 1280,
      height: 720,
    });
    expect(html).toContain("width: 1280");
    expect(html).toContain("height: 720");
  });

  it("defaults to 1920x1080 when dimensions not specified", () => {
    const html = renderTemplate(defaultParams);
    expect(html).toContain("width: 1920");
    expect(html).toContain("height: 1080");
  });

  it("includes slide counter", () => {
    const html = renderTemplate(defaultParams);
    expect(html).toContain("slide-counter");
  });
});
