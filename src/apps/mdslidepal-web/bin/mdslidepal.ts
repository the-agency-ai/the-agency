#!/usr/bin/env node

// What Problem: The CLI entry point for mdslidepal. Parses argv for the
// "serve" verb, one positional argument (markdown file path), and --port flag.
// This is deliberately minimal — raw process.argv, no CLI framework.
//
// How & Why: Only one verb (serve), one positional (input file), one flag
// (--port). A commander/yargs dependency would add bundle weight for no
// benefit. ~30 lines of parsing. Exits non-zero with a clear message on
// bad input (contract §11).
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { serve } from "../src/serve.js";

const args = process.argv.slice(2);

function printUsage(): void {
  console.error("Usage: mdslidepal serve <input.md> [--port <n>]");
  console.error("");
  console.error("  serve <input.md>    Build and serve a markdown slide deck");
  console.error("  --port <n>          Port number (default: 8000)");
}

if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
  printUsage();
  process.exit(0);
}

const verb = args[0];
if (verb !== "serve") {
  console.error(`[mdslidepal] Unknown command: ${verb}`);
  printUsage();
  process.exit(1);
}

// Parse remaining args
let inputPath: string | undefined;
let port: number | undefined;

for (let i = 1; i < args.length; i++) {
  const arg = args[i]!;
  if (arg === "--port") {
    const portStr = args[++i];
    if (!portStr) {
      console.error("[mdslidepal] --port requires a number");
      process.exit(1);
    }
    port = parseInt(portStr, 10);
    if (isNaN(port) || port < 1 || port > 65535) {
      console.error(`[mdslidepal] Invalid port: ${portStr}`);
      process.exit(1);
    }
  } else if (!arg.startsWith("--")) {
    inputPath = arg;
  } else {
    console.error(`[mdslidepal] Unknown flag: ${arg}`);
    printUsage();
    process.exit(1);
  }
}

if (!inputPath) {
  console.error("[mdslidepal] Missing input file");
  printUsage();
  process.exit(1);
}

const resolvedPath = resolve(inputPath);

if (!existsSync(resolvedPath)) {
  console.error(`[mdslidepal] File not found: ${inputPath}`);
  process.exit(1);
}

serve({
  inputPath: resolvedPath,
  port,
}).catch((err: Error) => {
  console.error(`[mdslidepal] Fatal: ${err.message}`);
  process.exit(1);
});
