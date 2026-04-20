# PROP-0005: Path Resolution Tool

**Status:** draft
**Priority:** low
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Frequently need to give Claude (or find ourselves) the full path to files:
- Resource files in principals/jordan/resources/
- Perplexity research files in iCloud
- Tools in various locations
- Artifacts, instructions, proposals

Currently requires searching or remembering paths.

## Proposal

A quick path resolution tool that finds files by partial name or type.

### Usage

```bash
# Find by partial name
./tools/resolve perplexity-2026-01-06-0826
# Returns: /Users/jdm/Library/Mobile Documents/.../perplexity-2026-01-06-0826

# Find by type flag
./tools/resolve -r markups/feature-x      # In resources
./tools/resolve -t my-tool                 # In tools
./tools/resolve -i INSTR-0067              # Instructions
./tools/resolve -a ART-0012                # Artifacts
./tools/resolve -p PROP-0003               # Proposals

# Find with fuzzy matching
./tools/resolve --fuzzy perplexity unix
# Returns matches containing both "perplexity" and "unix"
```

### Search Locations

```yaml
resources:
  - claude/principals/*/resources/
  - ~/Library/Mobile Documents/com~apple~CloudDocs/* claude/

tools:
  - tools/
  - tools/local/

instructions:
  - claude/principals/*/instructions/

artifacts:
  - claude/principals/*/artifacts/

proposals:
  - claude/proposals/
```

### Output Modes

```bash
./tools/resolve -t mytool           # Just path
./tools/resolve -t mytool --copy    # Copy to clipboard
./tools/resolve -t mytool --open    # Open in editor
./tools/resolve -t mytool --read    # Cat the file
```

## Key Points

- Instant path resolution
- No searching required
- Works with common Agency file types
- Clipboard integration for easy sharing

## Open Questions

- [ ] Should it index files for faster lookup?
- [ ] How to handle multiple matches?
- [ ] Integration with TheCaptain for "find me the file about X"?

## Dependencies

- Related proposals: none
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created
Jordan: "I can easily use it to give you the path to a specific resource file"
