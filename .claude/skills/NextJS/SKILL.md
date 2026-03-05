---
name: nextjs
description: Next.js App Router 기반 개발 가이드. Next.js 프로젝트에서 Server/Client Component, 데이터 페칭, Route Handler, Middleware, Server Actions 구현 시 참조한다.
---

# Next.js Skill - App Router 규칙

Next.js App Router 기반 프로젝트에 적용되는 규칙이다.
React 핵심 규칙은 `../React/SKILL.md`, 공통 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. App Router 기본 구조

### 예약 파일명
App Router는 다음 예약 파일명을 사용한다.

| 파일명 | 역할 | 설명 |
|--------|------|------|
| `page.tsx` | 페이지 | 해당 라우트의 UI |
| `layout.tsx` | 레이아웃 | 하위 라우트 공유 레이아웃 |
| `loading.tsx` | 로딩 UI | Suspense 기반 로딩 상태 |
| `error.tsx` | 에러 UI | Error Boundary 기반 에러 처리 |
| `not-found.tsx` | 404 UI | 리소스를 찾을 수 없을 때 |
| `template.tsx` | 템플릿 | 네비게이션마다 새 인스턴스 생성 |
| `default.tsx` | 기본 UI | Parallel Routes 기본 폴백 |

### 기본 구조 예시
```
app/
  layout.tsx          # 루트 레이아웃 (필수)
  page.tsx            # 홈 페이지
  loading.tsx         # 글로벌 로딩
  error.tsx           # 글로벌 에러
  not-found.tsx       # 404 페이지
  users/
    page.tsx          # /users
    [id]/
      page.tsx        # /users/:id
      loading.tsx
      error.tsx
  api/
    users/
      route.ts        # API: /api/users
```

---

## 2. Server Component vs Client Component

### 기본 원칙
- **모든 컴포넌트는 기본적으로 Server Component이다**
- `'use client'`는 실제로 클라이언트 기능이 필요할 때만 선언한다
- 서버에서 할 수 있는 일은 서버에서 처리한다

### Client Component가 필요한 경우
- `useState`, `useEffect` 등 React 훅 사용 시
- 브라우저 API 접근 시 (`window`, `document`, `localStorage`)
- 이벤트 핸들러 사용 시 (`onClick`, `onChange`)
- 클라이언트 전용 라이브러리 사용 시

### 분리 전략
- `'use client'` 경계를 최대한 하위로 밀어내린다
- 페이지 전체를 Client Component로 만들지 않는다

```typescript
// Bad - 페이지 전체를 Client Component로 선언
'use client';

export default function UserPage() {
  const [tab, setTab] = useState('profile');
  const users = await fetchUsers(); // Server에서 가능한 작업인데 Client로 선언

  return <div>...</div>;
}

// Good - 클라이언트 기능만 분리
// app/users/page.tsx (Server Component)
export default async function UserPage() {
  const users = await fetchUsers();

  return (
    <div>
      <UserList users={users} />
      <UserTabs /> {/* 이것만 Client Component */}
    </div>
  );
}

// components/UserTabs.tsx (Client Component)
'use client';

export function UserTabs() {
  const [tab, setTab] = useState('profile');
  return <Tabs value={tab} onChange={setTab} />;
}
```

---

## 3. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 페이지 파일 | `page.tsx` (예약) | `app/users/page.tsx` |
| 레이아웃 파일 | `layout.tsx` (예약) | `app/layout.tsx` |
| 로딩 파일 | `loading.tsx` (예약) | `app/users/loading.tsx` |
| 에러 파일 | `error.tsx` (예약) | `app/users/error.tsx` |
| API 라우트 | `route.ts` (예약) | `app/api/users/route.ts` |
| Server Action 파일 | `camelCase.ts` | `actions/createUser.ts` |
| Server Action 함수 | `camelCase` | `createUser`, `deletePost` |
| Route Group | `(groupName)` | `(marketing)`, `(dashboard)` |
| Private Folder | `_folderName` | `_components`, `_lib` |
| Dynamic Segment | `[param]` | `[id]`, `[slug]` |
| Catch-all Segment | `[...param]` | `[...slug]` |

---

## 4. 금지 사항

- Client Component에서 무거운 데이터 페칭 로직 작성 금지
- 불필요한 `'use client'` 선언 금지 - 서버에서 가능하면 서버에서 처리
- Pages Router 패턴 사용 금지 (`getServerSideProps`, `getStaticProps`, `_app.tsx`, `_document.tsx`)
- `page.tsx`에 `'use client'` 직접 선언 금지 - 클라이언트 로직은 하위 컴포넌트로 분리
- Server Component에서 `useState`, `useEffect` 등 클라이언트 훅 사용 금지
- `<img>` 태그 직접 사용 금지 - `next/image` 사용
- 외부 폰트를 `<link>` 태그로 로드 금지 - `next/font` 사용
- `router.push()`를 Server Component에서 사용 금지 - `redirect()` 사용
- API Route에서 비즈니스 로직 직접 구현 금지 - 별도 서비스 레이어로 분리

---

## 심화 참조

| 파일 | 내용 |
|------|------|
| `references/data-fetching.md` | 데이터 페칭 (Server Component fetch, Revalidation) + Route Handlers (CRUD, 동적 라우트) |
| `references/middleware-actions.md` | Middleware (인증, 리다이렉트, matcher) + Server Actions (form action, revalidation) |
| `references/optimization.md` | Metadata (정적/동적) + 디렉토리 구조 패턴 (Route Groups, Parallel/Intercepting Routes) + Image/Font 최적화 |
