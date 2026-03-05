# Metadata, 디렉토리 구조 패턴 & Image/Font 최적화

## Metadata

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

## 디렉토리 구조 패턴

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

## Image/Font 최적화

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
