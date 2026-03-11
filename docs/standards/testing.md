<!-- last-reviewed: 2026-03-11 -->

# Testing Standards

## Vitest Setup and Configuration

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.ts"],
    coverage: {
      provider: "v8", // Prefer v8 over istanbul for speed
      reporter: ["text", "lcov", "json-summary"],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
      exclude: ["src/**/*.test.ts", "src/**/index.ts", "src/generated/**"],
    },
    setupFiles: ["./src/test/setup.ts"],
  },
  resolve: {
    alias: { "@": path.resolve(__dirname, "src") },
  },
});
```

```typescript
// src/test/setup.ts — global test setup
import { beforeAll, afterAll } from "vitest";

beforeAll(() => {
  process.env.NODE_ENV = "test";
  process.env.DATABASE_URL = "postgres://test:test@localhost:5433/test_db";
});

afterAll(() => {
  // Clean up global resources
});
```

## pytest Setup and Fixtures

```python
# conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.database import engine, Base

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture(scope="session", autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest.fixture
def order_factory(db_session):
    """Factory fixture for creating test orders with defaults."""
    async def _create(**overrides):
        defaults = {
            "customer_id": "cust_test_123",
            "status": "pending",
            "total": 100.0,
        }
        data = {**defaults, **overrides}
        order = Order(**data)
        db_session.add(order)
        await db_session.flush()
        return order
    return _create
```

```ini
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "-v --tb=short --strict-markers"
markers = [
    "integration: marks tests that need external services",
    "slow: marks tests that take more than 5s",
]

[tool.coverage.run]
source = ["app"]
omit = ["app/test/*", "app/migrations/*"]

[tool.coverage.report]
fail_under = 80
show_missing = true
```

## Test Structure

Follow Arrange-Act-Assert. Use descriptive `describe`/`it` blocks.

```typescript
// src/services/order.service.test.ts
import { describe, it, expect, beforeEach } from "vitest";
import { OrderService } from "./order.service";

describe("OrderService", () => {
  let service: OrderService;

  beforeEach(() => {
    service = new OrderService(mockRepo, mockPaymentClient);
  });

  describe("createOrder", () => {
    it("creates an order with valid items and returns order ID", async () => {
      // Arrange
      const items = [{ productId: "prod_1", quantity: 2 }];

      // Act
      const result = await service.createOrder("cust_123", items);

      // Assert
      expect(result.id).toMatch(/^ord_/);
      expect(result.status).toBe("pending");
      expect(result.items).toHaveLength(1);
    });

    it("throws when cart is empty", async () => {
      await expect(service.createOrder("cust_123", [])).rejects.toThrow(
        "Cart must contain at least one item",
      );
    });

    it("rejects quantities exceeding available stock", async () => {
      mockRepo.getStock.mockResolvedValue(5);
      const items = [{ productId: "prod_1", quantity: 10 }];

      await expect(service.createOrder("cust_123", items)).rejects.toThrow(
        "Insufficient stock",
      );
    });
  });
});
```

## Mocking Patterns

### Vitest

```typescript
import { vi, describe, it, expect } from "vitest";

// Mock an entire module
vi.mock("@/clients/payment", () => ({
  PaymentClient: vi.fn().mockImplementation(() => ({
    charge: vi.fn().mockResolvedValue({ transactionId: "txn_mock" }),
    refund: vi.fn().mockResolvedValue({ refunded: true }),
  })),
}));

// Spy on a specific method
const chargespy = vi.spyOn(paymentClient, "charge");
await service.processPayment(order);
expect(chargespy).toHaveBeenCalledWith({
  amount: 199.9,
  currency: "BRL",
  orderId: "ord_123",
});
```

### Python unittest.mock

```python
from unittest.mock import AsyncMock, patch

@patch("app.services.order.PaymentClient")
async def test_process_payment(mock_payment_cls, client, order_factory):
    mock_client = AsyncMock()
    mock_client.charge.return_value = {"transaction_id": "txn_mock"}
    mock_payment_cls.return_value = mock_client

    order = await order_factory(total=250.0)
    response = await client.post(f"/v1/orders/{order.id}/pay")

    assert response.status_code == 200
    mock_client.charge.assert_called_once_with(amount=250.0, currency="BRL")
```

## Testcontainers for Integration Tests

Use real databases in CI. Testcontainers manages container lifecycle automatically.

```typescript
// src/test/integration/order.repo.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  PostgreSqlContainer,
  StartedPostgreSqlContainer,
} from "@testcontainers/postgresql";
import { OrderRepository } from "@/repositories/order.repository";
import { migrate } from "@/database/migrate";

describe("OrderRepository (integration)", () => {
  let container: StartedPostgreSqlContainer;
  let repo: OrderRepository;

  beforeAll(async () => {
    container = await new PostgreSqlContainer("postgres:16-alpine")
      .withDatabase("test")
      .start();
    const connectionString = container.getConnectionUri();
    await migrate(connectionString);
    repo = new OrderRepository(connectionString);
  }, 60_000);

  afterAll(async () => {
    await container.stop();
  });

  it("persists and retrieves an order by ID", async () => {
    const created = await repo.create({
      customerId: "cust_1",
      items: [],
      total: 99.9,
    });
    const found = await repo.findById(created.id);
    expect(found).toMatchObject({ customerId: "cust_1", total: 99.9 });
  });
});
```

```python
# tests/integration/test_order_repo.py
import pytest
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="module")
def postgres():
    with PostgresContainer("postgres:16-alpine") as pg:
        yield pg

@pytest.fixture
def repo(postgres):
    from app.repositories.order import OrderRepository
    return OrderRepository(dsn=postgres.get_connection_url())

async def test_create_and_find(repo):
    order = await repo.create(customer_id="cust_1", total=150.0)
    found = await repo.find_by_id(order.id)
    assert found.customer_id == "cust_1"
    assert found.total == 150.0
```

## E2E Testing with Playwright

```typescript
// e2e/checkout.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Checkout flow", () => {
  test("completes purchase with credit card", async ({ page }) => {
    await page.goto("/products/nike-air-max");
    await page.getByRole("button", { name: "Add to Cart" }).click();
    await page.getByRole("link", { name: "Go to Cart" }).click();

    await expect(page.getByTestId("cart-count")).toHaveText("1");

    await page.getByRole("button", { name: "Checkout" }).click();
    await page.getByLabel("Card Number").fill("4111111111111111");
    await page.getByLabel("Expiry").fill("12/27");
    await page.getByLabel("CVV").fill("123");
    await page.getByRole("button", { name: "Place Order" }).click();

    await expect(page.getByText("Order confirmed")).toBeVisible({
      timeout: 10_000,
    });
  });
});
```

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: process.env.BASE_URL ?? "http://localhost:3000",
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
    { name: "mobile", use: { ...devices["iPhone 14"] } },
  ],
});
```

## Test Data Factories / Builders

Centralize test data creation to keep tests DRY and readable.

```typescript
// src/test/factories/order.factory.ts
interface OrderAttrs {
  id?: string;
  customerId?: string;
  status?: "pending" | "confirmed" | "shipped";
  total?: number;
  items?: { productId: string; quantity: number }[];
}

let seq = 0;

export function buildOrder(overrides: OrderAttrs = {}) {
  seq += 1;
  return {
    id: `ord_test_${seq}`,
    customerId: "cust_default",
    status: "pending" as const,
    total: 100.0,
    items: [{ productId: "prod_1", quantity: 1 }],
    ...overrides,
  };
}

// Usage in tests
const order = buildOrder({ status: "confirmed", total: 350 });
```

## Contract Testing

Verify API contracts between services stay in sync using Pact.

```typescript
// src/test/contract/order-api.pact.test.ts
import { PactV4, MatchersV3 } from "@pact-foundation/pact";
const { like, eachLike, uuid } = MatchersV3;

const pact = new PactV4({
  consumer: "checkout-bff",
  provider: "order-service",
});

test("GET /v1/orders/:id returns an order", async () => {
  await pact
    .addInteraction()
    .given("order ord_abc exists")
    .uponReceiving("a request to get order ord_abc")
    .withRequest("GET", "/v1/orders/ord_abc")
    .willRespondWith(200, (b) => {
      b.jsonBody({
        data: {
          id: like("ord_abc"),
          status: like("confirmed"),
          total: like(199.9),
          items: eachLike({ productId: uuid(), quantity: like(1) }),
        },
      });
    })
    .executeTest(async (mockServer) => {
      const res = await fetch(`${mockServer.url}/v1/orders/ord_abc`);
      const body = await res.json();
      expect(body.data.id).toBe("ord_abc");
    });
});
```
