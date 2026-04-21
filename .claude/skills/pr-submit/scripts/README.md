# scripts/

## `pr-submit`

Bash script that runs the preflight and emits the dispatch. Invoked by the skill's Flow (Steps 1–6 map directly to script sections).

### Entry point

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/skills/pr-submit/scripts/pr-submit" --scope "..."
```

The skill's `argument-hint` frontmatter mirrors this CLI.

### What it does

1. Resolves agent identity (`./agency/tools/agent-identity`) — aborts outside an agent worktree
2. Verifies tree clean, branch pushed, origin matches HEAD
3. Computes `./agency/tools/diff-hash --base origin/master --json` for the receipt lookup
4. Globs `agency/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md`, picks most recent if multiple
5. Composes the dispatch body per `../reference.md` schema
6. Emits via `./agency/tools/dispatch create --to <org>/{principal}/captain --type pr-submit --subject "..." --body "..."`
7. Captures and reports the dispatch ID

### Exit codes

- `0` — dispatch sent successfully
- `1` — preflight failed (not in worktree, dirty tree, unpushed, receipt missing, etc.)
- `2` — dispatch emission failed (ISCP tool error)

### Related

- `../SKILL.md` — the skill definition the script implements
- `../reference.md` — dispatch payload schema (protocol v1.0)
- `../examples.md` — happy-path + failure-mode examples

## Why a script, not inline skill instructions

Multiple preflight checks + hash computation + glob lookup + dispatch emission is too much for reliable inline step-by-step execution under varying agent contexts. The script makes the sequence atomic and testable.

## Skill-tools versioning

The `scripts/` directory pattern is part of the v2 bundle structure (see `claude/REFERENCE-SKILL-AUTHORING.md` §5). Each skill gets its own `scripts/` namespace; no global `agency/tools/` collision.
