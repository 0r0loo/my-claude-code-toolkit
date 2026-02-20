# 타입 가드 (Type Guards)

이 문서는 TypeScript 타입 가드의 상세 패턴을 다룬다.
기본 규칙은 [SKILL.md](../SKILL.md)를 참고한다.

---

## is 키워드 (사용자 정의 타입 가드)

```typescript
interface Admin {
  role: 'admin';
  permissions: string[];
}

interface Guest {
  role: 'guest';
}

type AppUser = Admin | Guest;

// Bad - 타입 단언
function getPermissions(user: AppUser): string[] {
  return (user as Admin).permissions ?? [];
}

// Good - 타입 가드
function isAdmin(user: AppUser): user is Admin {
  return user.role === 'admin';
}

function getPermissions(user: AppUser): string[] {
  if (isAdmin(user)) {
    return user.permissions; // Admin으로 좁혀짐
  }
  return [];
}
```

---

## in 연산자

```typescript
interface Dog {
  bark: () => void;
}

interface Cat {
  meow: () => void;
}

type Pet = Dog | Cat;

function makeSound(pet: Pet): void {
  if ('bark' in pet) {
    pet.bark(); // Dog으로 좁혀짐
  } else {
    pet.meow(); // Cat으로 좁혀짐
  }
}
```

---

## Discriminated Union (태그드 유니언)

```typescript
// 공통 판별 필드(type)를 가진 유니언
type Shape =
  | { type: 'circle'; radius: number }
  | { type: 'rectangle'; width: number; height: number }
  | { type: 'triangle'; base: number; height: number };

function calculateArea(shape: Shape): number {
  switch (shape.type) {
    case 'circle':
      return Math.PI * shape.radius ** 2;
    case 'rectangle':
      return shape.width * shape.height;
    case 'triangle':
      return (shape.base * shape.height) / 2;
  }
}
```

---

## Exhaustive Check (never를 이용한 완전성 검사)

```typescript
// 모든 케이스를 처리했는지 컴파일 타임에 검증한다
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${value}`);
}

function getShapeLabel(shape: Shape): string {
  switch (shape.type) {
    case 'circle':
      return '원';
    case 'rectangle':
      return '직사각형';
    case 'triangle':
      return '삼각형';
    default:
      return assertNever(shape); // 새로운 Shape 추가 시 컴파일 에러 발생
  }
}
```