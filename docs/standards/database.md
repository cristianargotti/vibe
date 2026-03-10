# Database Standards

Tier 2 reference for database design, ORMs, migrations, caching, and connection management at Dafiti.

## Schema Design Conventions

All tables MUST include: UUID primary keys, created/updated timestamps, and soft-delete support.

```sql
CREATE TABLE products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku         VARCHAR(50) NOT NULL UNIQUE,
    name        VARCHAR(255) NOT NULL,
    price       NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    category_id UUID NOT NULL REFERENCES categories(id),
    is_active   BOOLEAN NOT NULL DEFAULT true,
    deleted_at  TIMESTAMPTZ,                              -- soft delete
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_category ON products (category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products (sku);
```

## TypeORM Entity with Relations

```typescript
import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany,
  CreateDateColumn, UpdateDateColumn, DeleteDateColumn, Index,
} from 'typeorm';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 20, unique: true })
  orderNumber: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  total: number;

  @Column({ type: 'enum', enum: ['pending', 'paid', 'shipped', 'delivered', 'cancelled'] })
  status: string;

  @ManyToOne(() => Customer, (customer) => customer.orders)
  customer: Customer;

  @Column({ type: 'uuid' })
  customerId: string;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;

  @DeleteDateColumn({ type: 'timestamptz' })
  deletedAt: Date | null;
}

@Entity('order_items')
@Index(['orderId', 'productId'], { unique: true })
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
  order: Order;

  @Column({ type: 'uuid' })
  orderId: string;

  @Column({ type: 'uuid' })
  productId: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  unitPrice: number;
}
```

## TypeORM Migration

```typescript
import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateOrders1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        order_number VARCHAR(20) NOT NULL UNIQUE,
        total NUMERIC(12,2) NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'pending',
        customer_id UUID NOT NULL REFERENCES customers(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        deleted_at TIMESTAMPTZ
      );
      CREATE INDEX idx_orders_customer ON orders (customer_id) WHERE deleted_at IS NULL;
      CREATE INDEX idx_orders_status ON orders (status) WHERE deleted_at IS NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE IF EXISTS orders CASCADE');
  }
}
```

## Prisma Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Customer {
  id        String   @id @default(uuid()) @db.Uuid
  email     String   @unique @db.VarChar(255)
  name      String   @db.VarChar(255)
  orders    Order[]
  deletedAt DateTime? @map("deleted_at") @db.Timestamptz
  createdAt DateTime  @default(now()) @map("created_at") @db.Timestamptz
  updatedAt DateTime  @updatedAt @map("updated_at") @db.Timestamptz

  @@map("customers")
  @@index([email])
}

model Order {
  id          String      @id @default(uuid()) @db.Uuid
  orderNumber String      @unique @map("order_number") @db.VarChar(20)
  total       Decimal     @db.Decimal(12, 2)
  status      OrderStatus @default(pending)
  customer    Customer    @relation(fields: [customerId], references: [id])
  customerId  String      @map("customer_id") @db.Uuid
  items       OrderItem[]
  deletedAt   DateTime?   @map("deleted_at") @db.Timestamptz
  createdAt   DateTime    @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime    @updatedAt @map("updated_at") @db.Timestamptz

  @@map("orders")
  @@index([customerId])
  @@index([status])
}

enum OrderStatus {
  pending
  paid
  shipped
  delivered
  cancelled
}
```

## SQLAlchemy Models

```python
from datetime import datetime
from uuid import uuid4
from sqlalchemy import Column, String, Numeric, ForeignKey, DateTime, Enum, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, relationship

class Base(DeclarativeBase):
    pass

class TimestampMixin:
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

class Order(TimestampMixin, Base):
    __tablename__ = "orders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    order_number = Column(String(20), unique=True, nullable=False)
    total = Column(Numeric(12, 2), nullable=False)
    status = Column(Enum("pending", "paid", "shipped", "delivered", "cancelled", name="order_status"), default="pending")
    customer_id = Column(UUID(as_uuid=True), ForeignKey("customers.id"), nullable=False)

    customer = relationship("Customer", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")

    __table_args__ = (
        Index("idx_orders_customer", "customer_id", postgresql_where="deleted_at IS NULL"),
        Index("idx_orders_status", "status", postgresql_where="deleted_at IS NULL"),
    )
```

## Alembic Migration

```python
"""create orders table

Revision ID: a1b2c3d4e5f6
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

def upgrade():
    op.create_table(
        "orders",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("order_number", sa.String(20), unique=True, nullable=False),
        sa.Column("total", sa.Numeric(12, 2), nullable=False),
        sa.Column("status", sa.String(20), server_default="pending", nullable=False),
        sa.Column("customer_id", UUID(as_uuid=True), sa.ForeignKey("customers.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_orders_customer", "orders", ["customer_id"], postgresql_where="deleted_at IS NULL")

def downgrade():
    op.drop_table("orders")
```

## Indexing Strategy

```sql
-- Composite index: query filters on status then sorts by date
CREATE INDEX idx_orders_status_created ON orders (status, created_at DESC)
  WHERE deleted_at IS NULL;

-- Partial index: only index active rows to keep it small
CREATE INDEX idx_products_active ON products (category_id, price)
  WHERE is_active = true AND deleted_at IS NULL;

-- Covering index: includes columns so Postgres can answer from the index alone
CREATE INDEX idx_orders_covering ON orders (customer_id, status)
  INCLUDE (total, created_at)
  WHERE deleted_at IS NULL;
```

## Connection Pooling

```typescript
// TypeORM — DataSource config
export const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: 5432,
  database: 'dafiti',
  username: process.env.DB_USER,
  password: process.env.DB_PASS,
  extra: {
    max: 20,                 // max connections in pool
    min: 5,                  // min idle connections
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  },
  logging: process.env.NODE_ENV !== 'production',
});
```

```python
# SQLAlchemy
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://user:pass@host:5432/dafiti",
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,          # verify connections before use
    pool_recycle=300,             # recycle connections every 5 min
    connect_args={"connect_timeout": 5},
)
```

## Redis Cache-Aside Pattern

```typescript
import Redis from 'ioredis';

const redis = new Redis({ host: 'redis', port: 6379, maxRetriesPerRequest: 3 });

const TTL = {
  SHORT:  60,       // 1 minute — volatile data
  MEDIUM: 300,      // 5 minutes — product listings
  LONG:   3600,     // 1 hour — category trees
};

async function getProduct(id: string): Promise<Product> {
  const cacheKey = `product:${id}`;

  // 1. Try cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);
  }

  // 2. Fetch from database
  const product = await productRepository.findOneBy({ id });
  if (!product) {
    throw new NotFoundException(`Product ${id} not found`);
  }

  // 3. Populate cache with TTL
  await redis.set(cacheKey, JSON.stringify(product), 'EX', TTL.MEDIUM);

  return product;
}

async function updateProduct(id: string, data: Partial<Product>): Promise<Product> {
  const product = await productRepository.save({ id, ...data });

  // Invalidate cache on write
  await redis.del(`product:${id}`);

  return product;
}
```

## Key Rules

- All tables use UUID primary keys, never auto-increment integers.
- Every table must have `created_at`, `updated_at`, and `deleted_at` columns.
- Use soft deletes (`deleted_at IS NOT NULL`) — never hard-delete business data.
- All partial indexes must filter out soft-deleted rows (`WHERE deleted_at IS NULL`).
- Migrations must be reversible — always implement `down`/`downgrade`.
- Connection pools: 20 max connections per service, with pre-ping enabled.
- Cache invalidation on every write path — stale cache is worse than no cache.
