# Python Standards

Tier 2 reference for Python services at Dafiti, targeting Python 3.11+.

## Type Hints

Use type hints everywhere. Prefer modern generics syntax (`list[str]` over `List[str]`).

```python
from typing import Protocol, TypeAlias, TypeVar

# TypeAlias for domain concepts
UserId: TypeAlias = str
JsonDict: TypeAlias = dict[str, object]

# Protocol for structural subtyping (duck-typing with type safety)
class Repository(Protocol[T]):
    async def find_by_id(self, id: str) -> T | None: ...
    async def save(self, entity: T) -> T: ...
    async def delete(self, id: str) -> None: ...

# TypeVar with bound for generic service
T = TypeVar("T")

class CacheService:
    async def get(self, key: str, deserializer: type[T]) -> T | None:
        raw = await self._client.get(key)
        if raw is None:
            return None
        return deserializer.model_validate_json(raw)

    async def set(self, key: str, value: object, ttl_seconds: int = 300) -> None:
        await self._client.set(key, value.model_dump_json(), ex=ttl_seconds)

# Callable type hints
from collections.abc import Callable, Awaitable

EventHandler: TypeAlias = Callable[[str, JsonDict], Awaitable[None]]
```

## Pydantic v2 Models with Validators

Pydantic models are the standard for data validation, serialization, and API schemas.

```python
from pydantic import BaseModel, Field, field_validator, model_validator

class Address(BaseModel):
    street: str = Field(min_length=1)
    city: str = Field(min_length=1)
    state: str = Field(pattern=r"^[A-Z]{2}$")
    zip_code: str = Field(pattern=r"^\d{5}(-\d{4})?$")

class CustomerCreate(BaseModel):
    email: str = Field(max_length=254)
    name: str = Field(min_length=2, max_length=120)
    address: Address
    tags: list[str] = Field(default_factory=list)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("tags")
    @classmethod
    def unique_tags(cls, v: list[str]) -> list[str]:
        return list(dict.fromkeys(v))  # preserve order, remove duplicates

class DateRange(BaseModel):
    start: date
    end: date

    @model_validator(mode="after")
    def end_after_start(self) -> "DateRange":
        if self.end < self.start:
            raise ValueError("end must not precede start")
        return self
```

## Async Patterns

Use `asyncio` for I/O-bound services. Never mix blocking I/O into the async event loop.

```python
import asyncio
import aiohttp

async def fetch_all_products(product_ids: list[str]) -> list[dict]:
    """Fetch multiple products concurrently with a connection pool."""
    async with aiohttp.ClientSession() as session:
        tasks = [_fetch_product(session, pid) for pid in product_ids]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [r for r in results if not isinstance(r, BaseException)]

async def _fetch_product(session: aiohttp.ClientSession, product_id: str) -> dict:
    url = f"https://api.internal/products/{product_id}"
    async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
        resp.raise_for_status()
        return await resp.json()

# Semaphore for rate limiting
async def fetch_with_limit(urls: list[str], max_concurrent: int = 10) -> list[str]:
    semaphore = asyncio.Semaphore(max_concurrent)

    async def _get(url: str) -> str:
        async with semaphore:
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as resp:
                    return await resp.text()

    return await asyncio.gather(*[_get(u) for u in urls])
```

## Ruff Configuration

Use ruff as the single linter and formatter. Configure it in `pyproject.toml`.

```toml
# pyproject.toml
[tool.ruff]
target-version = "py311"
line-length = 120

[tool.ruff.lint]
select = [
    "E",     # pycodestyle errors
    "W",     # pycodestyle warnings
    "F",     # pyflakes
    "I",     # isort
    "N",     # pep8-naming
    "UP",    # pyupgrade
    "B",     # flake8-bugbear
    "SIM",   # flake8-simplify
    "TCH",   # flake8-type-checking
    "RUF",   # ruff-specific rules
]
ignore = ["E501"]  # line length handled by formatter

[tool.ruff.lint.isort]
known-first-party = ["app"]
```

## structlog Setup with Bound Loggers

Use `structlog` for structured JSON logging. Bind request context early and propagate.

```python
import structlog

def configure_logging() -> None:
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

# Usage in a service
logger = structlog.get_logger()

async def process_order(order_id: str) -> None:
    log = logger.bind(order_id=order_id)
    log.info("processing_order_started")

    try:
        result = await _do_process(order_id)
        log.info("processing_order_completed", total=result.total)
    except Exception:
        log.exception("processing_order_failed")
        raise
```

## Context Managers

Use context managers to guarantee cleanup of resources.

```python
from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

@asynccontextmanager
async def db_transaction(pool: asyncpg.Pool) -> AsyncGenerator[asyncpg.Connection, None]:
    conn = await pool.acquire()
    tx = conn.transaction()
    await tx.start()
    try:
        yield conn
        await tx.commit()
    except Exception:
        await tx.rollback()
        raise
    finally:
        await pool.release(conn)

# Usage
async def transfer_funds(pool: asyncpg.Pool, from_id: str, to_id: str, amount: int) -> None:
    async with db_transaction(pool) as conn:
        await conn.execute("UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, from_id)
        await conn.execute("UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, to_id)
```

## Dataclasses vs Pydantic

Use dataclasses for internal value objects that never cross a serialization boundary. Use Pydantic for anything that touches I/O (API input, API output, config, database rows).

```python
from dataclasses import dataclass

# Internal value object — no validation or serialization needed
@dataclass(frozen=True, slots=True)
class Money:
    amount: int       # cents
    currency: str

    def add(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(amount=self.amount + other.amount, currency=self.currency)

# Pydantic — crosses I/O boundary (API response)
class MoneyResponse(BaseModel):
    amount: int
    currency: str
    display: str   # e.g. "$12.50"
```

## FastAPI Integration

FastAPI routes use Pydantic models for request/response and dependency injection for services.

```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Order Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://www.dafiti.com"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/orders", status_code=status.HTTP_201_CREATED, response_model=OrderResponse)
async def create_order(
    body: CreateOrderRequest,
    user: AuthUser = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
) -> OrderResponse:
    order = await service.create(body, user.id)
    return OrderResponse.model_validate(order)

@app.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    service: OrderService = Depends(get_order_service),
) -> OrderResponse:
    order = await service.find(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return OrderResponse.model_validate(order)
```

## Dependency Injection with Depends

Layer dependencies so each function declares exactly what it needs. FastAPI resolves the graph automatically.

```python
from functools import lru_cache
from fastapi import Depends

class Settings(BaseModel):
    database_url: str
    redis_url: str
    jwt_secret: str

@lru_cache
def get_settings() -> Settings:
    return Settings()  # reads from environment variables

async def get_db_pool(settings: Settings = Depends(get_settings)) -> asyncpg.Pool:
    return await asyncpg.create_pool(settings.database_url)

def get_order_repository(pool: asyncpg.Pool = Depends(get_db_pool)) -> OrderRepository:
    return PostgresOrderRepository(pool)

def get_order_service(repo: OrderRepository = Depends(get_order_repository)) -> OrderService:
    return OrderService(repo)

# Auth dependency
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    settings: Settings = Depends(get_settings),
) -> AuthUser:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        return AuthUser(id=payload["sub"], email=payload["email"])
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail="Invalid token") from exc
```
