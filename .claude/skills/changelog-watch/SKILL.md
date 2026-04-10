# Changelog Watch

Monitor Claude Code's changelog for new releases and features. Uses the Monitor tool to stream updates as they land.

## When to use

- At session start for continuous awareness of Claude Code changes
- When you want to know about new features, breaking changes, or opportunities
- Pairs with dispatch-monitor for full situational awareness

## Instructions

### Start watching

Use the Monitor tool to run the changelog-monitor script in the background:

```
Monitor the Claude Code changelog for new releases. Run ./claude/tools/changelog-monitor in the background. When a new version is detected, summarize what changed and flag anything relevant to our workflow.
```

The script:
- Polls the raw CHANGELOG.md from GitHub every 30 minutes (configurable with `--interval N`)
- Only outputs when the changelog has actually changed (silent otherwise)
- Extracts the latest entry automatically
- State persisted in `~/.agency/changelog-monitor/` (survives session restarts)

### When output arrives

1. Read the changelog entry
2. Evaluate relevance to TheAgency:
   - New tools or features we should adopt?
   - Breaking changes that affect our hooks/tools?
   - Performance improvements we benefit from?
   - Bug fixes for issues we've reported?
3. If relevant: flag it to the principal, capture a seed if it warrants adoption
4. If not relevant: note it silently, no output needed

### Example discoveries this pattern would catch

- Monitor tool (v2.1.98) — we adopted it within minutes of discovery
- Remote Control improvements
- Hook lifecycle changes
- New MCP capabilities
- Token pricing changes

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
