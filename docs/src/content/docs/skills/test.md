---
title: "/vibe:test"
sidebar:
  order: 7
---

Generates and runs tests for a given file or directory.

## Usage

```
/vibe:test <path>
```

## What it does

1. **Read standards** — loads `docs/standards/testing.md` for framework conventions
2. **Analyze target** — reads the file to understand its interface and behavior
3. **Generate tests** — creates tests covering:
   - Happy path scenarios
   - Edge cases (empty inputs, boundaries, nulls)
   - Error handling (exceptions, invalid inputs)
4. **Follow conventions** — uses AAA (Arrange/Act/Assert) pattern with descriptive names
5. **Mock external deps** — mocks databases, APIs, file systems — never mocks the unit under test
6. **Run tests** — executes the suite and reports coverage
7. **Fix failures** — automatically fixes any failing tests before finishing

## Test file placement

| Language   | Framework | File pattern | Location            |
| ---------- | --------- | ------------ | ------------------- |
| TypeScript | Vitest    | `*.test.ts`  | Next to source file |
| Python     | pytest    | `test_*.py`  | `tests/` directory  |

## Example

```
/vibe:test src/orders/orders.service.ts
```

Generates `src/orders/orders.service.test.ts` with:

```typescript
describe("OrdersService", () => {
  describe("findById", () => {
    it("should return order when found", async () => {
      // Arrange
      const mockOrder = createOrder({ id: "123" });
      repository.findOne.mockResolvedValue(mockOrder);

      // Act
      const result = await service.findById("123");

      // Assert
      expect(result).toEqual(mockOrder);
    });
  });
});
```
