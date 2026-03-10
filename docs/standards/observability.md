# Observability Standards

## Structured Logging

All services must emit structured JSON logs. Never use `console.log` or `print` in production code.

### Node.js with pino

```typescript
// src/logger.ts
import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  formatters: {
    level(label) {
      return { level: label };
    },
  },
  serializers: {
    err: pino.stdSerializers.err,
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
  },
  base: {
    service: process.env.SERVICE_NAME ?? "unknown",
    env: process.env.NODE_ENV ?? "development",
  },
});

// Request-scoped child logger (use in middleware)
export function requestLogger(req: Request) {
  return logger.child({
    requestId: req.headers["x-request-id"],
    correlationId: req.headers["x-correlation-id"],
    method: req.method,
    path: req.url,
  });
}
```

```typescript
// Express middleware for automatic request logging
import { randomUUID } from "node:crypto";
import { logger, requestLogger } from "./logger";

app.use((req, res, next) => {
  req.headers["x-request-id"] ??= randomUUID();
  req.headers["x-correlation-id"] ??= req.headers["x-request-id"];
  req.log = requestLogger(req);

  const start = performance.now();
  res.on("finish", () => {
    const duration_ms = Math.round(performance.now() - start);
    req.log.info({ statusCode: res.statusCode, duration_ms }, "request completed");
  });
  next();
});
```

### Python with structlog

```python
# app/logging_config.py
import structlog
import logging

def setup_logging(service_name: str, log_level: str = "INFO"):
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            logging.getLevelName(log_level)
        ),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
    )
    # Bind service-level context once
    structlog.contextvars.bind_contextvars(service=service_name)
```

```python
# FastAPI middleware for correlation IDs
import uuid
import structlog
from starlette.middleware.base import BaseHTTPMiddleware

class CorrelationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
        correlation_id = request.headers.get("x-correlation-id", request_id)

        structlog.contextvars.bind_contextvars(
            request_id=request_id,
            correlation_id=correlation_id,
            method=request.method,
            path=request.url.path,
        )
        log = structlog.get_logger()
        log.info("request_started")

        response = await call_next(request)
        response.headers["x-request-id"] = request_id
        response.headers["x-correlation-id"] = correlation_id

        log.info("request_completed", status_code=response.status_code)
        structlog.contextvars.unbind_contextvars(
            "request_id", "correlation_id", "method", "path"
        )
        return response
```

## OpenTelemetry Configuration

```typescript
// src/tracing.ts — initialize BEFORE importing any other module
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { HttpInstrumentation } from "@opentelemetry/instrumentation-http";
import { PgInstrumentation } from "@opentelemetry/instrumentation-pg";
import { Resource } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME } from "@opentelemetry/semantic-conventions";

const sdk = new NodeSDK({
  resource: new Resource({ [ATTR_SERVICE_NAME]: process.env.SERVICE_NAME }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? "http://localhost:4318/v1/traces",
  }),
  instrumentations: [new HttpInstrumentation(), new PgInstrumentation()],
});

sdk.start();
process.on("SIGTERM", () => sdk.shutdown());
```

### Custom Spans

```typescript
import { trace, SpanStatusCode } from "@opentelemetry/api";

const tracer = trace.getTracer("order-service");

async function processOrder(orderId: string) {
  return tracer.startActiveSpan("processOrder", async (span) => {
    span.setAttribute("order.id", orderId);
    try {
      await validateInventory(orderId);
      await chargePayment(orderId);
      span.setStatus({ code: SpanStatusCode.OK });
    } catch (err) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
      span.recordException(err);
      throw err;
    } finally {
      span.end();
    }
  });
}
```

## RED Metrics

Every service must expose Rate, Errors, and Duration for its primary operations.

```typescript
// Prometheus client example
import { Counter, Histogram } from "prom-client";

const httpRequestsTotal = new Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["method", "route", "status_code"] as const,
});

const httpRequestDuration = new Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["method", "route"] as const,
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});

// Middleware
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({ method: req.method, route: req.route?.path ?? req.path });
  res.on("finish", () => {
    httpRequestsTotal.inc({ method: req.method, route: req.route?.path ?? req.path, status_code: res.statusCode });
    end();
  });
  next();
});
```

## Alerting Rules (SLO-based)

Define alerts based on error budgets, not raw thresholds.

```yaml
# Prometheus alerting rule — 99.9% availability SLO
groups:
  - name: slo_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status_code=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.001
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate exceeds 0.1% SLO budget"
          runbook: "https://wiki.dafiti.internal/runbooks/high-error-rate"

      - alert: HighLatencyP99
        expr: |
          histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
          > 2.0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency above 2s"
```

## Health Check Endpoints

```typescript
// GET /healthz — shallow liveness check
app.get("/healthz", (_req, res) => res.status(200).json({ status: "ok" }));

// GET /readyz — deep readiness check
app.get("/readyz", async (_req, res) => {
  const checks: Record<string, string> = {};
  try {
    await pool.query("SELECT 1");
    checks.postgres = "ok";
  } catch {
    checks.postgres = "fail";
  }
  try {
    await redis.ping();
    checks.redis = "ok";
  } catch {
    checks.redis = "fail";
  }

  const healthy = Object.values(checks).every((v) => v === "ok");
  res.status(healthy ? 200 : 503).json({ status: healthy ? "ok" : "degraded", checks });
});
```

## Correlation IDs Across Services

When calling downstream services, always propagate correlation IDs.

```typescript
async function callDownstream(url: string, req: Request) {
  return fetch(url, {
    headers: {
      "x-correlation-id": req.headers["x-correlation-id"],
      "x-request-id": randomUUID(), // New request ID for this leg
      "content-type": "application/json",
    },
  });
}
```

## Runbook Template

Every alert must link to a runbook. Use this structure:

```markdown
## Alert: <AlertName>
### Impact
What user-facing behavior is affected.

### Detection
The Prometheus query or dashboard link that shows the problem.

### Mitigation
Step-by-step actions to restore service (restart, rollback, scale).

### Root Cause Investigation
Where to look: logs, traces, recent deploys, dependency status.

### Escalation
Who to contact if mitigation does not resolve within 15 minutes.
```
