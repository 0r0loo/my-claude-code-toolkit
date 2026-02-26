# Domain Service & Domain Event 심화

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. Domain Service 심화

### 여러 Aggregate 간 계산 로직

Domain Service는 단일 Entity에 속하지 않는, 여러 Aggregate를 조율하는 도메인 로직을 담당한다.

```typescript
// Bad - 특정 Entity에 속하는 로직을 Domain Service에 두기
class OrderDomainService {
  // 이 로직은 Order Entity에 속해야 한다
  cancelOrder(order: Order): void {
    if (order.status !== OrderStatus.PENDING) {
      throw new Error('Cannot cancel');
    }
    order.status = OrderStatus.CANCELLED;
  }

  // 이 로직도 Order Entity에 속해야 한다
  calculateTotal(order: Order): number {
    return order.items.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
  }
}
```

### 할인 계산 Domain Service

```typescript
// Good - 여러 Aggregate(Order, Customer, Promotion)의 정보가 필요한 할인 계산
class PricingService {
  calculateDiscount(
    order: Order,
    customerTier: CustomerTier,
    promotions: Promotion[],
  ): Money {
    let discount = Money.create(0, 'KRW');

    // 고객 등급별 할인
    if (customerTier === CustomerTier.VIP) {
      discount = discount.add(order.totalAmount.multiply(0.1));
    }

    // 프로모션 할인
    for (const promo of promotions) {
      if (promo.isApplicableTo(order)) {
        discount = discount.add(promo.calculateDiscount(order.totalAmount));
      }
    }

    return discount;
  }
}
```

### 이체 Domain Service

```typescript
// Good - 두 Aggregate(Account) 간 이체 - 어느 한쪽에 속하지 않는 로직
class TransferService {
  transfer(from: Account, to: Account, amount: Money): void {
    if (!from.canWithdraw(amount)) {
      throw new Error('Insufficient balance');
    }
    from.withdraw(amount);
    to.deposit(amount);
  }
}
```

### Domain Service vs Application Service 구분

| 구분 | Domain Service | Application Service |
|------|---------------|-------------------|
| 역할 | 순수 도메인 로직 | 유스케이스 흐름 조율 |
| 예시 | 할인 계산, 이체 규칙 | 트랜잭션, 이벤트 발행 |
| 상태 | stateless | stateless |
| 의존성 | 도메인 객체만 | Repository, EventPublisher 등 |
| 위치 | Domain 레이어 | Application 레이어 |

---

## 2. Domain Event 심화

### AggregateRoot 기반 이벤트 수집

Aggregate에서 이벤트를 수집하는 기반 클래스를 정의한다.

```typescript
// Good - AggregateRoot 기반 클래스
abstract class AggregateRoot {
  private _domainEvents: DomainEvent[] = [];

  get domainEvents(): ReadonlyArray<DomainEvent> {
    return [...this._domainEvents];
  }

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  clearDomainEvents(): void {
    this._domainEvents = [];
  }
}
```

### Aggregate에서 이벤트 발생

```typescript
// Good - Order Aggregate가 생성 시 이벤트를 수집
class Order extends AggregateRoot {
  // ... 기존 필드 생략

  static place(id: string, customerId: string, items: OrderItem[]): Order {
    const order = new Order(id, customerId, items);
    order.addDomainEvent(
      new OrderPlacedEvent(
        order.id,
        order.customerId,
        order.items.map(i => ({ productId: i.productId, quantity: i.quantity })),
        order.totalAmount.amount,
      ),
    );
    return order;
  }
}
```

### 이벤트 핸들러 독립 구현

각 핸들러는 독립적으로 이벤트를 처리하며, 핸들러 간 순서 의존성이 없다.

```typescript
// Good - 각 핸들러가 독립적으로 처리
class SendOrderConfirmationHandler {
  constructor(private readonly emailService: EmailService) {}

  async handle(event: OrderPlacedEvent): Promise<void> {
    await this.emailService.sendOrderConfirmation(event.orderId);
  }
}

class DecreaseStockHandler {
  constructor(private readonly inventoryService: InventoryService) {}

  async handle(event: OrderPlacedEvent): Promise<void> {
    for (const item of event.items) {
      await this.inventoryService.decrease(item.productId, item.quantity);
    }
  }
}

class AccumulatePointsHandler {
  constructor(private readonly pointService: PointService) {}

  async handle(event: OrderPlacedEvent): Promise<void> {
    await this.pointService.accumulate(event.customerId, event.totalAmount);
  }
}
```

### Application Service에서의 조합

Application Service가 Repository 저장과 이벤트 발행을 조율한다.

```typescript
// Good - Application Service가 유스케이스 흐름을 조율
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

### 이벤트 설계 원칙

| 원칙 | 설명 |
|------|------|
| 과거형 이름 | `OrderPlaced`, `PaymentCompleted` (not `PlaceOrder`) |
| 불변 객체 | 생성 후 변경하지 않는다 |
| 필요한 데이터만 | 이벤트에 Aggregate 전체를 넣지 않고, 핸들러가 필요한 최소 데이터만 포함 |
| 발생 시각 포함 | `occurredAt` 필드로 이벤트 발생 시각을 기록 |
| 순서 비의존 | 핸들러 간 실행 순서에 의존하지 않는다 |
| Aggregate에서 수집 | `addDomainEvent`로 수집, Application 레이어에서 `publishAll`로 발행 |
