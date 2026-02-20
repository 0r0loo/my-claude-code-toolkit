# 고급 타입 패턴 (Advanced Patterns)

이 문서는 TypeScript 고급 타입 패턴을 다룬다.
기본 규칙은 [SKILL.md](../SKILL.md)를 참고한다.

---

## Branded Type (같은 원시 타입이지만 구분해야 할 때)

```typescript
// Bad - UserId와 PostId가 모두 string이라 실수로 혼용 가능
function getPost(postId: string): Post { /* ... */ }
getPost(userId); // 컴파일 에러 없음 (런타임 버그)

// Good - Branded Type으로 구분
type Brand<T, B extends string> = T & { readonly __brand: B };

type UserId = Brand<string, 'UserId'>;
type PostId = Brand<string, 'PostId'>;

function createUserId(id: string): UserId {
  return id as UserId;
}

function createPostId(id: string): PostId {
  return id as PostId;
}

function getPost(postId: PostId): Post { /* ... */ }

const userId = createUserId('user-1');
const postId = createPostId('post-1');

getPost(postId); // OK
// getPost(userId); // 컴파일 에러 - UserId는 PostId에 할당 불가
```

---

## 조건부 타입 (Conditional Types)

```typescript
// 기본 조건부 타입
type IsString<T> = T extends string ? true : false;

type A = IsString<string>; // true
type B = IsString<number>; // false

// 분배 조건부 타입 (유니언에 자동 분배)
type NonNullable<T> = T extends null | undefined ? never : T;
type Result = NonNullable<string | null | undefined>; // string

// infer를 이용한 타입 추출
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type Resolved = UnwrapPromise<Promise<string>>; // string

// 배열 요소 타입 추출
type ElementType<T> = T extends (infer E)[] ? E : T;
type Item = ElementType<string[]>; // string

// 함수 반환 타입 추출 (ReturnType 구현)
type MyReturnType<T> = T extends (...args: any[]) => infer R ? R : never;
```

---

## 매핑 타입 (Mapped Types)

```typescript
// 기본 매핑 타입
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};

type Partial<T> = {
  [P in keyof T]?: T[P];
};

// 키 리매핑 (as 절)
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface Person {
  name: string;
  age: number;
}

type PersonGetters = Getters<Person>;
// { getName: () => string; getAge: () => number; }

// 특정 타입의 키만 필터링
type StringKeys<T> = {
  [K in keyof T as T[K] extends string ? K : never]: T[K];
};

type PersonStringKeys = StringKeys<Person>;
// { name: string; }
```

---

## 템플릿 리터럴 타입 (Template Literal Types)

```typescript
// 기본 사용
type EventName = `on${Capitalize<'click' | 'focus' | 'blur'>}`;
// 'onClick' | 'onFocus' | 'onBlur'

// CSS 단위
type CSSValue = `${number}${'px' | 'rem' | 'em' | '%'}`;
const width: CSSValue = '100px'; // OK
// const invalid: CSSValue = '100vw'; // 컴파일 에러

// API 경로 타입
type ApiPath = `/api/${'users' | 'posts' | 'comments'}`;
type ApiPathWithId = `${ApiPath}/${string}`;

// 조합 활용
type HTTPMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type Endpoint = `${HTTPMethod} ${ApiPath}`;
// 'GET /api/users' | 'GET /api/posts' | ... (12개 조합)
```

---

## 깊은 불변 타입 (Deep Readonly)

```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

interface NestedConfig {
  database: {
    host: string;
    port: number;
  };
  cache: {
    ttl: number;
  };
}

type FrozenConfig = DeepReadonly<NestedConfig>;
// database.host, database.port, cache.ttl 모두 readonly
```