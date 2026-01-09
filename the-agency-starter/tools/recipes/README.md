# Recipes

Patterns and tools adapted from [Anthropic's Claude Cookbooks](https://github.com/anthropics/anthropic-cookbook).

## What are Recipes?

Recipes are reusable patterns for working with Claude that go beyond simple tool usage. They're based on proven techniques from Anthropic's official cookbook.

## Structure

```
tools/recipes/
├── README.md                    # This file
├── context-compaction/          # Auto-summarize long sessions (58% token savings)
├── tool-search/                 # Semantic tool discovery (90% context reduction)
├── batch-processing/            # Background processing (50% cheaper)
└── prompt-caching/              # Cache agent.md/KNOWLEDGE (2x faster, 90% cheaper)
```

## Available Recipes

| Recipe | Benefit | Status |
|--------|---------|--------|
| context-compaction | 58% token savings | planned |
| tool-search | 90% context reduction for large toolsets | planned |
| batch-processing | 50% cheaper background jobs | planned |
| prompt-caching | 2x faster, 90% cheaper with caching | planned |

## Attribution

These recipes are adapted from Anthropic's Apache 2.0 licensed cookbooks:
- [Anthropic Cookbook](https://github.com/anthropics/anthropic-cookbook)

When adapting a recipe, include attribution in the file header:

```bash
# Adapted from: https://github.com/anthropics/anthropic-cookbook/blob/main/path/to/original
# License: Apache 2.0
```

## Adding a Recipe

1. Create a directory: `tools/recipes/recipe-name/`
2. Add implementation with attribution header
3. Add README.md explaining usage
4. Update this file's table

## See Also

- `claude/docs/cookbooks/` - Our local cache of cookbook analysis
- `claude/docs/cookbooks/COOKBOOK-SUMMARY.md` - Full index of 63 cookbooks
