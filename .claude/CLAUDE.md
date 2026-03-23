# Global Claude Code Rules

이 파일은 모든 프로젝트에 적용되는 글로벌 규칙이다.
Claude는 작업 시작 전 반드시 이 규칙을 따라야 한다.

---

## 0. 가치관

이 4가지 원칙은 모든 커맨드와 작업에 스며든다. 명시적 체크리스트가 아니라 **판단 기준**이다.

### 문제 먼저 (Problem First)

코드를 쓰기 전에 문제를 이해한다. "뭘 만들지"보다 "왜 필요한지"가 먼저다.

- 요구사항이 불명확하면 **추측하지 않고 질문한다**
- "로그인 페이지 만들어줘" → "소셜? 이메일? 비회원 접근 범위는?" 먼저 확인
- 문제가 명확하면 바로 진행. 불필요한 질문으로 속도를 늦추지 않는다

> 💡 문제 정의가 어려우면 → `/office-hours`로 구조화된 브레인스토밍
> 💡 버그의 원인이 불명확하면 → `/investigate`로 근본 원인부터 확정 (수정 전 조사 필수)
> 💡 기존 코드를 이해 못 하겠으면 → `/explain`으로 먼저 파악

### 가장 단순한 버전 (Simplest First)

완성형을 상상하지 말고, **지금 동작하는 최소 버전**부터 시작한다.

- "게시판 만들어줘" → 목록 조회부터. CRUD 전체를 한 번에 하지 않는다
- 추상화는 반복이 증명된 후에. 3번 반복되기 전엔 복붙이 낫다
- "나중에 필요할 수도"는 지금 만들 이유가 아니다

> 💡 기능 구현은 → `/feature`로 최소 단위씩 점진적으로
> 💡 구현 후 과도한 추상화가 없는지 → `/simplify`로 자가 점검
> 💡 코드 구조가 복잡해졌다면 → `/refactor`로 동작 유지하면서 정리

### 증거 기반 (Evidence-Based)

"좋을 것 같다"가 아니라 **코드가 말하는 것**을 따른다.

- 리뷰에서 "이건 좀 별로"가 아니라 "N+1 쿼리가 발생한다" (패턴 근거)
- 리팩터링에서 "깔끔하게"가 아니라 "이 로직이 3곳에서 반복된다" (중복 근거)
- 성능에서 "느릴 것 같다"가 아니라 "응답 시간이 baseline 대비 2배" (측정 근거)

> 💡 코드 품질 근거가 필요하면 → `/review`로 10가지 위험 패턴 자동 감지
> 💡 배포 후 성능 변화 측정은 → `/canary`로 before/after baseline 비교
> 💡 작업 트렌드와 리스크 데이터는 → `/retro`로 히스토리 기반 분석
> 💡 UI 품질을 객관적으로 점검하려면 → `/design-review`로 5차원 점수화

### 되돌릴 수 있는가 (Reversibility)

모든 변경에 **"이거 되돌리려면 어떻게 해야 하지?"**를 한 번 생각한다.

- 커밋은 원자적으로 — 하나의 커밋이 하나의 의미 있는 단위
- 마이그레이션은 롤백 계획과 함께 — "돌아갈 수 없음"이면 명시적 경고
- 파괴적 명령(`rm -rf`, `DROP TABLE`, `--force`)은 실행 전 한 번 멈춤

> 💡 위험한 명령을 실행해야 하면 → `/careful`로 리스크 분석 먼저
> 💡 DB/의존성 전환이 필요하면 → `/migrate`로 롤백 계획과 함께 단계별 실행
> 💡 편집 범위를 제한해서 실수를 방지하려면 → `/freeze`로 디렉토리 잠금
> 💡 최대 안전이 필요한 환경이면 → `/guard`로 careful + freeze 동시 활성화

---

## 1. 작업 복잡도 티어

작업 시작 전 반드시 티어를 판단하고, 티어에 맞는 워크플로우를 따른다.

| 티어 | 기준 | 예시 |
|------|------|------|
| **S (trivial)** | 단순 수정, 영향도 낮음 | 오타 수정, config 변경, README 업데이트, 일괄 rename |
| **M (moderate)** | 명확한 기능, 단일 레이어 | 단일 컴포넌트 추가, API 엔드포인트 1개, 유틸 함수 추가 |
| **L (complex)** | 설계 필요, 레이어 횡단 | 새 도메인 모듈, 핵심 엔티티 변경, FE+BE 동시 변경 |

### 티어 판단 Decision Tree

다음 질문을 순서대로 확인한다. **하나라도 Yes면 해당 티어 이상**이다.

```
Q1. 핵심 도메인 로직이 바뀌는가? (엔티티 구조, 비즈니스 규칙 변경)
    → Yes: L
Q2. 새로운 아키텍처/패턴 도입이 필요한가? (새 모듈, 새 라이브러리, 설계 결정)
    → Yes: L
Q3. FE + BE 동시 변경이 필요한가?
    → Yes: 영향도에 따라 M 또는 L (핵심 도메인이면 L, 단순 연동이면 M)
Q4. 단일 레이어에서 명확한 기능 추가/수정인가?
    → Yes: M
Q5. 위 모두 No — 단순 수정인가?
    → Yes: S
```

> **핵심**: 파일 수보다 **변경 영향도**를 우선한다. 20파일 일괄 rename은 S, 핵심 도메인 엔티티 1개 변경은 L이다.

### 탐색 및 패턴 파악

- `.claude/PROJECT_MAP.md`가 있으면 탐색 전에 반드시 먼저 Read하라
- 단순 구조 확인은 PROJECT_MAP.md로 충분. 코드 탐색이 필요할 때만 built-in `Explore` 에이전트를 사용
- 탐색 후 위 Decision Tree로 티어를 판단한다
- 갱신: `.claude/scripts/generate-project-map.sh` 실행

### 에이전트 위임 대상
- **탐색** → built-in `Explore` 에이전트 (haiku, read-only) — 코드 탐색, 기존 패턴 파악
- **구현** → `implementer-fe` 또는 `implementer-be` 에이전트 (구현만)
- **테스트** → `tester` 에이전트 (단위/통합 테스트, 명시적 호출 시에만)
- **E2E 테스트** → `e2e-tester` 에이전트 (Playwright, 명시적 호출 시에만)
- **코드 리뷰** → `code-reviewer` 에이전트 (opus)
- **Git 작업** → `git-manager` 에이전트 (sonnet)

> 스킬 매칭은 Skills 2.0 frontmatter의 description 기반 자동 매칭에 위임한다.

---

## 2. 점진적 구현 원칙

**"한 번에 하나, 완전하게"** — 범위를 넓게 잡고 80%로 끝내지 말고, 좁게 잡고 100%로 완성한다.

### 작업 분해
- 요구사항을 **가장 작은 배포 가능 단위(smallest deliverable unit)**로 쪼갠다
- 한 단위를 **완전히 끝낸 후** 다음 단위로 이동한다
- 에이전트 1회 호출 당 **파일 3개 이하**를 원칙으로 한다

### 예시: "게시판 만들어줘"
```
Step 1: Entity + API (목록 조회만) → 확인
Step 2: 목록 UI → 확인
Step 3: 생성 API + UI → 확인
Step 4: 수정/삭제 → 확인
```

### 금지
- 한 번의 계획에 기능 전체를 담아 한꺼번에 구현하는 것
- 에이전트에 5개 이상 파일 동시 생성/수정을 위임하는 것

---

## 2-1. 완료 기준 (Definition of Done)

각 작업 단위는 다음 조건을 **모두 만족**해야 "완료"로 판단한다.
에이전트는 구현 후 이 체크리스트를 자체 검증한다.

### 공통 DoD
- [ ] 타입 에러 없음 (`tsc --noEmit` 통과)
- [ ] 미사용 import/변수 없음
- [ ] 기존 테스트가 깨지지 않음
- [ ] 기존 프로젝트 패턴과 일관성 유지

> FE/BE별 추가 DoD는 프로젝트 루트 `CLAUDE.md`에서 오버라이드한다.

---

## 3. Task Header (의사결정 가시화)

> 상세 템플릿과 작성 규칙: `.claude/skills/Planning/SKILL.md` 참조

모든 티어에서 작업 시작 시 Task Header를 **코드블록 안에** 출력한다.
- **S**: 📋 ⚡ 📁
- **M**: 📋 ⚡ 📚 🔄 📁
- **L**: 📋 ⚡ 📚 🔄 📁 📌Plan (Step별 `○` → `▶ ⏳` → `✔` 갱신)

---

## 4. 티어별 워크플로우

### S 티어 (trivial)
Main Agent가 직접 처리한다. 서브에이전트 위임 불필요.
1. **Task Header 출력**
2. 파일 읽기 → 직접 수정 → 완료
3. 필요 시 `git-manager`로 커밋

### M 티어 (moderate)
TDD/Review를 생략하고 핵심 단계만 수행한다.
1. **Task Header 출력** (초기 티어 판단)
2. **탐색**: built-in `Explore`로 관련 코드 탐색 → 티어 확정 + Task Header의 📚, 🔄 결정
3. **계획 제시**: 아래 내용을 사용자에게 보여준다
   - 불명확한 부분이 있으면 **명확화 질문을 먼저** 포함한다
   - 참조할 스킬 목록 (📚에 표시)
   - 개선 방향, 변경 파일, 접근 방식 요약
4. **승인 대기**: 사용자가 승인(ok, ㄱㄱ 등)하면 구현 시작. **승인 전까지 구현 금지**
5. **Implementation**: `implementer` 에이전트에 구현 위임 (단위별로 나눠 호출, "테스트 없이 구현만" 지시)
6. **Commit**: `git-manager`로 커밋/PR 생성

### L 티어 (complex)
파일 기반 설계 후 **단위별로** 구현한다.
1. **Task Header 출력** (초기 티어 판단)
2. **Research**: built-in `Explore`로 관련 코드 탐색 → `research.md` 작성 (관련 코드 분석, 제약 조건)
3. **명확화 질문**: 불명확한 부분이 있으면 사용자에게 질문한다. 명확해진 후 다음 단계 진행
4. **Plan**: `plan.md` 작성 (참조 스킬 목록, 접근 방식, 변경 파일, 트레이드 오프, **단위별 작업 순서**)
5. **승인 대기**: 사용자가 plan.md에 메모 → 반영 → **승인 전까지 구현 금지**
6. **Implementation**: plan.md의 각 단위를 순서대로 `implementer`에 위임 (단위당 1회 호출)
7. **Test** (필요 시): `tester` 에이전트로 테스트 작성
8. **Review**: `code-reviewer`로 리뷰 → `git-manager`로 커밋/PR

### M/L 공통 원칙

1. **승인 전에는 어떤 파일도 생성/수정/삭제하지 않는다.** 폴더 생성, 파일 생성, 코드 작성 모두 포함. 탐색 후 반드시 계획을 먼저 보여주고, 사용자 승인을 받은 후에 구현한다.
2. **불명확한 요구사항은 추측하지 않고 질문한다.** 다음이 불명확할 때 반드시 확인:
   - 무엇을 만들어야 하는가 (기능/화면/API)
   - 어떻게 동작해야 하는가 (비즈니스 로직, 예외 처리)
   - 어떤 데이터를 다루는가 (Entity/필드, 필수/선택)
   - 기존 기능과의 관계 (연동, 의존성)
3. **질문과 계획은 동시에 제시할 수 있다.** "이 부분은 이렇게 이해했는데 맞나요? 맞다면 이런 계획으로 진행합니다" 형태도 OK.

### 풀스택 작업 (FE + BE 동시 변경)
티어는 영향도 기준으로 판단하되, 위임 순서는 BE 선행 → FE 후행을 따른다.

---

## 5. 문서 참조 가이드

<!-- AGENTS:START — install.sh init이 자동 갱신. 수동 편집 시 마커 유지 필요 -->
### Agents (서브에이전트 프롬프트)
- `.claude/agents/implementer-fe.md` - React 프론트엔드 구현
- `.claude/agents/implementer-be.md` - NestJS 백엔드 구현
- `.claude/agents/tester.md` - 단위/통합 테스트 작성 (FE/BE 통합)
- `.claude/agents/e2e-tester.md` - E2E 테스트 작성 (Playwright)
- `.claude/agents/code-reviewer.md` - 코드 리뷰 전문가
- `.claude/agents/git-manager.md` - Git 작업 전문가
- 탐색은 built-in `Explore` 에이전트를 사용 (별도 커스텀 agent 없음)
<!-- AGENTS:END -->

<!-- SKILLS:START — install.sh init이 자동 갱신. 수동 편집 시 마커 유지 필요 -->
### Skills (도메인 지식)
- `.claude/skills/Coding/SKILL.md` - 공통 코딩 원칙
- `.claude/skills/NestJS/SKILL.md` - NestJS 백엔드 규칙 (레이어, DTO, DI, 에러 핸들링)
  - `references/auth.md` - 인증/인가 (JWT, Guard, Role, Refresh Token)
  - `references/validation.md` - 유효성 검증 (class-validator, 커스텀 데코레이터)
  - `references/caching.md` - 캐싱 (Redis, TTL 전략, 무효화)
- `.claude/skills/React/SKILL.md` - React 컴포넌트, 훅, 상태 관리
- `.claude/skills/NextJS/SKILL.md` - Next.js App Router, SSR, Server Actions
- `.claude/skills/TailwindCSS/SKILL.md` - Tailwind CSS 유틸리티 패턴
- `.claude/skills/TanStackQuery/SKILL.md` - TanStack Query 서버 상태 관리
- `.claude/skills/Zustand/SKILL.md` - Zustand 클라이언트 상태 관리
- `.claude/skills/ReactHookForm/SKILL.md` - React Hook Form + Zod 폼 검증
- `.claude/skills/TypeScript/SKILL.md` - TypeScript 고급 패턴 (제네릭, 타입 가드, 유틸리티 타입)
- `.claude/skills/TypeORM/SKILL.md` - TypeORM Entity, Repository, QueryBuilder
- `.claude/skills/TDD/` - TDD 테스트 원칙 및 패턴
  - `SKILL.md` - 공통 TDD 원칙
  - `references/frontend.md` - React 테스트 규칙
  - `references/backend.md` - NestJS 테스트 규칙
- `.claude/skills/DDD/SKILL.md` - DDD 전술적 패턴 (Entity, VO, Aggregate, Repository, Domain Event)
- `.claude/skills/Planning/SKILL.md` - 작업 계획 (티어 판단, 작업 분해, 의존성 확인)
- `.claude/skills/APIDesign/SKILL.md` - REST API 설계 (URL, 응답 포맷, 페이지네이션, 에러 코드)
- `.claude/skills/Database/SKILL.md` - DB 설계 & 최적화 (정규화, 인덱싱, N+1, 쿼리 최적화)
- `.claude/skills/SVGIcon/SKILL.md` - SVG 아이콘 생성 (디자인 시스템용, React 래핑)
- `.claude/skills/E2E/SKILL.md` - Playwright E2E 테스트 (Page Object, 셀렉터, Waiting 전략)
- `.claude/skills/Git/SKILL.md` - Git 커밋/PR/브랜치 규칙
- `.claude/skills/FailureRecovery/SKILL.md` - 실패 복구 프로토콜 (진단, 처방, 에스컬레이션)
- `.claude/skills/Curation/SKILL.md` - AI 결과물 큐레이션 체크리스트
<!-- SKILLS:END -->

### Prompts (커스텀 커맨드)
- `.claude/prompts/feature.md` - /feature [기능명] -> 새 기능 구현 시작
- `.claude/prompts/fix.md` - /fix [증상] -> 버그 수정
- `.claude/prompts/investigate.md` - /investigate [증상] -> 조사 없이 수정 금지. 재현 → 원인 확정 → 보고서 → /fix 연계
- `.claude/prompts/review.md` - /review -> 현재 변경사항 리뷰
- `.claude/prompts/ship.md` - /ship [브랜치] -> 릴리스 파이프라인 (main 동기화 → 테스트 → 코드 리뷰 → 커버리지 → PR 생성)
- `.claude/prompts/careful.md` - /careful [명령] -> 위험 명령 방어 (세션 모드 또는 단일 명령 검토)
- `.claude/prompts/freeze.md` - /freeze [경로] -> 편집 범위 제한 (--status, --off 서브커맨드)
- `.claude/prompts/guard.md` - /guard [경로] -> careful + freeze 동시 활성화 (최대 안전 모드)
- `.claude/prompts/retro.md` - /retro [기간] -> git 히스토리 기반 회고 (작업 요약, 트렌드, 리스크)
- `.claude/prompts/canary.md` - /canary [URL] -> 배포 후 헬스체크 (접근성, 에러, 성능)
- `.claude/prompts/qa.md` - /qa [URL] -> 브라우저 기반 QA 테스트 (browse 도구 필요)
- `.claude/prompts/office-hours.md` - /office-hours [아이디어] -> 제품 진단 + 설계 (진단 모드/빌더 모드)
- `.claude/prompts/simplify.md` - /simplify -> 변경 코드 품질 점검 (재사용성, 품질, 효율성)
- `.claude/prompts/document-release.md` - /document-release [범위] -> 배포 후 문서 자동 갱신 (README, CHANGELOG, CLAUDE.md)
- `.claude/prompts/unfreeze.md` - /unfreeze -> /freeze 해제 (편집 제한 해제)
- `.claude/prompts/qa-only.md` - /qa-only [URL] -> 리포트 전용 QA (수정 안 함)
- `.claude/prompts/design-review.md` - /design-review [URL] -> 시각적 디자인 QA (간격, 계층, 색상, 반응형)
- `.claude/prompts/refactor.md` - /refactor [대상] -> 동작 유지 리팩터링 (추출, 이동, 단순화, 중복 제거)
- `.claude/prompts/explain.md` - /explain [대상] -> 코드 설명 (온보딩, 인수인계, 코드 이해)
- `.claude/prompts/migrate.md` - /migrate [대상] -> 마이그레이션 (DB, 의존성, 프레임워크 전환)
- `.claude/prompts/help-me.md` - /help-me [상황] -> 상황에 맞는 커맨드 추천 (뭘 써야 할지 모를 때)
- `.claude/prompts/plan-review.md` - /plan-review -> 구현 전 계획 검증 (아키텍처, 데이터 흐름, 실패 시나리오, 테스트 전략)
- `.claude/prompts/design-check.md` - /design-check -> 구현 전 UI/UX 설계 검증 (6차원 점수화)

### Tools (선택적)
- `.claude/tools/browse/` - Playwright 기반 헤드리스 브라우저 CLI (gstack browse 기반, MIT)
  - 설치: `--tools=browse` 플래그 또는 `bash .claude/tools/browse/setup.sh`
  - 요구사항: Bun >= 1.0

### Scripts
- `.claude/scripts/generate-project-map.sh` - PROJECT_MAP.md 자동 생성
- `.claude/scripts/detect-stack.sh` - manifest 기반 스택 자동 감지 (install.sh, diagnose.sh에서 공유)
- `diagnose.sh` - 프로젝트 에이전트 준비도 진단 CLI (스택 감지, 점수, 권장 스킬)

### Hooks
- `.claude/hooks/prompt-hook.sh` - hook (품질 체크 + 구조 변경 감지)

---

## 6. 다음 단계 자동 연결

작업 완료 후, 다음 단계가 **명확하면 바로 실행**하고, **애매하면 추천**한다.

### 자동 실행 (파이프라인)

다음 흐름은 앞 단계가 끝나면 자동으로 다음을 실행한다:

```
/office-hours → /plan-review → /design-check → /feature → /simplify → /review → /ship → /canary → /document-release
/investigate → /fix → /simplify → /review → /ship
```

- `/plan-review`: M/L 티어 작업에서 구현 전 자동 실행
- `/design-check`: UI가 포함된 작업에서만 자동 실행 (백엔드만이면 건너뜀)

자동 실행 시 한 줄로 알린다: "품질 점검 시작합니다 → `/simplify` 실행"

### 상황별 추천 (자동 실행이 아닌 경우)

| 현재 상황 | 추천 | 행동 |
|----------|------|------|
| 아이디어 정리 완료 | `/plan-review` | 자동 실행 (M/L) |
| 계획 검증 통과 + UI 있음 | `/design-check` | 자동 실행 |
| 새 아이디어 논의 | `/office-hours` | 추천 |
| 위험한 환경 작업 | `/careful` 또는 `/guard` | 추천 |
| 주말 / 스프린트 끝 | `/retro` | 추천 |
| 라이브 사이트 QA 필요 | `/qa` | 추천 |
| UI 디자인 점검 필요 | `/design-review` | 추천 |
| 코드 구조 복잡해짐 | `/refactor` | 추천 |
| 코드 이해 필요 | `/explain` | 추천 |
| DB/의존성 전환 필요 | `/migrate` | 추천 |
| 뭘 해야 할지 모름 | `/help-me` | 추천 |

### 규칙
- **자동 실행**: 파이프라인 내 다음 단계는 물어보지 않고 바로 실행
- **추천**: 파이프라인 밖 상황은 마지막 줄에 한 줄로 제안
- 사용자가 "다음 건 내가 할게" 또는 "자동 실행 그만" 하면 파이프라인 자동 실행을 중단하고 추천 모드로 전환
- 이미 해당 커맨드를 실행 중이면 추천하지 않음

---

## 7. 토큰 절약 원칙


- **탐색**: built-in `Explore` (haiku, read-only) 사용. 단순 구조 확인은 PROJECT_MAP.md로 대체
- **계획**: Planning 스킬 (`context: fork`) — 메인 컨텍스트 오염 방지
- **구현/리뷰만 opus 사용**: implementer, code-reviewer
- **자동 호출 제한**: `disable-model-invocation: true` 스킬(Curation, SVGIcon)은 명시적 호출만 허용
- **스킬 매칭**: Skills 2.0 description 기반 자동 매칭 — hook 기반 스킬 추천 불필요

---

## 8. 프로젝트별 오버라이드

프로젝트 루트에 `CLAUDE.md`가 있으면 이 글로벌 규칙보다 우선한다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.