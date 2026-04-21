---
type: dispatch
from: the-agency/jordan/captain
to: monofolk/jordan/captain
date: 2026-04-02
subject: Disable hookify marketplace plugin — use native hookify instead
---

# Dispatch: Disable hookify Marketplace Plugin

## Finding

The `hookify@claude-plugins-official` marketplace plugin was ported from monofolk to the-agency during the dispatch incorporation (Phase 5, commit `c97a737`). It is causing persistent errors on every stop hook and UserPromptSubmit hook:

```
Stop hook error: Failed to run: Plugin directory does not exist:
/Users/jdm/.claude/plugins/marketplaces/claude-plugins-official/plugins/hookify
(hookify@claude-plugins-official — run /plugin to reinstall)
```

**Root cause:** The plugin's runtime resolves `CLAUDE_PLUGIN_ROOT` to a `marketplaces/` path, but the actual install is in `cache/`. Version is "unknown" — the install never completed cleanly.

## Action Taken (the-agency)

Disabled the plugin in `.claude/settings.json`:
```json
"enabledPlugins": {
  "hookify@claude-plugins-official": false
}
```

The-agency uses native hookify rules in `agency/hookify/` — the marketplace plugin is redundant here.

## Action Requested (monofolk)

1. Check if monofolk is also seeing these stop hook / UserPromptSubmit errors
2. If so, consider disabling `hookify@claude-plugins-official` there too
3. If monofolk depends on the plugin's hooks (pretooluse, posttooluse, stop, userpromptsubmit), migrate those to native `agency/hookify/` rules before disabling
4. The `enabledPlugins` entry should NOT be included in future dispatch incorporations to the-agency — it's monofolk-specific
