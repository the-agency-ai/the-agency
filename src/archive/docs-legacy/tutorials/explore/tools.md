# Explore: Tools

**Time:** 4 minutes
**Goal:** Discover the CLI tools available in The Agency

## What Are Tools?

The Agency includes a comprehensive CLI toolkit in `tools/`:

```bash
ls -la tools/
```

All tools follow Unix philosophy:
- Do one thing well
- Compose with other tools
- Predictable input/output

## Core Tools

### Session Management
```bash
./tools/myclaude {workstream} {agent}     # Launch an agent
./tools/welcomeback                       # Resume after break
./tools/session-backup                    # Save session state
```

### Scaffolding
```bash
./tools/workstream-create {name}          # New workstream
./tools/agent-create {workstream} {name}  # New agent
./tools/epic-create                       # Plan major work
./tools/sprint-create {workstream} {id}   # Plan sprint
```

### Collaboration
```bash
./tools/collaborate                       # Request help from agent
./tools/collaboration-respond             # Respond to request
./tools/news-post                         # Broadcast update
./tools/news-read                         # Read news
./tools/dispatch-collaborations           # Launch agents for pending work
```

### Work Items
```bash
./tools/request                           # Create REQUEST
./tools/requests                          # List REQUESTs
./tools/bug                               # Report bug
./tools/idea                              # Capture idea
```

### Quality
```bash
./tools/commit-precheck                   # Run quality gates
./tools/test-run                          # Run tests
./tools/code-review                       # Automated review
```

### Git
```bash
./tools/sync                              # Push with checks
./tools/commit                            # Commit with format
./tools/doc-commit                        # Commit docs
./tools/tag                               # Tag releases
```

### Secrets
```bash
./tools/secret vault init                 # Initialize vault
./tools/secret create {name}              # Store secret
./tools/secret get {name}                 # Retrieve secret
./tools/secret list                       # List secrets
```

## Demo: Try a Few

Walk through 2-3 tools:

### Example 1: Create a REQUEST
```bash
./tools/request --agent captain --summary "Learn about Agency tools"
```

Show the created file.

### Example 2: List REQUESTs
```bash
./tools/requests
```

### Example 3: Post news
```bash
./tools/news-post "Just finished the tools tutorial!"
```

## Tool Patterns

All tools follow these patterns:

**Help:**
```bash
./tools/{tool} --help
```

**Version:**
```bash
./tools/{tool} --version
```

**Quiet operation:**
Most tools have `--quiet` or `-q` flags

## Tool Discovery

Show them how to explore:

```bash
# List all tools
ls -1 tools/

# Read a tool's header comments
head -20 tools/myclaude

# Check version
./tools/myclaude --version
```

## Building Your Own Tools

Mention that:
- Tools are just bash scripts
- Follow existing patterns
- Add to `tools/` directory
- Document with header comments

## Key Takeaways

✓ Rich CLI toolkit in `tools/`
✓ Tools for every part of the workflow
✓ Composable and predictable
✓ Easy to extend with custom tools

## Next Steps

Ask if they want to:
- Explore collaboration (how tools enable it)
- Try creating something (new project or existing codebase)
- Learn concepts (deeper understanding)

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - explore.tools
```
