# compact-prepare — unique protocol

This skill has no unique protocol beyond what `required_reading` covers in `SKILL.md`. See:

- `claude/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter shape, `mode: continuation` requirement.
- `claude/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern (skill shells to `claude/tools/session-pause`).

MAR R3 note: Step 3.1a in `SKILL.md` is a workaround for the-agency#355 (handoff must force-commit). When #355 lands upstream, that step moves into the `session-pause` tool and this skill drops its Step 1. See `usr/jordan/captain/session-lifecycle-refactor/plan.md` HG-7.
