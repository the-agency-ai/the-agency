// What Problem: Test coverage for image asset scanning and copying,
// including path traversal protection and image ref title text handling.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1 (QG coverage)

import { describe, it, expect } from "vitest";
import { findImageRefs, copyImages } from "../src/assets.js";
import { mkdtempSync, writeFileSync, mkdirSync, existsSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";

describe("findImageRefs", () => {
  it("finds markdown image references", () => {
    const md = "![alt](./images/photo.png)\n![other](pic.jpg)";
    const refs = findImageRefs(md, "/tmp");
    expect(refs).toEqual(["./images/photo.png", "pic.jpg"]);
  });

  it("skips remote URLs", () => {
    const md = "![remote](https://example.com/img.png)\n![data](data:image/png;base64,abc)";
    const refs = findImageRefs(md, "/tmp");
    expect(refs).toEqual([]);
  });

  it("handles image refs with title text", () => {
    const md = '![alt](./photo.png "A nice photo")';
    const refs = findImageRefs(md, "/tmp");
    expect(refs).toEqual(["./photo.png"]);
  });

  it("handles multiple images on one line", () => {
    const md = "![a](one.png) text ![b](two.png)";
    const refs = findImageRefs(md, "/tmp");
    expect(refs).toEqual(["one.png", "two.png"]);
  });
});

describe("copyImages — path traversal protection", () => {
  it("rejects absolute paths", async () => {
    const srcDir = mkdtempSync(join(tmpdir(), "mdslidepal-test-"));
    const outDir = mkdtempSync(join(tmpdir(), "mdslidepal-out-"));
    writeFileSync(join(srcDir, "test.md"), "![img](/etc/passwd)");
    const result = await copyImages(["/etc/passwd"], srcDir, outDir);
    expect(result).toEqual([]);
  });

  it("rejects path traversal with ../", async () => {
    const srcDir = mkdtempSync(join(tmpdir(), "mdslidepal-test-"));
    const outDir = mkdtempSync(join(tmpdir(), "mdslidepal-out-"));
    const result = await copyImages(["../../../etc/passwd"], srcDir, outDir);
    expect(result).toEqual([]);
  });

  it("copies valid local images", async () => {
    const srcDir = mkdtempSync(join(tmpdir(), "mdslidepal-test-"));
    const outDir = mkdtempSync(join(tmpdir(), "mdslidepal-out-"));
    mkdirSync(join(srcDir, "images"), { recursive: true });
    writeFileSync(join(srcDir, "images", "logo.png"), "fake-png");
    const result = await copyImages(["images/logo.png"], srcDir, outDir);
    expect(result).toEqual(["images/logo.png"]);
    expect(existsSync(join(outDir, "images", "logo.png"))).toBe(true);
  });
});
