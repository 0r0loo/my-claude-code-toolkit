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
│   ├── code-writer/
│   │   ├── common.md            ← 공통 구현 규칙
│   │   ├── backend.md           ← NestJS 백엔드 규칙
│   │   └── frontend.md          ← React 프론트엔드 규칙
│   ├── code-reviewer.md         ← 코드 품질 리뷰 (opus)
│   └── git-manager.md           ← Git 작업 (sonnet)
├── skills/
│   ├── Coding/
│   │   ├── SKILL.md             ← 공통 코딩 원칙
│   │   ├── frontend.md          ← React 코딩 규칙
│   │   └── backend.md           ← NestJS 코딩 규칙
│   └── Git/
│       └── SKILL.md             ← 커밋/PR/브랜치 규칙
└── hooks/
    └── quality-gate.sh          ← 품질 체크 프로토콜
```

## 설치

```bash
# 레포 클론
git clone https://github.com/your-username/my-claude-code-toolkit.git

# 설치 (글로벌 적용)
cd my-claude-code-toolkit
./install.sh
```

기존 `~/.claude/` 파일이 있으면 자동으로 백업 후 덮어쓴다.

## 작동 방식

### 워크플로우 (Planning → Implementation → Review)

1. **Planning**: 사용자 요구사항 분석 → `explore` 에이전트로 코드 탐색 → 작업 계획 제시
2. **Implementation**: `code-writer` 에이전트에 구현 위임 (FE/BE 별도 규칙)
3. **Review**: `code-reviewer`로 코드 리뷰 → `git-manager`로 커밋/PR 생성

### 서브에이전트 위임

Main Agent는 직접 코드를 작성하거나 탐색하지 않고, 전문 서브에이전트에 위임한다.
이를 통해 Context Window를 절약하고 각 작업에 최적화된 프롬프트를 사용한다.

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| explore | haiku | 빠른 코드베이스 탐색 |
| code-writer | opus | FE/BE 코드 구현 |
| code-reviewer | opus | 코드 품질 리뷰 |
| git-manager | sonnet | 커밋, 브랜치, PR |

### Quality Gate Hook

매 프롬프트마다 `quality-gate.sh`가 실행되어 적절한 에이전트/스킬 활용을 상기시킨다.

## 프로젝트별 커스터마이징

프로젝트 루트에 `CLAUDE.md`를 추가하면 글로벌 규칙보다 우선 적용된다.
프로젝트별 규칙은 글로벌 규칙을 확장하되, 충돌 시 프로젝트 규칙을 따른다.

## 업데이트

```bash
# 레포에서 최신 변경사항 pull
cd my-claude-code-toolkit
git pull

# 재설치
./install.sh
```
