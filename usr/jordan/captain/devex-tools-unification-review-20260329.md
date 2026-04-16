# DevEx Tools Unification Review

**Date:** 2026-03-29
**Scope:** Cross-repo audit of three tool sets for Agency 2.0 unification strategy
**Repos:** the-agency (`/Users/jordan_of/code/the-agency/tools/`), monofolk (`/Users/jordan_of/code/monofolk/`)

---

## Tool Set 1: the-agency/tools/ (106 tools)

### Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| Total tools | 106 | 100% |
| With TOOL_VERSION | 98 | 92% |
| Sourcing _log-helper | 95 | 90% |
| With --version and --help | 104 | 98% |
| Fully compliant (all 3) | ~93 | ~88% |
| Deprecated | 1 (agency-update) | <1% |
| Infrastructure (not subject to standard) | 3 (_log-helper, log-tool-use, log-tool-use-debug) | 3% |

### Tool Framework Pattern

The standard the-agency tool pattern consists of:

1. **`_log-helper` sourcing** -- telemetry via the Log Service (HTTP to `127.0.0.1:3141`)
2. **`TOOL_VERSION`** -- semantic version with date suffix (e.g., `1.2.0-20260120-000001`)
3. **`--version` / `--help`** -- standard CLI flags
4. **3-line stdout pattern** -- tool name, run ID, result (verbose output goes to log service)

Best example of the full pattern: `code-review` (line 17-19 comment explicitly references the output standard).

### Complete Tool Catalog

#### Session & Agent Management

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| hello | 1.1.0 | Yes | Yes | Welcome prompt for agent session startup |
| hi | 1.1.0 | Yes | Yes | Alias for hello |
| welcomeback | 1.0.0 | Yes | Yes | Session restart prompt |
| agentname | 1.0.0 | Yes | Yes | Get/set agent name |
| whoami | 1.0.0 | Yes | Yes | Show current agent identity |
| now | 1.0.0 | Yes | Yes | Show current time/context |
| observe | 1.0.0 | Yes | Yes | Observe agent activity |
| tab-status | 1.0.0 | Yes | Yes | iTerm2 tab status line |
| session-archive | 1.0.0 | Yes | Yes | Archive a completed session |
| session-backup | 1.0.0 | Yes | Yes | Backup session state |
| restore | 1.0.0 | Yes | Yes | Restore agent session context |
| context-save | 1.0.0 | Yes | Yes | Save context for later retrieval |
| context-review | 1.0.0 | Yes | Yes | Review saved context |

#### Scaffolding & Project Lifecycle

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| setup-agency | 1.0.0 | Yes | Yes | Set up a new agency project |
| project-create | 1.2.0 | Yes | Yes | Create a new project |
| project-update | 1.1.0 | Yes | Yes | Update project with latest starter changes |
| launch-project | N/A | No | Yes | Launch/bootstrap a project |
| agent-create | 1.2.0 | Yes | Yes | Create a new agent |
| epic-create | 1.1.0 | Yes | Yes | Create a new epic |
| sprint-create | 1.1.0 | Yes | Yes | Create a new sprint |
| workstream | 1.0.1 | Yes | Yes | Manage workstreams |
| workstream-create | 1.1.0 | Yes | Yes | Create a new workstream |
| tool-new | 1.0.0 | Yes | Yes | Scaffold a new tool |
| tool-find | 1.1.0 | Yes | Yes | Search for tools by name/purpose |
| tool-version-add | 1.0.0 | Yes | Yes | Add version metadata to a tool |
| install-hooks | N/A | No | Yes | Install git hooks |

#### Collaboration & Communication

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| collaborate | 1.0.2 | Yes | Yes | Create inter-agent collaboration requests |
| collaboration-respond | 1.0.1 | Yes | Yes | Respond to collaboration requests |
| message-send | 1.1.0 | Yes | Yes | Send inter-agent messages |
| message-read | 1.1.0 | Yes | Yes | Read inter-agent messages |
| news-post | 1.0.1 | Yes | Yes | Post to agent news/MOTD system |
| news-read | 1.0.1 | Yes | Yes | Read unread news messages |
| nit-add | 1.1.0 | Yes | Yes | Add a nit entry |
| nit-resolve | 1.1.0 | Yes | Yes | Mark a nit as resolved |
| principal | 1.0.1 | Yes | Yes | Manage principal identity |
| principal-create | 1.1.0 | Yes | Yes | Create a new principal |
| add-principal | 1.0.0 | Yes | Yes | Add a principal to a project |
| proposal-capture | 1.0.0 | Yes | Yes | Create a new proposal for discussion |

#### Quality & Review

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| code-review | 1.2.0 | Yes | Yes | Automated pattern-based code review |
| review-spawn | 1.0.0 | No | Yes | Spawn review subprocesses |
| commit-precheck | 2.0.0 | Yes | Yes | Pre-commit quality checks |
| test-run | 1.1.0 | Yes | Yes | Run tests with logging |
| bench | 1.0.0 | Yes | Yes | Run benchmarks |
| bench-build | 1.1.0 | Yes | Yes | Build benchmarks |
| agency-bench | 1.1.0 | Yes | Yes | Agency-level benchmarks |
| docbench | 1.0.0 | Yes | Yes | Documentation benchmarks |
| secrets-scan | 1.0.0 | No | Yes | Scan for leaked secrets |
| dependencies-check | 1.0.0 | Yes | Yes | Check dependency health |
| dependencies-install | 1.0.0 | Yes | Yes | Install dependencies |
| workflow-check | 1.0.0 | Yes | Yes | Check workflow compliance |
| designsystem-validate | 1.0.0 | Yes | Yes | Validate design system usage |
| designsystem-add | 1.0.0 | Yes | Yes | Add design system component |
| opportunities | 1.0.0 | No | Yes | Track improvement opportunities |
| findings-save | N/A | Yes | Yes | Save review findings |
| findings-consolidate | N/A | Yes | Yes | Consolidate findings |

#### Git & Version Control

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| commit | 2.0.0 | Yes | Yes | Create properly formatted commits |
| commit-prefix | 1.0.1 | Yes | Yes | Generate commit prefix |
| sync | 2.0.1 | Yes | Yes | Sync local with remote (pull --rebase + push) |
| tag | 2.0.0 | Yes | Yes | Git tag operations |
| release | 1.1.0 | Yes | Yes | Full release workflow |
| version-bump | 1.0.0 | Yes | Yes | Bump version numbers |
| version-next | 1.1.0 | Yes | Yes | Calculate next version |
| worktree-create | N/A | Yes | Yes | Create git worktrees |
| worktree-list | N/A | Yes | Yes | List git worktrees |
| worktree-delete | N/A | Yes | Yes | Delete git worktrees |

#### GitHub Integration

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| gh | 1.0.0 | Yes | Yes | GitHub CLI wrapper with logging |
| gh-api | 1.0.0 | Yes | Yes | GitHub API wrapper |
| gh-pr | 1.0.0 | Yes | Yes | GitHub PR operations |
| gh-release | 1.0.0 | No | Yes | GitHub release operations |
| bug-report | 1.1.0 | Yes | Yes | Create bug reports |

#### Secrets & Config

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| secret | 1.0.0 | Yes | Yes | Manage secrets |
| secret-migrate | 1.0.0 | Yes | Yes | Migrate secrets between stores |
| config | 1.0.0 | Yes | Yes | Manage agency configuration |
| myclaude | 1.2.0 | Yes | Yes | Claude Code configuration |

#### Knowledge & Artifacts

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| artifact-capture | 1.0.0 | Yes | Yes | Capture artifacts |
| artifact-index-update | 1.0.0 | Yes | Yes | Update artifact index |
| artifact-list | 1.0.0 | Yes | Yes | List artifacts |
| instruction-capture | 1.0.0 | Yes | Yes | Capture instructions |
| instruction-complete | 1.0.0 | Yes | Yes | Mark instruction complete |
| instruction-index-update | 1.0.0 | Yes | Yes | Update instruction index |
| instruction-list | 1.0.0 | Yes | Yes | List instructions |
| instruction-show | 1.0.0 | Yes | Yes | Show an instruction |
| request | 1.0.0 | Yes | Yes | Create a request |
| request-complete | 1.2.0 | Yes | Yes | Mark request complete |
| requests | 2.0.0 | Yes | Yes | List/manage requests |
| requests-backfill | 1.0.0 | Yes | Yes | Backfill request metadata |

#### Starter/Distribution

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| starter-release | 1.1.0 | Yes | Yes | Release starter pack |
| starter-test | 1.1.0 | Yes | Yes | Test starter pack |
| starter-verify | 1.0.0 | Yes | Yes | Verify starter integrity |
| starter-update | 1.0.0 | Yes | Yes | Update from starter |
| starter-compare | 1.1.0 | Yes | Yes | Compare with starter |
| starter-cleanup | 1.0.0 | Yes | Yes | Clean up starter artifacts |

#### Setup & Environment

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| mac-setup | 1.0.1 | Yes | Yes | macOS environment setup |
| linux-setup | 1.0.1 | Yes | Yes | Linux environment setup |
| icloud-setup | 1.0.1 | Yes | Yes | iCloud Drive setup |
| iterm-setup | 1.0.1 | Yes | Yes | iTerm2 configuration |
| browser | 1.0.0 | Yes | Yes | Browser automation |

#### Telemetry & Logging

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| _log-helper | N/A | N/A (is the helper) | N/A | Shared logging helper sourced by other tools |
| log | 1.2.0 | Yes | Yes | View and query logs |
| adhoc-log | 1.0.0 | Yes | Yes | Log ad-hoc work |
| log-tool-use | N/A | No | N/A | Hook: log tool invocations |
| log-tool-use-debug | N/A | No | N/A | Hook: debug tool invocation logging |
| agency-service | 1.3.0 | Special | Yes | Log service daemon (Express on port 3141) |

#### Figma & Design

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| figma-diff | 1.0.0 | Yes | Yes | Diff Figma designs |
| figma-extract | 1.2.0 | Yes | Yes | Extract assets from Figma |

#### Other

| Tool | Version | _log-helper | --version/--help | Purpose |
|------|---------|-------------|------------------|---------|
| run | 1.0.0 | Yes | Yes | Run arbitrary commands with logging |
| agency-feedback | 1.0.1 | Yes | Yes | Submit agency feedback |
| agency-update | 2.0.0-deprecated | N/A | Yes | Deprecated update mechanism |

### Framework Non-Compliance

**Missing _log-helper (9 tools):**
- `gh-release` -- has TOOL_VERSION, uses `gh` wrapper instead
- `opportunities` -- has TOOL_VERSION but no telemetry
- `review-spawn` -- has TOOL_VERSION but no telemetry
- `secrets-scan` -- has TOOL_VERSION but no telemetry
- `install-hooks` -- no TOOL_VERSION or telemetry
- `launch-project` -- no TOOL_VERSION or telemetry
- `log-tool-use` -- hook handler, not user-facing
- `log-tool-use-debug` -- hook handler, not user-facing
- `agency-service` -- the service itself, uses its own logging pattern

### Best Examples of the Framework Pattern

These tools demonstrate the gold-standard implementation of the full tool framework:

1. **`code-review`** -- Explicitly documents the 3-line stdout pattern in its header comment. Full _log-helper integration with run start/end. Clean --version/--help.
2. **`commit`** -- The most complex tool (2.0.0), full option parsing, proper telemetry, well-documented.
3. **`sync`** -- Clean implementation with --check/--dry-run, proper help text, version handling.
4. **`nit-add` / `nit-resolve`** -- Simple, clean tools following the exact pattern. Good candidates for "how to build a tool" examples.
5. **`dependencies-check`** -- Textbook implementation of the standard pattern with proper help formatting.

---

## Tool Set 2: monofolk Next-Gen (Jordan-era)

### usr/jordan/tools/

| Tool | Language | Purpose | Standard Pattern? |
|------|----------|---------|-------------------|
| telemetry-analyze.ts | TypeScript | Analyze telemetry data | No (standalone TS script) |
| transcript-analyze.ts | TypeScript | Analyze conversation transcripts | No (standalone TS script) |
| web-audit-crawl.ts | TypeScript | Crawl and audit websites | No (standalone TS script) |
| analyze-telemetry.test.ts | TypeScript | Tests for telemetry-analyze | N/A (test file) |
| analyze-transcripts.test.ts | TypeScript | Tests for transcript-analyze | N/A (test file) |

### usr/jordan/scripts/

| Tool | Language | Purpose | Standard Pattern? |
|------|----------|---------|-------------------|
| statusline.sh | Bash | Terminal status line display | No |
| switch-config.sh | Bash | Switch between configurations | No |
| captain-status.sh | Bash | Captain agent status display | No |
| pr-rebuild.sh | Bash | Rebuild PR metadata | No |
| handoff-write.sh | Bash | Write session handoff files | No |
| sandbox-sync.sh | Bash | Sync sandbox state | No |
| detect-hosting.ts | TypeScript | Detect web hosting platform | No |
| ghostty-integration.sh | Bash | Ghostty terminal integration | No |
| ghostty-setup.sh | Bash | Ghostty setup script | No |
| ghostty-claude-hook.sh | Bash | Ghostty Claude Code hook | No |

**Note:** None of the Jordan-era tools follow the-agency framework pattern. They are ad-hoc scripts written for specific operational needs.

---

## Tool Set 3: monofolk Legacy (Pre-Jordan)

### scripts/

| Tool | Language | Purpose | Category |
|------|----------|---------|----------|
| init.sh | Bash | Repository initialization | Setup |
| init-docker.sh | Bash | Docker environment initialization | Setup |
| worktree-bootstrap.sh | Bash | Bootstrap git worktree with full environment | Git/DevEx |
| fly-setup.sh | Bash | Fly.io deployment setup | Deploy |
| setup-deploy-tools.sh | Bash | Install deployment tooling | Deploy |

### scripts/data-model/

| Tool | Language | Purpose | Category |
|------|----------|---------|----------|
| gen-erd.ts | TypeScript | Generate ERD from markdown schema | Data Model |
| gdoc-to-md.ts | TypeScript | Convert Google Docs to markdown | Data Model |

### scripts/__tests__/

| Test | Framework | Coverage |
|------|-----------|----------|
| branch-freshness.bats | BATS | Git branch freshness checks |
| quality-check.bats | BATS | Pre-commit quality checks |
| session-handoff.bats | BATS | Session handoff generation |
| worktree-bootstrap.bats | BATS | Worktree bootstrap script |

### tools/ (Application-level toolkits)

These are multi-file TypeScript packages, not shell tools:

| Package | Type | Purpose |
|---------|------|---------|
| folio-cli | CLI (Commander.js) | Folio content platform CLI |
| folio-e2e | Test suite (Vitest) | Folio end-to-end tests |
| folio-mcp | MCP server | Folio Model Context Protocol server |
| folio-figma | Library | Figma-to-Folio integration |
| catalog-cli | CLI (tsx) | Catalog management CLI |
| catalog-mcp | MCP server | Catalog Model Context Protocol server |
| lib/ | Shared library | Prototype registry, build manifest, deploy, quality gate, web audit, transcripts |

---

## Analysis

### 1. Category Coverage Matrix

| Category | the-agency | monofolk Jordan | monofolk Legacy |
|----------|-----------|-----------------|-----------------|
| Session management | 13 tools | -- | -- |
| Scaffolding | 13 tools | -- | 2 (init.sh, init-docker.sh) |
| Collaboration | 12 tools | -- | -- |
| Quality/Review | 17 tools | -- | quality-check (BATS test) |
| Git operations | 10 tools | -- | worktree-bootstrap.sh |
| GitHub integration | 5 tools | pr-rebuild.sh | -- |
| Secrets/Config | 4 tools | switch-config.sh | -- |
| Knowledge/Artifacts | 12 tools | -- | -- |
| Starter/Distribution | 6 tools | -- | -- |
| Setup/Environment | 5 tools | ghostty-*.sh (3) | fly-setup.sh, setup-deploy-tools.sh |
| Telemetry/Logging | 6 tools | telemetry-analyze.ts | -- |
| Design/Figma | 2 tools | -- | folio-figma (package) |
| Data model | -- | -- | gen-erd.ts, gdoc-to-md.ts |
| Web audit | -- | web-audit-crawl.ts | web-audit lib + tests |
| Transcript analysis | -- | transcript-analyze.ts | transcript lib in tools/lib/ |
| Status/Display | tab-status | statusline.sh, captain-status.sh | -- |
| Handoff | -- | handoff-write.sh | session-handoff (BATS test) |
| Sandbox | -- | sandbox-sync.sh | -- |
| Content platform (Folio) | -- | -- | folio-cli, folio-e2e, folio-mcp |
| Catalog | -- | -- | catalog-cli, catalog-mcp |
| Deploy | -- | -- | fly-setup.sh, deploy lib |
| Hosting detection | -- | detect-hosting.ts | -- |

### 2. Gaps in the-agency (Capabilities monofolk has that the-agency doesn't)

| Capability | monofolk Tool | Gap in the-agency |
|------------|---------------|-------------------|
| Data model generation | gen-erd.ts, gdoc-to-md.ts | No data model tooling |
| Web auditing | web-audit-crawl.ts + lib/ | No web audit capability |
| Transcript analysis | transcript-analyze.ts + lib/ | No transcript analysis (session-archive is archive only) |
| Deploy infrastructure | fly-setup.sh, deploy lib, adapters | No deployment tooling (tools/sync is git-only) |
| Content platform CLI | folio-cli, catalog-cli | No application-specific CLIs |
| MCP servers | folio-mcp, catalog-mcp | No MCP server integration |
| E2E testing framework | folio-e2e (Vitest) | test-run exists but no structured E2E framework |
| Worktree bootstrap | worktree-bootstrap.sh | worktree-create exists but simpler |
| Terminal integration | ghostty-*.sh | iterm-setup exists but less integrated |
| Status display | statusline.sh, captain-status.sh | tab-status exists but limited |
| Handoff generation | handoff-write.sh | No handoff tooling |
| Sandbox management | sandbox-sync.sh | No sandbox tooling |
| Build manifests | tools/lib/build-manifest.ts | No build manifest system |
| Prototype registry | tools/lib/prototype-registry.ts | No prototype concept |
| Quality gate library | tools/lib/quality-gate.ts | Quality tools exist but no shared library |

### 3. Overlaps (Same capability in multiple tool sets)

| Capability | the-agency | monofolk |
|------------|-----------|----------|
| Git worktree management | worktree-create/list/delete | worktree-bootstrap.sh |
| Terminal status | tab-status | statusline.sh, captain-status.sh |
| Telemetry | _log-helper + agency-service + log | telemetry-analyze.ts |
| Quality checks | code-review, commit-precheck | quality-check (BATS), quality-gate.ts |
| Session management | session-archive, session-backup, restore | session-handoff (BATS) |
| Environment setup | mac-setup, linux-setup, iterm-setup | ghostty-*.sh, init.sh |
| iTerm2/Terminal | iterm-setup, tab-status | ghostty-*.sh (Ghostty-specific) |

### 4. Framework Compliance

**Full compliance (TOOL_VERSION + _log-helper + --version/--help):**
- **~93 of 106 tools (88%)** are fully compliant with the framework pattern

**Partial compliance breakdown:**
- 9 tools missing _log-helper (some by design -- infrastructure tools)
- 6 tools missing TOOL_VERSION
- 2 tools missing --version/--help

**By design non-compliant (infrastructure):**
- `_log-helper` itself (the shared helper)
- `log-tool-use`, `log-tool-use-debug` (hook handlers)
- `agency-service` (the daemon, has its own logging)

**Should be fixed:**
- `gh-release` -- should source _log-helper
- `opportunities` -- should source _log-helper
- `review-spawn` -- should source _log-helper
- `secrets-scan` -- should source _log-helper
- `install-hooks` -- should have TOOL_VERSION + _log-helper
- `launch-project` -- should have TOOL_VERSION + _log-helper

### 5. Best Examples for the Framework Spec

**Tier 1 -- Exemplars (use as spec reference):**

1. **`code-review`** -- Explicitly documents the 3-line output standard in comments. Perfect _log-helper integration. Clean structure.
2. **`nit-add`** / **`nit-resolve`** -- Small, focused tools. Perfect for "your first tool" tutorial.
3. **`dependencies-check`** -- Clean option parsing, proper help format, full compliance.

**Tier 2 -- Complex but well-structured:**

4. **`commit`** -- Shows how to build a complex tool (many options, multiple modes) while staying compliant.
5. **`sync`** -- Demonstrates --check/--dry-run pattern alongside the standard.
6. **`tag`** -- Version 2.0.0, shows tool evolution while maintaining compliance.

**Tier 3 -- Specialty patterns:**

7. **`agency-service`** -- Shows how a long-running service (Express daemon) fits the framework.
8. **`_log-helper`** -- The infrastructure foundation itself.

---

## Recommendations

1. **Fix the 6 partially compliant tools** in the-agency to reach >95% compliance before using as the Agency 2.0 reference.
2. **Extract `code-review` and `nit-add` as canonical examples** for the Agency 2.0 tool spec.
3. **The monofolk tools/lib/ pattern is different and valid** -- TypeScript shared libraries and multi-file packages are a separate concern from shell tools. Agency 2.0 should support both patterns.
4. **Jordan-era scripts need migration path** -- handoff-write.sh, sandbox-sync.sh, captain-status.sh are operational tools that should be formalized if they survive into Agency 2.0.
5. **MCP servers are a new tool type** -- folio-mcp and catalog-mcp represent a pattern the-agency doesn't have. Agency 2.0 should include MCP server scaffolding.
6. **Deploy tooling is a gap** -- the-agency has no deployment tools. The monofolk deploy lib (adapters for Docker, Vercel) is the starting point for Agency 2.0 deploy capability.
