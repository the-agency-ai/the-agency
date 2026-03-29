---
name: block-commit-main
enabled: true
event: bash
pattern: git commit
action: warn
---

**You are about to commit.** Before proceeding, verify:

1. You are NOT on the `main` or `master` branch — all changes go through PR branches
2. You are using `./tools/commit` — not bare `git commit`

If you are on main/master, create a branch first:
```bash
git checkout -b {workstream}/{description}
```

Then commit on the branch and create a PR.
