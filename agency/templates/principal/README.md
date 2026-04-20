# Principal: {{PRINCIPAL_NAME}}

This is your principal directory in The Agency.

## Directory Structure

```
{{PRINCIPAL_NAME}}/
  requests/     # Your work requests (REQUEST-{{PRINCIPAL_NAME}}-XXXX.md)
  artifacts/    # Deliverables produced for you (ART-XXXX.md)
  resources/    # Reference materials and documents
  config/       # Application-specific configurations
```

## Creating Requests

To create a new request:

```bash
./tools/request --agent captain --summary "Add feature X"
```

Or create a file manually in `requests/` following the naming convention:
`REQUEST-{{PRINCIPAL_NAME}}-XXXX-workstream-title.md`

## Viewing Your Requests

```bash
# List all open requests
./tools/requests

# List your requests specifically
./tools/requests --principal {{PRINCIPAL_NAME}}
```

## Configuration

The `config/` directory holds application-specific settings:
- `iterm/` - iTerm2 dynamic profiles
- `vscode/` - VS Code settings
- Other app configs as needed

## Getting Started

1. Review the captain's welcome: `/welcome`
2. Create your first request
3. Work with agents on your workstreams

---

*Welcome to The Agency!*
