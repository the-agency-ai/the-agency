# Programmatic Tool Calling (PTC)

> Source: https://platform.claude.com/cookbook/tool-use-programmatic-tool-calling-ptc

## Overview

Programmatic Tool Calling (PTC) allows Claude to write code that calls tools programmatically within the Code Execution environment, rather than requiring round-trips through the model for each tool invocation. This substantially reduces end-to-end latency and token consumption.

## Key Benefits

1. **Context Preservation Through Large Data Parsing** - Process hundreds of records with metadata in the code execution environment without sending raw data through the model's context
2. **Sequential Dependency Optimization** - Orchestrate workflows with dependencies in code rather than multiple API round trips
3. **Computational Logic in Code Execution** - Delegate arithmetic and aggregation to Python code, reducing cognitive load on the model

## Setup

### Prerequisites
- Python 3.11 or higher
- Anthropic API key
- Anthropic Python SDK >= 0.72

### Installation

```python
from dotenv import load_dotenv
from utils.visualize import visualize

load_dotenv()

MODEL = "claude-sonnet-4-5"

viz = visualize(auto_show=True)
```

## Tool Definitions

```python
import json
import anthropic
from utils.team_expense_api import get_custom_budget, get_expenses, get_team_members

client = anthropic.Anthropic()

tools = [
    {
        "name": "get_team_members",
        "description": 'Returns a list of team members for a given department. Available departments: engineering, sales, and marketing.\n\nRETURN FORMAT: Returns a JSON string containing an ARRAY of team member objects.',
        "input_schema": {
            "type": "object",
            "properties": {
                "department": {
                    "type": "string",
                    "description": "The department name. Case-insensitive.",
                }
            },
            "required": ["department"],
        },
    },
    {
        "name": "get_expenses",
        "description": "Returns all expense line items for a given employee in a specific quarter. Categories include: travel, lodging, meals, software, equipment, conference, office, and internet. IMPORTANT: Only expenses with status='approved' should be counted toward budget limits.\n\nRETURN FORMAT: Returns a JSON string containing an ARRAY of expense objects.",
        "input_schema": {
            "type": "object",
            "properties": {
                "employee_id": {
                    "type": "string",
                    "description": "The unique employee identifier",
                },
                "quarter": {
                    "type": "string",
                    "description": "Quarter identifier: 'Q1', 'Q2', 'Q3', or 'Q4'",
                },
            },
            "required": ["employee_id", "quarter"],
        },
    },
    {
        "name": "get_custom_budget",
        "description": 'Get the custom quarterly travel budget for a specific employee. Most employees have a standard $5,000 quarterly travel budget.\n\nRETURN FORMAT: Returns a JSON string containing a SINGLE OBJECT.',
        "input_schema": {
            "type": "object",
            "properties": {
                "user_id": {
                    "type": "string",
                    "description": "The unique employee identifier",
                }
            },
            "required": ["user_id"],
        },
    },
]

tool_functions = {
    "get_team_members": get_team_members,
    "get_expenses": get_expenses,
    "get_custom_budget": get_custom_budget,
}
```

## Traditional Tool Calling (Baseline)

```python
import time
from anthropic.types import TextBlock, ToolUseBlock
from anthropic.types.beta import BetaMessageParam as MessageParam
from anthropic.types.beta import BetaTextBlock, BetaToolUseBlock

messages: list[MessageParam] = []

def run_agent_without_ptc(user_message):
    """Run agent using traditional tool calling"""
    messages.append({"role": "user", "content": user_message})
    total_tokens = 0
    start_time = time.time()
    api_counter = 0

    while True:
        response = client.beta.messages.create(
            model=MODEL,
            max_tokens=4000,
            tools=tools,
            messages=messages,
            betas=["advanced-tool-use-2025-11-20"],
        )

        api_counter += 1
        total_tokens += response.usage.input_tokens + response.usage.output_tokens
        viz.capture(response)

        if response.stop_reason == "end_turn":
            final_response = next(
                (
                    block.text
                    for block in response.content
                    if isinstance(block, (BetaTextBlock, TextBlock))
                ),
                None,
            )
            elapsed_time = time.time() - start_time
            return final_response, messages, total_tokens, elapsed_time, api_counter

        if response.stop_reason == "tool_use":
            messages.append({"role": "assistant", "content": response.content})
            tool_results = []

            for block in response.content:
                if isinstance(block, (BetaToolUseBlock, ToolUseBlock)):
                    tool_name = block.name
                    tool_input = block.input
                    tool_use_id = block.id

                    result = tool_functions[tool_name](**tool_input)
                    content = str(result)

                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": tool_use_id,
                        "content": content,
                    })

            messages.append({"role": "user", "content": tool_results})
        else:
            print(f"\nUnexpected stop reason: {response.stop_reason}")
            elapsed_time = time.time() - start_time
            final_response = next(
                (
                    block.text
                    for block in response.content
                    if isinstance(block, (BetaTextBlock, TextBlock))
                ),
                f"Stopped with reason: {response.stop_reason}",
            )
            return final_response, messages, total_tokens, elapsed_time, api_counter
```

### Running the Traditional Agent

```python
query = "Which engineering team members exceeded their Q3 travel budget? Standard quarterly travel budget is $5,000. However, some employees have custom budget limits. For anyone who exceeded the $5,000 standard budget, check if they have a custom budget exception. If they do, use that custom limit instead to determine if they truly exceeded their budget."

result, conversation, total_tokens, elapsed_time, api_count_without_ptc = run_agent_without_ptc(query)

print(f"Result: {result}")
print(f"API calls made: {api_count_without_ptc}")
print(f"Total tokens used: {total_tokens:,}")
print(f"Total time taken: {elapsed_time:.2f}s")
```

**Results:**
- API calls: 4
- Total tokens: 110,473
- Elapsed time: 35.38s

## Programmatic Tool Calling (PTC)

### Enabling PTC

To enable PTC on tools, add the `allowed_callers` field:

```python
import copy

ptc_tools = copy.deepcopy(tools)
for tool in ptc_tools:
    tool["allowed_callers"] = ["code_execution_20250825"]

# Add the code execution tool
ptc_tools.append(
    {
        "type": "code_execution_20250825",
        "name": "code_execution",
    }
)
```

### Agent Implementation with PTC

```python
messages = []

def run_agent_with_ptc(user_message):
    """Run agent using PTC"""
    messages.append({"role": "user", "content": user_message})
    total_tokens = 0
    start_time = time.time()
    container_id = None
    api_counter = 0

    while True:
        request_params = {
            "model": MODEL,
            "max_tokens": 4000,
            "tools": ptc_tools,
            "messages": messages,
        }

        response = client.beta.messages.create(
            **request_params,
            betas=["advanced-tool-use-2025-11-20"],
            extra_body={"container": container_id} if container_id else None,
        )
        viz.capture(response)
        api_counter += 1

        # Track container for stateful execution
        if hasattr(response, "container") and response.container:
            container_id = response.container.id
            print(f"\n[Container] ID: {container_id}")

        total_tokens += response.usage.input_tokens + response.usage.output_tokens

        if response.stop_reason == "end_turn":
            final_response = next(
                (block.text for block in response.content if isinstance(block, BetaTextBlock)),
                None,
            )
            elapsed_time = time.time() - start_time
            return final_response, messages, total_tokens, elapsed_time, api_counter

        if response.stop_reason == "tool_use":
            messages.append({"role": "assistant", "content": response.content})
            tool_results = []

            for block in response.content:
                if isinstance(block, BetaToolUseBlock):
                    tool_name = block.name
                    tool_input = block.input
                    tool_use_id = block.id

                    caller_type = block.caller["type"]

                    if caller_type == "code_execution_20250825":
                        print(f"[PTC] Tool called from code execution environment: {tool_name}")
                    elif caller_type == "direct":
                        print(f"[Direct] Tool called by model: {tool_name}")

                    result = tool_functions[tool_name](**tool_input)

                    if isinstance(result, list) and result and isinstance(result[0], str):
                        content = "\n".join(result)
                    elif isinstance(result, (dict, list)):
                        content = json.dumps(result)
                    else:
                        content = str(result)

                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": tool_use_id,
                        "content": content,
                    })

            messages.append({"role": "user", "content": tool_results})
        else:
            print(f"\nUnexpected stop reason: {response.stop_reason}")
            elapsed_time = time.time() - start_time
            final_response = next(
                (block.text for block in response.content if isinstance(block, BetaTextBlock)),
                f"Stopped with reason: {response.stop_reason}",
            )
            return final_response, messages, total_tokens, elapsed_time, api_counter
```

### Running the PTC Agent

```python
result_ptc, conversation_ptc, total_tokens_ptc, elapsed_time_ptc, api_count_with_ptc = run_agent_with_ptc(query)

print(f"Result: {result_ptc}")
print(f"API calls made: {api_count_with_ptc}")
print(f"Total tokens used: {total_tokens_ptc:,}")
print(f"Total time taken: {elapsed_time_ptc:.2f}s")
```

**Results:**
- API calls: 4
- Total tokens: 15,919
- Elapsed time: 34.88s

### Example Code Generated by Claude with PTC

Claude automatically generates optimized code like:

```python
import asyncio
import json

async def main():
    # Get all engineering team members
    team_members_json = await get_team_members({'department': 'engineering'})
    team_members = json.loads(team_members_json)

    # Get Q3 expenses in parallel
    expense_tasks = [
        get_expenses({'employee_id': member['id'], 'quarter': 'Q3'})
        for member in team_members
    ]
    expenses_results = await asyncio.gather(*expense_tasks)

    # Calculate travel expenses for each member
    travel_spending = {}
    for i, member in enumerate(team_members):
        expenses = json.loads(expenses_results[i])
        # Only count approved expenses in travel category
        travel_total = sum(
            expense['amount']
            for expense in expenses
            if expense['category'] == 'travel' and expense['status'] == 'approved'
        )
        travel_spending[member['id']] = {
            'name': member['name'],
            'travel_total': travel_total
        }
```

## Performance Comparison

| Metric | Traditional | PTC |
|--------|-------------|-----|
| API Calls | 4 | 4 |
| Total Tokens | 110,473 | 15,919 |
| Elapsed Time (s) | 35.38 | 34.88 |
| Token Reduction | - | 85.6% |
| Time Reduction | - | 1.4% |

## When to Use PTC

PTC is most beneficial when:

- **Working with large, metadata-rich datasets** - Filtering, parsing, or aggregation operations
- **Sequential dependencies exist** - Tool calls that depend on results of previous calls
- **Multiple tool calls are needed** - In sequence or in loops across similar entities
- **Computational logic** - Can reduce what needs to flow through the model's context
- **Tools are safe** - For programmatic/repeated execution without human oversight

## Key Differences from Traditional Tool Calling

| Aspect | Traditional | PTC |
|--------|-------------|-----|
| Tool Invocation | Model makes direct API calls | Model writes code to call tools in execution environment |
| Data Flow | All raw data through model context | Processed data only through context |
| Round Trips | Multiple sequential round trips for dependent operations | Fewer round trips with optimized orchestration |
| Token Usage | Higher (all metadata included) | Much lower (irrelevant data filtered in code) |
| Latency | Multiple API calls add latency | Fewer API calls offset by execution time |

## Next Steps

Adapt this pattern to your own use cases:

- Financial data analysis and reporting with sequential lookups
- Multi-entity health checks that depend on initial scan results
- Large file processing with metadata (CSV, JSON, XML parsing)
- Database query result aggregation with follow-up queries
- Batch API operations with conditional logic based on initial results

---

## Relevance to The Agency

**High relevance** - PTC could significantly optimize our multi-agent tool calls:
- Agents could batch tool invocations in code rather than sequential API calls
- Reduce token consumption when agents process large amounts of data
- Enable more complex orchestration patterns within a single agent turn
