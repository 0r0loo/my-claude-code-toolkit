# 렌더링 최적화 및 조건부 렌더링 패턴

## 1. 렌더링 최적화

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

## 2. 조건부 렌더링 패턴

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
