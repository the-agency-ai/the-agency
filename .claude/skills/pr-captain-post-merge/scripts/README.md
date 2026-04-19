# scripts/

Empty by design. `pr-captain-post-merge` is pure orchestration — it invokes `claude/tools/gh-release`, `claude/tools/git-captain`, `/sync-all` (via Skill tool), and `gh` directly. No skill-specific scripts needed.

If future refinement requires a dedicated release-notes composer or branch-cleanup helper beyond what `claude/tools/gh-release` provides, it would land here.

The v2 bundle-structure requirement says this directory exists even when empty; this README explains why.
