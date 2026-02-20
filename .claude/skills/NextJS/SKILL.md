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

## 3. 데이터 페칭

### Server Component에서 직접 fetch
- Server Component에서 `async/await`로 직접 데이터를 가져온다
- `useEffect`로 데이터를 가져오지 않는다

```typescript
// Good - Server Component에서 직접 페칭
export default async function UserPage({ params }: { params: { id: string } }) {
  const user = await getUser(params.id);
  return <UserProfile user={user} />;
}
```

### Revalidation 전략
- **Time-based**: `next: { revalidate: 60 }` - 일정 시간마다 갱신
- **On-demand**: `revalidateTag()`, `revalidatePath()` - 특정 이벤트 시 갱신

```typescript
// Time-based revalidation
const data = await fetch('https://api.example.com/users', {
  next: { revalidate: 3600 }, // 1시간마다 갱신
});

// Tag-based revalidation
const data = await fetch('https://api.example.com/users', {
  next: { tags: ['users'] },
});

// Server Action에서 revalidation 트리거
'use server';
import { revalidateTag } from 'next/cache';

export async function createUser(formData: FormData) {
  await saveUser(formData);
  revalidateTag('users');
}
```

---

## 4. Route Handlers

### 위치 및 구조
- `app/api/` 디렉토리 하위에 `route.ts` 파일로 정의한다
- HTTP 메서드를 named export로 정의한다

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const users = await getUsers();
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await createUser(body);
  return NextResponse.json(user, { status: 201 });
}
```

### 동적 라우트
```typescript
// app/api/users/[id]/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  const user = await getUser(params.id);
  if (!user) {
    return NextResponse.json({ error: 'Not Found' }, { status: 404 });
  }
  return NextResponse.json(user);
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  const body = await request.json();
  const user = await updateUser(params.id, body);
  return NextResponse.json(user);
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  await deleteUser(params.id);
  return new NextResponse(null, { status: 204 });
}
```

---

## 5. Middleware

### 용도
- 인증/인가 체크
- 리다이렉트 처리
- 요청/응답 헤더 수정
- 국제화(i18n) 라우팅

### 작성 패턴
```typescript
// middleware.ts (프로젝트 루트)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;

  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
};
```

---

## 6. Metadata

### 정적 Metadata
```typescript
// app/about/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '소개 - 서비스명',
  description: '서비스 소개 페이지입니다.',
};
```

### 동적 Metadata
```typescript
// app/users/[id]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({
  params,
}: {
  params: { id: string };
}): Promise<Metadata> {
  const user = await getUser(params.id);

  return {
    title: `${user.name} - 프로필`,
    description: `${user.name}의 프로필 페이지입니다.`,
  };
}
```

---

## 7. Server Actions

### 정의 및 사용
- `'use server'` 지시문으로 서버 액션을 정의한다
- form의 `action` 속성이나 이벤트 핸들러에서 호출한다

```typescript
// actions/user.ts
'use server';

import { revalidatePath } from 'next/cache';

export async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  await db.user.create({ data: { name, email } });
  revalidatePath('/users');
}

export async function deleteUser(userId: string) {
  await db.user.delete({ where: { id: userId } });
  revalidatePath('/users');
}
```

### Form에서 사용
```typescript
// components/CreateUserForm.tsx
import { createUser } from '@/actions/user';

export function CreateUserForm() {
  return (
    <form action={createUser}>
      <input name="name" type="text" required />
      <input name="email" type="email" required />
      <button type="submit">생성</button>
    </form>
  );
}
```

---

## 8. 디렉토리 구조 패턴

### Route Groups - `(group)`
- URL에 영향을 주지 않고 라우트를 그룹화한다

```
app/
  (marketing)/
    about/page.tsx      # /about
    blog/page.tsx       # /blog
  (dashboard)/
    layout.tsx          # dashboard 전용 레이아웃
    settings/page.tsx   # /settings
    profile/page.tsx    # /profile
```

### Private Folders - `_folder`
- 라우팅에서 제외되는 내부 폴더

```
app/
  _components/          # 라우팅에 포함되지 않음
    Header.tsx
    Footer.tsx
  _lib/                 # 내부 유틸리티
    utils.ts
```

### Parallel Routes - `@slot`
- 동일 레이아웃에서 여러 페이지를 동시에 렌더링한다

```
app/
  layout.tsx            # children + @analytics + @team 동시 렌더링
  @analytics/
    page.tsx
  @team/
    page.tsx
```

### Intercepting Routes - `(.)`, `(..)`, `(...)`
- 현재 레이아웃 내에서 다른 라우트를 가로채서 표시한다

```
app/
  feed/
    page.tsx
    (..)photo/[id]/     # /photo/:id를 모달로 가로챔
      page.tsx
  photo/[id]/
    page.tsx            # 직접 접근 시 전체 페이지
```

---

## 9. Image/Font 최적화

### next/image
- 모든 이미지는 `next/image`를 사용한다
- `width`, `height`를 명시하거나 `fill` 속성을 사용한다

```typescript
import Image from 'next/image';

// 크기 지정
<Image src="/hero.png" alt="히어로 이미지" width={800} height={400} />

// fill 모드 (부모 기준 채움)
<div className="relative h-64 w-full">
  <Image src="/banner.png" alt="배너" fill className="object-cover" />
</div>
```

### next/font
- Google Fonts는 `next/font/google`을 사용한다
- 커스텀 폰트는 `next/font/local`을 사용한다

```typescript
// app/layout.tsx
import { Inter } from 'next/font/google';

const inter = Inter({ subsets: ['latin'] });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko" className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

---

## 10. 네이밍 컨벤션

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

## 11. 금지 사항

- Client Component에서 무거운 데이터 페칭 로직 작성 금지
- 불필요한 `'use client'` 선언 금지 - 서버에서 가능하면 서버에서 처리
- Pages Router 패턴 사용 금지 (`getServerSideProps`, `getStaticProps`, `_app.tsx`, `_document.tsx`)
- `page.tsx`에 `'use client'` 직접 선언 금지 - 클라이언트 로직은 하위 컴포넌트로 분리
- Server Component에서 `useState`, `useEffect` 등 클라이언트 훅 사용 금지
- `<img>` 태그 직접 사용 금지 - `next/image` 사용
- 외부 폰트를 `<link>` 태그로 로드 금지 - `next/font` 사용
- `router.push()`를 Server Component에서 사용 금지 - `redirect()` 사용
- API Route에서 비즈니스 로직 직접 구현 금지 - 별도 서비스 레이어로 분리