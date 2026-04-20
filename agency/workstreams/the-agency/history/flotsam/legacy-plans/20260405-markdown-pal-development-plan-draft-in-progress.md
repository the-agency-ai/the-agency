---
title: "Markdown Pal — Development Plan (DRAFT IN PROGRESS)"
slug: markdown-pal-development-plan-draft-in-progress
path: docs/plans/20260405-markdown-pal-development-plan-draft-in-progress.md
date: 2026-04-05
status: draft
branch: mdpal
worktree: mdpal
prototype: mdpal
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ac938883-a8cd-4d17-9006-54a052802d66
tags: [Backend, Frontend, Infra]
---

# Markdown Pal — Development Plan (DRAFT IN PROGRESS)

**Status:** Research phase — exploration complete, plan structure not yet drafted
**Date:** 2026-04-05
**PVR:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` (final)
**A&D:** `usr/jordan/mdpal/ad-mdpal-20260404.md` (revised, MAR round 2 complete)

## Context

Building the mdpal engine + CLI. Phase 1 is collaborative with mdpal-app. The A&D defines 16 sections covering parser protocol, engine API, CLI commands, bundle ops, testing strategy, and phase sequencing. All 8 /discuss items resolved. MAR round 2 complete with 8 findings fixed, 3 open (working copy: resolved, serialize: resolved, captain worktree model: awaiting response).

## Research Complete — Ready to Draft

Exploration agents gathered:
- All Swift types (Document, DocumentParser, SectionTree, SectionNode, DocumentBundle, etc.)
- All 17 CLI commands
- Phase sequencing (§15): 3 phases, collaborative Phase 1
- Testing strategy (§14): 5 layers, coverage targets, QG discipline
- Package structure (§10.2): independent packages in monorepo
- Technology choices: swift-markdown, swift-argument-parser, Yams
- Plan format conventions: phases with numbered iterations, slug identifiers, QGRs appended

## Next Step

Draft the full plan with Phase 1 iterations, then run MAR before presenting to Jordan.
