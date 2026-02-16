# TDD Agent - Frontend (React)

React 기반 프론트엔드 테스트를 작성할 때 이 규칙을 따른다.
공통 규칙은 `common.md`를 함께 참고한다.

---

## Testing Library 쿼리 우선순위

접근성과 사용자 관점을 반영하여 아래 순서로 쿼리를 선택한다:

1. **`getByRole`** - 가장 우선. 접근성 역할 기반 (e.g., `button`, `textbox`, `heading`)
2. **`getByLabelText`** - 폼 요소에 적합. label 연결 기반
3. **`getByPlaceholderText`** - label이 없는 입력 필드
4. **`getByText`** - 비대화형 요소의 텍스트 기반
5. **`getByDisplayValue`** - 현재 값이 표시된 폼 요소
6. **`getByAltText`** - 이미지, area 요소
7. **`getByTitle`** - title 속성 기반
8. **`getByTestId`** - 최후의 수단. 다른 쿼리로 불가능할 때만 사용

```typescript
// 좋은 예 - 역할 기반 쿼리
const submitButton = screen.getByRole('button', { name: '제출' });
const emailInput = screen.getByRole('textbox', { name: '이메일' });

// 피할 예 - testId 의존
const submitButton = screen.getByTestId('submit-btn');
```

---

## 사용자 이벤트

### userEvent 사용 (fireEvent보다 우선)
```typescript
import userEvent from '@testing-library/user-event';

it('should call onSubmit when form is submitted', async () => {
  const user = userEvent.setup();
  const handleSubmit = jest.fn();

  render(<LoginForm onSubmit={handleSubmit} />);

  // userEvent는 실제 사용자 행동을 시뮬레이션한다
  await user.type(screen.getByRole('textbox', { name: '이메일' }), 'alice@example.com');
  await user.type(screen.getByLabelText('비밀번호'), 'password123');
  await user.click(screen.getByRole('button', { name: '로그인' }));

  expect(handleSubmit).toHaveBeenCalledWith({
    email: 'alice@example.com',
    password: 'password123',
  });
});
```

### fireEvent vs userEvent
- `userEvent`: 실제 사용자 동작 시뮬레이션 (클릭, 타이핑, 탭 이동 등). **기본으로 사용한다.**
- `fireEvent`: DOM 이벤트 직접 발생. `scroll`, `resize` 등 userEvent가 지원하지 않는 이벤트에만 사용한다.

---

## 커스텀 훅 테스트

### renderHook 패턴
```typescript
import { renderHook, waitFor } from '@testing-library/react';

describe('useCounter', () => {
  it('should increment counter', () => {
    const { result } = renderHook(() => useCounter(0));

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

### Provider가 필요한 훅
```typescript
describe('useUser', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={new QueryClient()}>
      {children}
    </QueryClientProvider>
  );

  it('should fetch user data', async () => {
    const { result } = renderHook(() => useUser('1'), { wrapper });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toEqual(mockUser);
  });
});
```

---

## Provider Wrapper 패턴

### 공통 테스트 렌더 함수
```typescript
// test/utils.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { render, RenderOptions } from '@testing-library/react';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  initialEntries?: string[];
}

export function renderWithProviders(
  ui: React.ReactElement,
  options: CustomRenderOptions = {},
) {
  const { initialEntries = ['/'], ...renderOptions } = options;
  const queryClient = createTestQueryClient();

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={initialEntries}>
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    );
  }

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}
```

---

## MSW (Mock Service Worker) API 모킹

### 핸들러 정의
```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'Alice' },
      { id: '2', name: 'Bob' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: '3', ...body }, { status: 201 });
  }),

  http.get('/api/users/:id', ({ params }) => {
    const { id } = params;
    return HttpResponse.json({ id, name: 'Alice' });
  }),
];
```

### 서버 설정
```typescript
// mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

### 테스트에서 사용
```typescript
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('should display user list', async () => {
  render(<UserList />);

  await waitFor(() => {
    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.getByText('Bob')).toBeInTheDocument();
  });
});

it('should display error message on server error', async () => {
  // 특정 테스트에서 핸들러 오버라이드
  server.use(
    http.get('/api/users', () => {
      return HttpResponse.json(null, { status: 500 });
    }),
  );

  render(<UserList />);

  await waitFor(() => {
    expect(screen.getByText('오류가 발생했습니다')).toBeInTheDocument();
  });
});
```

---

## 파일 네이밍

```
src/
├── components/
│   └── UserCard/
│       ├── UserCard.tsx
│       └── UserCard.test.tsx        # 컴포넌트 테스트
├── hooks/
│   ├── useAuth.ts
│   └── useAuth.test.ts              # 훅 테스트
├── utils/
│   ├── formatDate.ts
│   └── formatDate.test.ts           # 유틸리티 테스트
└── mocks/
    ├── handlers.ts                  # MSW 핸들러
    └── server.ts                    # MSW 서버 설정
```

---

## 규칙

- 테스트 파일명은 `*.test.tsx` (컴포넌트) 또는 `*.test.ts` (훅/유틸)을 사용한다
- `getByTestId`는 다른 쿼리로 선택이 불가능할 때만 최후의 수단으로 사용한다
- `userEvent`를 기본으로 사용한다 - `fireEvent`는 특수한 경우에만 사용한다
- `waitFor` / `findBy`로 비동기 렌더링을 올바르게 처리한다
- API 모킹은 MSW를 사용한다 - `jest.mock`으로 fetch/axios를 직접 모킹하지 않는다
- 스냅샷 테스트(`toMatchSnapshot`)는 지양한다 - 행동 기반 테스트를 작성한다
- `.claude/skills/TDD/frontend.md`의 규칙을 따른다