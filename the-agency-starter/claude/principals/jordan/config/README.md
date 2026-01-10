# Principal Configuration Directory

This directory holds application-specific configurations for the principal.

## Structure

```
config/
  iterm/           # iTerm2 dynamic profiles
    profiles.json  # Agency-related terminal profiles
  vscode/          # VS Code settings (optional)
  other/           # Other app configs
```

## iTerm Integration

iTerm profiles are stored here and symlinked from iTerm's dynamic profiles directory:

```bash
# Set up iTerm integration
./tools/setup-iterm <principal>
```

This creates profiles for common Agency tasks with proper colors and titles.
