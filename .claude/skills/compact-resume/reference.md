# compact-resume — unique protocol

This skill has no unique protocol beyond what `required_reading` covers in `SKILL.md`. See:

- `claude/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter shape; `mode: continuation` is what this skill expects to read.
- `claude/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern (skill shells to `claude/tools/session-pickup` per agency#348).

Design detail: the `--from compact` mode of session-pickup deliberately skips worktree-sync and full preflight — `/compact` is in-process, master cannot have moved, and the preflight questions (monitor running? tree clean? handoff loaded?) are already answered by the PAUSE + PICKUP flow itself. `/session-resume` is the fresh-session equivalent that runs the full preflight after `/exit`.
