# Model Selection Guide

**Quick Reference:** Use Opus for coordination/reasoning, Sonnet for implementation, Haiku for search/exploration.

## Opus as Conductor Pattern (Default)

All agents run as **Opus 4.5** by default. Opus acts as the "conductor" - coordinating work, making architectural decisions, and spawning subagents (Sonnet/Haiku) for parallel execution.

```bash
# Launch with myclaude
./tools/myclaude housekeeping housekeeping
./tools/myclaude {workstream} {agent}
```

## Standard Workflow

1. Opus (you) receives task from user
2. Opus spawns subagents (Sonnet/Haiku) for parallel execution
3. Subagents complete work and return results
4. Opus integrates results and responds to user

**Use subagents liberally** - they run in parallel, save time, and let Opus focus on coordination.

## Mid-Session Model Switching

Use `/model` to switch models during a session (context preserved):

| Command           | Use Case                                      |
| ----------------- | --------------------------------------------- |
| `/model opus`     | Switch to Opus for complex reasoning          |
| `/model sonnet`   | Switch to Sonnet for implementation           |
| `/model haiku`    | Switch to Haiku for quick tasks               |

**Note:** `/model` preserves full context. Different from restarting with `claude --model X` which starts fresh.

## Subagent Model Selection

When spawning subagents via Task tool, select model based on task complexity:

```typescript
// Complex reasoning, security analysis, architectural decisions
Task({
  subagent_type: 'code-reviewer',
  model: 'opus', // Critical reasoning requires Opus
  prompt: 'Review security implications of this authentication flow',
});

// Standard implementation, most tasks
Task({
  subagent_type: 'general-purpose',
  model: 'sonnet', // Default for implementation work
  prompt: 'Implement the API endpoint according to spec',
});

// Quick searches, simple refactoring
Task({
  subagent_type: 'Explore',
  model: 'haiku', // Fast and cost-effective
  prompt: 'Find all usages of the deprecated function',
});
```

## Model Guidelines

| Model      | Cost | Use For                                                                |
| ---------- | ---- | ---------------------------------------------------------------------- |
| **Opus**   | $$$  | Security fixes, complex debugging, architectural planning, code review |
| **Sonnet** | $$   | Feature implementation, standard refactoring, testing                  |
| **Haiku**  | $    | Code search, simple edits, fast iteration, exploration                 |

## Parallel Subagent Execution

Launch multiple Task calls in single message = parallel execution. Use `run_in_background: true` for long-running tasks, collect with `TaskOutput`.

---

*Part of The Agency framework*
