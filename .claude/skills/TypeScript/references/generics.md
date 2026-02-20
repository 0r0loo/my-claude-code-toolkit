# 제네릭 (Generics)

이 문서는 TypeScript 제네릭의 상세 패턴을 다룬다.
기본 규칙은 [SKILL.md](../SKILL.md)를 참고한다.

---

## 함수 제네릭

```typescript
// Bad - any 사용
function first(arr: any[]): any {
  return arr[0];
}

// Good - 제네릭으로 타입 안전성 확보
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

const num = first([1, 2, 3]); // number | undefined
const str = first(['a', 'b']); // string | undefined
```

---

## 제약 조건 (extends)

```typescript
// Bad - 모든 타입 허용
function getProperty<T>(obj: T, key: string): unknown {
  return (obj as Record<string, unknown>)[key];
}

// Good - 제약 조건으로 타입 안전성 확보
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: 'Alice', age: 30 };
const name = getProperty(user, 'name'); // string
// getProperty(user, 'invalid'); // 컴파일 에러
```

---

## 제네릭 기본값

```typescript
interface PaginatedResponse<T, M = Record<string, never>> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  meta: M;
}

// 메타 정보 없이 사용
type UserListResponse = PaginatedResponse<User>;

// 메타 정보와 함께 사용
type SearchResponse = PaginatedResponse<User, { query: string; took: number }>;
```

---

## 실전 예시 - API 응답 래퍼

```typescript
// API 응답 공통 래퍼
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error: string | null;
  timestamp: number;
}

// 페이지네이션 래퍼
interface PaginatedData<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasNext: boolean;
}

// 조합하여 사용
type UserListApiResponse = ApiResponse<PaginatedData<User>>;

// 제네릭 API 호출 함수
async function apiGet<T>(url: string): Promise<ApiResponse<T>> {
  const response = await fetch(url);
  return response.json() as Promise<ApiResponse<T>>;
}

const result = await apiGet<User[]>('/api/users');
// result.data는 User[]로 타입 추론
```