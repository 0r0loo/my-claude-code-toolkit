---
name: zustand
description: 클라이언트 전역 상태(모달, 테마, 사이드바 등)를 관리할 때 호출. Zustand 스토어 생성, Selector, 미들웨어 설정 시 참조.
targetLib: "zustand@4"
user-invocable: true
lastUpdated: 2026-03-19
---

# Zustand Skill - 클라이언트 상태 관리 규칙

Zustand를 사용한 클라이언트 상태 관리 규칙을 정의한다.
서버 상태 관리는 `../TanStackQuery/SKILL.md`를 참고한다.

> 코드 예시: `references/patterns.md` 참조

---

## 1. 기본 패턴

- `create<StoreType>((set, get) => ({ ... }))`로 store 생성
- 필요한 값만 개별 selector로 구독 (리렌더링 최소화)
- 전체 store 구독 금지 (`const store = useStore()`)

---

## 2. Store 설계 원칙

- **도메인별 분리** — 하나의 store는 하나의 관심사만 담당
- **서버 상태 분리** — 서버 데이터는 TanStack Query, 클라이언트 상태만 Zustand

| 상태 유형 | 관리 도구 | 예시 |
|-----------|-----------|------|
| 서버 상태 | TanStack Query | 사용자 목록, 게시글, API 응답 |
| 클라이언트 상태 | Zustand | 모달, 테마, 사이드바 상태 |

---

## 3. Selector 패턴

- 개별 값은 개별 selector로 구독
- 여러 값을 한 번에 가져올 때 `useShallow`로 불필요한 리렌더링 방지

---

## 4. Actions 패턴

- `set`으로 상태 업데이트, `get`으로 현재 상태 읽기
- Action은 반드시 Store 안에 정의 (Store 밖에서 `setState` 직접 호출 금지)

---

## 5. Middleware

- **persist** — localStorage 저장. `partialize`로 저장할 상태만 선택
- **devtools** — Redux DevTools 연동. action 이름을 세 번째 인자로 전달
- **immer** — 불변 업데이트 간소화. 직접 변경 가능

---

## 6. Slice 패턴

- 큰 store를 `StateCreator<StoreState, [], [], SliceType>`로 분리
- 합칠 때 `create<StoreState>()((...args) => ({ ...sliceA(...args), ...sliceB(...args) }))`

---

## 7. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| Store 훅 | `use` + 도메인 + `Store` | `useAuthStore`, `useCartStore` |
| Store 파일 | 도메인 + `Store.ts` | `authStore.ts` |
| Slice 파일 | 도메인 + `Slice.ts` | `authSlice.ts` |
| Action | 동사 + 명사 (camelCase) | `addItem`, `setTheme`, `toggleSidebar` |
| Store 디렉토리 | `stores/` | `src/stores/authStore.ts` |

---

## ⚠️ AI 함정 목록

> AI가 자주 틀리는 실수. 새로운 실패 발견 시 한 줄씩 추가한다.

- selector 없이 `useStore()`로 전체 구독 → 무관한 상태 변경에도 리렌더링
- `set` 안에서 `get()` 대신 `state` 콜백 사용 안 함 → 클로저로 인한 stale state
- persist 미들웨어에서 `partialize` 빠뜨리면 action 함수까지 localStorage에 저장 시도 → 에러

---

## 8. 금지 사항

- Store에 서버 데이터 캐싱 금지 - 서버 상태는 TanStack Query 사용
- 거대한 단일 store 금지 - 도메인별로 분리
- Selector 없이 전체 store 구독 금지
- Store 밖에서 action 정의 금지
- `any` 타입 사용 금지
- 컴포넌트 안에서 `useStore.setState()` 직접 호출 금지