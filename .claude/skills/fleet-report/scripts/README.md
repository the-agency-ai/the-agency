# scripts/

This skill is pure orchestration — it invokes existing framework tools via the Bash tool:

- `./claude/tools/agency-health`
- `./claude/tools/dispatch`
- `./claude/tools/flag`
- `./claude/tools/collaboration`
- `./claude/tools/git-safe`
- `gh pr list`

No skill-specific scripts are needed. Directory preserved for bundle-structure consistency per v2 methodology (REFERENCE-SKILL-AUTHORING.md §1 "Full bundle structure — always").

If aggregation logic grows complex enough to warrant extraction (e.g., the human-mode composer becomes > 50 lines of bash inside the skill body), that code would land here as `compose-report.sh`. Until then: empty.
