# /review — 변경사항 코드 리뷰

현재 변경사항을 리뷰한다. 코드 품질 + 구조적 위험 패턴을 함께 검사한다.

## 절차

### 1. 변경 범위 파악
```bash
git diff --stat
git diff --name-only
```

### 2. 구조적 위험 패턴 감지

변경된 코드에서 다음 패턴을 **자동 탐지**한다. 발견 시 즉시 플래그:

| 패턴 | 위험도 | 예시 |
|------|--------|------|
| **하드코딩 시크릿** | 🔴 Critical | API 키, 패스워드, 토큰이 코드에 직접 포함 |
| **SQL 인젝션 가능** | 🔴 Critical | 문자열 보간으로 SQL 쿼리 조립 (`${userInput}`) |
| **XSS 가능** | 🔴 Critical | `dangerouslySetInnerHTML`, 사용자 입력 직접 렌더링 |
| **인증/인가 누락** | 🔴 Critical | 새 API 엔드포인트에 Guard/미들웨어 없음 |
| **무한 루프/재귀** | 🟡 High | 종료 조건 없는 루프, 깊이 제한 없는 재귀 |
| **에러 삼킴** | 🟡 High | 빈 catch 블록, 에러 무시 |
| **N+1 쿼리** | 🟡 High | 루프 안에서 DB 호출 |
| **미사용 코드** | 🟠 Medium | 추가됐지만 어디서도 호출되지 않는 함수/변수 |
| **타입 우회** | 🟠 Medium | `any`, `as unknown as`, `@ts-ignore` |
| **콘솔/디버그 잔류** | 🟠 Medium | `console.log`, `debugger`, `TODO` 코멘트 |

### 3. 코드 품질 체크
- Curation 스킬의 체크리스트를 적용
- Coding SKILL.md의 규칙을 적용

### 4. 결과 보고

```
## /review 결과 — [변경 파일 N개]

### 🔴 Critical (반드시 수정)
- [파일:라인] 설명

### 🟡 High (수정 권장)
- [파일:라인] 설명

### 🟠 Medium (개선 제안)
- [파일:라인] 설명

### ✅ Good Practices
- [잘 된 점]

판정: PASS / NEEDS_FIX
```

## 규칙
- Critical 항목이 1개라도 있으면 NEEDS_FIX
- 코드를 수정하지 않는다 (보고만). 수정은 사용자 판단.
- 변경된 파일만 리뷰한다 (전체 코드베이스 아님)
