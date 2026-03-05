# 데이터 페칭 & Route Handlers

## 데이터 페칭

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

## Route Handlers

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
