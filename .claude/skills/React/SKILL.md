---
name: react
description: React 컴포넌트 설계 및 상태 관리 가이드. React 컴포넌트, Props, 커스텀 훅, 렌더링 최적화 등 React 코드 작성 시 참조한다.
targetLib: "react@18"
lastUpdated: 2025-03-01
---

# React Skill - React 핵심 규칙

React 컴포넌트 설계 및 개발에 적용되는 핵심 규칙이다.
공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. 컴포넌트 설계 원칙

### 함수형 컴포넌트만 사용한다
- 클래스 컴포넌트를 사용하지 않는다
- `React.FC`를 사용하지 않는다 - Props를 직접 타이핑한다

### Props 타입 명시
- 모든 컴포넌트는 Props 타입을 `type`으로 선언한다
- Props 네이밍은 `컴포넌트명 + Props`로 한다

### SRP (Single Responsibility Principle)
- 하나의 컴포넌트는 하나의 역할만 수행한다
- "이 컴포넌트가 하는 일"을 한 문장으로 설명할 수 없으면 분리한다

### 크기 제한
- 컴포넌트는 최대 200줄을 넘기지 않는다
- 200줄을 초과하면 하위 컴포넌트로 분리한다

```typescript
// Bad
const UserPage = () => {
  // 200줄 이상의 거대한 컴포넌트
};

// Good
type UserPageProps = {
  userId: string;
};

export function UserPage({ userId }: UserPageProps) {
  const { user, isLoading } = useUser(userId);

  if (isLoading) return <UserSkeleton />;
  if (!user) return <UserNotFound />;

  return (
    <div>
      <UserHeader user={user} />
      <UserContent user={user} />
      <UserActions userId={user.id} />
    </div>
  );
}
```

---

## 2. Props 설계

### 최소한의 Props
- 컴포넌트가 실제로 사용하는 값만 전달한다
- Props가 5개를 초과하면 설계를 재검토한다

### 콜백 네이밍
- Props로 전달하는 콜백은 `on` + 동사로 네이밍한다

```typescript
// Bad
type ButtonProps = {
  clickHandler: () => void;
  deleteCallback: () => void;
};

// Good
type ButtonProps = {
  onClick: () => void;
  onDelete: () => void;
};
```

### 객체 통째 전달 지양
- 필요한 프로퍼티만 개별적으로 전달한다
- 단, Props가 너무 많아지면 객체 전달을 허용한다

```typescript
// Bad - 불필요한 데이터까지 전달
type UserAvatarProps = {
  user: User; // user.name, user.avatar만 사용하는데 전체 객체 전달
};

// Good - 필요한 값만 전달
type UserAvatarProps = {
  name: string;
  avatarUrl: string;
};
```

---

## 3. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | `PascalCase.tsx` | `UserCard.tsx` |
| 훅 파일 | `useCamelCase.ts` | `useAuth.ts` |
| 유틸 파일 | `camelCase.ts` | `formatDate.ts` |
| 컴포넌트 | `PascalCase` | `UserCard` |
| 커스텀 훅 | `useCamelCase` | `useUserList` |
| 이벤트 핸들러 | `handle` + 대상 + 동작 | `handleUserDelete` |
| Props 콜백 | `on` + 동작 | `onDelete`, `onChange` |
| Props 타입 | `컴포넌트명 + Props` | `UserCardProps` |
| Context | `PascalCase + Context` | `AuthContext` |
| Provider | `PascalCase + Provider` | `AuthProvider` |

---

## 4. 금지 사항

- `any` 타입 사용 금지
- 인라인 스타일(`style={{}}`) 사용 금지 - 프로젝트 스타일링 방식을 따른다
- `useEffect` 의존성 배열 누락 금지
- `index.tsx`에 컴포넌트 로직 직접 작성 금지 (re-export만 허용)
- 클래스 컴포넌트 사용 금지
- `React.FC` 사용 금지
- 배열 인덱스를 `key`로 사용 금지 (정적 리스트 제외)
- `useEffect` 내에서 상태 동기화 로직 작성 금지 (파생값으로 처리)
- Props drilling이 3단계 이상일 때 Context 또는 상태 관리 라이브러리 미사용 금지
- 서버 상태(API 데이터)를 `useState` + `useEffect`로 관리 금지 (서버 상태 라이브러리 사용)
- 각 함수/컴포넌트마다 try-catch 남발 금지 (에러 경계에서 일괄 처리)
- `<div onClick>`, `<span onClick>` 금지 (`<button>` 또는 `<a>` 사용)
- 아이콘 버튼에 `aria-label` 누락 금지
- `outline: none` 단독 사용 금지 (`focus-visible` 대체 필수)
- 입력 필드에 `onPaste` 차단 금지

---

## 심화 참조

| 파일 | 설명 |
|------|------|
| `references/state-hooks.md` | 상태 관리 원칙 (배치, 파생값, 서버/클라이언트 분리) + 커스텀 훅 패턴 |
| `references/rendering-patterns.md` | 렌더링 최적화 (useMemo/useCallback, key) + 조건부 렌더링 패턴 |
| `references/a11y-ux.md` | 에러 처리 (Error Boundary, 서버 상태 위임) + 접근성 (시맨틱 HTML, aria-label, focus-visible) + UX 패턴 (파괴적 액션 확인, URL 동기화, 가상화) |
