# Batch Processing with Message Batches API

> Source: https://github.com/anthropics/anthropic-cookbook/blob/main/misc/batch_processing.ipynb

## Overview

Asynchronous bulk processing of API requests using Claude's Message Batches API, which **reduces costs by 50%** compared to synchronous requests.

## Core Learning Objectives

- Creating and submitting message batches
- Monitoring batch processing status in real-time
- Retrieving results after completion
- Best practices for effective batching

## Basic Implementation

### Prepare and Submit Batch

```python
import anthropic

client = anthropic.Anthropic()

# Prepare questions for batch processing
questions = [
    "What are the benefits of solar panels?",
    "How do I diversify my investment portfolio?",
    "What's the best basketball defensive strategy?",
    "Why do leaves change color in autumn?"
]

# Format requests with custom IDs
requests = [
    {
        "custom_id": f"question_{i}",
        "params": {
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [
                {"role": "user", "content": question}
            ]
        }
    }
    for i, question in enumerate(questions)
]

# Submit batch
batch = client.beta.messages.batches.create(requests=requests)
print(f"Batch ID: {batch.id}")
print(f"Status: {batch.processing_status}")
```

### Monitor Progress

```python
import time

def monitor_batch(batch_id: str, poll_interval: int = 5):
    """Poll batch status until complete."""
    while True:
        batch = client.beta.messages.batches.retrieve(batch_id)
        print(f"Status: {batch.processing_status}")
        print(f"  - Succeeded: {batch.request_counts.succeeded}")
        print(f"  - Processing: {batch.request_counts.processing}")
        print(f"  - Errored: {batch.request_counts.errored}")

        if batch.processing_status == "ended":
            return batch

        time.sleep(poll_interval)

completed_batch = monitor_batch(batch.id)
```

### Retrieve Results

```python
# Get results after completion
results = client.beta.messages.batches.results(completed_batch.id)

for result in results:
    custom_id = result.custom_id
    if result.result.type == "succeeded":
        response_text = result.result.message.content[0].text
        print(f"{custom_id}: {response_text[:100]}...")
    else:
        print(f"{custom_id}: Error - {result.result.error}")
```

## Advanced: Diverse Request Types

Handle multiple request types in a single batch:

```python
import base64

# Load image for analysis
with open("image.jpg", "rb") as f:
    image_data = base64.standard_b64encode(f.read()).decode("utf-8")

mixed_requests = [
    # Simple question
    {
        "custom_id": "simple_question",
        "params": {
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [
                {"role": "user", "content": "What is the capital of France?"}
            ]
        }
    },
    # Image analysis
    {
        "custom_id": "image_analysis",
        "params": {
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_data
                            }
                        },
                        {
                            "type": "text",
                            "text": "Describe this image in detail."
                        }
                    ]
                }
            ]
        }
    },
    # With system prompt
    {
        "custom_id": "with_system",
        "params": {
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "system": "You are a helpful coding assistant.",
            "messages": [
                {"role": "user", "content": "Write a Python function to reverse a string."}
            ]
        }
    },
    # Multi-turn conversation
    {
        "custom_id": "multi_turn",
        "params": {
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [
                {"role": "user", "content": "What is 2+2?"},
                {"role": "assistant", "content": "2+2 equals 4."},
                {"role": "user", "content": "And what is that times 3?"}
            ]
        }
    }
]
```

## Batch Request Lifecycle

```
submitted → in_progress → ended
                ↓
         Request States:
         - succeeded
         - errored
         - canceled
         - expired
```

## Best Practices

1. **Use meaningful custom_ids**: Makes result correlation easy
2. **Handle errors gracefully**: Check result type before accessing message
3. **Appropriate poll intervals**: 5-30 seconds depending on batch size
4. **Batch similar requests**: Group by model and token limits when possible
5. **Monitor quotas**: Batch API has separate rate limits

## Cost Comparison

| Method | Cost | Latency |
|--------|------|---------|
| Synchronous | 100% | Real-time |
| Batch | **50%** | Minutes to hours |

---

## Relevance to The Agency

**Medium-High relevance** - Applications:

| Use Case | Agency Application |
|----------|-------------------|
| Bulk processing | Mass code review of multiple files |
| Cost reduction | Background analysis tasks |
| Parallel analysis | Multi-file understanding |
| Report generation | Sprint summaries across agents |

**Enhancement opportunity**: Create `./tools/batch-process` for submitting bulk analysis jobs that don't need real-time responses. Could be used for:
- End-of-day code review batches
- Knowledge indexing updates
- Cross-agent summary generation
