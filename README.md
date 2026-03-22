# my-claude-code-toolkit

매번 새 프로젝트마다 Claude Code 세팅을 처음부터 만드는 비효율을 해결한다.
`~/.claude/` 글로벌 설정으로 모든 프로젝트에 자동 적용되며, 이 GitHub 레포로 버전 관리한다.

## 설치

### npx로 설치 (권장)

clone 없이 바로 설치할 수 있다.

```bash
# 자동 감지 설치 (권장) — 스택을 자동으로 감지하고 맞는 스킬만 설치
npx @choblue/claude-code-toolkit init

# 자동 감지 + 확인 없이
npx @choblue/claude-code-toolkit init --yes

# 스택 지정 (감지 건너뜀)
npx @choblue/claude-code-toolkit init --stack=react
npx @choblue/claude-code-toolkit init --stack=react,nestjs

# 감지 결과만 미리보기
npx @choblue/claude-code-toolkit init --dry-run

# 전체 설치 (프로젝트 로컬, 레거시)
npx @choblue/claude-code-toolkit

# FE만 설치 (공통 + React, Next.js, TailwindCSS 등)
npx @choblue/claude-code-toolkit --fe

# BE만 설치 (공통 + NestJS, TypeORM 등)
npx @choblue/claude-code-toolkit --be

# 글로벌 설치
npx @choblue/claude-code-toolkit --global

# 스킬 선택 설치 (필요한 것만)
npx @choblue/claude-code-toolkit --skills=React,TailwindCSS,Zustand

# 프로젝트 진단 (에이전트 준비도 체크)
npx @choblue/claude-code-toolkit --diagnose

# 제거
npx @choblue/claude-code-toolkit --uninstall
```

### 소스에서 설치

```bash
# 레포 클론
git clone https://github.com/0r0loo/my-claude-code-toolkit.git
cd my-claude-code-toolkit

# 자동 감지 설치 (권장)
./install.sh init

# 전체 설치 (프로젝트 로컬, 레거시)
./install.sh

# FE만 설치
./install.sh --fe

# BE만 설치
./install.sh --be

# 글로벌 설치
./install.sh --global

# 스킬 선택 설치
./install.sh --skills=React,TailwindCSS

# 프로젝트 진단
bash diagnose.sh

# 제거
./install.sh --uninstall
```

| 옵션 | 설명 |
|------|------|
| `init` | 스택 자동 감지 + 맞춤 설치 (권장) |
| `init --yes` | 확인 없이 자동 설치 |
| `init --stack=LIST` | 스택 지정 (감지 건너뜀) |
| `init --dry-run` | 감지 결과만 출력 (설치 안 함) |
| (없음) | 전체 설치 (FE + BE), 프로젝트 로컬 |
| `--fe` | 공통 + FE 스킬만 설치 |
| `--be` | 공통 + BE 스킬만 설치 |
| `--fe --be` | 전체 설치 (기본값과 동일) |
| `--global` | `~/.claude/`에 글로벌 설치 |
| `--skills=LIST` | 쉼표로 구분된 스킬만 선택 설치 |
| `--diagnose` | 프로젝트 에이전트 준비도 진단 |
| `--uninstall` | 매니페스트 기반 설치 파일 제거 |
| `--force` | 사용자 수정 파일도 강제 덮어쓰기 |

기존 `settings.json`이 있으면 hook만 머지한다 (기존 설정 보존).

## 업데이트

```bash
# npx는 항상 최신 버전을 실행한다
npx @choblue/claude-code-toolkit

# 소스에서 설치한 경우
cd my-claude-code-toolkit
git pull
./install.sh
```

## 기술 스택

- Frontend: React (TypeScript)
- Backend: NestJS (TypeScript)
- 방식: 서브에이전트 위임 (Context 절약)

## 구조

```
.claude/
├── CLAUDE.md                    ← 핵심 워크플로우/위임 규칙
├── settings.json                ← hooks 설정
├── agents/
│   ├── implementer-fe.md        ← React 프론트엔드 구현 (M: 구현만, L: +테스트)
│   ├── implementer-be.md        ← NestJS 백엔드 구현 (M: 구현만, L: +테스트)
│   ├── tester.md                ← 테스트 코드 작성 (FE/BE 통합, opus)
│   ├── code-reviewer.md         ← 2-Pass 코드 리뷰 (Critical/Informational, opus)
│   ├── e2e-tester.md            ← E2E 테스트 작성 (Playwright)
│   └── git-manager.md           ← Git 작업 (sonnet)
├── skills/
│   ├── Coding/
│   │   ├── SKILL.md             ← 공통 코딩 원칙
│   │   └── references/          ← 설계 패턴, 에러 핸들링 예시
│   ├── NestJS/
│   │   ├── SKILL.md             ← NestJS 백엔드 규칙
│   │   └── references/          ← 인증/인가, 유효성 검증, 캐싱
│   ├── Planning/
│   │   └── SKILL.md             ← 작업 계획 (티어 판단, 작업 분해)
│   ├── React/
│   │   ├── SKILL.md             ← React 핵심 규칙
│   │   └── references/          ← 상태/훅, 렌더링 패턴, 접근성/UX
│   ├── NextJS/
│   │   ├── SKILL.md             ← Next.js App Router 핵심 규칙
│   │   └── references/          ← 데이터 페칭, 미들웨어, 최적화
│   ├── TailwindCSS/
│   │   ├── SKILL.md             ← Tailwind CSS 핵심 규칙
│   │   └── references/          ← 반응형/다크모드, 패턴, 트랜지션
│   ├── TanStackQuery/
│   │   ├── SKILL.md             ← TanStack Query 서버 상태
│   │   └── references/          ← useQuery, useMutation, Optimistic Update 예시
│   ├── Zustand/
│   │   ├── SKILL.md             ← Zustand 클라이언트 상태
│   │   └── references/          ← Store, Selector, Middleware, Slice 예시
│   ├── ReactHookForm/
│   │   ├── SKILL.md             ← React Hook Form 핵심 규칙
│   │   └── references/          ← Controller, 동적 필드, 중첩 스키마
│   ├── TypeScript/
│   │   ├── SKILL.md             ← TypeScript 고급 패턴
│   │   └── references/          ← 제네릭, 타입 가드, 고급 패턴
│   ├── TypeORM/
│   │   ├── SKILL.md             ← TypeORM Entity, Repository
│   │   └── references/          ← 고급 쿼리, 마이그레이션, 트랜잭션
│   ├── DDD/
│   │   ├── SKILL.md             ← DDD 전술적 패턴
│   │   └── references/          ← Entity/VO, Aggregate, Domain Event
│   ├── TDD/
│   │   ├── SKILL.md             ← TDD 핵심 원칙
│   │   └── references/          ← React 테스트, NestJS 테스트
│   ├── Git/
│   │   └── SKILL.md             ← 커밋/PR/브랜치 규칙
│   ├── APIDesign/
│   │   ├── SKILL.md             ← REST API 설계 원칙
│   │   └── references/          ← URL, 응답 포맷, 에러 응답 예시
│   ├── Database/
│   │   └── SKILL.md             ← DB 설계 & 최적화
│   ├── SVGIcon/
│   │   └── SKILL.md             ← SVG 아이콘 생성 (디자인 시스템)
│   ├── FailureRecovery/
│   │   └── SKILL.md             ← 실패 복구 프로토콜
│   ├── Curation/
│   │   └── SKILL.md             ← AI 결과물 큐레이션 체크리스트
│   └── manifests/               ← 스택 감지 메타데이터 (init 모드)
│       ├── core.json            ← 스택 무관 핵심 스킬 목록
│       ├── react.json           ← React 스택 감지 규칙 + 스킬/에이전트
│       └── nestjs.json          ← NestJS 스택 감지 규칙 + 스킬/에이전트
├── prompts/
│   ├── feature.md               ← /feature [기능명] 커스텀 커맨드
│   ├── fix.md                   ← /fix [증상] 커스텀 커맨드
│   ├── investigate.md           ← /investigate [증상] 조사 → 원인 확정 → /fix 연계
│   ├── review.md                ← /review 커스텀 커맨드
│   ├── ship.md                  ← /ship [브랜치] 릴리스 파이프라인
│   ├── careful.md               ← /careful [명령] 위험 명령 방어
│   ├── freeze.md                ← /freeze [경로] 편집 범위 제한
│   ├── guard.md                 ← /guard [경로] careful + freeze 결합
│   ├── retro.md                 ← /retro [기간] git 기반 회고
│   ├── canary.md                ← /canary [URL] 배포 후 헬스체크
│   ├── qa.md                    ← /qa [URL] 브라우저 QA (browse 도구 필요)
│   ├── office-hours.md          ← /office-hours [아이디어] 제품 진단 + 설계
│   ├── simplify.md              ← /simplify 변경 코드 품질 점검
│   ├── document-release.md      ← /document-release 배포 후 문서 갱신
│   ├── unfreeze.md              ← /unfreeze 편집 제한 해제
│   ├── qa-only.md               ← /qa-only [URL] 리포트 전용 QA
│   ├── design-review.md         ← /design-review [URL] 시각적 디자인 QA
│   ├── refactor.md              ← /refactor [대상] 리팩터링
│   ├── explain.md               ← /explain [대상] 코드 설명
│   └── migrate.md               ← /migrate [대상] 마이그레이션
├── tools/
│   └── browse/                  ← Playwright 헤드리스 브라우저 CLI (선택적, Bun 필요)
│       ├── src/                 ← TypeScript 소스 (gstack browse 기반, MIT)
│       ├── setup.sh             ← 빌드 스크립트
│       └── package.json
├── hooks/
│   └── prompt-hook.sh           ← hook (품질 체크 + 구조 변경 감지)
└── scripts/
    ├── generate-project-map.sh  ← PROJECT_MAP.md 자동 생성
    └── detect-stack.sh          ← manifest 기반 스택 감지 (install.sh/diagnose.sh 공유)
```

## 프로젝트 진단

설치 전/후에 프로젝트의 에이전트 코딩 준비도를 체크할 수 있다.

```bash
npx @choblue/claude-code-toolkit --diagnose
```

체크 항목:
- **스택 감지**: package.json 기반 기술 스택 자동 식별
- **Entry Point**: CLAUDE.md 존재 여부, 빌드/테스트 명령어 문서화
- **Invariant**: 린터, 포매터, TypeScript strict, pre-commit hook, CI/CD
- **구조**: README, .gitignore, .env.example, 테스트 파일
- **Claude 통합**: .claude/, skills, agents, hooks, PROJECT_MAP.md

결과로 점수(0-100), 성숙도 레벨(L1-L5), 권장 스킬, Quick Win을 출력한다.

## 작동 방식

### 작업 복잡도 티어

작업 시작 시 영향도를 기준으로 티어를 판단한다.

| 티어 | 기준 | 워크플로우 |
|------|------|-----------|
| **S** | 단순 수정, 영향도 낮음 | Main Agent 직접 처리 |
| **M** | 명확한 기능, 단일 레이어 | implementer (구현만) → git-manager |
| **L** | 설계 필요, 레이어 횡단 | implementer (구현+테스트) → code-reviewer → git-manager |

### 서브에이전트 위임

Main Agent는 직접 코드를 작성하거나 탐색하지 않고, 전문 서브에이전트에 위임한다.
이를 통해 Context Window를 절약하고 각 작업에 최적화된 프롬프트를 사용한다.

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| built-in Explore | haiku | 코드베이스 탐색 (read-only) |
| implementer | opus | FE/BE 구현 (M: 구현만, L: 구현+테스트) |
| code-reviewer | opus | 코드 품질 리뷰 |
| git-manager | sonnet | 커밋, 브랜치, PR |

### Hooks

매 프롬프트마다 통합 hook(`prompt-hook.sh`)이 실행된다.

| 기능 | 설명 |
|------|------|
| Quality Gate | 작업 키워드 감지 시 티어 판단 및 워크플로우 안내 |
| Project Map Detector | 프로젝트 구조 변경 감지 → 갱신 안내 |

### PROJECT_MAP.md

코드 탐색 시 매번 전체를 재탐색하는 비용을 줄이기 위해, 프로젝트 구조를 캐싱한다.

```bash
# PROJECT_MAP.md 생성
.claude/scripts/generate-project-map.sh

# 깊이 지정 (기본: 3)
.claude/scripts/generate-project-map.sh 5
```

생성되는 내용:
- 프로젝트 정보 (이름, 브랜치, 최근 커밋)
- 기술 스택 (package.json에서 자동 감지)
- 디렉토리 구조 (설정 가능한 깊이)
- 주요 파일 (설정 파일, 엔트리포인트)
- 빌드 명령 (dev/build/test/start)

## 프로젝트별 커스터마이징

프로젝트 루트에 `CLAUDE.md`를 추가하면 글로벌 규칙보다 우선 적용된다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.

## 권장 Permission 설정

매번 승인이 번거로운 안전한 명령어를 자동 허용할 수 있다.
프로젝트 `.claude/settings.json` 또는 글로벌 `~/.claude/settings.json`에 추가한다.

```json
{
  "permissions": {
    "allow": [
      "Bash(mkdir:*)",
      "Bash(cd:*)",
      "Bash(ls:*)",
      "Bash(pwd:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(echo:*)",
      "Bash(wc:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(npm run:*)",
      "Bash(npx:*)",
      "Bash(pnpm:*)",
      "Edit",
      "Write"
    ]
  }
}
```

> 위 설정은 **권장 사항**이며 선택적이다. 본인의 comfort level에 맞게 조정한다.
> `rm`, `git push`, `git reset` 등 파괴적 명령어는 의도적으로 포함하지 않았다.

## 보안 & 실행 범위

### 자동 실행 스크립트

| 스크립트 | 실행 시점 | 역할 | 네트워크 호출 | 파일 수정 |
|---------|----------|------|:----------:|:--------:|
| `prompt-hook.sh` | 프롬프트 제출 시 (UserPromptSubmit hook) | 품질 체크 + 구조 변경 감지 | 없음 | 없음 |
| `generate-project-map.sh` | 수동 실행 | PROJECT_MAP.md 생성 | 없음 | 1파일 |

### 감사 방법

- `bash -x .claude/hooks/prompt-hook.sh` — hook 실행 흐름 추적
- `.claude/.toolkit-manifest` — 설치된 파일 목록 + SHA256 해시 확인
- 모든 스크립트는 읽기 전용 작업만 수행 (파일 생성/삭제/네트워크 호출 없음)
