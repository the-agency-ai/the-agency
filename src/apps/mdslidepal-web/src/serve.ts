// What Problem: The "serve" verb needs to build the output directory, start
// a local HTTP server on it, and open the browser. This is the core user
// experience — one command to go from markdown to slides in the browser.
//
// How & Why: Uses `sirv` for zero-config static file serving (handles MIME
// types correctly, ~15kB) and `open` for cross-platform browser launching.
// Port auto-increment on EADDRINUSE so multiple decks can run simultaneously.
// The server binds to 127.0.0.1 (localhost only — no network exposure).
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { randomBytes } from "node:crypto";
import sirv from "sirv";
import open from "open";
import { buildOutput } from "./build.js";

export interface ServeOptions {
  inputPath: string;
  port?: number;
  themeName?: string;
  themesDir?: string;
}

/**
 * Build and serve a markdown slide deck.
 * Blocks until the process is terminated (Ctrl+C).
 */
export async function serve(options: ServeOptions): Promise<void> {
  const { inputPath, port = 8000, themeName, themesDir } = options;

  // Create a unique temp output directory
  const hash = randomBytes(4).toString("hex");
  const outputDir = join(tmpdir(), `mdslidepal-${hash}`);

  console.error(`[mdslidepal] Building slides from: ${inputPath}`);

  const result = await buildOutput({
    inputPath,
    outputDir,
    themeName,
    themesDir,
  });

  console.error(`[mdslidepal] Output: ${result.outputDir}`);
  console.error(`[mdslidepal] Slides: ~${result.slideCount}`);
  if (result.imagesCopied.length > 0) {
    console.error(`[mdslidepal] Images: ${result.imagesCopied.length} copied`);
  }

  // Start the server
  const handler = sirv(result.outputDir, { dev: true, single: false });
  const server = createServer(handler);

  const actualPort = await listen(server, port);
  const url = `http://127.0.0.1:${actualPort}/index.html`;

  console.error(`[mdslidepal] Serving at: ${url}`);
  console.error(`[mdslidepal] Press Ctrl+C to stop`);

  // Open browser
  await open(url);

  // Keep alive until Ctrl+C
  await new Promise<void>((resolve) => {
    process.on("SIGINT", () => {
      console.error("\n[mdslidepal] Shutting down...");
      server.close(() => resolve());
    });
    process.on("SIGTERM", () => {
      server.close(() => resolve());
    });
  });
}

/**
 * Try to listen on the given port, auto-incrementing up to 10 times on conflict.
 */
async function listen(
  server: ReturnType<typeof createServer>,
  startPort: number
): Promise<number> {
  const maxAttempts = 10;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const port = startPort + attempt;
    try {
      await new Promise<void>((resolve, reject) => {
        server.once("error", reject);
        server.listen(port, "127.0.0.1", () => {
          server.removeListener("error", reject);
          resolve();
        });
      });
      return port;
    } catch (err: unknown) {
      if ((err as NodeJS.ErrnoException).code === "EADDRINUSE") {
        if (attempt < maxAttempts - 1) {
          console.error(`[mdslidepal] Port ${port} in use, trying ${port + 1}...`);
          continue;
        }
      }
      throw err;
    }
  }

  throw new Error(`Could not find an available port (tried ${startPort}-${startPort + maxAttempts - 1})`);
}
