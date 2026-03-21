---
name: e2e
description: Playwright E2E 테스트를 작성하거나 e2e-tester 에이전트가 동작할 때 호출. 사용자 흐름 테스트, 크로스 브라우저, 접근성 검증 시 참조.
user-invocable: true
lastUpdated: 2026-03-21
---

# E2E Skill - Playwright E2E 테스트 규칙

Playwright 기반 E2E 테스트 규칙을 정의한다.
단위/통합 테스트는 `../TDD/SKILL.md`를 참고한다.

> 코드 예시: `references/patterns.md` 참조

---

## 1. E2E 테스트 철학

### 테스트 대상 (DO)
- 핵심 사용자 여정 (로그인, 가입, 결제, 핵심 CRUD)
- 복잡한 인터랙션 (드래그&드롭, 멀티스텝 폼)
- 크로스 브라우저 호환성
- 인증/인가 흐름

### 테스트 제외 (DON'T)
- 단위 로직 (유틸 함수, 계산) → 단위 테스트로
- API 계약 검증 → 통합 테스트로
- 엣지 케이스 전부 → E2E는 critical path만
- 내부 구현 세부사항

### 테스트 피라미드
```
    /  E2E  \     ← 적게, critical path만
   / 통합테스트 \   ← 컴포넌트 인터랙션
  /  단위테스트   \  ← 많이, 빠르게
```

---

## 2. 프로젝트 설정 탐색

E2E 테스트 작성 전 반드시 확인:
- `playwright.config.ts` — baseURL, timeout, 브라우저 설정
- 기존 E2E 테스트 파일 — 패턴, 구조, 네이밍 확인
- 인증 방식 — storageState 사용 여부
- `package.json` — playwright 버전, 스크립트

---

## 3. Page Object Model (POM)

페이지 로직을 클래스로 캡슐화한다. 테스트에서 직접 셀렉터를 사용하지 않는다.

### 규칙
- 페이지당 하나의 Page Object 클래스
- Locator는 `readonly`로 생성자에서 초기화
- 행위를 메서드로 제공 (goto, login, fillForm 등)
- 테스트에서는 Page Object 메서드만 호출

---

## 4. 셀렉터 우선순위

| 우선순위 | 셀렉터 | 예시 |
|---------|--------|------|
| 1 (권장) | `data-testid` | `page.getByTestId('submit-btn')` |
| 2 | Role | `page.getByRole('button', { name: '제출' })` |
| 3 | Text | `page.getByText('로그인')` |
| 4 | Label | `page.getByLabel('이메일')` |
| 5 (지양) | CSS/XPath | `page.locator('.btn-primary')` |

- CSS 클래스, nth-child 셀렉터 사용 금지 (깨지기 쉬움)
- `data-testid`는 테스트 전용 — 프로덕션 빌드에서 제거 가능

---

## 5. Waiting 전략

- `waitForLoadState('networkidle')` — 네트워크 안정화 대기
- `waitForURL('/dashboard')` — URL 변경 대기
- `expect(element).toBeVisible()` — 요소 표시 대기
- `waitForResponse(url)` — API 응답 대기

> **`waitForTimeout()` 사용 금지** — 고정 대기는 flaky test의 주범

---

## 6. 인증 상태 관리

### storageState 패턴
- 글로벌 setup에서 로그인 → storageState 파일로 저장
- 각 테스트에서 storageState를 재사용 → 매번 로그인 불필요
- 인증이 필요 없는 테스트는 별도 프로젝트로 분리

---

## 7. 네트워크 모킹

- `page.route()`로 외부 API 인터셉트
- 결제(Stripe 등), 이메일, SMS 같은 외부 서비스는 반드시 모킹
- 내부 API는 실제 호출 유지 (E2E의 목적)

---

## 8. 설정 권장값

| 항목 | 권장값 | 이유 |
|------|--------|------|
| `timeout` | 30초 | CI 환경 고려 |
| `retries` | CI: 2, 로컬: 0 | flaky 방어 |
| `fullyParallel` | true | 실행 속도 |
| `screenshot` | only-on-failure | 디버깅용 |
| `video` | retain-on-failure | 실패 재현용 |

---

## 9. 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| 테스트 디렉토리 | `e2e/` 또는 `tests/e2e/` | 프로젝트 컨벤션 따름 |
| 테스트 파일 | `기능명.spec.ts` | `auth.spec.ts`, `checkout.spec.ts` |
| Page Object | `기능명Page.ts` | `LoginPage.ts`, `DashboardPage.ts` |
| Fixture | `기능명.fixture.ts` | `auth.fixture.ts` |

---

## ⚠️ AI 함정 목록

> AI가 자주 틀리는 실수. 새로운 실패 발견 시 한 줄씩 추가한다.

- `waitForTimeout(3000)` 하드코딩 → flaky test. `waitForURL`/`waitForResponse`/`toBeVisible` 사용
- 테스트 간 데이터 의존성 → 테스트 순서가 바뀌면 실패. 각 테스트가 독립적이어야 함
- CSS 클래스로 셀렉터 작성 → 스타일 변경 시 테스트 깨짐. `data-testid` 사용
- 모든 시나리오를 E2E로 커버하려 함 → critical path만. 나머지는 단위/통합 테스트
- storageState 없이 매 테스트마다 로그인 → 실행 시간 폭증
- 외부 API(결제, 이메일) 모킹 안 함 → 실제 과금 발생 또는 rate limit

---

## 10. 체크리스트

- [ ] critical path만 E2E로 커버하는가?
- [ ] Page Object Model을 사용하는가?
- [ ] 고정 timeout(`waitForTimeout`) 없이 동적 대기를 사용하는가?
- [ ] 셀렉터가 `data-testid` 또는 role 기반인가?
- [ ] 테스트 간 독립적인가? (순서 무관)
- [ ] 외부 서비스가 모킹되어 있는가?
- [ ] 테스트 데이터 cleanup이 되는가?
