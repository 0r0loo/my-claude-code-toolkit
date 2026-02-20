---
name: typescript
description: TypeScript 고급 패턴 가이드. 타입 추론, 유틸리티 타입, 제네릭, 타입 가드, 고급 타입 패턴 등 TypeScript 코드 작성 시 참조한다.
---

# TypeScript Skill - 고급 패턴 규칙

FE/BE 공통으로 적용되는 TypeScript 심화 규칙을 정의한다.
공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. 타입 추론 활용

### 변수는 추론에 맡긴다

```typescript
// Bad - 불필요한 타입 명시
const name: string = 'Alice';
const count: number = 0;
const isActive: boolean = true;
const users: User[] = [user1, user2];

// Good - 타입 추론에 맡김
const name = 'Alice';
const count = 0;
const isActive = true;
const users = [user1, user2];
```

### 함수 반환 타입과 파라미터는 명시한다

```typescript
// Bad - 반환 타입 누락 (호출자가 추론에 의존해야 함)
function findUser(id: string) {
  return users.find((user) => user.id === id);
}

// Good - 반환 타입 명시
function findUser(id: string): User | undefined {
  return users.find((user) => user.id === id);
}

// Good - 파라미터 타입 명시
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}
```

### as const를 활용한다

```typescript
// Bad - 타입이 string[]으로 추론됨
const ROLES = ['admin', 'editor', 'viewer'];

// Good - readonly ['admin', 'editor', 'viewer']로 추론됨
const ROLES = ['admin', 'editor', 'viewer'] as const;
type Role = (typeof ROLES)[number]; // 'admin' | 'editor' | 'viewer'

// Good - 객체에도 활용
const HTTP_STATUS = {
  OK: 200,
  NOT_FOUND: 404,
  INTERNAL_ERROR: 500,
} as const;
type HttpStatus = (typeof HTTP_STATUS)[keyof typeof HTTP_STATUS]; // 200 | 404 | 500
```

### satisfies를 활용한다

```typescript
// Bad - 타입 명시로 인해 추론이 사라짐
const config: Record<string, string> = {
  apiUrl: 'https://api.example.com',
  timeout: '3000', // 실수로 string을 넣어도 감지 못함
};

// Good - satisfies로 타입 검증 + 추론 유지
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 3000,
} satisfies Record<string, string | number>;
// config.apiUrl의 타입이 string으로 추론됨 (Record<string, string | number>가 아님)
```

---

## 2. 유틸리티 타입

### 자주 사용하는 유틸리티 타입

| 유틸리티 타입 | 설명 | 용례 |
|---------------|------|------|
| `Pick<T, K>` | 특정 프로퍼티만 선택 | API 응답에서 필요한 필드만 추출 |
| `Omit<T, K>` | 특정 프로퍼티를 제외 | 생성 DTO에서 id 제외 |
| `Partial<T>` | 모든 프로퍼티를 선택적으로 | 업데이트 DTO |
| `Required<T>` | 모든 프로퍼티를 필수로 | 기본값 적용 후 타입 |
| `Record<K, V>` | 키-값 매핑 | 딕셔너리, 룩업 테이블 |
| `Exclude<U, E>` | 유니언에서 특정 타입 제외 | 특정 상태 제외 |
| `Extract<U, E>` | 유니언에서 특정 타입 추출 | 특정 상태만 추출 |
| `ReturnType<F>` | 함수의 반환 타입 추출 | 함수 결과 타입 재사용 |
| `Parameters<F>` | 함수의 매개변수 타입 추출 | 래퍼 함수 작성 시 |
| `Awaited<T>` | Promise를 풀어낸 타입 | async 함수 결과 타입 |
| `NonNullable<T>` | null/undefined 제거 | 필터링 후 타입 |

### 실전 예시

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
  updatedAt: Date;
}

// 생성 시 id, 날짜는 서버에서 생성
type CreateUserInput = Omit<User, 'id' | 'createdAt' | 'updatedAt'>;

// 수정 시 모든 필드 선택적
type UpdateUserInput = Partial<Pick<User, 'name' | 'email'>>;

// 공개 프로필 (비밀번호 제외)
type UserProfile = Omit<User, 'password'>;

// 함수 반환 타입 재사용
function getUsers() {
  return fetch('/api/users').then((res) => res.json() as Promise<User[]>);
}
type UsersResult = Awaited<ReturnType<typeof getUsers>>; // User[]
```

---

## 3. 타입 설계 원칙

### 유니언 > enum

enum 대신 const object 또는 union literal을 사용한다.

```typescript
// Bad - enum (트리셰이킹 불가, 런타임 코드 생성)
enum Status {
  Active = 'ACTIVE',
  Inactive = 'INACTIVE',
  Pending = 'PENDING',
}

// Good - const object (런타임 값이 필요할 때)
const STATUS = {
  Active: 'ACTIVE',
  Inactive: 'INACTIVE',
  Pending: 'PENDING',
} as const;
type Status = (typeof STATUS)[keyof typeof STATUS]; // 'ACTIVE' | 'INACTIVE' | 'PENDING'

// Good - union literal (런타임 값이 불필요할 때)
type Status = 'ACTIVE' | 'INACTIVE' | 'PENDING';
```

### interface vs type

| 용도 | 선택 | 이유 |
|------|------|------|
| 객체 형태 정의 | `interface` | 확장 가능, 선언 병합 지원 |
| 유니언/교차 타입 | `type` | interface로 표현 불가 |
| 함수 시그니처 | `type` | 간결한 표현 |
| 튜플 | `type` | interface로 표현 불가 |
| 기본형 별칭 | `type` | interface로 표현 불가 |
| Props/DTO 등 객체 | `interface` | 일관성 |

```typescript
// Good - 객체는 interface
interface UserProfile {
  name: string;
  email: string;
}

// Good - 유니언/조합은 type
type Result<T> = { success: true; data: T } | { success: false; error: string };
type EventHandler = (event: Event) => void;
type Coordinate = [number, number];
```

### readonly 활용 (불변 데이터)

```typescript
// 객체 불변
interface Config {
  readonly apiUrl: string;
  readonly timeout: number;
}

// 배열 불변
function processItems(items: readonly string[]): void {
  // items.push('new'); // 컴파일 에러
  // items[0] = 'modified'; // 컴파일 에러
  const filtered = items.filter((item) => item.length > 0); // OK (새 배열 반환)
}

// 깊은 불변 (Readonly 재귀)
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};
```

---

## 4. 비동기 타입

### Promise<T>와 async/await 반환 타입

```typescript
// Good - async 함수 반환 타입 명시
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json() as Promise<User>;
}

// Good - 에러 가능성이 있는 비동기 함수
type AsyncResult<T> = Promise<
  { success: true; data: T } | { success: false; error: string }
>;

async function safeFetchUser(id: string): AsyncResult<User> {
  try {
    const user = await fetchUser(id);
    return { success: true, data: user };
  } catch (e) {
    return { success: false, error: e instanceof Error ? e.message : '알 수 없는 오류' };
  }
}
```

### 에러 타입 처리

```typescript
// Bad - catch에서 any 사용
try {
  await fetchData();
} catch (e: any) {
  console.error(e.message);
}

// Good - unknown + 타입 가드
try {
  await fetchData();
} catch (e: unknown) {
  if (e instanceof Error) {
    console.error(e.message);
  } else {
    console.error('알 수 없는 오류', e);
  }
}

// Good - 에러 타입 가드 유틸 함수
function isError(value: unknown): value is Error {
  return value instanceof Error;
}

function getErrorMessage(error: unknown): string {
  if (isError(error)) return error.message;
  if (typeof error === 'string') return error;
  return '알 수 없는 오류가 발생했습니다';
}
```

### 병렬 비동기 처리 타입

```typescript
// 여러 비동기 작업의 결과 타입
async function fetchDashboard(userId: string): Promise<{
  user: User;
  posts: Post[];
  notifications: Notification[];
}> {
  const [user, posts, notifications] = await Promise.all([
    fetchUser(userId),
    fetchPosts(userId),
    fetchNotifications(userId),
  ]);

  return { user, posts, notifications };
}
```

---

## 참조 문서

- **[Generics](./references/generics.md)** - 제네릭 함수, 제약 조건, 고급 제네릭 패턴
- **[Type Guards](./references/type-guards.md)** - 타입 가드, 판별 유니온, 완전성 검사
- **[Advanced Patterns](./references/advanced-patterns.md)** - 조건부 타입, 매핑 타입, 템플릿 리터럴 타입

---

## 5. 금지 사항

- `any` 사용 금지 - `unknown`을 사용한 후 타입 가드로 좁힌다
- `as` 타입 단언 남용 금지 - 타입 가드 또는 올바른 타입 설계로 해결한다 (Branded Type 등 불가피한 경우 제외)
- `@ts-ignore` 사용 금지 - 타입 오류를 무시하지 않고 근본 원인을 해결한다
- `@ts-expect-error` 남용 금지 - 테스트 코드에서 의도적 에러 검증 시에만 허용한다
- non-null assertion (`!`) 남용 금지 - 옵셔널 체이닝(`?.`) 또는 타입 가드를 사용한다
- `enum` 사용 금지 - const object 또는 union literal을 사용한다
- 빈 인터페이스 `{}` 사용 금지 - `Record<string, never>` 또는 `unknown`을 사용한다

```typescript
// Bad
const data: any = response.body;
const user = data as User;
// @ts-ignore
const name = user!.name;

// Good
const data: unknown = response.body;
if (isUser(data)) {
  const name = data.name; // 타입 가드로 안전하게 접근
}
```