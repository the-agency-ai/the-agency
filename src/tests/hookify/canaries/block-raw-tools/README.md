# block-raw-tools canaries

These canaries test **`agency/hooks/block-raw-tools.sh`** — the one hook that
actually enforces bash-command discipline at runtime (wired as the
`PreToolUse/Bash` hook in `.claude/settings.json`).

## Why this directory is separate from the DSL rules

`agency/hookify/*.md` looks like a rule engine — each file declares
`event`/`pattern`/`action`. **It is not wired to anything.** The hookify plugin
is disabled (`enabledPlugins."hookify@claude-plugins-official": false`), and no
other code reads those `.md` files at runtime. They are a *specification*, not
enforcement.

The only thing that fires on a real Bash call is `block-raw-tools.sh`, and it
**hardcodes a subset** of the declared rules — and diverges from them (e.g. the
`.md` says `raw-cat` is a `warn`; the hook `block`s it). So these canaries
encode the hook's **empirically-verified** behavior, not the aspirational `.md`
action. Each was confirmed by piping its BODY through the live hook.

Scope of what the hook enforces (verified 2026-08-14, #144 Phase 1):

| Command | Decision |
|---|---|
| `cat`, `sed`/`awk`, `head`/`tail` | block (→ Read/Edit tools) |
| any `git …` (incl. `git status`) | block (→ git-safe family) |
| `gh pr merge`, `gh release create` | block (→ pr-merge / gh-release) |
| `grep`/`find` | block **only if** `ugrep`/`bfs` on PATH; else allow |
| `./agency/tools/…` prefix | allow (framework-tool exemption) |
| `AGENCY_ALLOW_RAW=1` | allow (explicit opt-out) |
| `cp`, `gh pr create`, compound `&&`, `cd` outside worktree, `brew install` | **NOT enforced** — declared in `.md`, dead at runtime |

The "NOT enforced" row is the known gap. It is deliberately **not** canaried
here as `allow` (that would bless the gap). Closing it — wiring the wanted
rules into the hook, marking the rest spec-only — is #144 Phase 2.

### Known hook limitations (documented, not canaried)

- **Leading-token matching only.** Every block anchors on `^cmd[[:space:]]`
  against the whitespace-trimmed command, so a blocked verb that is not the
  first token slips through: `foo && cat bar`, `echo x | cat`, `cd /tmp; git
  status` all fall through to allow. This is distinct from the (disconnected)
  compound-bash `.md` rule. Deliberately **not** canaried as `allow` — pinning
  it would read as endorsement. A future fix should make this a visible,
  intentional behavior change.
- **`warn` is not producible.** The hook only ever emits `block` (exit 2) or
  `{}` (exit 0). Canaries therefore support only `block`/`allow`. A `warn` tier
  is #144 Phase 2 and will need a third schema arm + exit convention.

### Coverage notes

The `git-captain` **authorization** gate (captain-only) is covered via
`cwd: isolated` — the hook resolves `./agency/tools/agent-identity` relative to
cwd, so from an isolated dir identity is not `captain` and the gate fires. Note
`./agency/tools/git-captain …` can *never* reach that gate (the `./agency/tools/`
exemption pre-empts it); only bare `git-captain …` can. Grep-family aliases
(`rg`/`egrep`/`fgrep`), `gawk`, bare-word forms, the `$CLAUDE_PROJECT_DIR`
exemption, and over-block guards (`npm`/`python3`/`curl` must stay allowed) each
have canaries. The harness's own malformed-fixture rejection is tested by the
`harness rejects …` meta-tests in `../../block-raw-tools.bats`.

## Canary schema

```
rule:              informational label
expected_decision: block | allow            (required)
expected_match:    substring of block reason (required when block)
path_mode:         default | stubbed | bare  (optional; default 'default')
                     stubbed → ugrep+bfs stubbed onto PATH (auto-detect fires)
                     bare    → PATH without ugrep/bfs (auto-detect falls through)
env:               extra VAR=VALUE for the hook process (optional)
---BODY---
<the command string fed as tool_input.command>
```

Drop a new `.canary` file here and `../../block-raw-tools.bats` covers it
automatically. Run: `bats src/tests/hookify/` or `test-run --suite hookify`.
