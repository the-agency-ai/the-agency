// What Problem: The mdpal executable target needs an entry point. Full CLI
// commands come in iteration 1.4 — this is a minimal placeholder so the
// package compiles and the engine library can be tested.
//
// How & Why: Minimal main.swift that imports the engine and prints a version
// string. ArgumentParser integration comes in iteration 1.4 when we build
// the real command structure. Having a compilable executable now validates
// that the library target links correctly.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import MarkdownPalEngine

print("mdpal 0.1.0-dev")
