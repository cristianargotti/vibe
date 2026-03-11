<!-- last-reviewed: 2026-03-11 -->

# API Design Standards

## REST Endpoint Naming

Use plural nouns, lowercase, kebab-case. Never use verbs in the URL path.

```
GET    /v1/orders                  # List orders
POST   /v1/orders                  # Create order
GET    /v1/orders/{orderId}        # Get single order
PATCH  /v1/orders/{orderId}        # Partial update
DELETE /v1/orders/{orderId}        # Delete/cancel

GET    /v1/orders/{orderId}/items  # Sub-resource listing
POST   /v1/orders/{orderId}/items  # Add item to order

# Actions that don't map to CRUD — use a verb sub-path
POST   /v1/orders/{orderId}/cancel
POST   /v1/payments/{paymentId}/refund
```

## Cursor-Based Pagination

Use opaque cursors, never page numbers. Encode the sort key into the cursor.

```typescript
// Encode/decode helpers
function encodeCursor(id: string, createdAt: Date): string {
  return Buffer.from(
    JSON.stringify({ id, t: createdAt.toISOString() }),
  ).toString("base64url");
}
function decodeCursor(cursor: string) {
  return JSON.parse(Buffer.from(cursor, "base64url").toString());
}

// Query builder
async function listOrders(cursor?: string, limit = 20) {
  let query = "SELECT * FROM orders";
  const params: unknown[] = [];

  if (cursor) {
    const { id, t } = decodeCursor(cursor);
    query += " WHERE (created_at, id) < ($1, $2)";
    params.push(t, id);
  }
  query += " ORDER BY created_at DESC, id DESC LIMIT $" + (params.length + 1);
  params.push(limit + 1); // Fetch one extra to detect hasMore

  const rows = await pool.query(query, params);
  const hasMore = rows.length > limit;
  const data = rows.slice(0, limit);

  return {
    data,
    pagination: {
      hasMore,
      nextCursor: hasMore
        ? encodeCursor(data.at(-1).id, data.at(-1).created_at)
        : null,
    },
  };
}
```

Response shape:

```json
{
  "data": [{ "id": "ord_abc", "total": 199.9 }],
  "pagination": {
    "hasMore": true,
    "nextCursor": "eyJpZCI6Im9yZF9hYmMiLCJ0IjoiMjAyNS0wMS0wMVQwMDowMDowMFoifQ"
  }
}
```

## Standard Error Response Format

All errors must follow this structure. Use RFC 7807 problem detail when applicable.

```typescript
interface ApiError {
  error: {
    code: string; // Machine-readable, e.g. "ORDER_NOT_FOUND"
    message: string; // Human-readable description
    details?: unknown[]; // Validation errors, per-field info
    requestId: string; // Correlation back to logs
  };
}

// Example error handler
app.use((err, req, res, _next) => {
  const status = err.status ?? 500;
  const code = err.code ?? "INTERNAL_ERROR";
  if (status >= 500) req.log.error({ err }, "unhandled error");

  res.status(status).json({
    error: {
      code,
      message: status >= 500 ? "An internal error occurred" : err.message,
      details: err.details ?? [],
      requestId: req.headers["x-request-id"],
    },
  });
});
```

## API Versioning

Use URL-path versioning (`/v1/`, `/v2/`). Header-based versioning adds complexity with minimal benefit.

- Breaking changes require a new version prefix.
- Additive changes (new optional fields, new endpoints) ship under the current version.
- Deprecate old versions with a `Sunset` header and a minimum 90-day migration window.

```typescript
app.use("/v1/orders", ordersV1Router);
app.use("/v2/orders", ordersV2Router);

// Sunset header middleware for deprecated version
app.use("/v1", (_req, res, next) => {
  res.setHeader("Sunset", "Sat, 01 Nov 2025 00:00:00 GMT");
  res.setHeader("Deprecation", "true");
  next();
});
```

## Rate Limiting

```typescript
import rateLimit from "express-rate-limit";

// Global rate limit
app.use(
  rateLimit({
    windowMs: 60_000,
    max: 100,
    standardHeaders: true, // RateLimit-* headers (RFC draft)
    keyGenerator: (req) => req.headers["x-api-key"] ?? req.ip,
  }),
);

// Endpoint-specific stricter limit
const createOrderLimiter = rateLimit({ windowMs: 60_000, max: 10 });
app.post("/v1/orders", createOrderLimiter, createOrderHandler);
```

## Request Validation Middleware

Validate all inputs at the boundary. Never trust user input.

```typescript
import { z } from "zod";

const CreateOrderBody = z.object({
  items: z
    .array(
      z.object({
        productId: z.string().uuid(),
        quantity: z.number().int().min(1).max(99),
      }),
    )
    .min(1)
    .max(50),
  shippingAddressId: z.string().uuid(),
  couponCode: z.string().max(32).optional(),
});

function validate<T>(schema: z.ZodSchema<T>) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(422).json({
        error: {
          code: "VALIDATION_ERROR",
          message: "Request body validation failed",
          details: result.error.issues,
          requestId: req.headers["x-request-id"],
        },
      });
    }
    req.validatedBody = result.data;
    next();
  };
}

app.post("/v1/orders", validate(CreateOrderBody), createOrderHandler);
```

## Idempotency Keys

Protect create operations from duplicate requests. Clients must send `Idempotency-Key`.

```typescript
async function idempotencyMiddleware(req, res, next) {
  const key = req.headers["idempotency-key"];
  if (!key)
    return res
      .status(400)
      .json({
        error: {
          code: "MISSING_IDEMPOTENCY_KEY",
          message: "Idempotency-Key header is required",
        },
      });

  const cached = await redis.get(`idempotency:${key}`);
  if (cached) {
    const { status, body } = JSON.parse(cached);
    return res.status(status).json(body);
  }

  const originalJson = res.json.bind(res);
  res.json = (body) => {
    redis.set(
      `idempotency:${key}`,
      JSON.stringify({ status: res.statusCode, body }),
      "EX",
      86400,
    );
    return originalJson(body);
  };
  next();
}

app.post(
  "/v1/orders",
  idempotencyMiddleware,
  validate(CreateOrderBody),
  createOrderHandler,
);
```

## Bulk Operations

Use a batch endpoint when clients need to operate on multiple resources. Return per-item results.

```typescript
// POST /v1/products/batch-update
const BatchUpdateBody = z.object({
  operations: z
    .array(
      z.object({
        productId: z.string().uuid(),
        update: z.object({
          price: z.number().positive().optional(),
          stock: z.number().int().min(0).optional(),
        }),
      }),
    )
    .min(1)
    .max(100),
});

async function batchUpdateHandler(req, res) {
  const results = await Promise.allSettled(
    req.validatedBody.operations.map((op) =>
      updateProduct(op.productId, op.update),
    ),
  );

  const response = results.map((r, i) => ({
    productId: req.validatedBody.operations[i].productId,
    status: r.status === "fulfilled" ? "success" : "error",
    error: r.status === "rejected" ? r.reason.message : undefined,
  }));

  const hasErrors = response.some((r) => r.status === "error");
  res.status(hasErrors ? 207 : 200).json({ results: response });
}
```

## HATEOAS Links

Include navigational links so clients can discover related actions.

```json
{
  "data": {
    "id": "ord_abc",
    "status": "confirmed",
    "total": 299.9
  },
  "_links": {
    "self": { "href": "/v1/orders/ord_abc" },
    "items": { "href": "/v1/orders/ord_abc/items" },
    "cancel": { "href": "/v1/orders/ord_abc/cancel", "method": "POST" },
    "invoice": { "href": "/v1/orders/ord_abc/invoice" }
  }
}
```

## OpenAPI Documentation

Co-locate OpenAPI specs in the repo. Generate them from Zod schemas when possible.

```typescript
import {
  extendZodWithOpenApi,
  OpenApiGeneratorV3,
} from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

extendZodWithOpenApi(z);

const OrderSchema = z
  .object({
    id: z.string().openapi({ example: "ord_abc123" }),
    status: z.enum(["pending", "confirmed", "shipped", "delivered"]),
    total: z.number().openapi({ example: 299.9 }),
  })
  .openapi("Order");

// Registry and generator produce the full spec as JSON
```
