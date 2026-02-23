# Changelog

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
