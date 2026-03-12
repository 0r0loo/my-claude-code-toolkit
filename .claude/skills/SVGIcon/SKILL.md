---
name: svg-icon
description: SVG 아이콘 생성 가이드. 디자인 시스템용 아이콘을 일관된 규칙으로 생성하며, React 컴포넌트 래핑 패턴을 제공한다.
lastUpdated: 2025-03-01
---

# SVG Icon Skill

디자인 시스템용 SVG 아이콘 생성 규칙. Stroke 기반 24x24 아이콘을 일관되게 만든다.

---

## 1. 기본 규격

| 속성 | 값 |
|------|-----|
| viewBox | `0 0 24 24` |
| 기본 크기 | 24x24px |
| stroke-width | `2` (기본), `1.5` (세밀한 아이콘) |
| stroke-linecap | `round` |
| stroke-linejoin | `round` |
| fill | `none` |
| stroke 색상 | `currentColor` |

---

## 2. SVG 작성 규칙

### 필수 속성

```svg
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="24"
  height="24"
  viewBox="0 0 24 24"
  fill="none"
  stroke="currentColor"
  stroke-width="2"
  stroke-linecap="round"
  stroke-linejoin="round"
>
  <!-- paths here -->
</svg>
```

### 경로 작성

```svg
<!-- Bad - 하드코딩된 색상 -->
<path stroke="#333333" d="M12 5v14" />

<!-- Bad - 불필요한 그룹/트랜스폼 -->
<g transform="translate(2, 2)">
  <path d="M10 3v14" />
</g>

<!-- Good - currentColor, 직접 좌표 -->
<path d="M12 5v14" />
```

### 금지 사항
- 하드코딩된 색상 (`#000`, `rgb()`, `hsl()`) - `currentColor`로 상속
- 불필요한 `<g>` 래핑 - 경로를 직접 배치
- `transform` 으로 위치 조정 - 좌표를 직접 계산
- `style` 어트리뷰트 - SVG 속성으로 지정
- 소수점 3자리 이상 - 최대 2자리 (`12.45` OK, `12.456` X)
- `id`, `class` 어트리뷰트 - React에서 충돌 위험

### 디자인 원칙
- **2px 그리드 정렬**: 주요 점은 짝수 좌표에 배치 (선명도)
- **2px 패딩**: 24x24 중 실제 아이콘은 20x20 영역 (2~22 범위)
- **단순함 우선**: 최소한의 path로 의도를 전달
- **시각적 균형**: 원형 아이콘은 살짝 크게, 삼각형은 살짝 작게 (광학 보정)

---

## 3. React 컴포넌트 패턴

### 아이콘 컴포넌트 타입

```typescript
type IconProps = {
  size?: number;
  className?: string;
} & React.SVGAttributes<SVGElement>;
```

### 개별 아이콘 컴포넌트

```tsx
function ChevronRight({ size = 24, className, ...props }: IconProps) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      {...props}
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}
```

### 아이콘 팩토리 (아이콘이 많을 때)

```tsx
function createIcon(name: string, paths: React.ReactNode) {
  const Icon = ({ size = 24, className, ...props }: IconProps) => (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
      {...props}
    >
      {paths}
    </svg>
  );
  Icon.displayName = name;
  return Icon;
}

// 사용
const Check = createIcon("Check", <path d="M20 6 9 17l-5-5" />);
const X = createIcon("X", (
  <>
    <path d="M18 6 6 18" />
    <path d="m6 6 12 12" />
  </>
));
const Plus = createIcon("Plus", (
  <>
    <path d="M5 12h14" />
    <path d="M12 5v14" />
  </>
));
```

---

## 4. 접근성

```tsx
<!-- 장식용 아이콘 (텍스트와 함께 사용) -->
<ChevronRight aria-hidden="true" />
<span>다음</span>

<!-- 단독 사용 아이콘 (의미 전달 필요) -->
<button aria-label="닫기">
  <X />
</button>

<!-- 상태 전달 아이콘 -->
<CheckCircle role="img" aria-label="완료" />
```

### 규칙
- 텍스트와 함께 쓰면 `aria-hidden="true"`
- 단독 사용 시 부모에 `aria-label` 또는 아이콘에 `role="img"` + `aria-label`
- 팩토리의 기본값은 `aria-hidden="true"` (대부분 텍스트와 함께 사용)

---

## 5. 파일 구조

```
src/
  components/
    icons/
      index.ts          # 모든 아이콘 re-export
      types.ts          # IconProps 타입
      create-icon.tsx   # 팩토리 함수 (선택)
      ChevronRight.tsx  # 개별 아이콘
      Check.tsx
      X.tsx
```

### 네이밍 규칙
- 파일명: PascalCase (`ChevronRight.tsx`)
- 컴포넌트명: PascalCase (`ChevronRight`)
- 방향이 있으면 접미사: `ChevronRight`, `ChevronDown`, `ArrowUp`
- 상태 변형: `Eye`, `EyeOff` / `Bell`, `BellOff`

---

## 6. 자주 쓰는 아이콘 경로 레퍼런스

### 네비게이션
```
chevron-right:  m9 18 6-6-6-6
chevron-left:   m15 18-6-6 6-6
chevron-down:   m6 9 6 6 6-6
chevron-up:     m6 15 6-6 6 6
arrow-right:    M5 12h14  +  m7-7 7 7-7
arrow-left:     M19 12H5  +  m7-7-7 7 7
```

### 액션
```
check:          M20 6 9 17l-5-5
x (close):      M18 6 6 18  +  m6 6 12 12
plus:           M5 12h14  +  M12 5v14
minus:          M5 12h14
search:         circle cx=11 cy=11 r=8  +  m21 21-4.3-4.3
```

### 일반
```
menu:           M4 12h16  +  M4 6h16  +  M4 18h16
home:           m3 9 9-7 9 7  +  M9 22V12h6v10
user:           circle cx=12 cy=8 r=4  +  path M20 21a8 8 0 0 0-16 0
settings:       circle cx=12 cy=12 r=3  +  적절한 gear path
```

---

## 7. 체크리스트

아이콘 생성/리뷰 시 확인:
- [ ] viewBox가 `0 0 24 24`인가?
- [ ] 색상이 모두 `currentColor` 상속인가?
- [ ] stroke-width가 일관적인가? (2 또는 1.5)
- [ ] 불필요한 `<g>`, `transform`, `style`이 없는가?
- [ ] 좌표가 2px 그리드에 정렬되어 있는가?
- [ ] 소수점이 2자리 이하인가?
- [ ] React에서 `aria-hidden` 또는 `aria-label`이 적절한가?
- [ ] 기존 아이콘과 시각적 무게감(weight)이 일관적인가?
