# 상태 관리 및 커스텀 훅

## 1. 상태 관리 원칙

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

## 2. 커스텀 훅

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
