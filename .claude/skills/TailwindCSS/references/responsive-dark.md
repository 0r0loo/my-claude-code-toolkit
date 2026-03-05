# 반응형 디자인, 다크 모드, 커스텀 설정

## 반응형 디자인

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

## 다크 모드

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

## 커스텀 설정

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
