# Claude Code Best Practices

**Back to:** [INDEX.md](INDEX.md)

---

## The Explore-Plan-Code-Commit Workflow

This approach significantly outperforms jumping directly to coding.

1. **Explore:** Ask Claude to read relevant files without writing code
2. **Plan:** Request a plan using "think," "think hard," or "ultrathink"
3. **Document:** Optionally document the plan as a GitHub issue
4. **Implement:** Have Claude implement the solution
5. **Commit:** Have Claude commit and create pull requests

---

## Test-Driven Development

Claude performs best with clear targets like tests or visual mocks.

1. Write test cases based on expected inputs/outputs
2. Run tests to confirm they fail
3. Commit the tests
4. Have Claude write code to pass the tests
5. Commit the working code

---

## Write-Screenshot-Iterate

For visual work, iterate with screenshots:

1. Provide screenshot capability (Puppeteer MCP, iOS simulator, or manual)
2. Provide a visual design mock
3. Have Claude implement
4. Share screenshot of result
5. Iterate until matching (usually 2-3 iterations)

---

## Git Workflows

Claude effectively handles:

- Searching git history to understand API evolution
- Writing descriptive commit messages based on context
- Complex operations like rebase conflict resolution
- Patch grafting between branches

Many developers use Claude for 90%+ of git interactions:

```bash
> what changed in the last week affecting auth?
> commit these changes with a descriptive message
> help me resolve these merge conflicts
```

---

## GitHub Workflows

```bash
> create a PR for this branch
> implement the code review fixes
> fix the failing CI build
> triage these open issues
```

**Tip:** Install the `gh` CLI for full GitHub integration.

---

## Being Specific

Vague instructions reduce first-attempt success.

| Bad | Good |
|-----|------|
| "add tests for foo.py" | "write a new test case for foo.py covering the edge case where the user is logged out, avoid mocks" |
| "fix the bug" | "fix the login bug where users see a blank screen after entering wrong credentials" |

---

## Using Images

Claude excels with visuals:

- Paste screenshots (cmd+ctrl+shift+4 to clipboard on macOS, then ctrl+v)
- Drag and drop image files
- Provide file paths to images

Particularly effective for design mocks and visual debugging.

---

## Course Correction

Use these tools for mid-course correction:

- Ask Claude to make a plan before coding
- Press `Escape` to interrupt during thinking, tool calls, or edits
- Double-tap `Escape` to jump back in history and edit previous prompts
- Ask Claude to undo changes

These correction tools generally produce better solutions faster than expecting first-attempt perfection.

---

## Context Management

Long sessions fill the context window with irrelevant content.

```bash
/clear   # Use frequently between tasks
```

---

## Checklists for Complex Work

For migrations, lint fixes, or complex scripts:

```bash
> create a markdown checklist for this migration
> work through each item, updating the checklist as you go
```

This improves performance on exhaustive solutions.

---

## Multiple Claude Instances

### Parallel Code Review

1. Have one Claude write code
2. Start another Claude to review it
3. Start a third Claude to apply feedback

Or: one writes tests, another writes code to pass them.

### Git Worktrees

Create parallel workspaces:

```bash
git worktree add ../project-feature-a feature-a
cd ../project-feature-a && claude
```

Tips:
- Use consistent naming
- One terminal tab per worktree
- Set up notifications for completion
- Clean up with `git worktree remove`

---

## Related

- [Commands Reference](04-commands.md)
- [Advanced Features](07-advanced.md)
