# TanStack Query 패턴 코드 예시

## 1. useQuery 기본 사용법

```typescript
const { data, isLoading, error } = useQuery({
  queryKey: ['users', { status: 'active' }],
  queryFn: () => userApi.getUsers({ status: 'active' }),
});

// enabled로 조건부 실행
const { data: user } = useQuery({
  queryKey: ['users', userId],
  queryFn: () => userApi.getUserById(userId),
  enabled: !!userId,
});

// select로 데이터 변환
const { data: userNames } = useQuery({
  queryKey: ['users'],
  queryFn: () => userApi.getUsers(),
  select: (users) => users.map((user) => user.name),
});
```

## 2. queryKey 팩토리 패턴

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

// Invalidation
queryClient.invalidateQueries({ queryKey: userKeys.lists() });
```

## 3. useMutation 기본 사용법

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

createUser.mutate({ name: '홍길동', email: 'hong@example.com' });
```

## 4. Optimistic Update 패턴

```typescript
const updateUser = useMutation({
  mutationFn: (data: UpdateUserDto) => userApi.updateUser(data),
  onMutate: async (newData) => {
    // 1. 진행 중인 쿼리 취소
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
    queryClient.setQueryData(userKeys.detail(newData.id), context?.previousUser);
  },
  onSettled: (_data, _error, variables) => {
    queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) });
  },
});
```

## 5. Prefetching

```typescript
function UserListItem({ userId }: { userId: string }) {
  const queryClient = useQueryClient();

  const handleMouseEnter = () => {
    queryClient.prefetchQuery({
      queryKey: userKeys.detail(userId),
      queryFn: () => userApi.getUserById(userId),
      staleTime: 1000 * 60 * 5,
    });
  };

  return (
    <Link to={`/users/${userId}`} onMouseEnter={handleMouseEnter}>
      사용자 상세
    </Link>
  );
}
```

## 6. Suspense 모드

```typescript
function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useSuspenseQuery({
    queryKey: userKeys.detail(userId),
    queryFn: () => userApi.getUserById(userId),
  });

  return <div>{user.name}</div>;
}

function UserPage({ userId }: { userId: string }) {
  return (
    <Suspense fallback={<UserProfileSkeleton />}>
      <UserProfile userId={userId} />
    </Suspense>
  );
}
```

## 7. QueryClient 설정

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      gcTime: 1000 * 60 * 30,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});
```

## 8. 캐시 전략 예시

```typescript
// 거의 안 바뀌는 데이터
useQuery({
  queryKey: categoryKeys.list(),
  queryFn: fetchCategories,
  staleTime: Infinity,
});

// 자주 바뀌는 데이터
useQuery({
  queryKey: postKeys.list(filters),
  queryFn: () => fetchPosts(filters),
  staleTime: 1000 * 60,
});

// 실시간 데이터: refetchInterval
useQuery({
  queryKey: ['notifications'],
  queryFn: fetchNotifications,
  staleTime: 0,
  refetchInterval: 1000 * 30,
});
```