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
- **탐색/검색 작업** → `explore` 에이전트 (haiku)
- **코드 구현** → `code-writer-fe` 또는 `code-writer-be` 에이전트 (opus)
- **코드 리뷰** → `code-reviewer` 에이전트 (opus)
- **Git 작업** → `git-manager` 에이전트 (sonnet)
- **테스트 작성/실행** → `test-writer-fe` 또는 `test-writer-be` 에이전트 (opus)

---

## 2. 티어별 워크플로우

### S 티어 (trivial)
Main Agent가 직접 처리한다. 서브에이전트 위임 불필요.
1. 파일 읽기 → 직접 수정 → 완료
2. 필요 시 `git-manager`로 커밋

### M 티어 (moderate)
TDD/Review를 생략하고 핵심 단계만 수행한다.
1. **Planning**: 요구사항 정리, 필요 시 `explore`로 탐색
2. **Implementation**: `code-writer` 에이전트에 구현 위임
3. **Commit**: `git-manager`로 커밋/PR 생성

### L 티어 (complex)
풀 프로세스를 따른다.
1. **Planning**: 요구사항 정리 → `explore`로 탐색 → 사용자 승인
2. **Test (Red)**: `test-writer`에 실패하는 테스트 작성 위임
3. **Implementation (Green)**: `code-writer`에 구현 위임 → 테스트 통과 확인
4. **Review**: `code-reviewer`로 리뷰 → `git-manager`로 커밋/PR

### 풀스택 작업 (FE + BE 동시 변경)
티어는 영향도 기준으로 판단하되, 위임 순서는 BE 선행 → FE 후행을 따른다.

---

## 3. 문서 참조 가이드

### Agents (서브에이전트 프롬프트)
- `.claude/agents/explore.md` - 코드베이스 탐색 전문가
- `.claude/agents/code-writer-fe.md` - React 프론트엔드 구현 전문가
- `.claude/agents/code-writer-be.md` - NestJS 백엔드 구현 전문가
- `.claude/agents/code-reviewer.md` - 코드 리뷰 전문가
- `.claude/agents/test-writer-fe.md` - React 프론트엔드 테스트 전문가
- `.claude/agents/test-writer-be.md` - NestJS 백엔드 테스트 전문가
- `.claude/agents/git-manager.md` - Git 작업 전문가

### Skills (도메인 지식)
- `.claude/skills/Coding/` - 코딩 원칙 및 패턴
  - `SKILL.md` - 공통 원칙
  - `backend.md` - NestJS 백엔드 규칙
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
  - `frontend.md` - React 테스트 규칙
  - `backend.md` - NestJS 테스트 규칙
- `.claude/skills/DDD/SKILL.md` - DDD 전술적 패턴 (Entity, VO, Aggregate, Repository, Domain Event)
- `.claude/skills/Git/SKILL.md` - Git 커밋/PR/브랜치 규칙

### Scripts
- `.claude/scripts/generate-project-map.sh` - PROJECT_MAP.md 자동 생성

### Hooks
- `.claude/hooks/prompt-hook.sh` - 통합 hook (품질 체크 + 스킬 추천 + 구조 변경 감지)
- `.claude/hooks/skill-keywords.conf` - 스킬별 키워드 매핑 설정

---

## 4. 프로젝트별 오버라이드

프로젝트 루트에 `CLAUDE.md`가 있으면 이 글로벌 규칙보다 우선한다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.