# Claude Code Quickstart

**Back to:** [INDEX.md](INDEX.md)

---

## Starting a Session

```bash
cd /path/to/your/project
claude
```

You'll see the welcome screen with session info and recent conversations.

---

## First Questions to Ask

```bash
> what does this project do?
> what technologies does this project use?
> where is the main entry point?
> explain the folder structure
```

Claude reads your files automatically and answers with full context awareness.

---

## Making Your First Code Change

```bash
> add a hello world function to the main file
```

Claude Code will:
1. Find the appropriate file
2. Show proposed changes
3. Ask for approval
4. Make the edit

**Note:** Always asks permission before modifying files.

---

## Git Operations

```bash
> what files have I changed?
> commit my changes with a descriptive message
> create a new branch called feature/quickstart
> show me the last 5 commits
> help me resolve merge conflicts
```

---

## Common Workflows

### Fix a Bug

```bash
> there's a bug where users can submit empty forms - fix it
```

### Add a Feature

```bash
> add input validation to the user registration form
```

### Refactor Code

```bash
> refactor the authentication module to use async/await
```

### Write Tests

```bash
> write unit tests for the calculator functions
```

### Update Docs

```bash
> update the README with installation instructions
```

### Code Review

```bash
> review my changes and suggest improvements
```

---

## Essential Commands

| Command | Description |
|---------|-------------|
| `claude` | Start interactive mode |
| `claude "task"` | Run one-time task |
| `claude -p "query"` | One-off query, then exit |
| `claude -c` | Continue most recent conversation |
| `claude -r` | Resume a previous conversation |
| `claude commit` | Create a Git commit |
| `/clear` | Clear conversation history |
| `/help` | Show available commands |
| `exit` or `Ctrl+C` | Exit Claude Code |

---

## Pro Tips

### Be Specific

Instead of: `"fix the bug"`

Try: `"fix the login bug where users see a blank screen after entering wrong credentials"`

### Use Step-by-Step

```bash
> 1. create a new database table for user profiles
> 2. create an API endpoint to get and update profiles
> 3. build a webpage for viewing and editing profiles
```

### Let Claude Explore First

```bash
> analyze the database schema
> then build a dashboard showing frequently returned products
```

### Keyboard Shortcuts

- Press `?` to see shortcuts
- Use Tab for command completion
- Press ↑ for command history
- Type `/` to see all slash commands

---

## Related

- [Commands Reference](04-commands.md)
- [Best Practices](06-best-practices.md)
