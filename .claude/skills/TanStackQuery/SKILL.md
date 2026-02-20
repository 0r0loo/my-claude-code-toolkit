---
name: tanstack-query
description: TanStack Query 서버 상태 관리 가이드. useQuery, useMutation, queryKey 팩토리, Optimistic Update, Prefetching 등 서버 상태 관리 시 참조한다.
---

# TanStack Query Skill - 서버 상태 관리 규칙

TanStack Query (React Query)를 사용한 서버 상태 관리 규칙을 정의한다.
클라이언트 상태 관리는 `../Zustand/SKILL.md`를 참고한다.

---

## 1. 기본 개념

### 서버 상태 vs 클라이언트 상태
- **서버 상태**: API에서 가져오는 데이터 (사용자 목록, 게시글 등)
- **클라이언트 상태**: UI에서만 존재하는 데이터 (모달 열림/닫힘, 폼 입력값 등)
- TanStack Query는 서버 상태만 관리한다

### Stale-While-Revalidate
- 캐시된 데이터(stale)를 먼저 보여주고, 백그라운드에서 최신 데이터를 가져온다
- 사용자 경험과 데이터 최신성을 동시에 확보한다

---

## 2. useQuery 패턴

### 기본 사용법

```typescript
// Good
const { data, isLoading, error } = useQuery({
  queryKey: ['users', { status: 'active' }],
  queryFn: () => userApi.getUsers({ status: 'active' }),
});

// Good - enabled로 조건부 실행
const { data: user } = useQuery({
  queryKey: ['users', userId],
  queryFn: () => userApi.getUserById(userId),
  enabled: !!userId,
});

// Good - select로 데이터 변환
const { data: userNames } = useQuery({
  queryKey: ['users'],
  queryFn: () => userApi.getUsers(),
  select: (users) => users.map((user) => user.name),
});
```

### queryKey 컨벤션
- 배열 형태로 작성한다
- 첫 번째 요소는 엔티티명 (복수형)
- 이후 요소는 필터/파라미터

```typescript
// 목록
['users']
['users', { status: 'active', page: 1 }]

// 단건
['users', userId]

// 관계 데이터
['users', userId, 'posts']
```

---

## 3. queryKey 팩토리 패턴

queryKey를 객체로 중앙 관리하여 일관성과 재사용성을 확보한다.

```typescript
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
};

// 사용
useQuery({
  queryKey: userKeys.detail(userId),
  queryFn: () => userApi.getUserById(userId),
});

// Invalidation - 모든 user 목록 캐시 무효화
queryClient.invalidateQueries({ queryKey: userKeys.lists() });
```

---

## 4. useMutation 패턴

### 기본 사용법

```typescript
const createUser = useMutation({
  mutationFn: (data: CreateUserDto) => userApi.createUser(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: userKeys.lists() });
  },
  onError: (error) => {
    toast.error(`사용자 생성 실패: ${error.message}`);
  },
});

// 호출
createUser.mutate({ name: '홍길동', email: 'hong@example.com' });
```

### onSuccess에서 반드시 캐시를 무효화한다

| 작업 | invalidateQueries 대상 |
|------|------------------------|
| 생성 | 목록 쿼리 (`lists()`) |
| 수정 | 목록 + 해당 상세 (`all`) 또는 정밀 지정 |
| 삭제 | 목록 쿼리 (`lists()`) |

---

## 5. Optimistic Update 패턴

사용자 경험을 위해 서버 응답 전에 UI를 먼저 업데이트한다.

```typescript
const updateUser = useMutation({
  mutationFn: (data: UpdateUserDto) => userApi.updateUser(data),
  onMutate: async (newData) => {
    // 1. 진행 중인 쿼리 취소 (덮어쓰기 방지)
    await queryClient.cancelQueries({ queryKey: userKeys.detail(newData.id) });

    // 2. 이전 데이터 스냅샷 저장
    const previousUser = queryClient.getQueryData(userKeys.detail(newData.id));

    // 3. 캐시를 낙관적으로 업데이트
    queryClient.setQueryData(userKeys.detail(newData.id), (old: User) => ({
      ...old,
      ...newData,
    }));

    // 4. 롤백용 컨텍스트 반환
    return { previousUser };
  },
  onError: (_error, newData, context) => {
    // 에러 시 이전 데이터로 롤백
    queryClient.setQueryData(userKeys.detail(newData.id), context?.previousUser);
  },
  onSettled: (_data, _error, variables) => {
    // 성공/실패 무관하게 캐시 재검증
    queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) });
  },
});
```

---

## 6. Prefetching

### 라우트 전환 시 Prefetching

```typescript
// 마우스 호버 시 미리 데이터를 가져온다
function UserListItem({ userId }: { userId: string }) {
  const queryClient = useQueryClient();

  const handleMouseEnter = () => {
    queryClient.prefetchQuery({
      queryKey: userKeys.detail(userId),
      queryFn: () => userApi.getUserById(userId),
      staleTime: 1000 * 60 * 5, // 5분 동안 재요청 방지
    });
  };

  return (
    <Link to={`/users/${userId}`} onMouseEnter={handleMouseEnter}>
      사용자 상세
    </Link>
  );
}
```

---

## 7. Suspense 모드

React Suspense와 함께 사용하여 로딩 처리를 선언적으로 한다.

```typescript
// useSuspenseQuery는 data가 항상 존재함을 보장한다
function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useSuspenseQuery({
    queryKey: userKeys.detail(userId),
    queryFn: () => userApi.getUserById(userId),
  });

  // user는 undefined가 아님 - 타입 안전
  return <div>{user.name}</div>;
}

// 부모에서 Suspense로 감싼다
function UserPage({ userId }: { userId: string }) {
  return (
    <Suspense fallback={<UserProfileSkeleton />}>
      <UserProfile userId={userId} />
    </Suspense>
  );
}
```

---

## 8. QueryClient 설정

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,    // 5분 - 데이터가 stale로 간주되기까지의 시간
      gcTime: 1000 * 60 * 30,      // 30분 - 미사용 캐시 제거까지의 시간
      retry: 1,                     // 실패 시 1회 재시도
      refetchOnWindowFocus: false,  // 윈도우 포커스 시 자동 refetch 비활성화
    },
  },
});
```

| 옵션 | 권장값 | 설명 |
|------|--------|------|
| `staleTime` | `5분` | 짧으면 요청 과다, 길면 데이터 지연 |
| `gcTime` | `30분` | staleTime보다 길어야 한다 |
| `retry` | `1` | 네트워크 오류 대비 최소 재시도 |
| `refetchOnWindowFocus` | `false` | 프로젝트 요구사항에 따라 조정 |

---

## 9. 금지 사항

- `useEffect`로 데이터 페칭 금지 - TanStack Query를 사용한다
- queryKey 하드코딩 금지 - queryKey 팩토리 패턴을 사용한다
- 불필요한 `refetchOnWindowFocus: true` 설정 금지 - 기본값 대신 명시적으로 관리한다
- `onSuccess` 콜백 안에서 상태 동기화 금지 (`useState`에 서버 데이터 복사 등)
- `queryFn` 안에서 에러를 삼키는 try-catch 금지 - TanStack Query가 에러를 관리하게 한다
- `cacheTime` 사용 금지 - v5부터 `gcTime`으로 변경되었다
