# Middleware & Server Actions

## Middleware

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

## Server Actions

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
