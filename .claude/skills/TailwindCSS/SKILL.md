# TailwindCSS Skill - Tailwind CSS 규칙

Tailwind CSS를 사용하는 프로젝트에 적용되는 스타일링 규칙이다.
React 규칙은 `../React/SKILL.md`, 공통 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. 유틸리티 클래스 사용 원칙

### 인라인 스타일 대신 유틸리티 클래스
- `style={{}}` 대신 Tailwind 유틸리티 클래스를 사용한다
- CSS 파일을 별도로 작성하지 않는다 (특수한 경우 제외)

```typescript
// Bad - 인라인 스타일
<div style={{ display: 'flex', gap: '8px', padding: '16px' }}>

// Good - 유틸리티 클래스
<div className="flex gap-2 p-4">
```

### 클래스 조합
- 관련 있는 클래스를 논리적 그룹으로 정렬한다
- 권장 순서: 레이아웃 -> 크기 -> 간격 -> 타이포그래피 -> 색상 -> 효과

```typescript
// Good - 논리적 순서로 정렬
<button className="flex items-center justify-center w-full h-10 px-4 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700">
  버튼
</button>
```

---

## 2. 반응형 디자인

### 브레이크포인트
| 접두사 | 최소 너비 | 용도 |
|--------|-----------|------|
| (없음) | 0px | 모바일 기본 |
| `sm:` | 640px | 소형 태블릿 |
| `md:` | 768px | 태블릿 |
| `lg:` | 1024px | 데스크톱 |
| `xl:` | 1280px | 대형 데스크톱 |
| `2xl:` | 1536px | 초대형 데스크톱 |

### Mobile-First 원칙
- 모바일 스타일을 기본으로 작성하고, 큰 화면에 대해 재정의한다

```typescript
// Good - Mobile-First
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  {items.map((item) => (
    <Card key={item.id} data={item} />
  ))}
</div>

// Good - 반응형 타이포그래피
<h1 className="text-2xl font-bold md:text-3xl lg:text-4xl">
  제목
</h1>
```

---

## 3. 다크 모드

### dark: prefix 사용
- `dark:` 접두사로 다크 모드 스타일을 정의한다
- v4에서는 기본적으로 `prefers-color-scheme` 미디어 쿼리로 동작한다
- 수동 토글(class 전략)이 필요하면 CSS에서 `@custom-variant`를 설정한다

```css
/* app.css - 수동 다크 모드 토글 시 */
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

```typescript
// 컴포넌트에서 사용
<div className="bg-white text-gray-900 dark:bg-gray-900 dark:text-white">
  <p className="text-gray-600 dark:text-gray-300">
    라이트/다크 모드를 지원하는 텍스트
  </p>
</div>
```

### 시맨틱 색상 활용
- 반복되는 라이트/다크 색상 조합은 `@theme`과 CSS 변수로 추출한다

```css
/* app.css */
@import "tailwindcss";

@theme {
  --color-background: #ffffff;
  --color-foreground: #0a0a0a;
}

.dark {
  --color-background: #0a0a0a;
  --color-foreground: #fafafa;
}
```

---

## 4. 커스텀 설정

### @theme 디렉티브 사용
- CSS 파일에서 `@theme` 디렉티브로 디자인 토큰을 정의한다
- v4에서는 `tailwind.config.ts`가 불필요하다. 모든 커스텀 설정은 CSS의 `@theme`에서 정의한다
- v4는 콘텐츠 파일을 자동 감지하므로 `content` 배열 설정이 불필요하다

```css
/* app.css */
@import "tailwindcss";

@theme {
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-danger: #ef4444;

  --spacing-18: 4.5rem;
  --spacing-88: 22rem;

  --font-sans: 'Inter', sans-serif;
}
```

---

## 5. 자주 쓰는 패턴

### Flexbox 레이아웃
```typescript
// 가로 정렬 (중앙)
<div className="flex items-center justify-center">

// 가로 정렬 (양쪽 분산)
<div className="flex items-center justify-between">

// 세로 정렬
<div className="flex flex-col gap-4">

// 자식 요소 간격
<div className="flex gap-2">
```

### Grid 레이아웃
```typescript
// 반응형 그리드
<div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">

// 고정 비율 그리드
<div className="grid grid-cols-[1fr_2fr] gap-4">

// 사이드바 레이아웃
<div className="grid grid-cols-[240px_1fr] gap-8">
```

### Spacing 패턴
```typescript
// 섹션 간격
<section className="py-12 md:py-16 lg:py-20">

// 컨테이너
<div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">

// 카드
<div className="rounded-lg border p-6 shadow-sm">
```

### Typography 패턴
```typescript
// 텍스트 말줄임
<p className="truncate">긴 텍스트...</p>

// 여러 줄 말줄임
<p className="line-clamp-3">긴 텍스트...</p>

// 반응형 텍스트
<h1 className="text-2xl font-bold tracking-tight md:text-4xl">
```

---

## 6. cn() 유틸리티

### clsx + tailwind-merge 조합
- 조건부 클래스 결합에는 `cn()` 유틸리티를 사용한다
- `clsx`로 조건부 결합하고, `tailwind-merge`로 충돌을 해결한다

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### 사용 예시
```typescript
import { cn } from '@/lib/utils';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  children: React.ReactNode;
}

export function Button({ variant = 'primary', size = 'md', className, children }: ButtonProps) {
  return (
    <button
      className={cn(
        // 기본 스타일
        'inline-flex items-center justify-center rounded-lg font-medium transition-colors',
        // variant
        {
          'bg-blue-600 text-white hover:bg-blue-700': variant === 'primary',
          'bg-gray-100 text-gray-900 hover:bg-gray-200': variant === 'secondary',
          'bg-red-600 text-white hover:bg-red-700': variant === 'danger',
        },
        // size
        {
          'h-8 px-3 text-sm': size === 'sm',
          'h-10 px-4 text-sm': size === 'md',
          'h-12 px-6 text-base': size === 'lg',
        },
        // 외부에서 전달된 클래스 (오버라이드 가능)
        className,
      )}
    >
      {children}
    </button>
  );
}
```

---

## 7. 컴포넌트 추출

### 반복 클래스 처리
- 동일한 클래스 조합이 3회 이상 반복되면 컴포넌트로 추출한다
- `@apply`보다 컴포넌트 추출을 우선한다

```typescript
// Bad - 동일한 클래스 반복
<button className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700">저장</button>
<button className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700">확인</button>
<button className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700">전송</button>

// Good - 컴포넌트로 추출
<Button>저장</Button>
<Button>확인</Button>
<Button>전송</Button>
```

### @apply 사용 (제한적 허용)
- 컴포넌트 추출이 어려운 경우에만 `@apply`를 사용한다
- 주로 base layer의 글로벌 스타일에서 사용한다
- v4에서도 `@apply`는 지원되지만, 여전히 컴포넌트 추출을 우선한다

```css
/* 허용 - 글로벌 기본 스타일 */
@layer base {
  body {
    @apply bg-background text-foreground;
  }
}

/* 지양 - 컴포넌트 스타일을 @apply로 작성 */
.btn-primary {
  @apply rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700;
}
```

---

## 8. 금지 사항

- 인라인 `style={{}}` 사용 금지 - Tailwind 유틸리티 클래스를 사용한다
- 임의값(arbitrary values) 남용 금지 - `w-[137px]` 같은 임의값은 최소화한다
  - 디자인 시스템의 토큰에 맞는 값을 사용한다
  - 불가피한 경우에만 임의값을 사용한다
- `@apply` 남용 금지 - 컴포넌트 추출을 우선한다
- `!important` 사용 금지 - Tailwind의 `!` 접두사(`!p-4`)도 최소화한다
- 커스텀 CSS 파일 남발 금지 - `globals.css` 외에 CSS 파일을 추가하지 않는다
- Tailwind 기본 테마 토큰 삭제 금지 - `@theme`에서 필요한 토큰만 추가한다
- 사용하지 않는 커스텀 색상/간격 정의 금지 - 실제 사용하는 값만 정의한다
- `tailwind.config.ts` 사용 금지 - v4에서는 CSS `@theme`으로 설정한다
- 클래스 문자열 동적 생성 금지 - Tailwind의 JIT가 감지하지 못한다

```typescript
// Bad - 동적 클래스 생성 (JIT가 감지 불가)
const color = 'blue';
<div className={`bg-${color}-500`}>

// Good - 완전한 클래스명 사용
const colorClasses = {
  blue: 'bg-blue-500',
  red: 'bg-red-500',
  green: 'bg-green-500',
} as const;

<div className={colorClasses[color]}>
```