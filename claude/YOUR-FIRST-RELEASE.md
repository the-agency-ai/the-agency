# Your First Release

This guide walks you through making a code change and shipping it as a PR — from first edit to merged release. It uses The Agency's safe tools throughout. Every step has a reason.

## Before You Start

You need:
- A work item ID (e.g., `REQUEST-jordan-0065`, `TASK-devex-007`) — or use `--no-work-item` for maintenance changes
- The right branch (not main)
- A clean working tree

If you are just starting: `./claude/tools/git-captain checkout-branch feat/my-change`

---

## Step 1 — Make Your Code Change

Edit files normally using the Edit or Write tools. When you are done, verify the state of the working tree:

```bash
./claude/tools/git-safe status
./claude/tools/git-safe diff
```

---

## Step 2 — Stage Your Files

Stage explicit file paths. Do not use `git add -A` or `git add .` — hookify blocks these, and they risk staging secrets or generated files.

```bash
./claude/tools/git-safe add claude/tools/my-tool
./claude/tools/git-safe add claude/docs/my-doc.md
```

Stage each file by name. For multiple files, list them all in one call or call `git-safe add` once per file.

**Common pitfall:** Passing a directory path (e.g., `git-safe add claude/tools/`) is blocked. Always use individual file paths.

---

## Step 3 — Commit

Use the commit tool with a work item reference:

```bash
./claude/tools/git-safe-commit "add my-tool with worktree boundary check" \
  --work-item TASK-devex-007 \
  --stage impl
```

For a change with no work item (housekeeping, doc fix):

```bash
./claude/tools/git-safe-commit "fix typo in README" --no-work-item
```

The tool builds a structured commit message, adds per-agent attribution trailers, and dispatches a notification to captain. You do not write the commit message format by hand.

Alternatively, use `/iteration-complete` from the skills interface — it runs the commit tool and a lightweight quality check together.

**Common pitfall:** Raw `git commit` is blocked by hookify. The error message will tell you to use `git-safe-commit` instead.

---

## Step 4 — Run the Quality Gate

Before creating a PR, you need a Quality Gate Receipt (QGR). This is a signed record that a multi-agent review ran against the current state of your code.

```
/quality-gate
```

Or via the pre-PR skill (preferred — it also runs tests):

```
/pr-prep
```

The quality gate runs parallel agent reviews covering logic, security, tests, and conventions. When it passes it writes a receipt to `claude/receipts/`.

**Common pitfall:** Skipping the quality gate. The `pr-create` tool will block you at step 9 if no valid receipt exists.

---

## Step 5 — Verify the Receipt

Confirm the receipt is valid before proceeding:

```bash
./claude/tools/receipt-verify
```

Exit 0 means the receipt is current and the hash matches the code state. Exit 1 means the receipt is stale or missing — run `/pr-prep` again.

**Common pitfall:** Making code changes after running the quality gate. Any change after the QG produces a stale receipt. Verify first, then do not touch the code.

---

## Step 6 — Create Your PR Branch (if not already on one)

If you committed directly on main (don't — but if you did), or if you need a fresh branch:

```bash
./claude/tools/git-captain checkout-branch feat/my-change
```

Branch names must be lowercase and match `[a-z0-9][a-z0-9._/-]*`. No uppercase, no leading hyphens.

**Common pitfall:** The branch already exists. Use `git-captain switch-branch <name>` to switch to an existing branch, not `checkout-branch`.

---

## Step 7 — Bump the Version

Every PR is a release. Update `claude/config/manifest.json`:

- Increment `agency_version` (e.g., `40.1` → `40.2`)
- Update `updated_at` to today's date

```bash
# Edit the manifest, then stage and commit it
./claude/tools/git-safe add claude/config/manifest.json
./claude/tools/git-safe-commit "bump version to 40.2" --no-work-item
```

The `/release` skill handles version bumping automatically. If you use `/release`, skip this step — it does it for you.

**Common pitfall:** Forgetting the version bump. `pr-create` checks that `manifest.json` differs from `origin/main` and will block you with a clear error message if it has not changed.

---

## Step 8 — Push the Branch

```bash
./claude/tools/git-push feat/my-change
```

Or simply:

```bash
./claude/tools/git-push
```

(Defaults to the current branch.) The tool sets upstream (`-u`) automatically. Use `--force-with-lease` if you need to update an already-pushed branch after a rebase-equivalent merge.

**Common pitfall:** Pushing to main. `git-push` blocks this. All changes reach main through PRs.

---

## Step 9 — Create the PR

```bash
./claude/tools/pr-create \
  --title "feat: add my-tool with worktree boundary check" \
  --body "$(cat <<'EOF'
## Summary
- Adds my-tool with X guard
- Blocks Y pattern

## Test plan
- [ ] bats tests/tools/my-tool.bats passes
- [ ] Verified on dirty-tree edge case

🤖 Generated with Claude Code
EOF
)"
```

`pr-create` runs three pre-flight checks before calling `gh pr create`:
1. You are on a branch (not main)
2. A valid receipt exists in `claude/receipts/`
3. `manifest.json` was bumped relative to `origin/main`

If any check fails, the tool exits with a clear message explaining what to fix.

**Common pitfall:** Raw `gh pr create` is blocked by hookify. Use `pr-create` or the `/release` skill.

---

## Step 10 — CI Runs

GitHub Actions runs the smoke test suite on your PR. The workflow is visible in the PR checks panel. You can monitor it with:

```
/monitor-ci
```

Wait for CI to go green before expecting a review. A red check means something is broken — fix it, push again, receipt-verify again.

---

## Step 11 — Wait for Principal Approval

Main has branch protection enabled. A principal must approve the PR before it can be merged. Do not merge your own PR. If the review takes time, address any review comments with additional commits on the branch.

After addressing comments: re-run `/pr-prep` to get a fresh receipt, push the updated branch, and update the PR.

---

## Step 12 — After Merge

Once the PR is merged on GitHub, run:

```
/post-merge
```

This verifies the merge happened, merges origin/main into your local main, and creates a GitHub release tag matching the version in `manifest.json`. It also cleans up the local branch if requested.

---

## Common Pitfalls Summary

| Pitfall | What happens | Fix |
|---|---|---|
| Forgetting version bump | `pr-create` blocks at step 9 | Update `manifest.json`, commit, push |
| Stale receipt | `pr-create` blocks at step 9 | Run `/pr-prep` again, do not change code after |
| Raw `git commit` | Hookify blocks it | Use `./claude/tools/git-safe-commit` |
| Raw `git push` | Hookify blocks it | Use `./claude/tools/git-push` |
| Raw `gh pr create` | Hookify blocks it | Use `./claude/tools/pr-create` |
| `git add .` or `git add -A` | Hookify blocks it | Use `./claude/tools/git-safe add <files>` |
| Pushing to main directly | `git-push` blocks it | Create a branch, use PR flow |
| Cross-worktree cp | `cp-safe` blocks it | Use `/worktree-sync` |
| QG after code change | Receipt becomes stale | Always QG last, before PR |

---

## The Fast Path: `/release`

If you want all of steps 4–9 handled automatically:

```
/release
```

The release skill runs `/pr-prep` (quality gate + tests), bumps the version, commits, pushes, and calls `pr-create`. Use it once you are comfortable with what each step does individually.

---

## Reference

- Safe tools full spec: `claude/REFERENCE-SAFE-TOOLS.md`
- Safe tools overview: `claude/README-SAFE-TOOLS.md`
- Receipt infrastructure: `claude/README-RECEIPT-INFRASTRUCTURE.md`
- Quality gate protocol: `claude/docs/QUALITY-GATE.md`
- Git discipline: `claude/docs/GIT-MERGE-NOT-REBASE.md`
