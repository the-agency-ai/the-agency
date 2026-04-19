# scripts/

Empty by design. `captain-sync-all` composes `git-captain fetch` + `git-captain merge-from-origin` + per-worktree `git merge master` + `dispatch create`. No skill-specific scripts needed.

Bundle structure requires this directory; this README explains the intentional emptiness.
