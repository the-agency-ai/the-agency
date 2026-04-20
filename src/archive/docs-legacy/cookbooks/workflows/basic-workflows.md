# Basic Multi-LLM Workflow Patterns

> Source: https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/basic_workflows.ipynb

## Overview

This cookbook demonstrates three foundational approaches for orchestrating multiple language model calls to optimize performance, cost, or latency trade-offs.

## Core Workflow Patterns

### 1. Prompt-Chaining

Decomposes complex tasks into sequential steps where each stage builds upon previous results.

```python
def chain(input_text: str, prompts: list[str]) -> str:
    """
    Process input through a chain of prompts sequentially.
    Each step receives the output of the previous step.
    """
    result = input_text
    for prompt in prompts:
        result = llm_call(prompt.format(input=result))
    return result
```

**Example use case:** Data extraction and formatting

Transform raw Q3 performance data through four stages:
1. Extract metrics
2. Normalize formats
3. Sort by value
4. Create markdown tables

**When to use:**
- Tasks that naturally decompose into sequential steps
- When each step depends on the previous result
- Quality is more important than speed

---

### 2. Parallelization

Distributes independent subtasks across concurrent LLM calls using `ThreadPoolExecutor`.

```python
from concurrent.futures import ThreadPoolExecutor

def parallel(inputs: list[str], prompt_template: str) -> list[str]:
    """
    Process multiple inputs concurrently with the same prompt.
    """
    def process_single(input_text):
        return llm_call(prompt_template.format(input=input_text))

    with ThreadPoolExecutor() as executor:
        results = list(executor.map(process_single, inputs))
    return results
```

**Example use case:** Stakeholder impact analysis

Examine four groups concurrently:
- Customers
- Employees
- Investors
- Suppliers

Each generates customized impact assessments with recommended actions and timelines.

**When to use:**
- Independent tasks that don't depend on each other
- Latency is critical
- Same processing logic applies to multiple inputs

---

### 3. Routing

Dynamic selection mechanism that analyzes input characteristics to choose specialized processing paths.

```python
def route(input_text: str, routes: dict[str, str]) -> str:
    """
    Classify input and delegate to appropriate handler.

    Args:
        input_text: The content to process
        routes: Dict mapping route names to specialized prompts
    """
    # Step 1: Classify the input
    classification_prompt = f"""
    Analyze this input and determine which route is most appropriate.
    Available routes: {list(routes.keys())}

    Input: {input_text}

    <thinking>Reason about which route fits best</thinking>
    <route>selected_route_name</route>
    """

    classification = llm_call(classification_prompt)
    selected_route = extract_xml(classification, "route")

    # Step 2: Process with specialized handler
    if selected_route in routes:
        return llm_call(routes[selected_route].format(input=input_text))
    else:
        return llm_call(routes["default"].format(input=input_text))
```

**Example use case:** Customer support ticket triage

Direct requests to four specialized teams:
- Billing
- Technical
- Account
- Product

Based on content analysis with chain-of-thought reasoning.

**When to use:**
- Inputs require different processing based on content
- Specialized handlers improve quality for specific types
- You want to optimize costs by using appropriate models per type

---

## Utility Functions

### LLM Call Wrapper

```python
import anthropic

client = anthropic.Anthropic()

def llm_call(prompt: str, model: str = "claude-sonnet-4-5") -> str:
    """Basic LLM call wrapper."""
    response = client.messages.create(
        model=model,
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.content[0].text
```

### XML Extraction

```python
import re

def extract_xml(text: str, tag: str) -> str:
    """Extract content from XML tags."""
    pattern = f"<{tag}>(.*?)</{tag}>"
    match = re.search(pattern, text, re.DOTALL)
    return match.group(1).strip() if match else ""
```

---

## Relevance to The Agency

**Very High relevance** - These are foundational patterns we use:

| Pattern | Agency Application |
|---------|-------------------|
| **Chaining** | Multi-step tool workflows, sprint planning |
| **Parallelization** | Concurrent agent operations, batch processing |
| **Routing** | Dispatching collaboration requests to appropriate agents |

These patterns could be formalized as Agency tools or utilities.
