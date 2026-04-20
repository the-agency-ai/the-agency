# Extended Thinking with Tool Use

> Source: https://platform.claude.com/cookbook/extended-thinking-extended-thinking-with-tool-use

## Overview

This cookbook demonstrates how to use Claude's extended thinking feature with tools, allowing you to see Claude's step-by-step reasoning before it provides answers. When using extended thinking with tool use, Claude shows thinking before making tool requests but not after receiving tool results.

## Setup

```python
%pip install anthropic

import anthropic
import os
import json

MODEL_NAME = "claude-sonnet-4-5"
MAX_TOKENS = 4000
THINKING_BUDGET_TOKENS = 2000

client = anthropic.Anthropic()

def print_thinking_response(response):
    """Pretty print a message response with thinking blocks."""
    print("\n==== FULL RESPONSE ====")
    for block in response.content:
        if block.type == "thinking":
            print("\n THINKING BLOCK:")
            print(block.thinking[:500] + "..." if len(block.thinking) > 500 else block.thinking)
        elif block.type == "redacted_thinking":
            print("\n REDACTED THINKING BLOCK:")
            print(f"[Data length: {len(block.data) if hasattr(block, 'data') else 'N/A'}]")
        elif block.type == "text":
            print("\n FINAL ANSWER:")
            print(block.text)
    print("\n==== END RESPONSE ====")
```

## Example 1: Single Tool Call with Thinking

```python
def tool_use_with_thinking():
    tools = [
        {
            "name": "weather",
            "description": "Get current weather information for a location.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "The location to get weather for."
                    }
                },
                "required": ["location"]
            }
        }
    ]

    def weather(location):
        weather_data = {
            "New York": {"temperature": 72, "condition": "Sunny"},
            "London": {"temperature": 62, "condition": "Cloudy"},
            "Tokyo": {"temperature": 80, "condition": "Partly cloudy"},
            "Paris": {"temperature": 65, "condition": "Rainy"},
        }
        return weather_data.get(location, {"error": f"No data for {location}"})

    # Initial request with tool use and thinking
    response = client.messages.create(
        model=MODEL_NAME,
        max_tokens=MAX_TOKENS,
        thinking={
            "type": "enabled",
            "budget_tokens": THINKING_BUDGET_TOKENS
        },
        tools=tools,
        messages=[{
            "role": "user",
            "content": "What's the weather like in Paris today?"
        }]
    )

    full_conversation = [{
        "role": "user",
        "content": "What's the weather like in Paris today?"
    }]

    if response.stop_reason == "tool_use":
        # Extract thinking blocks and tool use
        assistant_blocks = [block for block in response.content
                           if block.type in ["thinking", "redacted_thinking", "tool_use"]]

        full_conversation.append({
            "role": "assistant",
            "content": assistant_blocks
        })

        # Find and execute tool
        tool_use_block = next((block for block in response.content if block.type == "tool_use"), None)
        if tool_use_block:
            tool_result = weather(tool_use_block.input["location"])

            full_conversation.append({
                "role": "user",
                "content": [{
                    "type": "tool_result",
                    "tool_use_id": tool_use_block.id,
                    "content": json.dumps(tool_result)
                }]
            })

            # Continue conversation
            response = client.messages.create(
                model=MODEL_NAME,
                max_tokens=MAX_TOKENS,
                thinking={
                    "type": "enabled",
                    "budget_tokens": THINKING_BUDGET_TOKENS
                },
                tools=tools,
                messages=full_conversation
            )

    print_thinking_response(response)
```

## Example 2: Multiple Tool Calls with Thinking

```python
def multiple_tool_calls_with_thinking():
    tools = [
        {
            "name": "weather",
            "description": "Get current weather information for a location.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                },
                "required": ["location"]
            }
        },
        {
            "name": "news",
            "description": "Get latest news headlines for a topic.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "topic": {"type": "string"}
                },
                "required": ["topic"]
            }
        }
    ]

    # Initial request
    response = client.messages.create(
        model=MODEL_NAME,
        max_tokens=MAX_TOKENS,
        thinking={"type": "enabled", "budget_tokens": THINKING_BUDGET_TOKENS},
        tools=tools,
        messages=[{
            "role": "user",
            "content": "What's the weather in London, and the latest tech news?"
        }]
    )

    full_conversation = [{
        "role": "user",
        "content": "What's the weather in London, and the latest tech news?"
    }]

    # Handle multiple tool calls in a loop
    while response.stop_reason == "tool_use":
        assistant_blocks = [block for block in response.content
                           if block.type in ["thinking", "redacted_thinking", "tool_use"]]

        full_conversation.append({
            "role": "assistant",
            "content": assistant_blocks
        })

        tool_use_block = next((block for block in response.content if block.type == "tool_use"), None)
        if tool_use_block:
            # Execute appropriate tool
            if tool_use_block.name == "weather":
                tool_result = {"temperature": 62, "condition": "Cloudy"}
            elif tool_use_block.name == "news":
                tool_result = {"headlines": ["AI breakthrough", "Tech stocks rise"]}
            else:
                tool_result = {"error": "Unknown tool"}

            full_conversation.append({
                "role": "user",
                "content": [{
                    "type": "tool_result",
                    "tool_use_id": tool_use_block.id,
                    "content": json.dumps(tool_result)
                }]
            })

            response = client.messages.create(
                model=MODEL_NAME,
                max_tokens=MAX_TOKENS,
                thinking={"type": "enabled", "budget_tokens": THINKING_BUDGET_TOKENS},
                tools=tools,
                messages=full_conversation
            )
        else:
            break

    print_thinking_response(response)
```

## Example 3: Preserving Thinking Blocks

```python
def thinking_block_preservation_example():
    tools = [...]  # Same as above

    response = client.messages.create(
        model=MODEL_NAME,
        max_tokens=MAX_TOKENS,
        thinking={"type": "enabled", "budget_tokens": THINKING_BUDGET_TOKENS},
        tools=tools,
        messages=[{"role": "user", "content": "What's the weather in Berlin?"}]
    )

    thinking_blocks = [b for b in response.content if b.type == "thinking"]
    tool_use_blocks = [b for b in response.content if b.type == "tool_use"]

    if tool_use_blocks:
        tool_block = tool_use_blocks[0]
        tool_result = {"temperature": 60, "condition": "Foggy"}

        # CORRECT: Include all blocks (thinking + tool_use)
        complete_blocks = thinking_blocks + tool_use_blocks

        complete_response = client.messages.create(
            model=MODEL_NAME,
            max_tokens=MAX_TOKENS,
            thinking={"type": "enabled", "budget_tokens": THINKING_BUDGET_TOKENS},
            tools=tools,
            messages=[
                {"role": "user", "content": "What's the weather in Berlin?"},
                {"role": "assistant", "content": complete_blocks},
                {"role": "user", "content": [{
                    "type": "tool_result",
                    "tool_use_id": tool_block.id,
                    "content": json.dumps(tool_result)
                }]}
            ]
        )
```

## Key Points

### Thinking Block Preservation
1. **Preserve signatures**: Each thinking block contains a cryptographic signature validating conversation context
2. **Include all blocks**: When passing tool results, include both thinking and tool_use blocks
3. **Handle redacted thinking**: Both `thinking` and `redacted_thinking` blocks must be preserved

### Behavior Patterns
- Claude shows thinking **before** making tool requests
- Claude does **not** show thinking after receiving tool results
- New thinking blocks only appear after the next non-`tool_result` user turn
- Multiple tool calls require iterative loops until `stop_reason != "tool_use"`

### Configuration Best Practices
- Set minimum thinking budget: 1,024 tokens
- Match thinking configuration across all API calls in the conversation
- Ensure system prompts and tools remain consistent
- Plan for increased token usage when combining thinking with tools

## Expected Behavior

When tool use is triggered:
- Initial response contains: thinking block → text block → tool_use block
- After tool result: only tool_use block (no thinking block)
- Final response: text block with answer

---

## Relevance to The Agency

**Medium relevance** - Could be useful for:
- Complex multi-tool workflows where reasoning visibility helps debugging
- Quality assurance on agent decisions
- However, adds significant token overhead
- Best reserved for high-stakes or complex decisions rather than routine operations
