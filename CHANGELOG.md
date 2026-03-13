# Changelog

## 1.4.0

### Phase 1: 긴급 수정
- **FIX**: settings.json 머지 로직 도입 — 기존 사용자 설정을 보존하며 hook만 추가
- **FIX**: Quality Gate 조건부 출력 — 작업 키워드 감지 시에만 출력 (질문에는 미출력)
- **FIX**: prompt-hook JSON 파싱 python3 의존 제거 — jq > python3 > sed 3단계 fallback
- **FIX**: Skill Detector 출력 `/skill X` → `Read .claude/skills/X/SKILL.md`로 수정

### Phase 2: 구조 개선
- **REFACTOR**: code-writer/implementer 통합 (4파일 → 2파일)
  - implementer에 실행 모드 분기 추가 (M: 구현만, L: 구현+테스트)
  - code-writer 고유 콘텐츠(상태 관리, 에러 핸들링, DTO 작성 등) implementer에 머지
- **FEAT**: explore 출력에 Structured Summary(yaml 블록) 추가
- **FEAT**: code-reviewer PASS/NEEDS_FIX 판정 기준 테이블 명확화
- **FEAT**: install.sh `--uninstall` 옵션 추가 (매니페스트 기반 제거)
- **FIX**: 오래된 파일 삭제 후 빈 디렉토리 자동 정리
- **FEAT**: 전체 스킬 frontmatter에 targetLib/lastUpdated 추가

### Phase 3: 확장성
- **FEAT**: install.sh `--skills=React,TailwindCSS` 선택 설치 지원
  - `copy_common_core()` 분리 (최소 공통)
  - 스킬에 맞는 에이전트 자동 설치
- **FEAT**: FailureRecovery 스킬에 4개 실패 시나리오/처방 추가
- **REFACTOR**: Planning/CLAUDE.md 중복 제거 (CLAUDE.md는 요약, Planning이 정본)
- **FEAT**: /feature, /fix 프롬프트에 구체적 예시 추가
- **FEAT**: package.json engines 필드 추가 (node>=16)
- **FEAT**: generate-project-map.sh depth 인자 지원

## 1.3.2

- **FEAT**: 서브에이전트 스킬 전달 체계 구축
  - code-writer-be/fe, implementer-be/fe에 "Main Agent가 전달한 스킬 경로 Read 필수" 규칙 추가
  - CLAUDE.md M/L 워크플로우에 위임 시 스킬 경로 전달 필수 명시
- **FEAT**: Coding 스킬에 상수 관리 규칙 추가
  - 매직 넘버/스트링 금지 → 의미 있는 상수로 추출
  - 상수 분리 기준 (모듈 내 vs 공유 디렉토리)
  - `as const` 활용 (리터럴 타입 보장 + 유니온 타입 추출)
- **FIX**: APIDesign 스킬 응답 래핑 규칙 보강
  - 개별 핸들러 수동 래핑 금지 → 프레임워크 공통 응답 처리 계층에서 일괄 적용
  - 인프라 엔드포인트(health, version)는 `data` 래핑 대상 제외

## 1.3.1

- **FEAT**: explore 에이전트 강화 (haiku → sonnet)
  - 코드 탐색 + 기존 패턴 파악 + 스킬 식별 + 티어 판단 + 에이전트 흐름 권장
  - Main Agent가 바로 실행할 수 있는 수준의 컨텍스트 반환
  - CLAUDE.md M/L 워크플로우에 explore 기반 의사결정 반영
- **STYLE**: README 설치 섹션을 상단으로 이동

## 1.3.0

- **FEAT**: BE 스킬 확장
  - NestJS references 추가: 인증/인가(auth.md), 유효성 검증(validation.md), 캐싱(caching.md)
  - Auth 독립 스킬 → NestJS/references/auth.md로 이동
- **FEAT**: 공통 스킬 추가
  - APIDesign: REST API 설계 원칙 (URL, 응답 포맷, 에러 코드, 페이지네이션)
    - 응답: 모든 성공을 `data`로 감싸기, 목록은 `data` + `meta`
    - 에러: `field` + `reason` 구조 (FE 폼 setError 직접 매핑)
    - DELETE는 200 + 삭제 리소스 id 반환 (FE 캐시 무효화용)
  - Database: DB 설계 & 최적화 (정규화, 인덱싱, N+1, Soft Delete, 커넥션 풀)

## 1.2.9

- **FEAT**: SVG Icon 생성 스킬 추가 (`SVGIcon/SKILL.md`)
  - Stroke 기반 24x24 디자인 시스템용 아이콘 규격
  - React 컴포넌트 래핑 패턴 (개별 컴포넌트 + 팩토리)
  - 접근성, 파일 구조, 자주 쓰는 경로 레퍼런스
- **FIX**: Hook 메시지 강화 (스킬 규칙 준수율 개선)
  - Quality Gate: 3단계 명시 (티어 판단 → 스킬 Read → 에이전트 위임)
  - Skill Detector: "참조하라" → "Read하고 규칙을 따르라"
  - M 이상 직접 구현 시에도 스킬 규칙 필수 명시

## 1.2.8

- **FIX**: install.sh 파일 경로 오류 수정
  - references/ 구조 반영 (`copy_file` → `copy_dir` 변경)
  - 삭제된 파일 참조 제거 (Coding/frontend.md, Coding/backend.md, TDD 개별 파일)
  - 누락된 스킬/디렉토리 추가 (NestJS, FailureRecovery, Curation, prompts)
- **FIX**: Task Header를 코드블록으로 감싸 메시지와 시각적 구분
  - CLAUDE.md, Planning 스킬의 Task Header 예시를 코드블록 형식으로 변경
- **FEAT**: 루트 CLAUDE.md 추가 (install.sh 동기화 규칙 + 배포 체크리스트)
- **DEPRECATE**: v1.2.7 (install.sh 오류로 설치 실패)

## 1.2.7

- **FEAT**: Task Header 의사결정 가시화
  - 모든 티어에서 이모지 기반 Task Header 출력 (📋⚡📚🔄📁📌)
  - L 티어 Plan 진행 상태: ○ 대기 → ▶ ⏳ 진행 중 → ✔ 완료
  - hook에 Task Header 출력 리마인더 추가
- **REFACTOR**: 스킬 파일 references 분리
  - React, NextJS, TailwindCSS, ReactHookForm, TDD 스킬의 심화 내용을 references/로 분리
  - SKILL.md는 핵심 규칙만 유지 (200줄 이하)
- **REFACTOR**: NestJS 독립 스킬 분리
  - Coding/backend.md → NestJS/SKILL.md로 승격
  - Coding/frontend.md 삭제 (deprecated)
- **FIX**: Props 타입 선언을 interface에서 type으로 변경
  - React, TailwindCSS, ReactHookForm 스킬의 예제 코드 통일

## 1.2.6

- **FEAT**: 실패 복구 프로토콜 스킬 추가 (`FailureRecovery/SKILL.md`)
  - 실패 분류표 (방향 오류, 패턴 불일치, 부분 구현, 에러, 반복 실패)
  - 진단 -> 처방 -> 재시도 사이클, 에스컬레이션 기준
- **FEAT**: AI 결과물 큐레이션 스킬 추가 (`Curation/SKILL.md`)
  - AI스러움 제거, 실용성, 일관성 체크리스트
  - 리뷰 우선순위 가이드
- **FEAT**: 커스텀 슬래시 커맨드 템플릿 추가 (`prompts/`)
  - `/feature [기능명]` - 새 기능 구현 워크플로우
  - `/fix [증상]` - 버그 수정 워크플로우
  - `/review` - 변경사항 리뷰 워크플로우
- **FEAT**: 완료 기준(DoD) 추가 (`CLAUDE.md`)
  - 공통 DoD: 타입 에러, 미사용 코드, 테스트, 패턴 일관성
  - FE/BE DoD는 프로젝트별 오버라이드 방식

## 1.2.5

- **FEAT**: 점진적 구현 원칙 추가
  - "한 번에 하나, 완전하게" — smallest deliverable unit 분해
  - 에이전트 1회 호출 당 파일 3개 이하 원칙
  - Planning 스킬에 단위별 작업 순서 예시 추가

## 1.2.4

- **FEAT**: React 스킬에 접근성(a11y) & UX 패턴 섹션 추가
  - 시맨틱 HTML (`<button>` 필수), aria-label, alt+width+height, focus-visible
  - 폼 접근성 (label, type, inputMode, autoComplete)
  - 파괴적 액션 확인, URL 파라미터 동기화, 리스트 가상화 (50개+)
- **FEAT**: TailwindCSS 스킬에 트랜지션 & 모션 섹션 추가
  - `transition-all` 금지 → 속성 명시, `motion-reduce:` 변형
  - 다크 모드 `color-scheme: dark` 가이드

## 1.2.3

- **FEAT**: React 스킬에 에러 처리 섹션 추가
  - 에러 경계(Boundary) 기반 일괄 처리 원칙
  - Error Boundary, early return 패턴, 전역 에러 처리 가이드
  - `useState` + `useEffect` 에러 관리 금지, try-catch 남발 금지
- **FEAT**: TanStack Query 스킬에 캐시 전략 가이드 추가
  - 데이터 유형별 staleTime 테이블 (Infinity ~ 0)
  - 도메인별 설정 예시, 실시간 데이터 폴링 패턴

## 1.2.2

- **FEAT**: L 티어 파일 기반 설계 워크플로우 추가
  - `research.md` → `plan.md` → 주석 사이클 → 구현 단계
  - Planning 스킬에 research.md, plan.md 템플릿 추가
  - 사용자 승인 전까지 구현 금지 규칙 명시

## 1.2.1

- **FIX**: install.sh에서 삭제된 test-writer 참조 수정
  - `test-writer-fe/be` → `implementer-fe/be`로 변경
  - Planning 스킬 복사 누락 수정

## 1.2.0

- **REFACTOR**: 작업 복잡도 티어 시스템 도입 (S/M/L)
  - 파일 수 대신 변경 영향도 기반 판단
  - S: Main Agent 직접 처리, M: code-writer 위임, L: 풀 프로세스
  - 풀스택 작업(FE+BE) 위임 순서 가이드 추가
- **REFACTOR**: Hook 통합 (3개 → 1개)
  - `quality-gate.sh` + `skill-detector.sh` + `project-map-detector.sh` → `prompt-hook.sh`
  - 매 프롬프트 프로세스 3회 → 1회로 감소
- **REFACTOR**: test-writer를 implementer로 통합
  - `test-writer-fe/be` 삭제 → `implementer-fe/be` 신규
  - 구현 + 테스트를 한 에이전트가 동시 수행 (L 티어)
  - 에이전트 프롬프트 크기 74% 감소 (16KB → 4KB)
- **FEAT**: Planning 스킬 추가 (`skills/Planning/SKILL.md`)
  - 티어 판단 체크리스트, 작업 분해 템플릿, 계획 출력 형식

## 1.1.6

- **FEAT**: Coding 스킬에 선언적 & 함수형 스타일 가이드 추가
- **REFACTOR**: DDD 스킬 Reference 파일 분리

## 1.1.5

- **FEAT**: DDD 전술적 패턴 스킬 추가 (`skills/DDD/SKILL.md`)
  - Entity, Value Object, Aggregate, Repository, Domain Service, Domain Event 패턴
  - 레이어 구조 (Domain / Application / Infrastructure / Presentation)
  - Bad/Good 코드 예시로 실무 적용 가이드 제공
  - skill-keywords.conf에 DDD 키워드 매핑 추가
  - install.sh BE 설치에 DDD 스킬 포함
- **FEAT**: Coding 스킬에 선언적 & 함수형 스타일 가이드 추가
- **REFACTOR**: DDD 스킬 Reference 파일 분리
  - SKILL.md 핵심만 유지 (747줄 → 약 570줄)
  - `references/entity-vo.md` - Entity + Value Object 심화 패턴
  - `references/aggregate-repository.md` - Aggregate + Repository 심화 패턴
  - `references/domain-events.md` - Domain Service + Domain Event 심화 패턴

## 1.1.4

- **FEAT**: PROJECT_MAP.md 자동 생성 시스템 추가
  - `generate-project-map.sh`: 프로젝트 구조를 캐싱하여 explore 에이전트 탐색 비용 절감
  - `project-map-detector.sh`: 구조 변경 감지 hook (파일 추가/삭제, 설정 파일 변경 시 갱신 안내)
  - explore 에이전트에 PROJECT_MAP.md 사전 체크 규칙 추가
  - install.sh에 scripts/ 디렉토리 복사 추가

## 1.1.3

- **FEAT**: 프롬프트 기반 스킬 자동 추천 hook 추가 (`skill-detector.sh`, `skill-keywords.conf`)
  - 사용자 프롬프트를 분석하여 관련 스킬을 자동 추천
  - 키워드 매핑을 conf 파일로 분리하여 확장성 확보
  - 매칭 없으면 침묵 (노이즈 방지)

## 1.1.2

- **STYLE**: TailwindCSS 스킬 클래스 가독성 개선

## 1.1.1

- **FEAT**: 에이전트/스킬 메타데이터 추가 및 스킬 구조 개선
- **FEAT**: 스마트 업데이트 메커니즘 추가
