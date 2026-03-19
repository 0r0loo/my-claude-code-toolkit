# Coding 패턴 코드 예시

## 1. Early Return (Guard Clause)

```typescript
// Bad - 깊은 중첩
function processOrder(order: Order): void {
  if (order) {
    if (order.isValid()) {
      if (order.items.length > 0) {
        // 실제 로직
      }
    }
  }
}

// Good - 얼리 리턴
function processOrder(order: Order): void {
  if (!order) return;
  if (!order.isValid()) return;
  if (order.items.length === 0) return;

  // 실제 로직
}
```

## 2. 삼항 연산자

```typescript
// Bad - 중첩 삼항
const label = status === 'active' ? '활성' : status === 'pending' ? '대기' : '비활성';

// Bad - 긴 삼항
const message = user.isAdmin ? `관리자 ${user.name}님 환영합니다` : `${user.name}님 환영합니다`;

// Good - 중첩은 맵 또는 함수로 전환
const STATUS_LABEL: Record<string, string> = {
  active: '활성',
  pending: '대기',
  inactive: '비활성',
};
const label = STATUS_LABEL[status] ?? '알 수 없음';

// Good - 길면 if/else 또는 변수 추출
const message = user.isAdmin
  ? `관리자 ${user.name}님 환영합니다`
  : `${user.name}님 환영합니다`;
```

```tsx
// Bad - JSX 내 중첩 삼항
{isLoading ? <Spinner /> : error ? <ErrorView /> : <Content />}

// Good - 변수 추출 후 단순화
const content = isLoading ? <Spinner /> : <Content />;
if (error) return <ErrorView />;
return content;
```

## 3. 선언적 & 함수형 스타일

```typescript
// Bad - 명령적: 루프로 직접 조작
const activeNames: string[] = [];
for (const user of users) {
  if (user.isActive) {
    activeNames.push(user.name);
  }
}

// Good - 선언적: 의도를 바로 드러냄
const isActive = (u: User) => u.isActive;
const toName = (u: User) => u.name;
const activeNames = users.filter(isActive).map(toName);
```

### 순수 함수 우선

```typescript
// Bad - 외부 상태를 변경
let totalPrice = 0;
function addItemPrice(price: number): void {
  totalPrice += price;
}

// Good - 새 값을 반환하는 순수 함수
function calculateTotal(prices: number[]): number {
  return prices.reduce((sum, price) => sum + price, 0);
}
```

### 불변성

```typescript
// Bad - 원본 변경
user.role = 'admin';
items.push(newItem);

// Good - 새 객체/배열 생성
const promotedUser = { ...user, role: 'admin' };
const updatedItems = [...items, newItem];
```

### 부수효과 격리

```typescript
// Bad - 비즈니스 로직에 부수효과가 섞임
async function processOrder(order: Order): Promise<void> {
  const total = order.items.reduce((s, i) => s + i.price, 0);
  const discount = total > 100 ? total * 0.1 : 0;
  await db.save({ ...order, total: total - discount });
  await sendEmail(order.userId, total - discount);
}

// Good - 순수 계산과 부수효과를 분리
function calcOrderTotal(items: OrderItem[]): number {
  const total = items.reduce((s, i) => s + i.price, 0);
  const discount = total > 100 ? total * 0.1 : 0;
  return total - discount;
}

async function processOrder(order: Order): Promise<void> {
  const finalTotal = calcOrderTotal(order.items);
  await db.save({ ...order, total: finalTotal });
  await sendEmail(order.userId, finalTotal);
}
```

## 4. 상수 관리

```typescript
// Bad - 매직 넘버
if (password.length < 8) { ... }
if (status === 'APPROVED') { ... }
setTimeout(callback, 300000);

// Good - 상수로 추출
const MIN_PASSWORD_LENGTH = 8;
const ORDER_STATUS = { APPROVED: 'APPROVED', REJECTED: 'REJECTED' } as const;
const FIVE_MINUTES_MS = 5 * 60 * 1000;

if (password.length < MIN_PASSWORD_LENGTH) { ... }
if (status === ORDER_STATUS.APPROVED) { ... }
setTimeout(callback, FIVE_MINUTES_MS);
```

## 5. 에러 핸들링

```typescript
// Bad - 에러를 삼킴
try {
  await saveUser(user);
} catch (e) {
  // do nothing
}

// Bad - 원본 에러 정보 손실
try {
  await saveUser(user);
} catch (e) {
  throw new Error('저장 실패');
}

// Good - 원본 에러 보존
try {
  await saveUser(user);
} catch (e) {
  throw new Error(`사용자 저장 실패: ${user.id}`, { cause: e });
}
```