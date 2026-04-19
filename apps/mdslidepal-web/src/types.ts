// What Problem: We need a TypeScript type that mirrors the shared theme JSON
// schema at agency/workstreams/mdslidepal/themes/theme-schema.json, so the
// theme loader and CSS emitter can work with typed data.
//
// How & Why: A structural interface that matches the JSON shape. No runtime
// validation in Iteration 1 — structural typing catches shape mismatches at
// compile time. Full JSON Schema validation deferred to Phase 2.
//
// Written: 2026-04-12 during mdslidepal-web Iteration 1

export interface ThemeColors {
  background: string;
  foreground: string;
  accent: string;
  muted: string;
  subtle: string;
  border: string;
  link: string;
  code_background: string;
  code_border: string;
}

export interface ThemeFonts {
  sans_family: string;
  mono_family: string;
  display_family: string;
}

export interface HeadingScale {
  h1: number;
  h2: number;
  h3: number;
  h4: number;
  h5: number;
  h6: number;
}

export interface SlidePadding {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export interface CodeTheme {
  background: string;
  foreground: string;
  comment: string;
  keyword: string;
  string: string;
  number: string;
  function: string;
  variable: string;
  type: string;
  operator: string;
  punctuation: string;
}

export interface ThemeTransitions {
  default: string;
  fade_duration_ms: number;
  fade_easing: string;
}

export interface LogicalDimensions {
  width: number;
  height: number;
}

export interface Theme {
  $schema?: string;
  name: string;
  version: string;
  description: string;
  aspect_ratio: string;
  logical_dimensions: LogicalDimensions;
  colors: ThemeColors;
  fonts: ThemeFonts;
  heading_scale: HeadingScale;
  body_size: number;
  line_height: number;
  spacing_unit: number;
  slide_padding: SlidePadding;
  code_theme: CodeTheme;
  transitions: ThemeTransitions;
}
