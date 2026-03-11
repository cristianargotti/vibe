<!-- last-reviewed: 2026-03-11 -->

# LLM & AI Integration Standards

## Prompt Engineering Patterns

Structure prompts with explicit role separation. Always use system messages to set behavior boundaries and output format.

```typescript
// System / User / Assistant role pattern
const messages = [
  {
    role: "system",
    content: `You are a product classifier for Dafiti's catalog.
Rules:
- Respond ONLY with valid JSON matching the schema below.
- If uncertain, set "confidence" below 0.5.
Schema: { "category": string, "subcategory": string, "confidence": number }`,
  },
  // Few-shot examples improve consistency
  {
    role: "user",
    content: "Classify: Nike Air Max 90 running shoe, men's size 42",
  },
  {
    role: "assistant",
    content: '{"category":"Shoes","subcategory":"Running","confidence":0.95}',
  },
  // Actual request
  { role: "user", content: `Classify: ${productDescription}` },
];
```

Use chain-of-thought when the task requires reasoning before an answer.

```typescript
const systemPrompt = `You are a returns-policy assistant.
Think step by step:
1. Identify the product type and purchase date.
2. Check if it falls within the 30-day return window.
3. Determine if the reason qualifies under our policy.
4. Output your final decision as JSON: { "eligible": boolean, "reason": string }
Wrap your reasoning in <thinking> tags. Only the JSON goes outside.`;
```

## RAG Implementation

### Chunking Strategy

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=512,
    chunk_overlap=64,
    separators=["\n\n", "\n", ". ", " "],
)

def chunk_product_docs(raw_text: str, metadata: dict) -> list[dict]:
    chunks = splitter.split_text(raw_text)
    return [
        {"text": chunk, "metadata": {**metadata, "chunk_index": i}}
        for i, chunk in enumerate(chunks)
    ]
```

### Embedding + pgvector Storage

```sql
-- Enable the extension once per database
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE product_embeddings (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id  BIGINT NOT NULL REFERENCES products(id),
    chunk_index INT NOT NULL,
    content     TEXT NOT NULL,
    embedding   vector(1536) NOT NULL,  -- text-embedding-3-small dimension
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX ON product_embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
```

```python
import anthropic
import openai
import psycopg

openai_client = openai.OpenAI()

def embed_and_store(chunks: list[dict], product_id: int):
    texts = [c["text"] for c in chunks]
    response = openai_client.embeddings.create(
        model="text-embedding-3-small", input=texts
    )
    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            for i, emb in enumerate(response.data):
                cur.execute(
                    "INSERT INTO product_embeddings (product_id, chunk_index, content, embedding) "
                    "VALUES (%s, %s, %s, %s)",
                    (product_id, i, texts[i], emb.embedding),
                )
        conn.commit()
```

### Retrieval + Reranking

```python
def retrieve(query: str, top_k: int = 10, rerank_top: int = 3) -> list[dict]:
    query_emb = openai_client.embeddings.create(
        model="text-embedding-3-small", input=[query]
    ).data[0].embedding

    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT content, 1 - (embedding <=> %s::vector) AS similarity "
                "FROM product_embeddings ORDER BY embedding <=> %s::vector LIMIT %s",
                (query_emb, query_emb, top_k),
            )
            candidates = [{"content": row[0], "score": row[1]} for row in cur.fetchall()]

    # Cross-encoder reranking for precision
    reranked = rerank_with_cross_encoder(query, candidates)
    return reranked[:rerank_top]
```

## Model Selection Guide

| Use Case                                         | Model                  | Reason                           |
| ------------------------------------------------ | ---------------------- | -------------------------------- |
| Complex reasoning, code generation, architecture | Claude Opus            | Highest accuracy, handles nuance |
| Summarization, classification, chat              | Claude Sonnet          | Best cost/quality balance        |
| High-volume extraction, tagging, routing         | Claude Haiku           | Lowest latency and cost          |
| Embeddings                                       | text-embedding-3-small | Optimized for vector search      |

Rule of thumb: start with Sonnet, upgrade to Opus only when Sonnet measurably fails on your eval set. Use Haiku for anything that runs per-request at scale.

## Guardrails and Output Validation

Always validate LLM output against a schema before using it downstream.

```typescript
// TypeScript with Zod
import { z } from "zod";

const ClassificationSchema = z.object({
  category: z.string().min(1),
  subcategory: z.string().min(1),
  confidence: z.number().min(0).max(1),
});

function parseClassification(raw: string) {
  const parsed = JSON.parse(raw);
  const result = ClassificationSchema.safeParse(parsed);
  if (!result.success) {
    logger.warn(
      { errors: result.error.issues, raw },
      "LLM output failed validation",
    );
    return null; // Fall back to manual classification
  }
  return result.data;
}
```

```python
# Python with Pydantic
from pydantic import BaseModel, Field, field_validator

class ProductClassification(BaseModel):
    category: str = Field(min_length=1)
    subcategory: str = Field(min_length=1)
    confidence: float = Field(ge=0.0, le=1.0)

    @field_validator("category")
    @classmethod
    def must_be_known_category(cls, v: str) -> str:
        allowed = {"Shoes", "Clothing", "Accessories", "Sports"}
        if v not in allowed:
            raise ValueError(f"Unknown category: {v}")
        return v
```

## Safety Patterns

```python
import re

PII_PATTERNS = [
    (re.compile(r"\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b"), "CPF"),   # Brazilian CPF
    (re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"), "EMAIL"),
    (re.compile(r"\b(?:\+55\s?)?\(?\d{2}\)?\s?\d{4,5}-?\d{4}\b"), "PHONE_BR"),
]

def redact_pii(text: str) -> str:
    for pattern, label in PII_PATTERNS:
        text = pattern.sub(f"[REDACTED_{label}]", text)
    return text

def safe_llm_call(prompt: str, user_input: str) -> str:
    sanitized = redact_pii(user_input)
    response = call_llm(prompt, sanitized)
    return redact_pii(response)  # Also redact any PII the model might generate
```

## Evaluation

Build eval datasets as versioned JSON files. Track precision, recall, and latency per model version.

```python
import json
import time

def run_eval(eval_path: str, classify_fn) -> dict:
    with open(eval_path) as f:
        cases = json.load(f)

    correct, total, latencies = 0, 0, []
    for case in cases:
        t0 = time.perf_counter()
        result = classify_fn(case["input"])
        latencies.append(time.perf_counter() - t0)
        if result and result.category == case["expected_category"]:
            correct += 1
        total += 1

    return {
        "accuracy": correct / total,
        "p95_latency_ms": sorted(latencies)[int(len(latencies) * 0.95)] * 1000,
        "total_cases": total,
    }
```
