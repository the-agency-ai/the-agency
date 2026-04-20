# Evaluator-Optimizer Workflow Pattern

> Source: https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/evaluator_optimizer.ipynb

## Core Concept

An LLM pattern where one model generates solutions while another evaluates and provides feedback iteratively until quality criteria are met.

## When to Apply This Pattern

The approach works well when you have:
- **Clear evaluation criteria** that can be codified
- **Value from iterative refinement** (responses demonstrably improve with feedback)
- **LLM capability** to provide meaningful evaluative commentary

## Architecture Components

### 1. Generator

Creates solutions using a generator prompt with optional context from previous attempts.

```python
def generate(task: str, feedback: str = None) -> str:
    """Generate a solution, optionally incorporating feedback."""
    prompt = f"""
    Task: {task}

    {"Previous feedback to address: " + feedback if feedback else ""}

    Generate your solution:
    """
    return llm_call(prompt)
```

### 2. Evaluator

Assesses outputs against criteria, returning status and feedback.

```python
def evaluate(task: str, solution: str, criteria: list[str]) -> dict:
    """
    Evaluate a solution against criteria.
    Returns: {"status": "pass"|"fail", "feedback": "..."}
    """
    prompt = f"""
    Task: {task}
    Solution: {solution}

    Evaluate against these criteria:
    {chr(10).join(f"- {c}" for c in criteria)}

    <evaluation>
      <status>pass or fail</status>
      <feedback>Specific improvements needed if fail</feedback>
    </evaluation>
    """
    response = llm_call(prompt)
    return {
        "status": extract_xml(response, "status"),
        "feedback": extract_xml(response, "feedback")
    }
```

### 3. Optimization Loop

Orchestrates the cycle, maintaining memory of attempts and thoughts until passing evaluation.

```python
def optimize(task: str, criteria: list[str], max_iterations: int = 5) -> dict:
    """
    Run the evaluator-optimizer loop until criteria are met.
    """
    history = []
    feedback = None

    for iteration in range(max_iterations):
        # Generate
        solution = generate(task, feedback)

        # Evaluate
        evaluation = evaluate(task, solution, criteria)

        history.append({
            "iteration": iteration + 1,
            "solution": solution,
            "evaluation": evaluation
        })

        if evaluation["status"] == "pass":
            return {
                "final_solution": solution,
                "iterations": iteration + 1,
                "history": history
            }

        feedback = evaluation["feedback"]

    return {
        "final_solution": solution,
        "iterations": max_iterations,
        "status": "max_iterations_reached",
        "history": history
    }
```

## Practical Example: MinStack Implementation

**Task:** Implement a Stack with O(1) operations for push, pop, and getMin().

### First Iteration

Produced working code but evaluator identified gaps:
- Missing error handling for empty stack operations
- No type hints
- Incomplete documentation

### Second Iteration

Incorporated feedback:
```python
class MinStack:
    """
    A stack that supports push, pop, and retrieving the minimum
    element in O(1) time complexity.
    """

    def __init__(self) -> None:
        self._stack: list[int] = []
        self._min_stack: list[int] = []

    def push(self, val: int) -> None:
        """Push a value onto the stack."""
        if not isinstance(val, int):
            raise TypeError("Value must be an integer")
        self._stack.append(val)
        if not self._min_stack or val <= self._min_stack[-1]:
            self._min_stack.append(val)

    def pop(self) -> int:
        """Remove and return the top element."""
        if not self._stack:
            raise IndexError("Pop from empty stack")
        val = self._stack.pop()
        if val == self._min_stack[-1]:
            self._min_stack.pop()
        return val

    def getMin(self) -> int:
        """Return the minimum element in O(1)."""
        if not self._min_stack:
            raise IndexError("Stack is empty")
        return self._min_stack[-1]
```

**Result:** Passed evaluation with production-ready code.

## Variations

### Self-Evaluation

Use the same model for both generation and evaluation:

```python
def self_improve(task: str, criteria: list[str]) -> str:
    prompt = f"""
    Task: {task}
    Criteria: {criteria}

    1. Generate an initial solution
    2. Evaluate it against the criteria
    3. If it doesn't pass, improve it
    4. Repeat until satisfied

    <final_solution>Your best solution here</final_solution>
    """
    return extract_xml(llm_call(prompt), "final_solution")
```

### Multi-Evaluator

Use different evaluators for different criteria:

```python
evaluators = {
    "correctness": "Check if the code produces correct output",
    "style": "Check if the code follows PEP 8 guidelines",
    "performance": "Check if the algorithm is efficient"
}

def multi_evaluate(solution: str, evaluators: dict) -> dict:
    results = {}
    for name, prompt in evaluators.items():
        results[name] = evaluate_single(solution, prompt)
    return results
```

---

## Relevance to The Agency

**High relevance** - Maps to several Agency patterns:

| Evaluator-Optimizer | Agency Equivalent |
|--------------------|-------------------|
| Generator | Agent doing work |
| Evaluator | Code review / pre-commit checks |
| Feedback loop | Quality gates + iteration |
| Criteria | KNOWLEDGE.md standards |

**Applications:**
- **Code review agent**: Generate → Review → Improve cycle
- **Documentation quality**: Draft → Evaluate → Refine
- **Sprint planning**: Plan → Review → Adjust

**Enhancement opportunity**: Add explicit evaluator-optimizer pattern to `./tools/code-review` with structured feedback that agents can incorporate.
