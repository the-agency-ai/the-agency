# Principals Index

Principals are human stakeholders who direct agent work via requests.

## Registered Principals

_Add principals here as they join the project._

| Principal | Role | Added |
|-----------|------|-------|
| (none yet) | | |

## Adding a Principal

```bash
./tools/principal-create {name}
```

Or manually:
```bash
mkdir -p claude/principals/{name}/requests
mkdir -p claude/principals/{name}/artifacts
mkdir -p claude/principals/{name}/resources
mkdir -p claude/principals/{name}/config
```

## Principal Directory Structure

```
claude/principals/{name}/
  README.md             # Principal overview and instructions
  requests/             # REQUEST-{name}-XXXX files they've issued
  artifacts/            # Deliverables produced for them
  resources/            # Reference materials they've provided
  config/               # Application-specific configurations
```

## Request Naming

```
REQUEST-{principal}-XXXX-workstream-title.md
```

Example: `REQUEST-jordan-0001-web-implement-dark-mode.md`

## Artifact Naming

```
ART-XXXX-{principal}-{workstream}-{agent}-{date}-{title}.md
```

Example: `ART-0001-jordan-web-web-2026-01-01-dark-mode-implementation.md`
| testprincipal | 2026-04-05 16:45:01 +08 | Active |
| uppercasetest | 2026-04-05 16:45:03 +08 | Active |
| batsstructtest | 2026-04-05 16:45:03 +08 | Active |
| batsreadmetest | 2026-04-05 16:45:03 +08 | Active |
| test | 2026-04-05 23:48:30 +08 | Active |
