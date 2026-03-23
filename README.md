# my-claude-code-toolkit

Claude Code에 23개 개발 커맨드를 추가한다. 설치하면 기획부터 배포까지 AI가 알아서 이어간다.

## 빠르게 시작하기

### 설치 (30초)

```bash
npx @choblue/claude-code-toolkit init
```

스택을 자동 감지하고 맞는 스킬만 설치한다. 끝.

### 사용법 (이것만 알면 된다)

```bash
# 기능 만들기
claude "/feature 로그인 페이지"

# 자동으로 품질 점검(/simplify) → 코드 리뷰(/review) 이어짐

# 배포
claude "/ship"
```

### 전체 개발 플로우

```
기획 → 검증 → 디자인 검증 → 구현 → 품질 점검 → 코드 리뷰 → 배포 → 헬스체크 → 문서 갱신
```

| 단계 | 커맨드 | 하는 일 |
|------|--------|--------|
| 기획 | `/office-hours` | 아이디어 구조화, 진짜 필요한 건지 검증 |
| 계획 검증 | `/plan-review` | 아키텍처, 실패 시나리오, 테스트 전략 점검 |
| 디자인 검증 | `/design-check` | UI 설계 6차원 점수화 (UI 없으면 건너뜀) |
| 구현 | `/feature 기능명` | 서브에이전트가 코드 작성 |
| 품질 점검 | `/simplify` | 재사용성, 품질, 효율성 자가 점검 |
| 코드 리뷰 | `/review` | 위험 패턴 10가지 자동 감지 |
| 배포 | `/ship` | 테스트 → 리뷰 → 버전 bump → PR 생성 |
| 헬스체크 | `/canary URL` | 배포 후 상태 확인 (이전과 비교) |
| 문서 갱신 | `/document-release` | README, CHANGELOG 자동 업데이트 |

> 구현→품질 점검→코드 리뷰는 자동으로 이어진다. 배포부터는 확인을 받는다.

### 버그 수정

```bash
claude "/investigate 로그인에서 500 에러"   # 원인 조사 (수정 안 함)
claude "/fix 로그인 500 에러"               # 원인 기반 수정
# → 자동으로 /simplify → /review 이어짐
```

### 그 외 상황별

| 상황 | 커맨드 |
|------|--------|
| 코드 이해 / 온보딩 | `/explain 대상` |
| 코드 구조 개선 | `/refactor 대상` |
| DB/의존성 업그레이드 | `/migrate 대상` |
| 브라우저 QA 테스트 | `/qa URL` |
| 버그 리포트만 | `/qa-only URL` |
| 시각적 디자인 점검 | `/design-review URL` |
| 위험한 명령 방어 | `/careful` |
| 편집 범위 제한 | `/freeze 경로` / `/unfreeze` |
| 최대 안전 모드 | `/guard 경로` |
| 주간 회고 | `/retro` |
| 뭘 해야 할지 모를 때 | `/help-me` |

---

## 상세 문서

아래부터는 설치 옵션, 내부 구조, 설정 방법 등 자세한 내용.

### 설치 옵션

```bash
# 자동 감지 설치 (권장)
npx @choblue/claude-code-toolkit init

# 자동 감지 + 확인 없이
npx @choblue/claude-code-toolkit init --yes

# 스택 지정 (감지 건너뜀)
npx @choblue/claude-code-toolkit init --stack=react
npx @choblue/claude-code-toolkit init --stack=react,nestjs

# 감지 결과만 미리보기
npx @choblue/claude-code-toolkit init --dry-run

# 전체 설치 (FE + BE)
npx @choblue/claude-code-toolkit

# FE만 / BE만
npx @choblue/claude-code-toolkit --fe
npx @choblue/claude-code-toolkit --be

# 글로벌 설치
npx @choblue/claude-code-toolkit --global

# 스킬 선택 설치
npx @choblue/claude-code-toolkit --skills=React,TailwindCSS

# 프로젝트 진단
npx @choblue/claude-code-toolkit --diagnose

# 제거
npx @choblue/claude-code-toolkit --uninstall
```

| 옵션 | 설명 |
|------|------|
| `init` | 스택 자동 감지 + 맞춤 설치 (권장) |
| `init --yes` | 확인 없이 자동 설치 |
| `init --stack=LIST` | 스택 지정 (감지 건너뜀) |
| `init --dry-run` | 감지 결과만 출력 (설치 안 함) |
| (없음) | 전체 설치 (FE + BE) |
| `--fe` | 공통 + FE 스킬만 |
| `--be` | 공통 + BE 스킬만 |
| `--global` | `~/.claude/`에 글로벌 설치 |
| `--skills=LIST` | 쉼표로 구분된 스킬만 선택 |
| `--diagnose` | 프로젝트 에이전트 준비도 진단 |
| `--uninstall` | 매니페스트 기반 설치 파일 제거 |
| `--force` | 사용자 수정 파일도 강제 덮어쓰기 |

기존 `settings.json`이 있으면 hook만 머지한다 (기존 설정 보존).

### 소스에서 설치

```bash
git clone https://github.com/0r0loo/my-claude-code-toolkit.git
cd my-claude-code-toolkit
./install.sh init
```

### 업데이트

```bash
npx @choblue/claude-code-toolkit init    # npx는 항상 최신 버전
```

### 기술 스택

- Frontend: React (TypeScript)
- Backend: NestJS (TypeScript)
- 방식: 서브에이전트 위임 (Context 절약)

### 구조

```
.claude/
├── CLAUDE.md                    ← 핵심 워크플로우/위임 규칙
├── settings.json                ← hooks 설정
├── agents/
│   ├── implementer-fe.md        ← React 프론트엔드 구현
│   ├── implementer-be.md        ← NestJS 백엔드 구현
│   ├── tester.md                ← 테스트 코드 작성
│   ├── code-reviewer.md         ← 2-Pass 코드 리뷰
│   ├── e2e-tester.md            ← E2E 테스트 (Playwright)
│   └── git-manager.md           ← Git 작업
├── skills/                      ← 20개 도메인 지식 스킬
│   ├── Coding, React, NextJS, TailwindCSS, NestJS, TypeORM, ...
│   └── manifests/               ← 스택 감지 메타데이터
├── prompts/                     ← 23개 커스텀 커맨드 (/feature, /ship, ...)
├── tools/
│   └── browse/                  ← Playwright 헤드리스 브라우저 (선택적)
├── hooks/
│   └── prompt-hook.sh           ← 품질 체크 + 구조 변경 감지
└── scripts/
    ├── generate-project-map.sh  ← PROJECT_MAP.md 자동 생성
    └── detect-stack.sh          ← manifest 기반 스택 감지
```

### 프로젝트 진단

```bash
npx @choblue/claude-code-toolkit --diagnose
```

스택 감지, 린터/포매터/CI 설정, Claude 통합 상태를 체크하고 점수(0-100)와 권장 스킬을 출력한다.

### 작동 방식

**작업 복잡도 티어**: 작업 시작 시 영향도를 기준으로 자동 판단.

| 티어 | 기준 | 워크플로우 |
|------|------|-----------|
| **S** | 단순 수정 | Main Agent 직접 처리 |
| **M** | 명확한 기능 | implementer → git-manager |
| **L** | 설계 필요 | implementer → code-reviewer → git-manager |

**서브에이전트 위임**: Main Agent가 직접 코드를 쓰지 않고 전문 에이전트에 위임. Context Window 절약.

| 에이전트 | 역할 |
|---------|------|
| built-in Explore (haiku) | 코드베이스 탐색 |
| implementer (opus) | FE/BE 구현 |
| code-reviewer (opus) | 코드 품질 리뷰 |
| git-manager (sonnet) | 커밋, 브랜치, PR |

### 프로젝트별 커스터마이징

프로젝트 루트에 `CLAUDE.md`를 추가하면 글로벌 규칙보다 우선 적용된다.

### 권장 Permission 설정

```json
{
  "permissions": {
    "allow": [
      "Bash(mkdir:*)", "Bash(cd:*)", "Bash(ls:*)", "Bash(pwd:*)",
      "Bash(cat:*)", "Bash(head:*)", "Bash(tail:*)", "Bash(echo:*)",
      "Bash(wc:*)", "Bash(git status:*)", "Bash(git diff:*)",
      "Bash(git log:*)", "Bash(git branch:*)", "Bash(git add:*)",
      "Bash(git commit:*)", "Bash(npm run:*)", "Bash(npx:*)",
      "Bash(pnpm:*)", "Edit", "Write"
    ]
  }
}
```

> `rm`, `git push`, `git reset` 등 파괴적 명령어는 의도적으로 포함하지 않았다.

### 보안 & 실행 범위

| 스크립트 | 실행 시점 | 네트워크 | 파일 수정 |
|---------|----------|:------:|:--------:|
| `prompt-hook.sh` | 프롬프트 제출 시 | 없음 | 없음 |
| `generate-project-map.sh` | 수동 실행 | 없음 | 1파일 |

감사: `bash -x .claude/hooks/prompt-hook.sh` / `.claude/.toolkit-manifest`로 설치 파일 + SHA256 해시 확인.