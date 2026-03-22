# TODOS

## Phase 2 — 멀티 스택 확장

### 모노레포 감지 추가
- **What**: monorepo workspace (nx, turborepo, pnpm workspace) 감지 시 하위 패키지별 스택 감지
- **Why**: 모노레포 프로젝트에서 init이 잘못 감지할 수 있음
- **Context**: confidence threshold이 0.5 미만이면 수동 선택으로 fallback하므로 시급하지는 않음. 모노레포 루트에서 실행하면 모든 workspace의 package.json을 스캔하여 union으로 감지해야 함
- **Depends on**: manifest 기반 감지 인프라 (v1.13.0에서 완료)

### CLAUDE.md 마커 손상 복구
- **What**: 사용자가 CLAUDE.md의 마커 코멘트를 실수로 삭제했을 때 재설치 시 복구하는 로직
- **Why**: F4 failure mode — 마커가 없으면 동적 갱신이 조용히 실패
- **Context**: 현재는 마커 없으면 경고만 출력하고 건너뜀. 복구 로직은 CLAUDE.md 템플릿에서 마커 섹션을 추출하여 재삽입하는 방식이 적절
- **Depends on**: CLAUDE.md 마커 구현 (v1.13.0에서 완료)

### 신규 스택 팩 — Python
- **What**: Python (FastAPI/Django) 스택 팩 manifest + 스킬 추가
- **Why**: 멀티 스택 비전의 첫 검증 — React/NestJS 외 스택 지원 확인
- **Context**: manifest.json 스펙에 fileContains 필드로 requirements.txt/pyproject.toml 내 패키지 감지 가능. 스킬 콘텐츠는 새로 작성 필요
- **Depends on**: manifest 기반 감지 인프라

### 신규 스택 팩 — Vue
- **What**: Vue.js 스택 팩 manifest + 스킬 추가
- **Why**: FE 생태계 확장 — React 외 프레임워크 커버
- **Depends on**: manifest 기반 감지 인프라
