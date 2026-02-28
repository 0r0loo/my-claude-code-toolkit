# Changelog

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
