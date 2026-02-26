---
name: ddd
description: DDD 전술적 패턴 가이드. Entity, Value Object, Aggregate, Repository, Domain Service, Domain Event 등 도메인 모델링 시 참조한다.
---

# DDD Skill - DDD 전술적 패턴 규칙

도메인 주도 설계(DDD)의 전술적 패턴과 규칙을 정의한다.
NestJS 레이어 규칙은 `../Coding/backend.md`, 공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. Entity

### 정의
- 식별자(id)로 구분되는 도메인 객체다
- 동등성 비교는 id로 한다 (`equals` 메서드)
- 비즈니스 로직을 Entity 내부에 캡슐화한다 (Rich Domain Model)

```typescript
// Bad - Anemic Entity (getter/setter만 있는 빈 껍데기)
class Order {
  id: string;
  status: OrderStatus;
  items: OrderItem[];
  totalAmount: number;

  getId(): string { return this.id; }
  getStatus(): OrderStatus { return this.status; }
  setStatus(status: OrderStatus): void { this.status = status; }
  setTotalAmount(amount: number): void { this.totalAmount = amount; }
}

// Service에 비즈니스 로직이 흩어져 있음
class OrderService {
  cancel(order: Order): void {
    if (order.getStatus() !== OrderStatus.PENDING) {
      throw new Error('Cannot cancel');
    }
    order.setStatus(OrderStatus.CANCELLED);
  }

  calculateTotal(order: Order): void {
    let total = 0;
    for (const item of order.items) {
      total += item.price * item.quantity;
    }
    order.setTotalAmount(total);
  }
}
```

```typescript
// Good - Rich Entity (상태 변경 메서드를 Entity가 직접 제공, 불변식 보호)
class Order {
  private readonly _id: string;
  private _status: OrderStatus;
  private readonly _items: OrderItem[];

  constructor(id: string, items: OrderItem[]) {
    if (items.length === 0) {
      throw new Error('Order must have at least one item');
    }
    this._id = id;
    this._status = OrderStatus.PENDING;
    this._items = items;
  }

  get id(): string { return this._id; }
  get status(): OrderStatus { return this._status; }
  get items(): ReadonlyArray<OrderItem> { return [...this._items]; }

  get totalAmount(): number {
    return this._items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
  }

  cancel(): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new Error('Only pending orders can be cancelled');
    }
    this._status = OrderStatus.CANCELLED;
  }

  confirm(): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new Error('Only pending orders can be confirmed');
    }
    this._status = OrderStatus.CONFIRMED;
  }

  equals(other: Order): boolean {
    return this._id === other._id;
  }
}
```

### 핵심 원칙
- Entity는 자신의 상태를 스스로 보호한다 (불변식 보호)
- 외부에서 직접 상태를 변경하지 못하게 한다 (setter 노출 금지)
- 도메인 행위는 Entity 메서드로 표현한다

---

## 2. Value Object

### 정의
- 불변(immutable) 객체다
- 속성 기반 동등성으로 비교한다 (`equals`)
- 생성 시 자기 검증을 수행한다 (잘못된 상태로 생성 불가)
- 팩토리 메서드(`static create`)로 생성한다

```typescript
// Bad - 원시값으로 도메인 개념 표현
class Order {
  constructor(
    public readonly id: string,
    public readonly customerEmail: string,  // 단순 string
    public readonly totalAmount: number,    // 단순 number - 음수 가능
    public readonly currency: string,       // "KRW"? "krw"? 검증 없음
  ) {}
}

// 유효성 검증이 여기저기 흩어짐
function createOrder(email: string, amount: number) {
  if (!email.includes('@')) throw new Error('Invalid email');
  if (amount < 0) throw new Error('Invalid amount');
  // ...
}
```

```typescript
// Good - Value Object로 감싸기
class Email {
  private readonly _value: string;

  private constructor(value: string) {
    this._value = value;
  }

  static create(value: string): Email {
    if (!value || !value.includes('@')) {
      throw new Error(`Invalid email: ${value}`);
    }
    return new Email(value.trim().toLowerCase());
  }

  get value(): string { return this._value; }

  equals(other: Email): boolean {
    return this._value === other._value;
  }
}
```

### 핵심 원칙
- 원시값 대신 Value Object를 사용하여 도메인 개념을 명시적으로 표현한다
- 생성자를 `private`으로 두고 `static create` 팩토리 메서드로 유효성 검사를 강제한다
- 상태 변경이 필요하면 새로운 인스턴스를 반환한다 (불변 유지)
- 도메인 연산(add, multiply 등)을 Value Object 메서드로 제공한다

---

## 3. Aggregate

### 정의
- Aggregate Root를 통해서만 내부 Entity에 접근한다
- 일관성 경계(consistency boundary)를 정의한다
- 트랜잭션 범위 = Aggregate 경계다
- 불변식(invariant)을 보호한다
- Aggregate 간 참조는 ID로만 한다 (직접 참조 금지)

```typescript
// Bad - Aggregate 경계 없이 Entity끼리 직접 참조
class Order {
  id: string;
  items: OrderItem[];
  customer: Customer;  // 다른 Aggregate를 직접 참조
}

class OrderItem {
  product: Product;  // 다른 Aggregate를 직접 참조
}

// 외부에서 내부 Entity를 직접 조작
const order = await orderRepository.findById(orderId);
order.items[0].quantity = 999;  // 불변식 검증 없이 직접 변경
order.customer.name = 'hacked'; // 다른 Aggregate의 상태를 직접 변경
```

```typescript
// Good - Aggregate Root가 내부 Entity를 관리
class Order {
  private readonly _id: string;
  private readonly _customerId: string; // ID로만 참조
  private readonly _items: OrderItem[];
  private _status: OrderStatus;

  constructor(id: string, customerId: string, items: OrderItem[]) {
    if (items.length === 0) {
      throw new Error('Order must have at least one item');
    }
    this._id = id;
    this._customerId = customerId;
    this._items = items;
    this._status = OrderStatus.PENDING;
  }

  get id(): string { return this._id; }
  get customerId(): string { return this._customerId; }
  get items(): ReadonlyArray<OrderItem> { return [...this._items]; }
  get status(): OrderStatus { return this._status; }

  // Aggregate Root를 통해서만 내부 Entity 조작
  addItem(productId: string, price: Money, quantity: number): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new Error('Cannot modify confirmed order');
    }
    const existing = this._items.find(i => i.productId === productId);
    if (existing) {
      existing.increaseQuantity(quantity);
    } else {
      this._items.push(new OrderItem(productId, price, quantity));
    }
  }

  removeItem(productId: string): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new Error('Cannot modify confirmed order');
    }
    const index = this._items.findIndex(i => i.productId === productId);
    if (index === -1) {
      throw new Error(`Item not found: ${productId}`);
    }
    this._items.splice(index, 1);
    if (this._items.length === 0) {
      throw new Error('Order must have at least one item');
    }
  }

  get totalAmount(): Money {
    return this._items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.create(0, 'KRW'),
    );
  }
}
```

### 핵심 원칙
- Aggregate Root만 외부에 공개한다 (내부 Entity는 Root를 통해서만 접근)
- 불변식은 Aggregate 내부에서 항상 보장한다
- Aggregate 간에는 객체 참조 대신 ID 참조를 사용한다
- 하나의 트랜잭션에서 하나의 Aggregate만 변경한다
- Aggregate를 작게 설계한다 (필요한 Entity만 포함)

---

## 4. Repository

### 정의
- 도메인 관점의 컬렉션 인터페이스다 (도메인 레이어에 인터페이스 정의)
- 인프라 레이어에서 구현한다 (TypeORM, Prisma 등)
- Aggregate 단위로 저장/조회한다

```typescript
// Bad - Service에서 직접 ORM 호출
class OrderService {
  constructor(
    @InjectRepository(OrderEntity)
    private readonly orderRepo: Repository<OrderEntity>,
  ) {}

  async findOrder(id: string): Promise<Order> {
    // 도메인 레이어가 인프라(TypeORM)에 직접 의존
    const entity = await this.orderRepo.findOne({
      where: { id },
      relations: ['items'],
    });
    return entity;
  }
}
```

```typescript
// Good - Repository 인터페이스를 도메인 레이어에 정의

// domain/order/order.repository.ts (도메인 레이어 - 인터페이스만)
interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  findByCustomerId(customerId: string): Promise<Order[]>;
  save(order: Order): Promise<void>;
  delete(id: string): Promise<void>;
}
```

### 핵심 원칙
- Repository 인터페이스는 도메인 레이어에 위치한다
- 구현체는 인프라 레이어에 위치한다 (의존성 역전)
- Repository는 Aggregate Root 단위로 정의한다 (OrderItem용 Repository는 만들지 않는다)
- Mapper를 사용하여 도메인 모델과 영속성 모델(ORM Entity)을 분리한다

---

## 5. Domain Service

### 정의
- Entity나 Value Object에 속하지 않는 도메인 로직을 담당한다
- 여러 Aggregate를 조율하는 로직을 수행한다
- 상태를 가지지 않는다 (stateless)

```typescript
// Bad - 특정 Entity에 속하는 로직을 Domain Service에 두기
class OrderDomainService {
  cancelOrder(order: Order): void {
    // 이 로직은 Order Entity에 속해야 한다
    if (order.status !== OrderStatus.PENDING) {
      throw new Error('Cannot cancel');
    }
    order.status = OrderStatus.CANCELLED;
  }
}
```

```typescript
// Good - 여러 Aggregate 간 계산/조율 로직을 Domain Service에 두기
class PricingService {
  calculateDiscount(
    order: Order,
    customerTier: CustomerTier,
    promotions: Promotion[],
  ): Money {
    let discount = Money.create(0, 'KRW');
    if (customerTier === CustomerTier.VIP) {
      discount = discount.add(order.totalAmount.multiply(0.1));
    }
    for (const promo of promotions) {
      if (promo.isApplicableTo(order)) {
        discount = discount.add(promo.calculateDiscount(order.totalAmount));
      }
    }
    return discount;
  }
}
```

### 핵심 원칙
- 단일 Entity에 속하는 로직은 Domain Service가 아닌 해당 Entity에 둔다
- Domain Service는 여러 Aggregate 간의 조율이 필요할 때만 사용한다
- 상태를 가지지 않는다 (모든 데이터는 매개변수로 받는다)
- Domain Service와 Application Service를 혼동하지 않는다
  - Domain Service: 순수 도메인 로직 (할인 계산 등)
  - Application Service: 유스케이스 흐름 조율 (트랜잭션, 이벤트 발행)

---

## 6. Domain Event

### 정의
- 도메인에서 발생한 중요한 변경을 알리는 메시지다
- 이벤트 이름은 과거형으로 작성한다 (OrderPlaced, PaymentCompleted)
- Aggregate에서 이벤트를 수집하고, Application 레이어에서 발행한다

```typescript
// Bad - 직접 의존성 호출
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly emailService: EmailService,  // 외부 서비스 직접 의존
    private readonly inventoryService: InventoryService,  // 외부 서비스 직접 의존
    private readonly pointService: PointService,  // 외부 서비스 직접 의존
  ) {}

  async placeOrder(command: PlaceOrderCommand): Promise<void> {
    const order = Order.create(command);
    await this.orderRepo.save(order);
    // 직접 호출 - 결합도 높음, 하나가 실패하면 전체 실패
    await this.emailService.sendOrderConfirmation(order);
    await this.inventoryService.decreaseStock(order.items);
    await this.pointService.accumulatePoints(order.customerId, order.totalAmount);
  }
}
```

```typescript
// Good - Domain Event 패턴

// 도메인 이벤트 정의
class OrderPlacedEvent {
  readonly occurredAt: Date;

  constructor(
    readonly orderId: string,
    readonly customerId: string,
    readonly items: ReadonlyArray<{ productId: string; quantity: number }>,
    readonly totalAmount: number,
  ) {
    this.occurredAt = new Date();
  }
}

// Application Service에서 이벤트 발행
class PlaceOrderUseCase {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly eventPublisher: DomainEventPublisher,
  ) {}

  async execute(command: PlaceOrderCommand): Promise<void> {
    const order = Order.place(command.id, command.customerId, command.items);
    await this.orderRepo.save(order);
    // Aggregate에서 수집한 이벤트를 발행
    await this.eventPublisher.publishAll(order.domainEvents);
    order.clearDomainEvents();
  }
}
```

### 핵심 원칙
- 이벤트 이름은 과거형으로 작성한다 (OrderPlaced, not PlaceOrder)
- 이벤트는 불변 객체다 (생성 후 변경하지 않는다)
- Aggregate 내부에서 이벤트를 수집하고, Application 레이어에서 발행한다
- 이벤트 핸들러 간에는 순서 의존성을 두지 않는다
- 이벤트를 통해 Aggregate 간 결합도를 낮춘다

---

## 7. 레이어 구조

### 의존성 방향

```
Presentation → Application → Domain ← Infrastructure
```

- 화살표는 의존 방향이다. Domain 레이어는 아무것에도 의존하지 않는다.
- Infrastructure는 Domain의 인터페이스를 구현한다 (의존성 역전).

### 각 레이어의 역할

| 레이어 | 역할 | 포함 요소 |
|--------|------|-----------|
| **Domain** | 핵심 비즈니스 규칙 | Entity, Value Object, Aggregate, Domain Service, Domain Event, Repository 인터페이스 |
| **Application** | 유스케이스 흐름 조율 | Application Service(Use Case), DTO, 트랜잭션 관리, 이벤트 발행 |
| **Infrastructure** | 기술적 구현 | Repository 구현, ORM Entity, 외부 API 클라이언트, 메시지 브로커 |
| **Presentation** | 외부 인터페이스 | Controller, Request/Response DTO, 인증/인가 |

### 디렉토리 예시

```
src/modules/order/
├── domain/
│   ├── order.ts                  # Aggregate Root (Entity)
│   ├── order-item.ts             # 내부 Entity
│   ├── order-status.ts           # Value Object / Enum
│   ├── money.ts                  # Value Object
│   ├── order.repository.ts       # Repository 인터페이스
│   ├── order-placed.event.ts     # Domain Event
│   └── pricing.service.ts        # Domain Service
├── application/
│   ├── place-order.use-case.ts   # Application Service
│   ├── dto/
│   │   ├── place-order.command.ts
│   │   └── order-response.dto.ts
│   └── event-handlers/
│       └── send-confirmation.handler.ts
├── infrastructure/
│   ├── persistence/
│   │   ├── order.orm-entity.ts   # ORM Entity (TypeORM)
│   │   ├── order.mapper.ts       # Domain <-> ORM 변환
│   │   └── typeorm-order.repository.ts
│   └── external/
│       └── payment-gateway.client.ts
└── presentation/
    ├── order.controller.ts
    └── dto/
        ├── create-order.request.ts
        └── order.response.ts
```

```typescript
// Bad - 레이어 경계 무시
// domain/order.ts에서 TypeORM 데코레이터 사용
import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  status: string;
}
```

```typescript
// Good - 도메인 모델과 ORM Entity 분리

// domain/order.ts - 순수 도메인 모델 (인프라 의존성 없음)
class Order extends AggregateRoot {
  private readonly _id: string;
  private _status: OrderStatus;

  constructor(id: string, status: OrderStatus) {
    super();
    this._id = id;
    this._status = status;
  }
  // ... 비즈니스 로직
}

// infrastructure/persistence/order.orm-entity.ts - ORM 전용 Entity
@Entity('orders')
class OrderOrmEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar' })
  status: string;

  @OneToMany(() => OrderItemOrmEntity, (item) => item.order, {
    cascade: ['insert', 'update'],
  })
  items: OrderItemOrmEntity[];
}

// infrastructure/persistence/order.mapper.ts - 변환 로직
class OrderMapper {
  static toDomain(entity: OrderOrmEntity): Order {
    return new Order(entity.id, entity.status as OrderStatus);
  }

  static toEntity(domain: Order): OrderOrmEntity {
    const entity = new OrderOrmEntity();
    entity.id = domain.id;
    entity.status = domain.status;
    return entity;
  }
}
```

### 핵심 원칙
- Domain 레이어는 외부에 의존하지 않는다 (순수 TypeScript)
- Application 레이어는 Domain의 Entity와 Repository 인터페이스를 사용한다
- Infrastructure 레이어는 Domain의 인터페이스를 구현한다 (의존성 역전)
- Presentation 레이어는 Application 레이어의 Use Case를 호출한다

---

## 8. 금지 사항

- Entity에 getter/setter만 두고 로직을 Service에 몰아넣기 금지 (Anemic Domain Model)
- 도메인 레이어에서 인프라 기술(ORM 데코레이터, 프레임워크 데코레이터 등)에 직접 의존 금지
- Aggregate 간 직접 객체 참조 금지 - ID 참조를 사용한다
- Aggregate 경계를 넘는 트랜잭션 금지 - 도메인 이벤트로 처리한다
- Application Service에 도메인 로직 작성 금지 - 도메인 레이어에 위치시킨다
- 도메인 레이어에서 외부 서비스 직접 호출 금지

---

## 참조 문서

- **[Entity & Value Object 심화](./references/entity-vo.md)** - Entity 확장 패턴, Value Object 도메인 연산, Money 패턴 심화
- **[Aggregate & Repository 심화](./references/aggregate-repository.md)** - Aggregate 내부 Entity 관리, 불변식 보호, Repository 구현 패턴
- **[Domain Service & Domain Event 심화](./references/domain-events.md)** - 이벤트 발행/구독 패턴, AggregateRoot 기반 이벤트 수집, 핸들러 구현
