# Extended Thinking

> Source: https://platform.claude.com/cookbook/extended-thinking-extended-thinking

## Overview

Extended thinking enables Claude to create `thinking` content blocks where it outputs internal reasoning before delivering a final answer. This provides transparency into the model's thought process.

## Setup

```python
%pip install anthropic

import anthropic
import os

client = anthropic.Anthropic()

def print_thinking_response(response):
    """Pretty print a message response with thinking blocks."""
    print("\n==== FULL RESPONSE ====")
    for block in response.content:
        if block.type == "thinking":
            print("\n THINKING BLOCK:")
            print(block.thinking[:500] + "..." if len(block.thinking) > 500 else block.thinking)
            print(f"\n[Signature available: {bool(getattr(block, 'signature', None))}]")
        elif block.type == "redacted_thinking":
            print("\n REDACTED THINKING BLOCK:")
            print(f"[Data length: {len(block.data) if hasattr(block, 'data') else 'N/A'}]")
        elif block.type == "text":
            print("\n FINAL ANSWER:")
            print(block.text)
    print("\n==== END RESPONSE ====")
```

## Basic Example

```python
def basic_thinking_example():
    response = client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=4000,
        thinking={
            "type": "enabled",
            "budget_tokens": 2000
        },
        messages=[{
            "role": "user",
            "content": "Solve this puzzle: Three people check into a hotel..."
        }]
    )

    print_thinking_response(response)

basic_thinking_example()
```

**Key Response Structure:**
- **Thinking Block**: Shows Claude's step-by-step reasoning
- **Text Block**: Final answer explaining the solution

## Streaming with Extended Thinking

```python
def streaming_with_thinking():
    with client.messages.stream(
        model="claude-sonnet-4-5",
        max_tokens=4000,
        thinking={
            "type": "enabled",
            "budget_tokens": 2000
        },
        messages=[{
            "role": "user",
            "content": "Solve this puzzle..."
        }]
    ) as stream:
        current_block_type = None
        current_content = ""

        for event in stream:
            if event.type == "content_block_start":
                current_block_type = event.content_block.type
                print(f"\n--- Starting {current_block_type} block ---")
                current_content = ""

            elif event.type == "content_block_delta":
                if event.delta.type == "thinking_delta":
                    print(event.delta.thinking, end="", flush=True)
                    current_content += event.delta.thinking
                elif event.delta.type == "text_delta":
                    print(event.delta.text, end="", flush=True)
                    current_content += event.delta.text

            elif event.type == "content_block_stop":
                if current_block_type == "thinking":
                    print(f"\n[Completed thinking block, {len(current_content)} characters]")
                print(f"--- Finished {current_block_type} block ---\n")
                current_block_type = None

            elif event.type == "message_stop":
                print("\n--- Message complete ---")

streaming_with_thinking()
```

## Token Counting and Context Window Management

```python
def token_counting_example():
    base_messages = [{"role": "user", "content": "Solve this puzzle..."}]
    base_token_count = client.messages.count_tokens(
        model="claude-sonnet-4-5",
        messages=base_messages
    ).input_tokens

    print(f"Base token count (input only): {base_token_count}")

    # Demo with escalating thinking budgets
    thinking_budgets = [1024, 2000, 4000, 8000, 16000, 32000]
    context_window = 200000

    for budget in thinking_budgets:
        print(f"\nWith thinking budget of {budget} tokens:")
        print(f"Input tokens: {base_token_count}")
        print(f"Max tokens needed: {base_token_count + budget + 1000}")
        print(f"Remaining context window: {context_window - (base_token_count + budget + 1000)}")

        if base_token_count + budget + 1000 > context_window:
            print("WARNING: This would exceed the context window!")

token_counting_example()
```

## Understanding Redacted Thinking Blocks

Occasionally Claude's internal reasoning is flagged by safety systems, which encrypts some or all of the `thinking` block. These are returned as `redacted_thinking` blocks and are decrypted when passed back to the API.

```python
def redacted_thinking_example():
    # Using the special test string that triggers redacted thinking
    response = client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=4000,
        thinking={
            "type": "enabled",
            "budget_tokens": 2000
        },
        messages=[{
            "role": "user",
            "content": "ANTHROPIC_MAGIC_STRING_TRIGGER_REDACTED_THINKING_..."
        }]
    )

    redacted_blocks = [block for block in response.content if block.type == "redacted_thinking"]
    thinking_blocks = [block for block in response.content if block.type == "thinking"]
    text_blocks = [block for block in response.content if block.type == "text"]

    print(f"Response includes {len(response.content)} total blocks:")
    print(f"- {len(redacted_blocks)} redacted thinking blocks")
    print(f"- {len(thinking_blocks)} regular thinking blocks")
    print(f"- {len(text_blocks)} text blocks")
```

## Error Cases

### 1. Minimum Budget Requirement
```python
# Error: Minimum thinking budget is 1,024 tokens
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=4000,
    thinking={
        "type": "enabled",
        "budget_tokens": 500  # Too small - minimum is 1024
    },
    messages=[{"role": "user", "content": "Explain quantum computing."}]
)
```

### 2. Incompatible Features
```python
# Error: Cannot use temperature with thinking
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=4000,
    temperature=0.7,  # Not compatible with thinking
    thinking={
        "type": "enabled",
        "budget_tokens": 2000
    },
    messages=[{"role": "user", "content": "Write a creative story."}]
)
# Error: temperature may only be set to 1 when thinking is enabled
```

### 3. Context Window Limits
```python
# Error: Exceeding context window
long_content = "Please analyze this text. " + "This is sample text. " * 150000

response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=20000,
    thinking={
        "type": "enabled",
        "budget_tokens": 10000
    },
    messages=[{"role": "user", "content": long_content}]
)
# Error: prompt is too long: exceeds 200k token maximum
```

## Important Considerations

1. **Minimum Budget**: Start at 1,024 tokens and increase incrementally
2. **Incompatible Features**:
   - Cannot use `temperature`, `top_p`, or `top_k` modifications
   - Cannot pre-fill responses
3. **Pricing**: Extended thinking tokens count as output tokens and toward rate limits
4. **Context Window**: Claude 3.7 Sonnet has a 200k token context window

---

## Relevance to The Agency

**Medium relevance** - Extended thinking could improve:
- Complex planning and architectural decisions
- Code review quality by showing reasoning
- Debugging complex issues with transparent thought process
- However, adds token cost and may not be needed for routine tasks
