# Coding Skill - Frontend (React)

React 프론트엔드 코드에 적용되는 규칙이다.
공통 원칙은 `SKILL.md`를 함께 참고한다.

---

## 1. 컴포넌트 설계

### 분리 기준
- 재사용 가능한 UI → 별도 컴포넌트
- 독립적인 상태를 가진 영역 → 별도 컴포넌트
- 조건부 렌더링이 복잡한 영역 → 별도 컴포넌트
- 컴포넌트는 최대 200줄을 넘기지 않는다

### Props 설계
- Props는 최소한으로 유지한다
- 객체를 통째로 전달하기보다 필요한 값만 전달한다 (단, 너무 많아지면 객체로)
- 콜백은 `on` + 동사로 네이밍한다 (`onDelete`, `onChange`)
- Props 타입을 interface로 명시한다

```typescript
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

---

## 2. 상태 관리

### 원칙
- 상태는 가능한 가까운 곳에 배치한다 (lifting state는 필요할 때만)
- 파생 가능한 값은 상태로 만들지 않는다
- 서버 상태와 클라이언트 상태를 분리한다

### 분류
- **로컬 상태**: `useState`, `useReducer`
- **서버 상태**: React Query / SWR (프로젝트 설정에 따름)
- **전역 상태**: 프로젝트의 기존 상태 관리 라이브러리를 따른다

---

## 3. 커스텀 훅

- 데이터 페칭/상태 관리 로직은 커스텀 훅으로 분리한다
- 훅 이름은 `use`로 시작한다 (e.g., `useUserList`, `useAuth`)
- 하나의 훅이 하나의 관심사를 담당한다

---

## 4. 네이밍 컨벤션 (FE)

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | `PascalCase.tsx` | `UserCard.tsx` |
| 훅/유틸 파일 | `camelCase.ts` | `useAuth.ts` |
| 컴포넌트 | `PascalCase` | `UserCard` |
| 훅 | `useCamelCase` | `useUserList` |
| 이벤트 핸들러 | `handle` + 대상 + 동작 | `handleUserDelete` |
| Props 콜백 | `on` + 동작 | `onDelete` |

---

## 5. 금지 사항

- `any` 타입 사용 금지
- 인라인 스타일 사용 금지 (프로젝트 스타일링 방식을 따름)
- `useEffect` 의존성 배열 누락 금지
- 불필요한 `useMemo`/`useCallback` (성능 문제가 없으면 사용하지 않는다)
- `index.tsx`에 컴포넌트 로직 직접 작성 금지 (re-export만)