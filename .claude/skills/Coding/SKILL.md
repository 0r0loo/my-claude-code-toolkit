---
name: coding
description: 공통 코딩 원칙과 패턴. 코드 작성 시 항상 참조하며, SRP, 네이밍 컨벤션, 에러 처리, 코드 품질 체크리스트를 제공한다.
user-invocable: true
lastUpdated: 2026-03-19
---

# Coding Skill - 공통 원칙

이 문서는 모든 코드 작성 시 적용되는 공통 원칙을 정의한다.
FE/BE 상세 규칙은 기술별 스킬에서 다룬다.
- BE: `../NestJS/SKILL.md`, `../TypeORM/SKILL.md`
- FE: `../React/SKILL.md`, `../NextJS/SKILL.md`, `../TailwindCSS/SKILL.md` 등

---

## 1. 설계 원칙

### SRP (Single Responsibility Principle)
- 함수는 하나의 작업만 수행한다
- 클래스/모듈은 하나의 책임만 갖는다
- "이 함수가 하는 일"을 한 문장으로 설명할 수 없으면 분리한다

### 결합도(Coupling)와 응집도(Cohesion)
- **낮은 결합도**: 모듈 간 의존성을 최소화한다
  - 인터페이스/추상화를 통해 의존한다
  - 구현 세부사항에 직접 의존하지 않는다
- **높은 응집도**: 관련 있는 로직을 같은 모듈에 모은다
  - 하나의 모듈 안에서 데이터와 동작이 밀접하게 관련된다

### Early Return (Guard Clause)
- 예외/실패 조건을 함수 상단에서 먼저 처리하고 빠져나온다
- 중첩 if를 줄여 가독성을 높인다

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

### 삼항 연산자 (Ternary Operator)

- **1단만 허용한다.** 중첩 삼항은 금지.
- 삼항이 한 줄(80자)을 넘기면 `if/else` 또는 early return으로 전환한다
- JSX 조건부 렌더링: 표시/숨김은 `&&`, 분기는 삼항 1단, 그 이상은 변수 추출 또는 컴포넌트 분리

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

### DRY (Don't Repeat Yourself)
- 동일한 로직이 3번 이상 반복되면 추출한다
- 단, 2번까지는 중복을 허용한다 (섣부른 추상화 방지)

### 선언적 & 함수형 스타일

**선언적 > 명령적** - "어떻게(how)" 대신 "무엇(what)"을 표현한다.

```typescript
// Bad - 명령적: 루프로 직접 조작
const activeNames: string[] = [];
for (const user of users) {
  if (user.isActive) {
    activeNames.push(user.name);
  }
}

// Good - 선언적: 의도를 바로 드러냄
// 필터/변환 조건은 변수로 추출하여 합성하라
const isActive = (u: User) => u.isActive;
const toName = (u: User) => u.name;
const activeNames = users.filter(isActive).map(toName);
```

**순수 함수 우선** - 같은 입력이면 항상 같은 출력, 부수효과 없음.

```typescript
// Bad - 외부 상태를 변경
let totalPrice = 0;
function addItemPrice(price: number): void {
  totalPrice += price; // 외부 변수 변경
}

// Good - 새 값을 반환하는 순수 함수
function calculateTotal(prices: number[]): number {
  return prices.reduce((sum, price) => sum + price, 0);
}
```

**불변성** - 기존 데이터를 변경하지 않고 새 데이터를 생성한다.

```typescript
// Bad - 원본 변경
user.role = 'admin';
items.push(newItem);

// Good - 새 객체/배열 생성
const promotedUser = { ...user, role: 'admin' };
const updatedItems = [...items, newItem];
```

**부수효과 격리** - 순수 로직과 부수효과(I/O)를 분리한다.

```typescript
// Bad - 비즈니스 로직에 부수효과가 섞임
async function processOrder(order: Order): Promise<void> {
  const total = order.items.reduce((s, i) => s + i.price, 0);
  const discount = total > 100 ? total * 0.1 : 0;
  await db.save({ ...order, total: total - discount }); // 부수효과
  await sendEmail(order.userId, total - discount);       // 부수효과
}

// Good - 순수 계산과 부수효과를 분리
function calcOrderTotal(items: OrderItem[]): number {
  const total = items.reduce((s, i) => s + i.price, 0);
  const discount = total > 100 ? total * 0.1 : 0;
  return total - discount;
}

async function processOrder(order: Order): Promise<void> {
  const finalTotal = calcOrderTotal(order.items); // 순수
  await db.save({ ...order, total: finalTotal }); // I/O 경계
  await sendEmail(order.userId, finalTotal);       // I/O 경계
}
```

### 상수 관리

**매직 넘버/스트링 금지** — 의미 없는 리터럴을 코드에 직접 사용하지 않는다.

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

**상수 분리 기준**
- **한 모듈에서만 사용** → 같은 파일 상단 또는 모듈 내 `constants.ts`
- **여러 모듈에서 공유** → `src/constants/` 또는 `src/shared/constants/`에 도메인별 분리

**`as const` 활용** — 객체/배열 상수는 `as const`로 리터럴 타입을 보장한다.

```typescript
// as const 없이 — 타입이 string[]으로 넓어짐
const ROLES = ['ADMIN', 'USER', 'GUEST'];

// as const — 타입이 readonly ['ADMIN', 'USER', 'GUEST']
const ROLES = ['ADMIN', 'USER', 'GUEST'] as const;
type Role = (typeof ROLES)[number]; // 'ADMIN' | 'USER' | 'GUEST'
```

---

## 2. 네이밍 컨벤션

### 일반 규칙
- 의도를 드러내는 이름을 사용한다
- 축약어를 피한다 (`btn` → `button`, `msg` → `message`)
- 단, 관례적 축약은 허용한다 (`id`, `url`, `api`, `dto`)

### 변수/함수
```
// Bad
const d = new Date();
const list = getItems();
function process(data) {}

// Good
const createdAt = new Date();
const activeUsers = getActiveUsers();
function validateUserInput(input) {}
```

### Boolean
- `is`, `has`, `can`, `should` 접두사를 사용한다
```
isActive, hasPermission, canEdit, shouldRender
```

### 함수
- 동사로 시작한다
- 반환값이 예측 가능한 이름을 사용한다
```
getUserById()    // User 반환
calculateTotal() // number 반환
isValid()        // boolean 반환
```

---

## 3. 에러 핸들링

### 원칙
- 시스템 경계(외부 API, 사용자 입력, 파일 I/O)에서 에러를 처리한다
- 내부 로직에서 불필요한 try-catch를 남발하지 않는다
- 에러 메시지는 디버깅에 도움되는 정보를 포함한다

### 패턴
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

---

## 4. 코드 품질 체크리스트

코드 작성/리뷰 시 다음을 확인한다:
- [ ] 함수/클래스가 SRP를 지키는가?
- [ ] 네이밍이 의도를 드러내는가?
- [ ] 시스템 경계에서 에러 핸들링이 되어 있는가?
- [ ] 불필요한 복잡도가 없는가?
- [ ] `any` 타입을 사용하지 않았는가?
- [ ] 기존 프로젝트 패턴과 일관성이 있는가?

