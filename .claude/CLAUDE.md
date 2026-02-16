# Global Claude Code Rules

이 파일은 모든 프로젝트에 적용되는 글로벌 규칙이다.
Claude는 작업 시작 전 반드시 이 규칙을 따라야 한다.

---

## 1. Context 절약 원칙

Main Agent의 Context Window는 제한적이다. 반드시 서브에이전트에 위임하라.

### 위임 규칙
- **탐색/검색 작업** → `explore` 에이전트 (haiku) 위임
- **코드 구현** → `code-writer` 에이전트 (opus) 위임
- **코드 리뷰** → `code-reviewer` 에이전트 (opus) 위임
- **Git 작업** → `git-manager` 에이전트 (sonnet) 위임
- **테스트 작성/실행** → `tdd` 에이전트 (opus) 위임

### Main Agent 허용 작업
- 사용자와의 대화, 요구사항 분석
- 작업 계획 수립 (Planning)
- 서브에이전트 호출 및 결과 요약
- 최종 확인 및 사용자 보고

### Main Agent 금지 작업
- 직접 파일 탐색 (Glob/Grep 3회 이상)
- 직접 코드 작성 (단순 수정 제외)
- 직접 Git 작업 (commit, push, PR 생성)
- 대량 파일 읽기 (Read 5회 이상)

---

## 2. 작업 워크플로우

모든 작업은 다음 4단계를 따른다:

### Phase 1: Planning
1. 사용자 요구사항을 정리한다
2. `explore` 에이전트로 관련 코드/파일 탐색
3. 작업 계획을 사용자에게 제시하고 승인받는다

### Phase 2: Test (Red)
1. `tdd` 에이전트에 실패하는 테스트 작성을 위임한다
2. 테스트가 실패하는 것을 확인한다 (Red 상태)

### Phase 3: Implementation (Green + Refactor)
1. `code-writer` 에이전트에 구현을 위임한다
2. 테스트를 통과시키는 최소한의 코드만 구현한다
3. `tdd` 에이전트로 테스트 통과를 확인한다 (Green 상태)
4. 필요 시 리팩토링 후 테스트가 여전히 통과하는지 확인한다

### Phase 4: Review
1. `code-reviewer` 에이전트로 코드 + 테스트 리뷰를 수행한다
2. Critical 이슈가 있으면 `code-writer`에 수정을 위임한다
3. 리뷰 통과 후 `git-manager`로 커밋/PR을 생성한다

---

## 3. 문서 참조 가이드

### Agents (서브에이전트 프롬프트)
- `.claude/agents/explore.md` - 코드베이스 탐색 전문가
- `.claude/agents/code-writer/` - 코드 구현 전문가
  - `common.md` - 공통 규칙
  - `backend.md` - NestJS 백엔드 규칙
  - `frontend.md` - React 프론트엔드 규칙
- `.claude/agents/code-reviewer.md` - 코드 리뷰 전문가
- `.claude/agents/tdd/` - TDD 테스트 전문가
  - `common.md` - 공통 규칙
  - `backend.md` - NestJS 백엔드 테스트 규칙
  - `frontend.md` - React 프론트엔드 테스트 규칙
- `.claude/agents/git-manager.md` - Git 작업 전문가

### Skills (도메인 지식)
- `.claude/skills/Coding/` - 코딩 원칙 및 패턴
  - `SKILL.md` - 공통 원칙
  - `frontend.md` - React 프론트엔드 규칙
  - `backend.md` - NestJS 백엔드 규칙
- `.claude/skills/TDD/` - TDD 테스트 원칙 및 패턴
  - `SKILL.md` - 공통 TDD 원칙
  - `frontend.md` - React 테스트 규칙
  - `backend.md` - NestJS 테스트 규칙
- `.claude/skills/Git/SKILL.md` - Git 커밋/PR/브랜치 규칙

### Hooks
- `.claude/hooks/quality-gate.sh` - 품질 체크 프로토콜

---

## 4. 프로젝트별 오버라이드

프로젝트 루트에 `CLAUDE.md`가 있으면 이 글로벌 규칙보다 우선한다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.