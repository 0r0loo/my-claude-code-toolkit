# 자주 쓰는 패턴 & 컴포넌트 추출

## 자주 쓰는 패턴

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

## 컴포넌트 추출

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
