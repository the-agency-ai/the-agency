# scripts/

Empty by design. This skill is pure orchestration — it invokes `claude/tools/pr-merge` directly and handles the agent-side workflow around it. No skill-specific scripts needed.

If future refinement requires a dedicated preflight or post-merge helper (beyond what `claude/tools/pr-merge` handles), it would land here.

The v2 bundle-structure requirement says this directory exists even when empty; this README explains why.
