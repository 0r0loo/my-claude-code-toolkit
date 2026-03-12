# my-claude-code-toolkit 종합 리뷰 리포트

> 리뷰어: Claude | 날짜: 2026-03-12
> 대상: 전체 레포지토리 (v1.3.3)

---

## 총평

**잘 만든 프로젝트다.** 1인 개발자가 Claude Code를 체계적으로 활용하기 위한 툴킷으로, 티어 시스템(S/M/L), 서브에이전트 위임, 스킬 기반 지식 관리, 훅을 통한 자동 품질 게이트까지 잘 설계되어 있다. 특히 "한 번에 하나, 완전하게"라는 점진적 구현 원칙과 매니페스트 기반 install.sh는 실용적이다.

다만 현재 구조에서 **확장성, 유지보수성, 실제 사용 시 마찰**에 관한 개선점이 꽤 있다. 아래에서 카테고리별로 정리한다.

---

## 1. 아키텍처 / 구조적 문제

### 1-1. CLAUDE.md 이중 구조의 혼란

**문제**: 프로젝트 루트 `CLAUDE.md`와 `.claude/CLAUDE.md` 두 개가 존재한다. 루트 CLAUDE.md는 "이 레포지토리 자체"의 규칙(install.sh 동기화, 배포 체크리스트)이고, `.claude/CLAUDE.md`는 "설치 대상 프로젝트"에 복사되는 글로벌 규칙이다.

**위험**: 이 레포를 `npx`로 설치한 사용자 프로젝트에서는 `.claude/CLAUDE.md`만 복사되므로 문제없지만, **이 레포 자체를 Claude Code로 작업할 때** 두 CLAUDE.md의 우선순위가 혼란스럽다. Claude Code는 프로젝트 루트의 CLAUDE.md와 .claude/CLAUDE.md를 모두 읽는데, 루트가 오버라이드한다고 써있지만 실제로는 둘 다 적용된다.

**제안**: 루트 CLAUDE.md의 역할을 더 명확히 분리하거나, `.claude/CLAUDE.md`에 "이 파일은 설치 대상용"이라는 주석을 최상단에 추가.

### 1-2. 스킬이 NestJS + React에 하드코딩

**문제**: 현재 스킬셋이 React/NextJS/NestJS/TypeORM에 강하게 묶여 있다. 다른 스택(Vue, Angular, Express, Prisma, Drizzle 등)을 쓰는 프로젝트에는 맞지 않는 스킬이 대량으로 설치된다.

**제안**:
- `--fe` 옵션을 더 세분화: `--fe react`, `--fe vue` 같은 서브옵션
- 또는 스킬을 "core"와 "optional"로 나눠서, `install.sh --skills react,tailwind,zustand` 같은 선택 설치 지원
- 장기적으로는 `skill.json` 같은 매니페스트로 스킬 의존성을 선언하는 방향

### 1-3. 에이전트 모델 지정의 경직성

**문제**: explore는 sonnet, code-writer/implementer는 opus, git-manager는 sonnet으로 고정되어 있다. 사용자의 Claude Code 플랜이나 비용 선호에 따라 모델을 조정할 수 없다.

**제안**: CLAUDE.md에서 에이전트별 모델을 설정 가능하게 하거나, "비용 최적화 모드"를 추가. 예: `code-writer`를 sonnet으로 돌리는 옵션.

---

## 2. install.sh 개선점

### 2-1. settings.json 덮어쓰기 문제 (Critical)

**문제**: `copy_common()`에서 `copy_file "settings.json"`을 하면 사용자의 **기존 settings.json이 통째로 교체**된다. 사용자가 이미 다른 hook이나 설정을 가지고 있으면 날아간다.

매니페스트 기반으로 "사용자 수정 감지"를 하지만, **첫 설치 시 기존 settings.json이 있으면 매니페스트 기록 없이 무조건 덮어쓴다** (188번 라인: "매니페스트에 기록 없음 → 그냥 복사").

**제안**: settings.json은 단순 복사가 아닌 **머지** 전략이 필요하다. 기존 hooks 배열에 prompt-hook을 추가하는 방식으로 변경. `jq` 등을 활용:
```bash
# 기존 settings.json이 있으면 hook만 추가
if [ -f "$TARGET_DIR/settings.json" ]; then
  jq '.hooks.UserPromptSubmit += [{"matcher":"","hooks":[{"type":"command","command":".claude/hooks/prompt-hook.sh"}]}]' \
    "$TARGET_DIR/settings.json" > tmp && mv tmp "$TARGET_DIR/settings.json"
fi
```

### 2-2. 빈 디렉토리 정리 누락

**문제**: 오래된 파일 정리 시 파일만 삭제하고 빈 디렉토리는 남는다. 예: `skills/OldSkill/` 안의 파일은 삭제되지만 빈 폴더가 남는다.

**제안**: 파일 삭제 후 빈 디렉토리도 정리:
```bash
find "$TARGET_DIR/skills" -type d -empty -delete 2>/dev/null
```

### 2-3. 에러 메시지가 한국어 전용

**문제**: npm 패키지로 배포하면서 모든 메시지가 한국어다. 글로벌 사용자를 고려하면 영어가 기본이어야 한다.

**제안**: i18n까지는 아니더라도, 최소한 영어 기본 + 한국어 옵션(`--lang ko`) 또는 README에 한국어 버전 별도 제공.

### 2-4. --uninstall 옵션 없음

**문제**: 설치 기능만 있고 제거 기능이 없다. 매니페스트가 있으므로 깔끔한 제거가 가능한데 활용하지 않고 있다.

**제안**: `--uninstall` 옵션 추가. 매니페스트에 기록된 파일만 삭제.

---

## 3. Hook (prompt-hook.sh) 개선점

### 3-1. python3 의존성

**문제**: Skill Detector에서 JSON 파싱을 위해 `python3`을 사용한다 (27번 라인). python3이 없는 환경에서는 fallback으로 raw input을 그대로 쓰는데, 이 경우 JSON 전체가 `PROMPT`에 들어가서 키워드 매칭이 오염된다.

**제안**: `jq`를 사용하거나, bash 순수 파싱으로 교체:
```bash
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "$INPUT")
```

### 3-2. 버블소트 성능

**문제**: 스킬 스코어 정렬에 O(n²) 버블소트를 사용한다 (62-71번 라인). 스킬이 16개 정도라 지금은 문제없지만, 확장 시 비효율적.

**제안**: 당장은 괜찮지만, `sort` 명령으로 교체하면 더 깔끔:
```bash
# score|index 형태로 sort
sorted=$(for i in "${!SKILL_SCORES[@]}"; do echo "${SKILL_SCORES[$i]}|$i"; done | sort -rn -t'|' -k1)
```

### 3-3. Quality Gate 메시지가 매번 출력

**문제**: 모든 프롬프트에 Quality Gate 메시지가 주입된다. 단순 질문("이 함수 뭐하는 거야?")에도 "티어 판단 → Task Header 출력"을 요구한다.

**제안**: 질문/대화형 프롬프트를 구분하는 로직 추가. 예: 프롬프트에 "만들어", "구현", "추가", "수정", "삭제" 등 작업 키워드가 있을 때만 Quality Gate 출력.

### 3-4. /skill 명령어 포맷 불일치

**문제**: Skill Detector 출력에서 `/skill React` 같은 형태로 추천하는데, Claude Code에서 `/skill`은 실제 명령어가 아니다. Claude Code의 스킬은 `Read`로 SKILL.md를 읽는 방식이다.

**제안**: 추천 포맷을 실제 사용 방식으로 변경:
```
- React: Read .claude/skills/React/SKILL.md
```

---

## 4. 스킬 파일 개선점

### 4-1. 스킬 간 중복 내용

**문제**: 여러 스킬에서 같은 내용이 반복된다:
- `NestJS/SKILL.md`에 validation, auth, caching이 요약되어 있고, 동시에 `references/`에도 상세 내용 존재
- `Coding/SKILL.md`의 SRP, 네이밍 컨벤션이 다른 스킬에서도 반복 언급
- `Git/SKILL.md`와 `git-manager.md` 에이전트의 커밋 규칙이 중복

**제안**: 스킬 간 참조 관계를 명확히 하고, 중복 제거. "이 주제의 상세 내용은 X를 참조" 패턴 일관 적용.

### 4-2. 스킬 버전/갱신 날짜 없음

**문제**: 각 스킬에 작성일/수정일이 없어서, 내용이 최신 버전의 라이브러리를 반영하는지 알 수 없다. 예: TanStack Query v5, Next.js 15, Tailwind v4 등의 변경사항이 반영되었는지 불분명.

**제안**: 각 SKILL.md frontmatter에 `version`, `lastUpdated`, `targetLib` 필드 추가:
```yaml
---
name: TanStackQuery
targetLib: "@tanstack/react-query@5"
lastUpdated: 2025-03-01
---
```

### 4-3. FailureRecovery 스킬이 너무 얇음

**문제**: 47줄로 가장 짧은 스킬이다. 분류표와 3단계 프로토콜만 있고, 실제 적용 예시가 없다.

**제안**: 실제 실패 사례와 처방 예시를 추가. 예: "TypeORM migration 실패 시", "React hydration mismatch 시" 등 구체적 시나리오.

### 4-4. Database 스킬에 Prisma/Drizzle 부재

**문제**: TypeORM 전용 스킬은 있지만, 최근 트렌드인 Prisma나 Drizzle에 대한 스킬이 없다. Database/SKILL.md는 일반 DB 설계만 다룬다.

**제안**: Database 스킬을 ORM-agnostic하게 유지하되, TypeORM 외 ORM 스킬을 optional로 추가할 수 있는 구조 마련.

---

## 5. 에이전트 프롬프트 개선점

### 5-1. code-writer와 implementer의 역할 중복

**문제**: `code-writer-fe`와 `implementer-fe`의 차이가 "테스트 작성 포함 여부"뿐이다. 프롬프트 내용의 70%가 동일하다. BE도 마찬가지.

**제안**: 베이스 에이전트 프롬프트를 하나로 두고, 테스트 관련 부분만 조건부로 포함하는 구조. 또는 `code-writer`에 `--with-test` 플래그 개념을 도입.

### 5-2. explore 에이전트의 출력이 Main Agent에 최적화되지 않음

**문제**: explore의 출력 형식이 마크다운 테이블 기반인데, Main Agent가 이걸 파싱해서 다음 에이전트에 전달해야 한다. 구조화된 데이터(예: JSON)가 아니라 자연어 테이블이라 정보 손실 가능성이 있다.

**제안**: explore 출력에 기계 파싱 가능한 섹션을 추가:
```
### Machine-Readable
TIER: M
SKILLS: React(.claude/skills/React/SKILL.md), TDD(.claude/skills/TDD/SKILL.md)
AGENT_FLOW: code-writer-fe -> git-manager
FILES: 3
```

### 5-3. code-reviewer 판정 기준이 모호

**문제**: PASS/NEEDS_FIX 이분법인데, "Warning이 몇 개까지 PASS인지" 기준이 없다.

**제안**: 명시적 기준 추가. 예: "Critical 0개 AND Warning 3개 이하 = PASS"

---

## 6. 프롬프트/스크립트 개선점

### 6-1. /feature, /fix, /review 프롬프트가 단순

**문제**: `/feature` 프롬프트는 5단계 워크플로우를 나열하지만, 구체적인 예시나 가드레일이 부족하다. `/fix`도 마찬가지.

**제안**: 각 프롬프트에 예시 시나리오를 포함. `/feature` 예시:
```
예시: /feature 댓글 기능
→ 티어 판단: M (단일 도메인, FE+BE지만 단순 CRUD)
→ explore → code-writer-be (Entity, Service, Controller) → code-writer-fe (컴포넌트)
```

### 6-2. generate-project-map.sh의 depth 제한

**문제**: `find` depth가 3으로 제한되어, 깊은 모노레포 구조에서는 중요한 파일을 놓칠 수 있다.

**제안**: depth를 설정 가능하게 하거나, `package.json`이 있는 워크스페이스를 자동 감지하여 각각의 PROJECT_MAP을 생성.

---

## 7. 패키징/배포 개선점

### 7-1. package.json에 engines 필드 없음

**문제**: Node.js 최소 버전 요구사항이 명시되지 않았다. `bin/cli.js`가 특별한 문법을 안 쓰긴 하지만, bash 스크립트에서 `declare -a`(bash 4+) 등을 사용한다.

**제안**: `"engines": { "node": ">=16" }` 추가, README에 bash 4+ 요구사항 명시.

### 7-2. npm audit/CI 파이프라인 없음

**문제**: 의존성이 없어서 audit은 불필요하지만, CI에서 install.sh 테스트를 자동화하면 좋겠다.

**제안**: GitHub Actions로 install.sh 스모크 테스트:
```yaml
- run: mkdir -p /tmp/test-project && cd /tmp/test-project && bash $GITHUB_WORKSPACE/install.sh
- run: diff <(ls .claude/skills/) <(expected_list)
```

### 7-3. CHANGELOG.md 자동화 없음

**문제**: CHANGELOG.md를 수동으로 관리한다. 배포 체크리스트에 있지만 실수로 빠뜨릴 수 있다.

**제안**: `standard-version`이나 `changesets` 도입, 또는 git-manager 에이전트에 CHANGELOG 업데이트 기능 추가.

---

## 8. 방향성 제안

### 단기 (다음 버전)

1. **settings.json 머지 로직** — 가장 위험한 버그, 즉시 수정 필요
2. **Quality Gate 조건부 출력** — 사용자 경험 개선
3. **/skill 명령어 포맷 수정** — 실제 동작과 일치시키기
4. **스킬 frontmatter에 버전/날짜 추가** — 유지보수 추적

### 중기 (v2.0)

1. **스킬 선택 설치** — `--skills react,tailwind` 방식
2. **code-writer/implementer 통합** — 중복 제거
3. **--uninstall 옵션** — 깔끔한 제거 지원
4. **explore 출력 구조화** — 에이전트 간 데이터 전달 정확도 향상

### 장기 (v3.0+)

1. **스킬 레지스트리** — 커뮤니티 스킬 공유/설치 (npm처럼)
2. **스택 프리셋** — `--preset nextjs-prisma`, `--preset remix-drizzle`
3. **프로젝트 분석 기반 자동 추천** — package.json을 읽어서 필요한 스킬 자동 제안
4. **성과 추적** — 티어별 작업 완료율, 에이전트 호출 횟수 등 메트릭

---

## 파일별 상세 점수

| 카테고리 | 파일 | 점수 | 핵심 이슈 |
|----------|------|------|----------|
| 코어 | .claude/CLAUDE.md | 9/10 | 티어 시스템 잘 설계, 문서 참조 가이드 유용 |
| 코어 | CLAUDE.md (루트) | 7/10 | 역할이 좁아서 굳이 분리할 필요가 있나 고민 |
| 설치 | install.sh | 7/10 | 매니페스트 좋음, settings.json 머지 누락이 치명적 |
| 설치 | bin/cli.js | 8/10 | 단순하고 명확 |
| 훅 | prompt-hook.sh | 6/10 | python 의존성, /skill 포맷 불일치, 무조건 출력 |
| 훅 | skill-keywords.conf | 8/10 | 확장 쉬운 구조, 키워드 커버리지 좋음 |
| 에이전트 | explore.md | 9/10 | 가장 완성도 높은 에이전트 프롬프트 |
| 에이전트 | code-writer-*.md | 7/10 | implementer와 70% 중복 |
| 에이전트 | implementer-*.md | 7/10 | code-writer와 70% 중복 |
| 에이전트 | code-reviewer.md | 7/10 | PASS/NEEDS_FIX 기준 모호 |
| 에이전트 | git-manager.md | 8/10 | 안전 규칙 잘 정의됨 |
| 스킬 | Coding/SKILL.md | 9/10 | 공통 원칙으로 훌륭, 예시 코드 적절 |
| 스킬 | React/SKILL.md | 8/10 | 실용적, 금지사항 명확 |
| 스킬 | NestJS/SKILL.md | 8/10 | 레이어 구조 명확, references 활용 좋음 |
| 스킬 | TypeScript/SKILL.md | 8/10 | 고급 패턴까지 커버, references 구성 우수 |
| 스킬 | TDD/SKILL.md | 8/10 | FE/BE 분리된 references 좋음 |
| 스킬 | DDD/SKILL.md | 8/10 | 전술적 패턴 잘 정리, references 3개로 깊이 있음 |
| 스킬 | Planning/SKILL.md | 7/10 | CLAUDE.md와 내용 중복 |
| 스킬 | FailureRecovery/SKILL.md | 5/10 | 너무 얇음, 실제 예시 부족 |
| 스킬 | Curation/SKILL.md | 7/10 | 좋은 관점이지만 짧음 |
| 스킬 | 기타 FE/BE 스킬 | 8/10 | 전반적으로 잘 작성됨 |
| 프롬프트 | feature/fix/review.md | 6/10 | 구조만 있고 예시/가드레일 부족 |
| 스크립트 | generate-project-map.sh | 7/10 | 실용적, depth 제한이 아쉬움 |

---

## 결론

이 툴킷의 핵심 가치는 **"Claude Code에게 일관된 워크플로우를 강제하는 것"**이다. 티어 시스템, 에이전트 위임 패턴, 스킬 기반 도메인 지식 주입이라는 3축이 잘 맞물려 있다.

가장 시급한 건 **settings.json 머지 로직**과 **hook의 무조건 출력 문제**다. 이 두 가지만 고쳐도 실사용 경험이 크게 좋아진다.

장기적으로는 "NestJS + React 전용 툴킷"에서 "스택 무관 Claude Code 프레임워크"로 진화하는 방향을 추천한다. 스킬 선택 설치와 커뮤니티 스킬 레지스트리가 그 열쇠다.
