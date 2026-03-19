# TypeScript 패턴 코드 예시

## 1. 타입 추론 활용

### 변수 추론 / 함수 반환 타입 명시

```typescript
// Bad - 불필요한 타입 명시
const name: string = 'Alice';
const count: number = 0;

// Good - 타입 추론에 맡김
const name = 'Alice';
const count = 0;

// Bad - 반환 타입 누락
function findUser(id: string) {
  return users.find((user) => user.id === id);
}

// Good - 반환 타입 명시
function findUser(id: string): User | undefined {
  return users.find((user) => user.id === id);
}
```

### as const / satisfies

```typescript
// as const - 리터럴 타입 추론
const ROLES = ['admin', 'editor', 'viewer'] as const;
type Role = (typeof ROLES)[number]; // 'admin' | 'editor' | 'viewer'

const HTTP_STATUS = {
  OK: 200,
  NOT_FOUND: 404,
  INTERNAL_ERROR: 500,
} as const;
type HttpStatus = (typeof HTTP_STATUS)[keyof typeof HTTP_STATUS]; // 200 | 404 | 500

// satisfies - 타입 검증 + 추론 유지
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 3000,
} satisfies Record<string, string | number>;
// config.apiUrl의 타입이 string으로 추론됨
```

## 2. 유틸리티 타입 실전 예시

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

## 3. 유니언 > enum

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
type Status = (typeof STATUS)[keyof typeof STATUS];

// Good - union literal (런타임 값이 불필요할 때)
type Status = 'ACTIVE' | 'INACTIVE' | 'PENDING';
```

## 4. interface vs type

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

## 5. readonly 활용

```typescript
// 객체 불변
interface Config {
  readonly apiUrl: string;
  readonly timeout: number;
}

// 배열 불변
function processItems(items: readonly string[]): void {
  const filtered = items.filter((item) => item.length > 0); // OK (새 배열 반환)
}

// 깊은 불변
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};
```

## 6. 비동기 타입

```typescript
// async 함수 반환 타입 명시
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json() as Promise<User>;
}

// 에러 가능성이 있는 비동기 함수
type AsyncResult<T> = Promise<
  { success: true; data: T } | { success: false; error: string }
>;

// 에러 타입 처리 - unknown + 타입 가드
try {
  await fetchData();
} catch (e: unknown) {
  if (e instanceof Error) {
    console.error(e.message);
  }
}

// 에러 타입 가드 유틸 함수
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === 'string') return error;
  return '알 수 없는 오류가 발생했습니다';
}

// 병렬 비동기 처리 타입
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

## 7. 금지 사항 예시

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