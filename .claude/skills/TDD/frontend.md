# TDD Skill - Frontend (React)

React 프론트엔드 테스트에 적용되는 규칙이다.
공통 원칙은 `SKILL.md`를 함께 참고한다.

---

## 1. Testing Library 철학

> "The more your tests resemble the way your software is used, the more confidence they can give you."
> -- Testing Library 핵심 원칙

### 사용자가 보는 대로 테스트하라
- DOM 구조나 컴포넌트 내부 상태를 테스트하지 않는다
- 사용자가 화면에서 보고, 클릭하고, 입력하는 것을 기준으로 테스트한다
- `data-testid`는 **최후의 수단**이다. 시맨틱한 쿼리를 먼저 시도한다

```typescript
// Bad - 구현 세부사항 테스트
expect(component.state.isOpen).toBe(true);
expect(wrapper.find('.modal-class')).toHaveLength(1);

// Good - 사용자 관점 테스트
expect(screen.getByRole('dialog')).toBeInTheDocument();
expect(screen.getByText('모달 제목')).toBeVisible();
```

---

## 2. 쿼리 우선순위

Testing Library 쿼리는 접근성과 사용자 경험을 기준으로 우선순위가 있다.

| 우선순위 | 쿼리 | 용도 |
|----------|-------|------|
| 1 | `getByRole` | 접근성 역할로 조회 (button, heading, textbox 등) |
| 2 | `getByLabelText` | 폼 요소를 라벨로 조회 |
| 3 | `getByPlaceholderText` | placeholder로 조회 |
| 4 | `getByText` | 텍스트 콘텐츠로 조회 |
| 5 | `getByDisplayValue` | 현재 입력값으로 조회 |
| 6 | `getByAltText` | alt 속성으로 조회 (이미지) |
| 7 | `getByTitle` | title 속성으로 조회 |
| 8 | `getByTestId` | data-testid로 조회 (**최후의 수단**) |

```typescript
// Best - 역할 기반
screen.getByRole('button', { name: '저장' });
screen.getByRole('heading', { level: 2 });
screen.getByRole('textbox', { name: '이메일' });

// Good - 라벨 기반
screen.getByLabelText('비밀번호');

// Acceptable - 텍스트 기반
screen.getByText('환영합니다');

// Last resort - testid 기반
screen.getByTestId('complex-chart');
```

---

## 3. userEvent vs fireEvent

### userEvent를 기본으로 사용한다

`userEvent`는 실제 사용자 상호작용을 더 정확하게 시뮬레이션한다.

| 항목 | `fireEvent` | `userEvent` |
|------|-------------|-------------|
| 이벤트 수준 | 단일 DOM 이벤트 | 사용자 행동 전체 시뮬레이션 |
| 예시: click | `click` 이벤트만 발생 | `pointerDown` → `mouseDown` → `pointerUp` → `mouseUp` → `click` |
| 예시: type | 값을 직접 설정 | 키보드 입력을 하나씩 시뮬레이션 |
| 포커스 | 자동 처리 안 됨 | 자동으로 포커스 이동 |
| 권장 여부 | 특수한 경우에만 | **기본으로 사용** |

```typescript
import userEvent from '@testing-library/user-event';

it('should submit form with user input', async () => {
  // Arrange
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);

  // Act
  await user.type(screen.getByLabelText('이메일'), 'test@test.com');
  await user.type(screen.getByLabelText('비밀번호'), 'password123');
  await user.click(screen.getByRole('button', { name: '로그인' }));

  // Assert
  expect(mockSubmit).toHaveBeenCalledWith({
    email: 'test@test.com',
    password: 'password123',
  });
});
```

### fireEvent 사용이 적절한 경우
- `scroll`, `resize` 등 userEvent가 지원하지 않는 이벤트
- 특정 DOM 이벤트를 정밀하게 제어해야 하는 경우

---

## 4. 비동기 렌더링 테스트

### waitFor

상태 변경 후 DOM 업데이트를 기다린다.

```typescript
it('should show user list after loading', async () => {
  // Arrange
  render(<UserList />);

  // Act & Assert
  await waitFor(() => {
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

### findBy*

`getBy` + `waitFor`의 축약형이다. 비동기로 나타나는 요소를 조회할 때 사용한다.

```typescript
it('should display success message after save', async () => {
  // Arrange
  const user = userEvent.setup();
  render(<UserForm />);

  // Act
  await user.click(screen.getByRole('button', { name: '저장' }));

  // Assert
  const successMessage = await screen.findByText('저장되었습니다');
  expect(successMessage).toBeInTheDocument();
});
```

### queryBy*

요소가 **없음**을 확인할 때 사용한다 (`getBy`는 없으면 에러를 던진다).

```typescript
it('should hide error message initially', () => {
  render(<LoginForm />);

  expect(screen.queryByText('로그인 실패')).not.toBeInTheDocument();
});
```

### 규칙
- 비동기 요소 조회: `findBy*` 사용
- 요소 부재 확인: `queryBy*` 사용
- 복잡한 비동기 대기: `waitFor` 사용
- `waitFor` 안에서 부수 효과(side effect)를 실행하지 않는다

---

## 5. renderHook 테스트

커스텀 훅은 `renderHook`으로 테스트한다.

```typescript
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('should initialize with default value', () => {
    // Arrange & Act
    const { result } = renderHook(() => useCounter(0));

    // Assert
    expect(result.current.count).toBe(0);
  });

  it('should increment counter', () => {
    // Arrange
    const { result } = renderHook(() => useCounter(0));

    // Act
    act(() => {
      result.current.increment();
    });

    // Assert
    expect(result.current.count).toBe(1);
  });

  it('should reset counter to initial value', () => {
    // Arrange
    const { result } = renderHook(() => useCounter(5));

    // Act
    act(() => {
      result.current.increment();
      result.current.increment();
      result.current.reset();
    });

    // Assert
    expect(result.current.count).toBe(5);
  });
});
```

### 규칙
- 상태 변경은 반드시 `act()`로 감싼다
- `result.current`로 최신 값에 접근한다
- Provider가 필요한 훅은 `wrapper` 옵션을 사용한다 (아래 섹션 참고)

---

## 6. Provider Wrapper 패턴

외부 Provider에 의존하는 컴포넌트/훅 테스트 시 wrapper를 제공한다.

### 재사용 가능한 wrapper 함수

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import { render, renderHook, RenderOptions } from '@testing-library/react';
import { ReactElement, ReactNode } from 'react';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  });
}

function AllProviders({ children }: { children: ReactNode }) {
  const queryClient = createTestQueryClient();
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        {children}
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export function renderWithProviders(
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>,
) {
  return render(ui, { wrapper: AllProviders, ...options });
}

export function renderHookWithProviders<T>(hook: () => T) {
  return renderHook(hook, { wrapper: AllProviders });
}
```

### 사용 예시

```typescript
import { renderWithProviders } from '../test-utils';

it('should render user profile', async () => {
  renderWithProviders(<UserProfile userId="1" />);

  await waitFor(() => {
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

### 규칙
- 테스트용 `QueryClient`는 `retry: false`로 설정한다 (실패 시 즉시 에러)
- 각 테스트마다 새로운 `QueryClient` 인스턴스를 생성한다 (캐시 격리)
- wrapper 유틸은 `test-utils.tsx`에 정의하여 재사용한다

---

## 7. MSW (Mock Service Worker)

API 호출을 네트워크 수준에서 가로채어 Mock 응답을 제공한다.

### Handler 정의

```typescript
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'John', email: 'john@test.com' },
      { id: '2', name: 'Jane', email: 'jane@test.com' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      { id: '3', ...body },
      { status: 201 },
    );
  }),

  http.get('/api/users/:id', ({ params }) => {
    const { id } = params;
    if (id === '999') {
      return HttpResponse.json(
        { message: 'User not found' },
        { status: 404 },
      );
    }
    return HttpResponse.json({ id, name: 'John', email: 'john@test.com' });
  }),
];
```

### 서버 설정

```typescript
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// jest.setup.ts 또는 vitest.setup.ts
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### 테스트에서 핸들러 오버라이드

```typescript
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

it('should show error message when API fails', async () => {
  // Arrange - 이 테스트에서만 에러 응답으로 오버라이드
  server.use(
    http.get('/api/users', () => {
      return HttpResponse.json(
        { message: 'Internal Server Error' },
        { status: 500 },
      );
    }),
  );

  render(<UserList />);

  // Assert
  const errorMessage = await screen.findByText('데이터를 불러올 수 없습니다');
  expect(errorMessage).toBeInTheDocument();
});
```

### 규칙
- 기본 핸들러(성공 케이스)는 `handlers.ts`에 정의한다
- 에러/예외 케이스는 개별 테스트에서 `server.use()`로 오버라이드한다
- `onUnhandledRequest: 'error'`로 설정하여 미처리된 요청을 감지한다
- `afterEach`에서 `server.resetHandlers()`로 오버라이드를 초기화한다

---

## 8. 파일 위치 및 네이밍

| 대상 | 위치 | 예시 |
|------|------|------|
| 컴포넌트 테스트 | 소스 파일과 같은 디렉토리 | `UserCard.test.tsx` |
| 훅 테스트 | 소스 파일과 같은 디렉토리 | `useAuth.test.ts` |
| 유틸 테스트 | 소스 파일과 같은 디렉토리 | `formatDate.test.ts` |
| MSW 핸들러 | `src/mocks/` | `src/mocks/handlers.ts` |
| 테스트 유틸 | `src/test-utils.tsx` | 공통 render, wrapper 등 |

### 규칙
- 컴포넌트 테스트 확장자: `*.test.tsx`
- 훅/유틸 테스트 확장자: `*.test.ts`
- 테스트 파일은 테스트 대상과 같은 이름을 사용한다

---

## 9. 금지 사항

- `container.querySelector`로 DOM을 직접 조회 금지 (Testing Library 쿼리 사용)
- 컴포넌트 내부 상태를 직접 접근하여 검증 금지
- `fireEvent`를 기본으로 사용 금지 (`userEvent` 우선)
- 스냅샷 테스트를 행동 테스트의 대체로 사용 금지
- `waitFor` 안에서 부수 효과 실행 금지 (조회/단언만 수행)
- `act` 경고를 무시하거나 억제 금지 (원인을 해결)
- `data-testid` 남용 금지 (시맨틱 쿼리 우선)