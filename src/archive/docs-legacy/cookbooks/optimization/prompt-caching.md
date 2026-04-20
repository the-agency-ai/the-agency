# Prompt Caching with Claude API

> Source: https://github.com/anthropics/anthropic-cookbook/blob/main/misc/prompt_caching.ipynb

## Core Concept

Prompt caching enables storing and reusing context within prompts, offering substantial performance and cost improvements:
- **Latency reduction**: >2x faster responses
- **Cost reduction**: Up to 90% savings

## How Caching Works

### Cache Control Parameter

Add `cache_control: {"type": "ephemeral"}` to content blocks to create cache entries:

```python
import anthropic

client = anthropic.Anthropic()

# First call - creates cache
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": large_document,  # e.g., 187,000 tokens
                    "cache_control": {"type": "ephemeral"}
                },
                {
                    "type": "text",
                    "text": "What is the main theme of this document?"
                }
            ]
        }
    ]
)

# Check cache statistics
print(f"Cache creation tokens: {response.usage.cache_creation_input_tokens}")
print(f"Cache read tokens: {response.usage.cache_read_input_tokens}")
```

### Three Scenarios

1. **Non-cached baseline**: Standard API calls process all tokens normally
2. **Cache creation**: First call with `cache_control` stores tokens
3. **Cache hits**: Subsequent identical calls read from cache (1.9x speed improvement)

## Usage Statistics

Track these in the response:
- `cache_creation_input_tokens` - Tokens stored during initial call
- `cache_read_input_tokens` - Tokens retrieved from cache
- `input_tokens` / `output_tokens` - Standard token counts

## Multi-Turn Conversation Strategy

```python
class ConversationHistory:
    def __init__(self, system_prompt: str = None):
        self.turns = []
        self.system_prompt = system_prompt

    def add_user_message(self, content: str):
        self.turns.append({"role": "user", "content": content})

    def add_assistant_message(self, content: str):
        self.turns.append({"role": "assistant", "content": content})

    def get_messages_with_cache(self):
        """Apply cache control to most recent user message only."""
        messages = []
        for i, turn in enumerate(self.turns):
            if i == len(self.turns) - 1 and turn["role"] == "user":
                # Cache the latest user message
                messages.append({
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": turn["content"],
                            "cache_control": {"type": "ephemeral"}
                        }
                    ]
                })
            else:
                messages.append(turn)
        return messages
```

**Performance Pattern:**
- Initial response: ~5.8 seconds
- Subsequent turns: 8-10 seconds
- Nearly 100% of input cached after first exchange

## Best Use Cases

Caching is most valuable for:
- **Large documents/codebases** remaining constant across queries
- **System prompts** with extensive instructions
- **Multi-turn conversations** reducing cumulative processing costs
- **Repeated analysis** of the same source material

## Caching Limitations

- Cache entries are ephemeral (short-lived)
- Minimum content size required for caching
- Cache must be identical across calls to hit
- Different models don't share caches

---

## Relevance to The Agency

**High relevance** - Direct applications:

| Use Case | Agency Application |
|----------|-------------------|
| Large context | Agent.md + KNOWLEDGE.md caching across turns |
| System prompts | Agent identity caching |
| Multi-turn | Long work sessions with context preservation |
| Repeated analysis | Code review of same files |

**Enhancement opportunity**: Integrate caching into `./tools/myclaude` session management to reduce token costs for long-running agents.
