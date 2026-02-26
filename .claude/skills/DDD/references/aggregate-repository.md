# Aggregate & Repository 심화

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. Aggregate 심화

### 내부 Entity (OrderItem) 관리

Aggregate Root는 내부 Entity의 생명주기를 완전히 관리한다. 외부에서 내부 Entity를 직접 생성하거나 조작할 수 없다.

```typescript
// Good - Aggregate 내부 Entity
class OrderItem {
  constructor(
    private readonly _productId: string, // ID로만 참조
    private readonly _price: Money,
    private _quantity: number,
  ) {
    if (quantity <= 0) {
      throw new Error('Quantity must be positive');
    }
  }

  get productId(): string { return this._productId; }
  get price(): Money { return this._price; }
  get quantity(): number { return this._quantity; }

  get subtotal(): Money {
    return this._price.multiply(this._quantity);
  }

  increaseQuantity(amount: number): void {
    if (amount <= 0) throw new Error('Amount must be positive');
    this._quantity += amount;
  }
}
```

### Aggregate Root의 addItem / removeItem 패턴

Aggregate Root가 불변식을 보호하면서 내부 Entity를 조작하는 전체 패턴이다.

```typescript
// Good - Aggregate Root가 내부 Entity의 추가/제거를 관리
class Order {
  private readonly _id: string;
  private readonly _customerId: string;
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

### Aggregate 간 ID 참조 패턴

```typescript
// Bad - Aggregate 간 직접 객체 참조
class Order {
  customer: Customer;      // 다른 Aggregate를 직접 참조
  items: OrderItem[];
}

class OrderItem {
  product: Product;        // 다른 Aggregate를 직접 참조
}

// Good - ID로만 참조
class Order {
  private readonly _customerId: string;   // ID 참조
  private readonly _items: OrderItem[];
}

class OrderItem {
  private readonly _productId: string;    // ID 참조
}
```

### Aggregate 설계 원칙

| 원칙 | 설명 |
|------|------|
| 작게 유지 | 꼭 필요한 Entity만 포함. 크기가 커지면 분리 검토 |
| ID 참조 | Aggregate 간 객체 참조 대신 ID 참조 사용 |
| 하나의 트랜잭션 | 하나의 트랜잭션에서 하나의 Aggregate만 변경 |
| 불변식 보호 | 모든 상태 변경 시 비즈니스 규칙(불변식) 검증 |
| Root를 통한 접근 | 외부에서 내부 Entity에 직접 접근 불가 |

---

## 2. Repository 심화

### Repository 인터페이스와 구현 분리

```typescript
// domain/order/order.repository.ts (도메인 레이어 - 인터페이스만)
interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  findByCustomerId(customerId: string): Promise<Order[]>;
  save(order: Order): Promise<void>;
  delete(id: string): Promise<void>;
}
```

### TypeORM 기반 구현체

```typescript
// infrastructure/persistence/typeorm-order.repository.ts (인프라 레이어 - 구현)
@Injectable()
class TypeOrmOrderRepository implements OrderRepository {
  constructor(
    @InjectRepository(OrderEntity)
    private readonly ormRepo: Repository<OrderEntity>,
  ) {}

  async findById(id: string): Promise<Order | null> {
    const entity = await this.ormRepo.findOne({
      where: { id },
      relations: ['items'],
    });
    if (!entity) return null;
    return OrderMapper.toDomain(entity);
  }

  async save(order: Order): Promise<void> {
    const entity = OrderMapper.toEntity(order);
    await this.ormRepo.save(entity);
  }

  async findByCustomerId(customerId: string): Promise<Order[]> {
    const entities = await this.ormRepo.find({
      where: { customerId },
      relations: ['items'],
    });
    return entities.map(OrderMapper.toDomain);
  }

  async delete(id: string): Promise<void> {
    await this.ormRepo.delete(id);
  }
}
```

### Mapper 패턴

도메인 모델과 ORM Entity 간 변환을 담당한다.

```typescript
// infrastructure/persistence/order.mapper.ts
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

### NestJS Module에서 DI 바인딩

```typescript
// Module에서 DI 바인딩
@Module({
  providers: [
    {
      provide: 'OrderRepository', // 또는 Symbol/abstract class 토큰
      useClass: TypeOrmOrderRepository,
    },
  ],
})
class OrderModule {}
```

### Repository 설계 원칙

| 원칙 | 설명 |
|------|------|
| Aggregate Root 단위 | OrderItem용 Repository는 만들지 않는다 |
| 인터페이스 분리 | 도메인 레이어에 인터페이스, 인프라 레이어에 구현 |
| Mapper 사용 | 도메인 모델과 ORM Entity를 반드시 분리한다 |
| 의존성 역전 | Service는 인터페이스에 의존, 구현체는 DI로 주입 |