# 트랜지션 & 모션

### transition 속성 명시
- `transition-all` 사용을 금지한다 - 변경되는 속성만 명시한다
- 불필요한 속성까지 트랜지션되면 성능이 저하된다

```typescript
// Bad - 모든 속성에 트랜지션
<button className="transition-all">

// Good - 필요한 속성만
<button className="transition-colors">
<div className="transition-[transform,opacity]">
```

### prefers-reduced-motion 존중
- 애니메이션/트랜지션이 있는 요소에는 `motion-reduce:` 변형을 고려한다

```typescript
// 모션 감소 선호 시 애니메이션 비활성화
<div className="animate-bounce motion-reduce:animate-none">
<div className="transition-transform motion-reduce:transition-none">
```

### 다크 모드 color-scheme
- 다크 모드 지원 시 `color-scheme: dark`를 설정하여 네이티브 UI(스크롤바, 입력 필드 등)도 다크 테마에 맞춘다

```css
/* app.css */
.dark {
  color-scheme: dark;
}
```
