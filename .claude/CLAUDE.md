# Global Claude Code Rules

이 파일은 모든 프로젝트에 적용되는 글로벌 규칙이다.
Claude는 작업 시작 전 반드시 이 규칙을 따라야 한다.

---

## 1. 작업 복잡도 티어

작업 시작 전 반드시 티어를 판단하고, 티어에 맞는 워크플로우를 따른다.

| 티어 | 기준 | 예시 |
|------|------|------|
| **S (trivial)** | 단순 수정, 영향도 낮음 | 오타 수정, config 변경, README 업데이트, 일괄 rename |
| **M (moderate)** | 명확한 기능, 단일 레이어 | 단일 컴포넌트 추가, API 엔드포인트 1개, 유틸 함수 추가 |
| **L (complex)** | 설계 필요, 레이어 횡단 | 새 도메인 모듈, 핵심 엔티티 변경, FE+BE 동시 변경 |

> **판단 기준**: 파일 수보다 **변경 영향도**를 우선한다. 20파일 일괄 rename은 S, 핵심 도메인 엔티티 1개 변경은 L이다.

### PROJECT_MAP.md 활용
- `.claude/PROJECT_MAP.md`가 있으면 explore 전에 반드시 먼저 Read하라
- 단순 구조 확인은 explore 생략 가능
- 세부 코드 탐색이 필요할 때만 explore 위임
- 갱신: `.claude/scripts/generate-project-map.sh` 실행

### 에이전트 위임 대상
- **탐색** → `explore` 에이전트 (haiku) — 코드 탐색, 기존 패턴 파악, 티어 판단, 에이전트 흐름 권장
- **구현 (M 티어)** → `implementer-fe` 또는 `implementer-be` 에이전트 (구현만)
- **구현+테스트 (L 티어)** → `implementer-fe` 또는 `implementer-be` 에이전트 (구현 + 테스트)
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
1. **Task Header 출력**
2. **Planning**: `explore`로 탐색 → explore 결과 기반으로 Task Header의 📚, 🔄 결정
3. **Implementation**: `implementer` 에이전트에 구현 위임 (단위별로 나눠 호출, "테스트 없이 구현만" 지시)
4. **Commit**: `git-manager`로 커밋/PR 생성

### L 티어 (complex)
파일 기반 설계 후 **단위별로** 구현한다.
1. **Task Header 출력**
2. **Research**: `explore`로 탐색 → `research.md` 작성 (관련 코드 분석, 제약 조건)
3. **Plan**: `plan.md` 작성 (접근 방식, 변경 파일, 트레이드 오프, **단위별 작업 순서**)
4. **주석 사이클**: 사용자가 plan.md에 메모 → 반영 → **승인 전까지 구현 금지**
5. **Implementation + Test**: plan.md의 각 단위를 순서대로 `implementer`에 위임 (단위당 1회 호출)
6. **Review**: `code-reviewer`로 리뷰 → `git-manager`로 커밋/PR

### 풀스택 작업 (FE + BE 동시 변경)
티어는 영향도 기준으로 판단하되, 위임 순서는 BE 선행 → FE 후행을 따른다.

---

## 5. 문서 참조 가이드

### Agents (서브에이전트 프롬프트)
- `.claude/agents/explore.md` - 코드베이스 탐색 전문가
- `.claude/agents/implementer-fe.md` - React 프론트엔드 구현 (M: 구현만, L: 구현+테스트)
- `.claude/agents/implementer-be.md` - NestJS 백엔드 구현 (M: 구현만, L: 구현+테스트)
- `.claude/agents/code-reviewer.md` - 코드 리뷰 전문가
- `.claude/agents/git-manager.md` - Git 작업 전문가

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
- `.claude/skills/Git/SKILL.md` - Git 커밋/PR/브랜치 규칙
- `.claude/skills/FailureRecovery/SKILL.md` - 실패 복구 프로토콜 (진단, 처방, 에스컬레이션)
- `.claude/skills/Curation/SKILL.md` - AI 결과물 큐레이션 체크리스트

### Prompts (커스텀 커맨드)
- `.claude/prompts/feature.md` - /feature [기능명] -> 새 기능 구현 시작
- `.claude/prompts/fix.md` - /fix [증상] -> 버그 수정
- `.claude/prompts/review.md` - /review -> 현재 변경사항 리뷰

### Scripts
- `.claude/scripts/generate-project-map.sh` - PROJECT_MAP.md 자동 생성
- `diagnose.sh` - 프로젝트 에이전트 준비도 진단 CLI (스택 감지, 점수, 권장 스킬)

### Hooks
- `.claude/hooks/prompt-hook.sh` - hook (품질 체크 + 구조 변경 감지)

---

## 6. 토큰 절약 원칙

- **탐색**: `explore` 에이전트 (haiku) 우선. 단순 구조 확인은 PROJECT_MAP.md로 대체
- **계획**: Planning 스킬 (`context: fork`) — 메인 컨텍스트 오염 방지
- **구현/리뷰만 opus 사용**: implementer, code-reviewer
- **자동 호출 제한**: `disable-model-invocation: true` 스킬(Curation, SVGIcon)은 명시적 호출만 허용
- **스킬 매칭**: Skills 2.0 description 기반 자동 매칭 — hook 기반 스킬 추천 불필요

---

## 7. 프로젝트별 오버라이드

프로젝트 루트에 `CLAUDE.md`가 있으면 이 글로벌 규칙보다 우선한다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.