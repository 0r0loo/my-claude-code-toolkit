# my-claude-code-toolkit

매번 새 프로젝트마다 Claude Code 세팅을 처음부터 만드는 비효율을 해결한다.
`~/.claude/` 글로벌 설정으로 모든 프로젝트에 자동 적용되며, 이 GitHub 레포로 버전 관리한다.

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
│   ├── explore.md               ← 코드베이스 탐색 (haiku)
│   ├── code-writer-fe.md        ← React 프론트엔드 구현 - M 티어 (opus)
│   ├── code-writer-be.md        ← NestJS 백엔드 구현 - M 티어 (opus)
│   ├── implementer-fe.md        ← React 구현+테스트 - L 티어 (opus)
│   ├── implementer-be.md        ← NestJS 구현+테스트 - L 티어 (opus)
│   ├── code-reviewer.md         ← 코드 품질 리뷰 (opus)
│   └── git-manager.md           ← Git 작업 (sonnet)
├── skills/
│   ├── Coding/
│   │   ├── SKILL.md             ← 공통 코딩 원칙
│   │   └── backend.md           ← NestJS 코딩 규칙
│   ├── Planning/
│   │   └── SKILL.md             ← 작업 계획 (티어 판단, 작업 분해)
│   ├── React/
│   │   └── SKILL.md             ← React 컴포넌트, 훅, 상태 관리
│   ├── NextJS/
│   │   └── SKILL.md             ← Next.js App Router, SSR
│   ├── TailwindCSS/
│   │   └── SKILL.md             ← Tailwind CSS 유틸리티 패턴
│   ├── TanStackQuery/
│   │   └── SKILL.md             ← TanStack Query 서버 상태
│   ├── Zustand/
│   │   └── SKILL.md             ← Zustand 클라이언트 상태
│   ├── ReactHookForm/
│   │   └── SKILL.md             ← React Hook Form + Zod
│   ├── TypeScript/
│   │   └── SKILL.md             ← TypeScript 고급 패턴
│   ├── TypeORM/
│   │   ├── SKILL.md             ← TypeORM Entity, Repository
│   │   └── references/          ← 고급 쿼리, 마이그레이션, 트랜잭션
│   ├── DDD/
│   │   ├── SKILL.md             ← DDD 전술적 패턴
│   │   └── references/          ← Entity/VO, Aggregate, Domain Event 심화
│   ├── TDD/
│   │   ├── SKILL.md             ← TDD 핵심 원칙
│   │   ├── frontend.md          ← React 테스트 규칙
│   │   └── backend.md           ← NestJS 테스트 규칙
│   └── Git/
│       └── SKILL.md             ← 커밋/PR/브랜치 규칙
├── hooks/
│   ├── prompt-hook.sh           ← 통합 hook (품질 체크 + 스킬 추천 + 구조 변경 감지)
│   └── skill-keywords.conf      ← 스킬별 키워드 매핑 설정
└── scripts/
    └── generate-project-map.sh  ← PROJECT_MAP.md 자동 생성
```

## 설치

### npx로 설치 (권장)

clone 없이 바로 설치할 수 있다.

```bash
# 전체 설치 (프로젝트 로컬)
npx @choblue/claude-code-toolkit

# FE만 설치 (공통 + React, Next.js, TailwindCSS 등)
npx @choblue/claude-code-toolkit --fe

# BE만 설치 (공통 + NestJS, TypeORM 등)
npx @choblue/claude-code-toolkit --be

# 글로벌 설치
npx @choblue/claude-code-toolkit --global

# 글로벌 + FE만
npx @choblue/claude-code-toolkit --global --fe
```

### 소스에서 설치

```bash
# 레포 클론
git clone https://github.com/0r0loo/my-claude-code-toolkit.git
cd my-claude-code-toolkit

# 전체 설치 (프로젝트 로컬)
./install.sh

# FE만 설치
./install.sh --fe

# BE만 설치
./install.sh --be

# 글로벌 설치
./install.sh --global

# 글로벌 + FE만
./install.sh --global --fe
```

| 옵션 | 설명 |
|------|------|
| (없음) | 전체 설치 (FE + BE), 프로젝트 로컬 |
| `--fe` | 공통 + FE 스킬만 설치 |
| `--be` | 공통 + BE 스킬만 설치 |
| `--fe --be` | 전체 설치 (기본값과 동일) |
| `--global` | `~/.claude/`에 글로벌 설치 |

기존 `.claude/` 파일이 있으면 자동으로 백업 후 덮어쓴다.

## 작동 방식

### 작업 복잡도 티어

작업 시작 시 영향도를 기준으로 티어를 판단한다.

| 티어 | 기준 | 워크플로우 |
|------|------|-----------|
| **S** | 단순 수정, 영향도 낮음 | Main Agent 직접 처리 |
| **M** | 명확한 기능, 단일 레이어 | code-writer → git-manager |
| **L** | 설계 필요, 레이어 횡단 | implementer (구현+테스트) → code-reviewer → git-manager |

### 서브에이전트 위임

Main Agent는 직접 코드를 작성하거나 탐색하지 않고, 전문 서브에이전트에 위임한다.
이를 통해 Context Window를 절약하고 각 작업에 최적화된 프롬프트를 사용한다.

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| explore | haiku | 빠른 코드베이스 탐색 |
| code-writer | opus | FE/BE 코드 구현 (M 티어) |
| implementer | opus | FE/BE 구현+테스트 동시 수행 (L 티어) |
| code-reviewer | opus | 코드 품질 리뷰 |
| git-manager | sonnet | 커밋, 브랜치, PR |

### Hooks

매 프롬프트마다 통합 hook(`prompt-hook.sh`)이 실행된다.

| 기능 | 설명 |
|------|------|
| Quality Gate | 티어 판단 및 워크플로우 안내 |
| Skill Detector | 프롬프트 키워드 분석 → 관련 스킬 자동 추천 |
| Project Map Detector | 프로젝트 구조 변경 감지 → 갱신 안내 |

`skill-keywords.conf`에서 스킬별 키워드를 관리하며, 스킬 추가 시 conf 파일만 수정하면 된다.

### PROJECT_MAP.md

explore 에이전트가 매번 코드베이스를 재탐색하는 비용을 줄이기 위해, 프로젝트 구조를 캐싱한다.

```bash
# PROJECT_MAP.md 생성
.claude/scripts/generate-project-map.sh
```

생성되는 내용:
- 프로젝트 정보 (이름, 브랜치, 최근 커밋)
- 기술 스택 (package.json에서 자동 감지)
- 디렉토리 구조 (3레벨 깊이)
- 주요 파일 (설정 파일, 엔트리포인트)
- 빌드 명령 (dev/build/test/start)

## 프로젝트별 커스터마이징

프로젝트 루트에 `CLAUDE.md`를 추가하면 글로벌 규칙보다 우선 적용된다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.

## 업데이트

```bash
# npx는 항상 최신 버전을 실행한다
npx @choblue/claude-code-toolkit

# 소스에서 설치한 경우
cd my-claude-code-toolkit
git pull
./install.sh
```