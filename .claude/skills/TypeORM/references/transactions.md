# TypeORM Transactions - 트랜잭션 패턴 및 사용 가이드

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. DataSource.transaction() 패턴

가장 간결한 트랜잭션 패턴이다. 콜백 내에서 제공되는 `EntityManager`를 사용한다.

```typescript
@Injectable()
export class OrderService {
  constructor(private readonly dataSource: DataSource) {}

  async createOrder(dto: CreateOrderDto): Promise<Order> {
    return this.dataSource.transaction(async (manager) => {
      const order = manager.create(Order, {
        userId: dto.userId,
        totalAmount: dto.totalAmount,
      });
      await manager.save(order);

      const orderItems = dto.items.map((item) =>
        manager.create(OrderItem, { ...item, orderId: order.id }),
      );
      await manager.save(orderItems);

      await manager.decrement(
        Product,
        { id: In(dto.items.map((i) => i.productId)) },
        'stock',
        1,
      );

      return order;
    });
  }
}
```

---

## 2. QueryRunner를 사용한 수동 트랜잭션

세밀한 제어가 필요한 경우 사용한다.

```typescript
async transferPoints(fromId: string, toId: string, amount: number): Promise<void> {
  const queryRunner = this.dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    await queryRunner.manager.decrement(User, { id: fromId }, 'points', amount);
    await queryRunner.manager.increment(User, { id: toId }, 'points', amount);

    await queryRunner.commitTransaction();
  } catch (error) {
    await queryRunner.rollbackTransaction();
    throw error;
  } finally {
    await queryRunner.release(); // 반드시 release
  }
}
```

---

## 3. 트랜잭션 선택 가이드

| 상황 | 권장 패턴 |
|------|----------|
| 단순 다중 저장 | `DataSource.transaction()` |
| 조건부 커밋/롤백 | `QueryRunner` 수동 트랜잭션 |
| 중간에 외부 API 호출 필요 | `QueryRunner` (커밋 시점 제어) |