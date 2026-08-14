# src/tests/hookify — enforcement-hook tests

Tests for the framework's **live** command-enforcement hooks. Today that is one
hook: `agency/hooks/block-raw-tools.sh`, wired as the `PreToolUse/Bash` hook in
`.claude/settings.json`. It fires on every Bash tool call across every captain
and worktree agent, so a regression here silently blocks — or wrongly frees —
the entire fleet.

Run: `bats src/tests/hookify/` or `./agency/tools/test-run --suite hookify`.

## Why this suite does NOT use `test_helper.bash`

`src/tests/tools/test_helper.bash` couples every test to the git/ISCP isolation
machinery (`test_isolation_setup`/`test_isolation_teardown`). The hook tests
never touch git state or the ISCP DB — they pipe JSON to a hook and read its
decision — so pulling in that weight would be the wrong kind of DRY. Instead the
`.bats` files here compute `REPO_ROOT` inline with the same formula the helper
uses (`dirname` of the test dir, up two). This is a **deliberate, documented
convention for this subtree** — not an oversight. New test files under
`src/tests/hookify/` should follow it (inline `REPOROOT`, no `load 'test_helper'`)
unless they genuinely need git isolation. The tradeoff: no `assert_*` helpers
here; assertions are plain `[ ]`/`[[ ]]`.

Fragility to know about: the inline `REPO_ROOT` formula assumes this directory is
exactly two levels under the repo root (`src/tests/hookify`). If the suite is
ever nested deeper, update the formula. (`test_helper.bash` has the identical
assumption.)

## Why we test the hook, not the `.md` DSL

`agency/hookify/*.md` looks like a rule engine (`event`/`pattern`/`action`), but
the hookify plugin is **disabled** (`enabledPlugins."hookify@claude-plugins-official": false`)
and nothing reads those files at runtime. They are a *specification*, not
enforcement. The only thing that fires is `block-raw-tools.sh`, which hardcodes a
subset of the declared rules and diverges from them. So the canaries encode the
hook's **empirically-verified** behavior, not the aspirational `.md` action. See
`canaries/block-raw-tools/README.md` for the per-rule map and the known
enforcement gaps (`cp`, `gh pr create`, compound `&&`, …) that #144 Phase 2 will
resolve.

## The `agency/` vs `src/agency/` copy

The tests target `agency/hooks/block-raw-tools.sh` — the copy actually wired to
`.claude/settings.json`, which is correct. Note the repo also keeps a byte-identical
`src/agency/hooks/block-raw-tools.sh` payload copy. As of this suite they are in
sync; if the `src/`-as-source-of-truth migration makes `src/` canonical, edits
landing in `src/agency/` alone would desync from the enforced copy and this suite
would not catch it. Tracked via flag (see #144 Phase 1 notes).

## Canary schema

See `canaries/block-raw-tools/README.md`. The harness (`block-raw-tools.bats`) is
data-driven: drop a `.canary` file and it is covered automatically. The harness's
own well-formedness validation is itself tested by the `harness rejects …`
meta-tests in that `.bats` file.
