# Zustand 패턴 코드 예시

## 1. Store 생성 기본

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

## 2. Selector 패턴

```typescript
// Good - 필요한 값만 구독 (리렌더링 최소화)
const count = useCounterStore((state) => state.count);
const increment = useCounterStore((state) => state.increment);

// Bad - 전체 store 구독 (불필요한 리렌더링 발생)
const store = useCounterStore();
```

### 개별 Selector

```typescript
function UserInfo() {
  const userName = useAuthStore((state) => state.userName);
  const avatarUrl = useAuthStore((state) => state.avatarUrl);
  return <div>{userName}</div>;
}
```

### Shallow 비교

```typescript
import { useShallow } from 'zustand/react/shallow';

const { userName, avatarUrl } = useAuthStore(
  useShallow((state) => ({
    userName: state.userName,
    avatarUrl: state.avatarUrl,
  }))
);
```

## 3. Store 설계 - 도메인별 분리

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
}));
```

## 4. Actions 패턴

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
      name: 'settings-storage',
      partialize: (state) => ({
        theme: state.theme,
        language: state.language,
      }),
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
        if (todo) todo.done = !todo.done;
      }),
  }))
);
```

## 6. Slice 패턴

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