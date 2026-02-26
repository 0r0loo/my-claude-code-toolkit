# Changelog

## 1.1.5

- **FEAT**: DDD 전술적 패턴 스킬 추가 (`skills/DDD/SKILL.md`)
  - Entity, Value Object, Aggregate, Repository, Domain Service, Domain Event 패턴
  - 레이어 구조 (Domain / Application / Infrastructure / Presentation)
  - Bad/Good 코드 예시로 실무 적용 가이드 제공
  - skill-keywords.conf에 DDD 키워드 매핑 추가
  - install.sh BE 설치에 DDD 스킬 포함

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
