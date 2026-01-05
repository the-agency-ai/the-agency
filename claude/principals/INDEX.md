# Principals Index

Principals are human stakeholders who direct agent work via instructions.

## Registered Principals

_Add principals here as they join the project._

| Principal | Role | Added |
|-----------|------|-------|
| (none yet) | | |

## Adding a Principal

```bash
mkdir -p claude/principals/{name}/instructions
mkdir -p claude/principals/{name}/artifacts
touch claude/principals/{name}/preferences.yaml
```

Or use the housekeeping agent:
```bash
./tools/myclaude housekeeping housekeeping "Add a principal named {name}"
```

## Principal Directory Structure

```
claude/principals/{name}/
  preferences.yaml      # How they like to work
  instructions/         # INSTR-XXXX files they've issued
  artifacts/            # Deliverables produced for them
  resources/            # Reference materials they've provided
```

## Instruction Naming

```
INSTR-XXXX-{principal}-{workstream}-{agent}-{title}.md
```

Example: `INSTR-0001-jordan-web-web-implement-dark-mode.md`

## Artifact Naming

```
ART-XXXX-{principal}-{workstream}-{agent}-{date}-{title}.md
```

Example: `ART-0001-jordan-web-web-2026-01-01-dark-mode-implementation.md`
