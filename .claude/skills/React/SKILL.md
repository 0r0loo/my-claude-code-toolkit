---
name: react
description: React 컴포넌트 설계 및 상태 관리 가이드. React 컴포넌트, Props, 커스텀 훅, 렌더링 최적화 등 React 코드 작성 시 참조한다.
---

# React Skill - React 핵심 규칙

React 컴포넌트 설계 및 개발에 적용되는 핵심 규칙이다.
공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. 컴포넌트 설계 원칙

### 함수형 컴포넌트만 사용한다
- 클래스 컴포넌트를 사용하지 않는다
- `React.FC`를 사용하지 않는다 - Props를 직접 타이핑한다

### Props interface 명시
- 모든 컴포넌트는 Props 타입을 `interface`로 선언한다
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
interface UserPageProps {
  userId: string;
}

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
interface ButtonProps {
  clickHandler: () => void;
  deleteCallback: () => void;
}

// Good
interface ButtonProps {
  onClick: () => void;
  onDelete: () => void;
}
```

### 객체 통째 전달 지양
- 필요한 프로퍼티만 개별적으로 전달한다
- 단, Props가 너무 많아지면 객체 전달을 허용한다

```typescript
// Bad - 불필요한 데이터까지 전달
interface UserAvatarProps {
  user: User; // user.name, user.avatar만 사용하는데 전체 객체 전달
}

// Good - 필요한 값만 전달
interface UserAvatarProps {
  name: string;
  avatarUrl: string;
}
```

---

## 3. 상태 관리 원칙

### 가까운 곳에 배치
- 상태는 그것을 사용하는 가장 가까운 컴포넌트에 배치한다
- 상위 컴포넌트로의 lifting은 실제로 필요할 때만 수행한다

### 파생값은 상태가 아니다
- 기존 상태에서 계산할 수 있는 값은 별도 상태로 만들지 않는다

```typescript
// Bad - 파생값을 상태로 관리
const [items, setItems] = useState<Item[]>([]);
const [itemCount, setItemCount] = useState(0);
// items가 변경될 때마다 setItemCount를 호출해야 함

// Good - 파생값은 계산
const [items, setItems] = useState<Item[]>([]);
const itemCount = items.length;
```

### 서버 상태와 클라이언트 상태 분리
- **서버 상태**: API에서 가져온 데이터 -> React Query / SWR 사용
- **클라이언트 상태**: UI 상태 (모달 열림, 탭 선택 등) -> useState / useReducer 사용
- 서버 데이터를 `useState`로 복사하지 않는다

---

## 4. 커스텀 훅

### use 접두사
- 모든 커스텀 훅은 `use`로 시작한다

### 하나의 관심사
- 하나의 훅은 하나의 관심사만 다룬다

### 데이터 페칭/상태 로직 분리
- 컴포넌트에서 데이터 페칭과 상태 로직을 커스텀 훅으로 분리한다

```typescript
// Bad - 컴포넌트에 로직이 섞여 있음
function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setIsLoading(true);
    fetchUsers()
      .then(setUsers)
      .catch(setError)
      .finally(() => setIsLoading(false));
  }, []);

  // ... 렌더링
}

// Good - 커스텀 훅으로 분리
function useUserList() {
  const { data: users = [], isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  });

  return { users, isLoading, error };
}

function UserList() {
  const { users, isLoading, error } = useUserList();
  // ... 렌더링만 담당
}
```

---

## 5. 렌더링 최적화

### 불필요한 useMemo/useCallback 금지
- 성능 문제가 실제로 측정된 경우에만 사용한다
- 참조 동일성이 필요한 경우(의존성 배열, memo된 자식 컴포넌트)에만 사용한다

```typescript
// Bad - 불필요한 메모이제이션
const userName = useMemo(() => `${first} ${last}`, [first, last]);

// Good - 단순 계산은 그냥 수행
const userName = `${first} ${last}`;
```

### key 올바르게 사용
- 리스트 렌더링 시 고유한 식별자를 `key`로 사용한다
- 배열 인덱스를 `key`로 사용하지 않는다 (정적 리스트 제외)

```typescript
// Bad
{items.map((item, index) => (
  <Item key={index} data={item} />
))}

// Good
{items.map((item) => (
  <Item key={item.id} data={item} />
))}
```

---

## 6. 조건부 렌더링 패턴

### 단순 조건
- 2개 이하의 조건은 삼항 연산자 또는 `&&`를 사용한다

```typescript
// 단순 표시/숨김
{isVisible && <Modal />}

// 이분기
{isLoading ? <Skeleton /> : <Content />}
```

### 복잡한 조건
- 3개 이상의 분기는 early return 또는 별도 컴포넌트로 분리한다

```typescript
// Bad - 중첩된 삼항
{isLoading ? <Skeleton /> : error ? <Error /> : data ? <Content /> : <Empty />}

// Good - early return
function UserContent({ isLoading, error, data }: UserContentProps) {
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorDisplay error={error} />;
  if (!data) return <EmptyState />;
  return <Content data={data} />;
}
```

---

## 7. 네이밍 컨벤션

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

## 8. 금지 사항

- `any` 타입 사용 금지
- 인라인 스타일(`style={{}}`) 사용 금지 - 프로젝트 스타일링 방식을 따른다
- `useEffect` 의존성 배열 누락 금지
- `index.tsx`에 컴포넌트 로직 직접 작성 금지 (re-export만 허용)
- 클래스 컴포넌트 사용 금지
- `React.FC` 사용 금지
- 배열 인덱스를 `key`로 사용 금지 (정적 리스트 제외)
- `useEffect` 내에서 상태 동기화 로직 작성 금지 (파생값으로 처리)
- Props drilling이 3단계 이상일 때 Context 또는 상태 관리 라이브러리 미사용 금지