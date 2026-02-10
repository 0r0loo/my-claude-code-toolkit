# Code Writer Agent - Frontend (React)

React 기반 프론트엔드 코드를 구현할 때 이 규칙을 따른다.
공통 규칙은 `common.md`를 함께 참고한다.

---

## 구현 순서

1. **타입/인터페이스** - Props, State, API 응답 타입 정의
2. **훅 (Hooks)** - 데이터 페칭, 상태 관리 로직
3. **컴포넌트** - UI 렌더링 (작은 단위 → 큰 단위)
4. **페이지** - 컴포넌트 조합, 라우팅

---

## React 패턴 가이드

### 디렉토리 구조
```
src/
├── components/         # 재사용 가능 UI 컴포넌트
│   ├── common/         # Button, Input, Modal 등
│   └── domain/         # 도메인 특화 컴포넌트 (UserCard, OrderList 등)
├── hooks/              # 커스텀 훅
├── pages/              # 페이지 컴포넌트 (라우트 단위)
├── types/              # 공통 타입 정의
├── apis/               # API 호출 함수
├── utils/              # 유틸리티 함수
└── constants/          # 상수
```

### 컴포넌트 작성
- 함수형 컴포넌트만 사용한다
- Props 타입을 interface로 명시한다
- 컴포넌트 하나가 하나의 책임만 갖도록 분리한다
- 조건부 렌더링이 3개 이상이면 컴포넌트를 분리한다

```typescript
// 예시
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <div>
      <span>{user.name}</span>
      <button onClick={() => onEdit(user.id)}>Edit</button>
    </div>
  );
}
```

### 커스텀 훅
- 데이터 페칭/상태 관리 로직은 커스텀 훅으로 분리한다
- 훅 이름은 `use`로 시작한다 (e.g., `useUserList`, `useAuth`)
- 하나의 훅이 하나의 관심사를 담당한다

### 상태 관리
- 로컬 상태: `useState`, `useReducer`
- 서버 상태: React Query / SWR (프로젝트 설정에 따름)
- 전역 상태: 프로젝트의 기존 상태 관리 라이브러리를 따른다
- 상태를 최소한으로 유지한다 (파생 가능한 값은 상태로 만들지 않는다)

### 에러 핸들링
- API 호출 시 에러 상태를 처리한다 (loading, error, success)
- Error Boundary를 활용한다 (프로젝트에 설정되어 있는 경우)
- 사용자에게 의미있는 에러 메시지를 표시한다

---

## 네이밍 컨벤션

- 파일 (컴포넌트): `PascalCase.tsx` (e.g., `UserCard.tsx`)
- 파일 (훅/유틸): `camelCase.ts` (e.g., `useAuth.ts`, `formatDate.ts`)
- 컴포넌트: `PascalCase` (e.g., `UserCard`)
- 훅: `useCamelCase` (e.g., `useUserList`)
- 이벤트 핸들러: `handle` + 대상 + 동작 (e.g., `handleUserDelete`)
- Props 콜백: `on` + 동작 (e.g., `onDelete`, `onChange`)

---

## 규칙

- 컴포넌트는 최대 200줄을 넘기지 않는다 (넘으면 분리)
- 인라인 스타일을 사용하지 않는다 (프로젝트의 스타일링 방식을 따른다)
- `any` 타입을 사용하지 않는다
- `useEffect`에는 반드시 의존성 배열을 명시한다
- 불필요한 리렌더링을 방지한다 (`useMemo`, `useCallback`은 필요할 때만)