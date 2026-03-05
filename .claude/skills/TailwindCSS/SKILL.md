---
name: tailwindcss
description: Tailwind CSS 유틸리티 패턴 가이드. 스타일링, 반응형 디자인, 다크 모드, CVA 패턴, cn() 유틸리티 등 Tailwind 기반 스타일 작업 시 참조한다.
---

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
- 권장 순서: 레이아웃 → 크기 → 간격 → 타이포그래피 → 색상 → 효과
- **클래스가 길어지면 관심사별로 줄바꿈하여 가독성을 높인다**

```typescript
// Bad - 한 줄로 길게 나열 (화면 벗어남, 어떤 CSS가 있는지 파악 어려움)
<button className="flex items-center justify-center w-full h-10 px-4 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700">

// Good - 관심사별 줄바꿈
<button
  className={cn(
    'flex items-center justify-center', // 레이아웃
    'w-full h-10 px-4',                 // 크기/간격
    'text-sm font-medium text-white',   // 타이포그래피
    'bg-blue-600 rounded-lg',           // 배경/모양
    'hover:bg-blue-700',                // 상태
  )}
>
  버튼
</button>
```

---

## 2. cn() 유틸리티

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

type ButtonProps = {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  children: React.ReactNode;
};

export function Button({ variant = 'primary', size = 'md', className, children }: ButtonProps) {
  return (
    <button
      className={cn(
        // 기본 스타일
        'inline-flex items-center justify-center',
        'rounded-lg font-medium transition-colors',
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

### CVA (Class Variance Authority)
- variant가 있는 컴포넌트는 `cva`로 스타일을 정의한다
- `cn()` + `cva` 조합으로 variant 관리와 클래스 오버라이드를 동시에 처리한다

```typescript
// components/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  // 기본 스타일
  [
    'inline-flex items-center justify-center', // 레이아웃
    'rounded-lg font-medium',                  // 모양/타이포
    'transition-colors',                       // 효과
    'disabled:pointer-events-none disabled:opacity-50', // 상태
  ],
  {
    variants: {
      variant: {
        primary: 'bg-blue-600 text-white hover:bg-blue-700',
        secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200',
        danger: 'bg-red-600 text-white hover:bg-red-700',
        ghost: 'hover:bg-gray-100',
        link: 'text-blue-600 underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-sm',
        lg: 'h-12 px-6 text-base',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> &
  VariantProps<typeof buttonVariants>;

export function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button className={cn(buttonVariants({ variant, size }), className)} {...props} />
  );
}
```

### CVA 사용 원칙
- variant가 2개 이상이면 `cva`를 사용한다 (1개면 `cn()`으로 충분)
- `VariantProps<typeof xxxVariants>`로 Props 타입을 자동 추론한다
- `defaultVariants`로 기본값을 선언한다
- 컴포넌트 외부에서 `className`으로 오버라이드할 수 있게 `cn()`을 함께 사용한다

---

## 3. 금지 사항

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
- `transition-all` 사용 금지 - 변경되는 속성만 명시한다 (`transition-colors`, `transition-opacity` 등)
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

---

## 심화 참조

- `references/responsive-dark.md` - 반응형 디자인, 다크 모드, 커스텀 설정 (@theme, 브레이크포인트, dark: prefix)
- `references/patterns-components.md` - 자주 쓰는 레이아웃/타이포그래피 패턴, 컴포넌트 추출 규칙
- `references/transitions.md` - 트랜지션 & 모션 (transition 속성 명시, prefers-reduced-motion, color-scheme)
