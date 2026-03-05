# 에러 처리, 접근성 (a11y) 및 UX 패턴

## 1. 에러 처리

### 원칙: 에러 처리를 각 함수/컴포넌트에 흩뿌리지 않는다
- 각 함수마다 try-catch를 덕지덕지 붙이지 않는다
- `useState`로 에러 상태를 직접 관리하지 않는다 (TanStack Query가 제공)
- 에러 처리는 **경계(Boundary)**에서 한 번에 처리한다

### API 에러: 서버 상태 라이브러리에 위임

```typescript
// Bad - useState + useEffect로 에러 직접 관리
function UserList() {
  const [error, setError] = useState<Error | null>(null);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetchUsers()
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);
}

// Good - 서버 상태 라이브러리가 에러를 관리
function UserList() {
  const { data: users, isLoading, error } = useUserList();
  if (error) return <ErrorDisplay error={error} />;
}
```

### 렌더링 에러: Error Boundary

```typescript
<ErrorBoundary fallback={<ErrorFallback />}>
  <UserContent />
</ErrorBoundary>
```

### 전역 API 에러: interceptor 또는 라이브러리 설정에서 일괄 처리
- axios interceptor, QueryClient defaultOptions 등 프로젝트 설정에 따른다
- 개별 컴포넌트가 아닌 앱 수준에서 에러 알림(toast 등)을 처리한다

### 에러 UI 분기: early return 패턴

```typescript
function UserPage({ userId }: UserPageProps) {
  const { data: user, isLoading, error } = useUser(userId);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorDisplay error={error} />;
  if (!user) return <EmptyState />;

  return <UserContent user={user} />;
}
```

---

## 2. 접근성 (a11y)

### 시맨틱 HTML 사용
- 클릭 가능한 요소는 반드시 `<button>` 또는 `<a>`를 사용한다
- `<div onClick>`, `<span onClick>`을 금지한다

```typescript
// Bad
<div onClick={handleDelete} className="cursor-pointer">삭제</div>

// Good
<button type="button" onClick={handleDelete}>삭제</button>
```

### 아이콘 버튼에 aria-label 필수

```typescript
// Bad - 스크린 리더가 내용을 알 수 없음
<button onClick={onClose}><XIcon /></button>

// Good
<button onClick={onClose} aria-label="닫기"><XIcon /></button>
```

### 이미지에 alt, width, height 필수

```typescript
// Bad
<img src={user.avatar} />

// Good
<img src={user.avatar} alt={`${user.name} 프로필`} width={40} height={40} />
```

### focus-visible 보장
- `outline: none`을 사용할 때 반드시 `focus-visible` 대체 스타일을 제공한다

```typescript
// Bad - 포커스 표시 완전 제거
<button className="outline-none">

// Good - 키보드 포커스 시 표시
<button className="outline-none focus-visible:ring-2 focus-visible:ring-blue-500">
```

### 폼 접근성
- 모든 입력 필드에 `<label>` 또는 `aria-label`을 연결한다
- 적절한 `type`, `inputMode`, `autoComplete` 속성을 사용한다
- 붙여넣기(`onPaste`)를 차단하지 않는다

---

## 3. UX 패턴

### 파괴적 액션에 확인 단계
- 삭제, 초기화 등 되돌릴 수 없는 동작에는 확인 UI를 추가한다

### URL 파라미터와 UI 상태 동기화
- 탭, 필터, 페이지 등 공유 가능한 UI 상태는 URL 파라미터에 반영한다

```typescript
// Bad - 새로고침하면 상태 소실
const [tab, setTab] = useState('overview');

// Good - URL에 상태 반영 (deep-link 가능)
const [searchParams, setSearchParams] = useSearchParams();
const tab = searchParams.get('tab') ?? 'overview';
```

### 대규모 리스트 가상화
- 50개 이상의 항목을 렌더링할 때는 가상화 라이브러리를 사용한다
- `@tanstack/react-virtual`, `react-window` 등을 활용한다
