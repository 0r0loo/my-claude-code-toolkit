---
name: typescript
description: 복잡한 타입 설계, 제네릭 함수 작성, 유틸리티 타입 조합, 타입 가드 구현 시 호출. any/as 사용을 피하고 타입 안전한 코드를 작성할 때 참조.
user-invocable: true
lastUpdated: 2026-03-19
---

# TypeScript Skill - 고급 패턴 규칙

FE/BE 공통으로 적용되는 TypeScript 심화 규칙을 정의한다.
공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

> 코드 예시: `references/patterns.md` 참조

---

## 1. 타입 추론 활용

- **변수는 추론에 맡긴다** — 불필요한 타입 명시 금지
- **함수 반환 타입과 파라미터는 명시한다** — 호출자가 추론에 의존하지 않게
- **`as const`** — 배열/객체를 리터럴 타입으로 추론. union type 추출에 활용
- **`satisfies`** — 타입 검증 + 추론 유지를 동시에

---

## 2. 유틸리티 타입

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

---

## 3. 타입 설계 원칙

- **유니언 > enum** — enum 대신 const object 또는 union literal 사용 (트리셰이킹 가능)
- **interface vs type**:
  - 객체 형태 → `interface` (확장 가능, 선언 병합)
  - 유니언/교차/함수/튜플/기본형 → `type`
- **readonly 활용** — 불변 데이터에 `readonly`, `readonly T[]`, `DeepReadonly<T>` 적용

---

## 4. 비동기 타입

- `async` 함수 반환 타입을 `Promise<T>`로 명시한다
- catch에서 `any` 대신 `unknown` 사용 후 타입 가드로 좁힌다
- 에러 타입 가드 유틸 함수(`getErrorMessage`) 활용
- 병렬 비동기: `Promise.all`의 결과를 구조 분해하여 타입 안전하게 사용

---

## 참조 문서

- **[패턴 코드 예시](./references/patterns.md)** - 타입 추론, 유틸리티 타입, 비동기 타입의 Bad/Good 예시
- **[Generics](./references/generics.md)** - 제네릭 함수, 제약 조건, 고급 제네릭 패턴
- **[Type Guards](./references/type-guards.md)** - 타입 가드, 판별 유니온, 완전성 검사
- **[Advanced Patterns](./references/advanced-patterns.md)** - 조건부 타입, 매핑 타입, 템플릿 리터럴 타입

---

## ⚠️ AI 함정 목록

> AI가 자주 틀리는 실수. 새로운 실패 발견 시 한 줄씩 추가한다.

- `as` 단언으로 타입 에러를 "해결"하면 런타임에 터짐 → 타입 가드나 설계 변경으로 해결
- `Partial<T>`로 업데이트 DTO를 만들면 빈 객체도 통과됨 → 최소 1개 필드 필수 조건 추가
- 유니언 타입에서 공통 필드만 접근 가능 → 판별 유니온(discriminated union)으로 설계
- `Record<string, T>`에서 없는 키 접근 시 undefined인데 타입은 T → `noUncheckedIndexedAccess` 권장

---

## 5. 금지 사항

- `any` 사용 금지 - `unknown` + 타입 가드로 좁힌다
- `as` 타입 단언 남용 금지 - 타입 가드 또는 올바른 타입 설계로 해결
- `@ts-ignore` 사용 금지 - 근본 원인을 해결한다
- `@ts-expect-error` 남용 금지 - 테스트 코드에서 의도적 에러 검증 시에만 허용
- non-null assertion (`!`) 남용 금지 - 옵셔널 체이닝(`?.`) 또는 타입 가드 사용
- `enum` 사용 금지 - const object 또는 union literal 사용
- 빈 인터페이스 `{}` 사용 금지 - `Record<string, never>` 또는 `unknown` 사용