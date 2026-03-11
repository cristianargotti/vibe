<!-- last-reviewed: 2026-03-11 -->

# TypeScript Standards

Tier 2 reference for strict TypeScript patterns used across Dafiti services.

## Strict Mode Configuration

Every project must enable strict compiler options. Extend from the shared base config.

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "bundler",
    "target": "ES2022",
    "module": "ES2022",
    "baseUrl": ".",
    "paths": {
      "@/domain/*": ["src/domain/*"],
      "@/app/*": ["src/application/*"],
      "@/infra/*": ["src/infrastructure/*"],
      "@/shared/*": ["src/shared/*"],
    },
  },
}
```

## Zod Schema Patterns

Use Zod as the single source of truth for runtime validation. Derive TypeScript types from schemas, never the reverse.

```ts
import { z } from "zod";

// Define schemas, then derive types
const AddressSchema = z.object({
  street: z.string().min(1),
  city: z.string().min(1),
  state: z.string().min(2).max(5),
  zip: z.string().regex(/^[\dA-Z]{4,10}[-\s]?[\dA-Z]{0,5}$/), // Supports BR (CEP), CO, CL, AR formats
});

const CustomerSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(2).max(120),
  address: AddressSchema,
  tags: z.array(z.string()).default([]),
  createdAt: z.coerce.date(),
});

// Derived types — never define these manually
type Address = z.infer<typeof AddressSchema>;
type Customer = z.infer<typeof CustomerSchema>;

// Partial schemas for updates
const CustomerUpdateSchema = CustomerSchema.partial().omit({
  id: true,
  createdAt: true,
});
type CustomerUpdate = z.infer<typeof CustomerUpdateSchema>;

// Reusable refinements
const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
```

## Custom Error Classes

All services use a structured `AppError` hierarchy. Never throw plain `Error` objects.

```ts
export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly statusCode: number = 500,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super("NOT_FOUND", `${resource} with id ${id} not found`, 404);
  }
}

export class ValidationError extends AppError {
  constructor(errors: Record<string, string[]>) {
    super("VALIDATION_ERROR", "Request validation failed", 400, { errors });
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super("CONFLICT", message, 409);
  }
}

// Usage
function findOrder(id: string): Order {
  const order = db.get(id);
  if (!order) throw new NotFoundError("Order", id);
  return order;
}
```

## Barrel Exports

Each module exposes a single `index.ts` that controls the public API. Internal files must never be imported directly from outside the module.

```ts
// src/domain/customer/index.ts
export { Customer } from "./customer.entity";
export { CustomerRepository } from "./customer.repository";
export type { CreateCustomerInput } from "./customer.types";

// Do NOT re-export internal helpers or private types
```

## Readonly Usage

Default to `readonly` for function parameters, class properties, and return types. Mutability must be an explicit, justified choice.

```ts
interface OrderLine {
  readonly productId: string;
  readonly quantity: number;
  readonly unitPrice: number;
}

function calculateTotal(lines: readonly OrderLine[]): number {
  return lines.reduce((sum, line) => sum + line.quantity * line.unitPrice, 0);
}

// Readonly mapped type for API responses
type ApiResponse<T> = Readonly<{
  data: T;
  meta: { requestId: string; timestamp: string };
}>;
```

## Discriminated Unions

Model domain states as discriminated unions rather than optional fields or boolean flags.

```ts
type PaymentState =
  | { status: "pending"; createdAt: Date }
  | { status: "processing"; transactionId: string }
  | { status: "completed"; transactionId: string; paidAt: Date }
  | { status: "failed"; transactionId: string; reason: string; failedAt: Date };

function describePayment(payment: PaymentState): string {
  switch (payment.status) {
    case "pending":
      return `Awaiting processing since ${payment.createdAt.toISOString()}`;
    case "processing":
      return `Processing transaction ${payment.transactionId}`;
    case "completed":
      return `Paid on ${payment.paidAt.toISOString()}`;
    case "failed":
      return `Failed: ${payment.reason}`;
  }
  // No default needed — TypeScript enforces exhaustiveness
}
```

## Utility Types

Prefer built-in utility types and targeted custom helpers over ad-hoc type gymnastics.

```ts
// Pick only what the consumer needs
type OrderSummary = Pick<Order, "id" | "status" | "total">;

// Make specific fields optional for patch operations
type Updatable<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
type UpdatableCustomer = Updatable<Customer, "name" | "email">;

// Ensure at least one key is provided in a partial update
type AtLeastOne<T> = {
  [K in keyof T]-?: Required<Pick<T, K>> & Partial<Omit<T, K>>;
}[keyof T];

type CustomerPatch = AtLeastOne<Pick<Customer, "name" | "email" | "address">>;

// Branded types for domain identifiers
type Brand<T, B extends string> = T & { readonly __brand: B };
type OrderId = Brand<string, "OrderId">;
type CustomerId = Brand<string, "CustomerId">;

function createOrderId(raw: string): OrderId {
  if (!raw.startsWith("ORD-")) throw new Error("Invalid order id format");
  return raw as OrderId;
}
```

## Path Aliases

Always use path aliases from `tsconfig.json` — never relative paths that climb more than one level.

```ts
// Correct
import { CustomerRepository } from "@/domain/customer";
import { AppError } from "@/shared/errors";

// Wrong — deep relative paths are fragile and unreadable
import { CustomerRepository } from "../../../domain/customer/customer.repository";
```
