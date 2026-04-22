---
name: block-raw-gh-release
enabled: true
event: bash
pattern: 'gh release create'
action: block
---

🚫 BLOCKED: Raw `gh release create` is not allowed. Use `./agency/tools/gh-release` (direct) or `./agency/tools/release` (full workflow), or invoke `/post-merge` which handles release creation after PR merge.

Why: releases are framework boundaries — version must match `agency/config/manifest.json`, notes must follow the D{day}-R{release} format, target must be verified. Captain shipped v42.1 on Day 42 by reaching for raw `gh release create` after pr-merge instead of `/post-merge`. Route through the tools that exist.

Safe paths:
  ./agency/tools/gh-release create v<version> --notes "..."   # direct wrapper (logged)
  ./agency/tools/release ...                                   # full workflow (tag + changelog + gh release)
  /post-merge <PR>                                             # post-PR-merge release creation in one pass

Skill: /post-merge, /release

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
