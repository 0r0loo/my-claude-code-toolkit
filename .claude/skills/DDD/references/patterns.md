# DDD 패턴 코드 예시

## 1. Entity - Bad vs Good

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

## 2. Value Object - Bad vs Good

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

## 3. Aggregate - Bad vs Good

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
}
```

## 4. Repository - Bad vs Good

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
interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  findByCustomerId(customerId: string): Promise<Order[]>;
  save(order: Order): Promise<void>;
  delete(id: string): Promise<void>;
}
```

## 5. Domain Service - Bad vs Good

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

## 6. Domain Event - Bad vs Good

```typescript
// Bad - 직접 의존성 호출
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly emailService: EmailService,
    private readonly inventoryService: InventoryService,
    private readonly pointService: PointService,
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

class PlaceOrderUseCase {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly eventPublisher: DomainEventPublisher,
  ) {}

  async execute(command: PlaceOrderCommand): Promise<void> {
    const order = Order.place(command.id, command.customerId, command.items);
    await this.orderRepo.save(order);
    await this.eventPublisher.publishAll(order.domainEvents);
    order.clearDomainEvents();
  }
}
```

## 7. 레이어 구조 - Bad vs Good

```typescript
// Bad - 레이어 경계 무시: domain/order.ts에서 TypeORM 데코레이터 사용
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