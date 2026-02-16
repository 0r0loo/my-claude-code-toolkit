# Zustand Skill - 클라이언트 상태 관리 규칙

Zustand를 사용한 클라이언트 상태 관리 규칙을 정의한다.
서버 상태 관리는 `../TanStackQuery/SKILL.md`를 참고한다.

---

## 1. 기본 패턴

### Store 생성

```typescript
import { create } from 'zustand';

interface CounterStore {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

export const useCounterStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));
```

### Selector로 구독

```typescript
// Good - 필요한 값만 구독 (리렌더링 최소화)
const count = useCounterStore((state) => state.count);
const increment = useCounterStore((state) => state.increment);

// Bad - 전체 store 구독 (불필요한 리렌더링 발생)
const store = useCounterStore();
```

---

## 2. Store 설계 원칙

### 도메인별 분리
- 하나의 store는 하나의 관심사만 담당한다
- 관련 없는 상태를 하나의 store에 넣지 않는다

```typescript
// Good - 도메인별 분리
const useAuthStore = create<AuthStore>(() => ({ /* 인증 관련 */ }));
const useUIStore = create<UIStore>(() => ({ /* UI 상태 관련 */ }));
const useCartStore = create<CartStore>(() => ({ /* 장바구니 관련 */ }));

// Bad - 모든 것을 하나의 store에
const useAppStore = create<AppStore>(() => ({
  user: null,
  isModalOpen: false,
  cartItems: [],
  theme: 'light',
  // ... 모든 상태가 뒤섞임
}));
```

### 서버 상태와 클라이언트 상태 분리

| 상태 유형 | 관리 도구 | 예시 |
|-----------|-----------|------|
| 서버 상태 | TanStack Query | 사용자 목록, 게시글, API 응답 |
| 클라이언트 상태 | Zustand | 모달 열림/닫힘, 테마, 사이드바 상태 |

---

## 3. Selector 패턴

### 개별 Selector

```typescript
// Good - 각 값을 개별 selector로 구독
function UserInfo() {
  const userName = useAuthStore((state) => state.userName);
  const avatarUrl = useAuthStore((state) => state.avatarUrl);
  return <div>{userName}</div>;
}
```

### Shallow 비교

여러 값을 한 번에 가져올 때 `useShallow`로 불필요한 리렌더링을 방지한다.

```typescript
import { useShallow } from 'zustand/react/shallow';

// Good - 객체 반환 시 useShallow 사용
const { userName, avatarUrl } = useAuthStore(
  useShallow((state) => ({
    userName: state.userName,
    avatarUrl: state.avatarUrl,
  }))
);
```

---

## 4. Actions 패턴

### set과 get 사용

```typescript
interface TodoStore {
  todos: Todo[];
  addTodo: (text: string) => void;
  removeTodo: (id: string) => void;
  toggleTodo: (id: string) => void;
}

export const useTodoStore = create<TodoStore>((set, get) => ({
  todos: [],

  addTodo: (text) =>
    set((state) => ({
      todos: [...state.todos, { id: crypto.randomUUID(), text, done: false }],
    })),

  removeTodo: (id) =>
    set((state) => ({
      todos: state.todos.filter((todo) => todo.id !== id),
    })),

  // get()으로 현재 상태를 읽어야 할 때
  toggleTodo: (id) => {
    const todo = get().todos.find((t) => t.id === id);
    if (!todo) return;
    set((state) => ({
      todos: state.todos.map((t) =>
        t.id === id ? { ...t, done: !t.done } : t
      ),
    }));
  },
}));
```

### Action은 Store 안에 정의한다

```typescript
// Good - action이 store 안에 있음
export const useCartStore = create<CartStore>((set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
}));

// Bad - action이 store 밖에 있음
export const useCartStore = create<CartStore>(() => ({
  items: [],
}));

export function addItem(item: CartItem) {
  useCartStore.setState((state) => ({ items: [...state.items, item] }));
}
```

---

## 5. Middleware

### persist - localStorage 저장

```typescript
import { persist } from 'zustand/middleware';

export const useSettingsStore = create<SettingsStore>()(
  persist(
    (set) => ({
      theme: 'light' as const,
      language: 'ko' as const,
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    {
      name: 'settings-storage', // localStorage key
      partialize: (state) => ({
        theme: state.theme,
        language: state.language,
      }), // 저장할 상태만 선택
    }
  )
);
```

### devtools - 개발 도구 연동

```typescript
import { devtools } from 'zustand/middleware';

export const useAuthStore = create<AuthStore>()(
  devtools(
    (set) => ({
      user: null,
      login: (user) => set({ user }, false, 'auth/login'),
      logout: () => set({ user: null }, false, 'auth/logout'),
    }),
    { name: 'AuthStore' }
  )
);
```

### immer - 불변 업데이트 간소화

```typescript
import { immer } from 'zustand/middleware/immer';

export const useTodoStore = create<TodoStore>()(
  immer((set) => ({
    todos: [],
    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) todo.done = !todo.done; // 직접 변경 가능
      }),
  }))
);
```

---

## 6. Slice 패턴

큰 store를 slice로 분리하여 합치는 패턴이다.

```typescript
// authSlice.ts
interface AuthSlice {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
}

const createAuthSlice: StateCreator<StoreState, [], [], AuthSlice> = (set) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
});

// uiSlice.ts
interface UISlice {
  isSidebarOpen: boolean;
  toggleSidebar: () => void;
}

const createUISlice: StateCreator<StoreState, [], [], UISlice> = (set) => ({
  isSidebarOpen: true,
  toggleSidebar: () => set((state) => ({ isSidebarOpen: !state.isSidebarOpen })),
});

// store.ts - Slice 합치기
type StoreState = AuthSlice & UISlice;

export const useAppStore = create<StoreState>()((...args) => ({
  ...createAuthSlice(...args),
  ...createUISlice(...args),
}));
```

---

## 7. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| Store 훅 | `use` + 도메인 + `Store` | `useAuthStore`, `useCartStore` |
| Store 파일 | 도메인 + `Store.ts` | `authStore.ts`, `cartStore.ts` |
| Slice 파일 | 도메인 + `Slice.ts` | `authSlice.ts`, `uiSlice.ts` |
| Action | 동사 + 명사 (camelCase) | `addItem`, `setTheme`, `toggleSidebar` |
| Store 디렉토리 | `stores/` | `src/stores/authStore.ts` |

---

## 8. 금지 사항

- Store에 서버 데이터 캐싱 금지 - 서버 상태는 TanStack Query를 사용한다
- 거대한 단일 store 금지 - 도메인별로 분리한다
- Selector 없이 전체 store 구독 금지 - 필요한 값만 개별 selector로 가져온다
- Store 밖에서 action 정의 금지 - action은 store 안에 정의한다
- `any` 타입 사용 금지 - store에 명시적 타입을 정의한다
- 컴포넌트 안에서 `useStore.setState()` 직접 호출 금지 - store에 정의된 action을 사용한다
