// What Problem: Verify that the theme loader reads agency-default.json and
// themeToCss produces valid CSS with the expected custom properties.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { describe, it, expect } from "vitest";
import { loadTheme, themeToCss } from "../src/theme.js";
import { resolve } from "node:path";

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

describe("loadTheme", () => {
  it("loads agency-default theme", async () => {
    const theme = await loadTheme("agency-default", themesDir);
    expect(theme.name).toBe("agency-default");
    expect(theme.version).toBe("0.1.0");
    expect(theme.colors.background).toBe("#ffffff");
    expect(theme.colors.foreground).toBe("#1a1a1a");
    expect(theme.colors.link).toBe("#0066cc");
    expect(theme.fonts.sans_family).toContain("system-ui");
  });

  it("throws on missing theme", async () => {
    await expect(loadTheme("nonexistent", themesDir)).rejects.toThrow();
  });
});

describe("themeToCss", () => {
  it("emits reveal.js custom properties", async () => {
    const theme = await loadTheme("agency-default", themesDir);
    const css = themeToCss(theme);

    expect(css).toContain("--r-main-color: #1a1a1a");
    expect(css).toContain("--r-heading-color: #1a1a1a");
    expect(css).toContain("--r-link-color: #0066cc");
    expect(css).toContain("--r-background-color: #ffffff");
    expect(css).toContain("--r-main-font: system-ui");
  });

  it("emits mdslidepal-scoped variables", async () => {
    const theme = await loadTheme("agency-default", themesDir);
    const css = themeToCss(theme);

    expect(css).toContain("--mdp-code-bg: #f5f5f5");
    expect(css).toContain("--mdp-border: #dddddd");
    expect(css).toContain("--mdp-accent: #0066cc");
  });

  it("emits heading sizes", async () => {
    const theme = await loadTheme("agency-default", themesDir);
    const css = themeToCss(theme);

    expect(css).toContain(".reveal h1 { font-size: 72px; }");
    expect(css).toContain(".reveal h2 { font-size: 56px; }");
    expect(css).toContain(".reveal h3 { font-size: 44px; }");
  });

  it("emits slide padding", async () => {
    const theme = await loadTheme("agency-default", themesDir);
    const css = themeToCss(theme);

    expect(css).toContain("padding: 96px 120px 96px 120px");
  });
});
