# Release History

This file tracks releases of The Agency framework.

## Recent Releases

| Version | Date | Notes |
|---------|------|-------|
| v107.0.0 | 2026-01-20 | |
| v106.1.0 | 2026-01-20 | |
| v106.0.1 | 2026-01-20 | |
| v106.0.0 | 2026-01 | Current |
| v105.1.0 | 2026-01 | |
| v105.0.0 | 2026-01 | |
| v104.0.0 | 2026-01 | |
| v103.0.0 | 2026-01 | |
| v102.0.0 | 2026-01 | |
| v101.0.0 | 2026-01 | |
| v100.0.0 | 2026-01 | Major milestone |

## Release Process

Releases are cut using `./tools/release`:

```bash
# Cut a new release
./tools/release X.Y.Z --push --github

# With REQUEST completion
./tools/release X.Y.Z --push --github --request REQUEST-jordan-XXXX
```

## Starter Releases

The Agency Starter releases are managed separately via `./tools/starter-release`.

See the-agency-starter repository for starter-specific releases.
