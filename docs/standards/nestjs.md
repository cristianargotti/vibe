# NestJS Standards

Tier 2 reference for NestJS service architecture following hexagonal design principles.

## Hexagonal Architecture Folder Structure

Every NestJS module follows this directory layout. The domain layer has zero framework imports.

```
src/
  modules/
    order/
      domain/
        order.entity.ts          # Pure domain model
        order.repository.ts      # Port (abstract class)
        order.errors.ts          # Domain-specific errors
      application/
        create-order.use-case.ts # Orchestrates domain logic
        order.service.ts         # Application service facade
        dto/
          create-order.dto.ts
          order-response.dto.ts
      infrastructure/
        order-typeorm.repository.ts   # Adapter — implements port
        order.controller.ts
        order.module.ts
  shared/
    filters/
      app-exception.filter.ts
    guards/
      jwt-auth.guard.ts
    interceptors/
      logging.interceptor.ts
    decorators/
      current-user.decorator.ts
```

## Controller / Service / Repository Pattern

Controllers handle HTTP concerns only. Services contain orchestration logic. Repositories encapsulate data access behind an abstract port.

```ts
// domain/order.entity.ts
export class Order {
  constructor(
    public readonly id: string,
    public readonly customerId: string,
    public readonly items: readonly OrderItem[],
    public readonly status: OrderStatus,
    public readonly createdAt: Date,
  ) {}

  get total(): number {
    return this.items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);
  }

  cancel(): Order {
    if (this.status !== "pending") {
      throw new OrderDomainError("Only pending orders can be cancelled");
    }
    return new Order(this.id, this.customerId, this.items, "cancelled", this.createdAt);
  }
}

// domain/order.repository.ts — the port
export abstract class OrderRepository {
  abstract findById(id: string): Promise<Order | null>;
  abstract save(order: Order): Promise<Order>;
  abstract findByCustomer(customerId: string, page: number, limit: number): Promise<Order[]>;
}

// application/order.service.ts
@Injectable()
export class OrderService {
  constructor(private readonly orderRepo: OrderRepository) {}

  async create(dto: CreateOrderDto, userId: string): Promise<Order> {
    const order = new Order(randomUUID(), userId, dto.items, "pending", new Date());
    return this.orderRepo.save(order);
  }

  async cancel(orderId: string): Promise<Order> {
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);
    const cancelled = order.cancel();
    return this.orderRepo.save(cancelled);
  }
}

// infrastructure/order.controller.ts
@Controller("orders")
@UseGuards(JwtAuthGuard)
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() dto: CreateOrderDto,
    @CurrentUser() user: AuthUser,
  ): Promise<OrderResponseDto> {
    const order = await this.orderService.create(dto, user.id);
    return OrderResponseDto.from(order);
  }

  @Patch(":id/cancel")
  async cancel(@Param("id", ParseUUIDPipe) id: string): Promise<OrderResponseDto> {
    const order = await this.orderService.cancel(id);
    return OrderResponseDto.from(order);
  }
}
```

## DTOs with class-validator

DTOs live in the application layer. Use `class-validator` decorators for input and explicit static factories for output.

```ts
// application/dto/create-order.dto.ts
import { IsArray, IsInt, IsUUID, Min, ValidateNested } from "class-validator";
import { Type } from "class-transformer";

class OrderItemDto {
  @IsUUID()
  productId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}

// application/dto/order-response.dto.ts
export class OrderResponseDto {
  id: string;
  status: string;
  total: number;
  createdAt: string;

  static from(order: Order): OrderResponseDto {
    const dto = new OrderResponseDto();
    dto.id = order.id;
    dto.status = order.status;
    dto.total = order.total;
    dto.createdAt = order.createdAt.toISOString();
    return dto;
  }
}
```

## Guards for Auth

Guards run before interceptors and pipes. Use them exclusively for authentication and authorization.

```ts
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);
    if (!token) throw new UnauthorizedException("Missing bearer token");

    try {
      const payload = await this.jwtService.verifyAsync(token);
      request["user"] = payload;
      return true;
    } catch {
      throw new UnauthorizedException("Invalid or expired token");
    }
  }

  private extractToken(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(" ") ?? [];
    return type === "Bearer" ? token : undefined;
  }
}
```

## Interceptors for Logging and Transforms

Use interceptors for cross-cutting concerns that wrap the request lifecycle.

```ts
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const { method, url } = request;
    const start = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - start;
        this.logger.log(`${method} ${url} completed in ${duration}ms`);
      }),
      catchError((error) => {
        const duration = Date.now() - start;
        this.logger.error(`${method} ${url} failed after ${duration}ms: ${error.message}`);
        throw error;
      }),
    );
  }
}
```

## Module Encapsulation

Each module explicitly declares what it exports. Never use `@Global()` except for truly cross-cutting infrastructure (config, logging).

```ts
@Module({
  imports: [TypeOrmModule.forFeature([OrderEntity])],
  controllers: [OrderController],
  providers: [
    OrderService,
    { provide: OrderRepository, useClass: OrderTypeOrmRepository },
  ],
  exports: [OrderService], // Only expose the service, never the repository
})
export class OrderModule {}
```

## Custom Decorators

Extract repeated parameter-extraction logic into custom decorators.

```ts
import { createParamDecorator, ExecutionContext } from "@nestjs/common";

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user as AuthUser;
  },
);
```

## Exception Filters

A global filter translates `AppError` instances into consistent HTTP responses.

```ts
@Catch()
export class AppExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(AppExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    if (exception instanceof AppError) {
      response.status(exception.statusCode).json({
        code: exception.code,
        message: exception.message,
        details: exception.details,
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      response.status(status).json(exception.getResponse());
      return;
    }

    this.logger.error("Unhandled exception", exception);
    response.status(500).json({ code: "INTERNAL_ERROR", message: "Internal server error" });
  }
}
```
