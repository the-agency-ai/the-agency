# Orchestrator-Workers Workflow Pattern

> Source: https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/orchestrator_workers.ipynb

## Pattern Definition

The orchestrator-workers pattern is a dynamic task decomposition approach where a central LLM analyzes each unique input and determines optimal subtasks to delegate to specialized workers, rather than using fixed parallelization schemes.

## Core Architecture

**Two-phase operation:**

1. **Analysis Phase**: An orchestrator LLM receives the task, analyzes valuable approaches, and generates structured subtask descriptions in XML format.

2. **Execution Phase**: Each worker LLM receives the original task for context, plus specific instructions for their assigned subtask type.

The distinguishing feature is **runtime adaptability**—subtasks aren't predetermined but emerge based on specific input characteristics.

## Implementation

```python
class FlexibleOrchestrator:
    def __init__(self, orchestrator_prompt: str, worker_prompt: str):
        self.orchestrator_prompt = orchestrator_prompt
        self.worker_prompt = worker_prompt

    def parse_tasks(self, xml_response: str) -> list[dict]:
        """Convert XML task output into structured dictionaries."""
        tasks = []
        # Parse <task><type>...</type><details>...</details></task> blocks
        task_pattern = r"<task>(.*?)</task>"
        for match in re.finditer(task_pattern, xml_response, re.DOTALL):
            task_xml = match.group(1)
            task_type = extract_xml(task_xml, "type")
            details = extract_xml(task_xml, "details")
            tasks.append({"type": task_type, "details": details})
        return tasks

    def process(self, task: str, context: str = "") -> dict:
        """Main orchestration logic."""
        # Phase 1: Orchestrator determines subtasks
        orchestrator_input = self.orchestrator_prompt.format(
            task=task,
            context=context
        )
        orchestrator_response = llm_call(orchestrator_input)
        subtasks = self.parse_tasks(orchestrator_response)

        # Phase 2: Workers execute subtasks
        results = {}
        for subtask in subtasks:
            worker_input = self.worker_prompt.format(
                task=task,
                context=context,
                subtask_type=subtask["type"],
                subtask_details=subtask["details"]
            )
            result = llm_call(worker_input)
            if result.strip():  # Validate non-empty
                results[subtask["type"]] = result
            else:
                results[subtask["type"]] = "Error: Empty worker response"

        return {
            "orchestrator_analysis": orchestrator_response,
            "worker_results": results
        }
```

## Example: Marketing Copy Generation

**Task:** Generate product descriptions for an eco-friendly water bottle

**Orchestrator Output:**
```xml
<tasks>
  <task>
    <type>technical-specifications</type>
    <details>Feature-focused content emphasizing materials, certifications, measurable metrics</details>
  </task>
  <task>
    <type>lifestyle-emotional</type>
    <details>Story-driven messaging connecting product to environmental values</details>
  </task>
  <task>
    <type>benefit-practical</type>
    <details>Problem-solution format highlighting everyday usability</details>
  </task>
</tasks>
```

**Worker Results:**
- **Technical**: Specs, materials, certifications
- **Lifestyle**: Emotional story, brand values
- **Practical**: Use cases, daily benefits

Each variation serves different marketing channels without pre-definition.

## When to Apply This Pattern

**Suitable for:**
- Tasks requiring multiple distinct perspectives
- Situations where optimal decomposition depends on input content
- Content generation needing audience-specific variations
- Analysis benefiting from different analytical lenses

**Unsuitable for:**
- Simple single-output tasks (unnecessary complexity)
- Latency-critical applications (N+1 API calls add overhead)
- Predictable subtasks (simpler parallelization approaches suffice)

## Key Considerations

**Performance factors:**
- Requires N+1 API calls minimum (orchestrator + N workers)
- Current implementation runs workers sequentially
- Orchestrator prompt quality directly impacts task decomposition effectiveness

**Failure scenarios:**
- Suboptimal task breakdown from inadequate prompts
- Empty or malformed worker responses
- XML parsing failures if models deviate from format

## Enhancement Opportunities

1. **Async workers**: Parallelize worker execution for reduced latency
2. **Retry logic**: Handle transient failures gracefully
3. **Synthesis phase**: Add final LLM call to combine worker outputs
4. **Model optimization**: Use Opus for orchestrator, Haiku for workers

---

## Relevance to The Agency

**Very High relevance** - This is essentially what The Agency does:

| Orchestrator-Workers | The Agency Equivalent |
|---------------------|----------------------|
| Orchestrator | Principal giving instructions |
| Workers | Specialized agents |
| Task decomposition | Sprint planning |
| Subtask assignment | Collaboration requests |

**Key insight**: The Agency's `./tools/collaborate` and `./tools/dispatch-collaborations` already implement this pattern. This cookbook validates our approach and suggests enhancements like:
- Automatic task decomposition based on instruction content
- Model selection per agent (Opus for planning, Sonnet for execution)
- Synthesis agents that combine multi-agent outputs
