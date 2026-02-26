# Entity & Value Object 심화

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. Entity 심화

### Value Object를 활용한 Entity 강화

Entity 내부에서 Value Object를 사용하여 도메인 개념을 명확히 표현한다.

```typescript
// Good - Entity가 Value Object를 내부적으로 활용
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

  get totalAmount(): Money {
    return this._items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.create(0, 'KRW'),
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

### equals 메서드 패턴

Entity의 동등성 비교는 반드시 id 기반으로 한다.

```typescript
// Bad - 모든 속성 비교
class User {
  equals(other: User): boolean {
    return this.name === other.name && this.email === other.email;
  }
}

// Good - id 기반 비교
class User {
  private readonly _id: string;

  equals(other: User): boolean {
    return this._id === other._id;
  }
}
```

### 상태 전이(State Transition) 패턴

Entity의 상태 변경은 명시적인 메서드로 표현하고, 허용되지 않는 전이를 방어한다.

```typescript
// Good - 상태 전이를 명시적으로 관리
class Order {
  private _status: OrderStatus;

  // 허용 전이: PENDING -> CONFIRMED -> SHIPPED -> DELIVERED
  //           PENDING -> CANCELLED

  confirm(): void {
    this.assertStatus(OrderStatus.PENDING, 'confirm');
    this._status = OrderStatus.CONFIRMED;
  }

  ship(): void {
    this.assertStatus(OrderStatus.CONFIRMED, 'ship');
    this._status = OrderStatus.SHIPPED;
  }

  deliver(): void {
    this.assertStatus(OrderStatus.SHIPPED, 'deliver');
    this._status = OrderStatus.DELIVERED;
  }

  cancel(): void {
    if (this._status !== OrderStatus.PENDING) {
      throw new Error('Only pending orders can be cancelled');
    }
    this._status = OrderStatus.CANCELLED;
  }

  private assertStatus(expected: OrderStatus, action: string): void {
    if (this._status !== expected) {
      throw new Error(
        `Cannot ${action} order in ${this._status} status (expected: ${expected})`,
      );
    }
  }
}
```

---

## 2. Value Object 심화

### Money 패턴 전체 구현

Money는 대표적인 Value Object로, 금액과 통화를 함께 관리한다.

```typescript
// Good - Money Value Object 전체 구현
class Money {
  private constructor(
    private readonly _amount: number,
    private readonly _currency: string,
  ) {}

  static create(amount: number, currency: string): Money {
    if (amount < 0) {
      throw new Error('Amount cannot be negative');
    }
    if (!['KRW', 'USD', 'EUR'].includes(currency)) {
      throw new Error(`Unsupported currency: ${currency}`);
    }
    return new Money(amount, currency);
  }

  get amount(): number { return this._amount; }
  get currency(): string { return this._currency; }

  add(other: Money): Money {
    if (this._currency !== other._currency) {
      throw new Error('Cannot add different currencies');
    }
    return Money.create(this._amount + other._amount, this._currency);
  }

  multiply(factor: number): Money {
    return Money.create(this._amount * factor, this._currency);
  }

  equals(other: Money): boolean {
    return this._amount === other._amount && this._currency === other._currency;
  }
}
```

### 복합 Value Object

여러 속성을 가진 Value Object도 동일한 패턴을 따른다.

```typescript
// Good - 복합 Value Object (주소)
class Address {
  private constructor(
    private readonly _street: string,
    private readonly _city: string,
    private readonly _zipCode: string,
    private readonly _country: string,
  ) {}

  static create(street: string, city: string, zipCode: string, country: string): Address {
    if (!street || !city || !zipCode || !country) {
      throw new Error('All address fields are required');
    }
    if (!/^\d{5}$/.test(zipCode)) {
      throw new Error(`Invalid zip code: ${zipCode}`);
    }
    return new Address(street, city, zipCode, country);
  }

  get street(): string { return this._street; }
  get city(): string { return this._city; }
  get zipCode(): string { return this._zipCode; }
  get country(): string { return this._country; }

  equals(other: Address): boolean {
    return (
      this._street === other._street &&
      this._city === other._city &&
      this._zipCode === other._zipCode &&
      this._country === other._country
    );
  }

  // 상태 변경 시 새 인스턴스 반환 (불변 유지)
  changeStreet(newStreet: string): Address {
    return Address.create(newStreet, this._city, this._zipCode, this._country);
  }
}
```

### Value Object vs 원시값 판단 기준

| 기준 | 원시값 사용 | Value Object 사용 |
|------|------------|-------------------|
| 유효성 검증 | 필요 없음 | 생성 시 검증 필요 |
| 도메인 연산 | 없음 | add, multiply 등 존재 |
| 포맷/정규화 | 불필요 | trim, lowercase 등 필요 |
| 여러 속성 조합 | 단일 값 | 복합 값 (Money = amount + currency) |
| 비즈니스 의미 | 범용적 | 도메인 특화 의미 |