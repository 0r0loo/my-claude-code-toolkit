새 기능 구현을 시작한다.

## 입력
- 기능명: $ARGUMENTS
- 관련 도메인: (사용자가 지정)

## 절차
1. 티어를 판단하라
2. PROJECT_MAP.md를 읽어라
3. 티어별 워크플로우를 따라라
4. 구현 후 DoD 체크리스트를 검증하라

## 예시

### 예시 1: /feature 댓글 기능
```
📋 게시글 댓글 기능 추가
⚡ M — 단일 도메인, CRUD
📚 APIDesign, TypeORM
🔄 implementer-be → implementer-fe → git-manager
📁 6 files (entity, dto, service, controller, component, hook)
```

### 예시 2: /feature 실시간 알림
```
📋 실시간 알림 시스템 구현
⚡ L — WebSocket 도입, FE+BE 동시 변경, 새 인프라 패턴
📚 NestJS, React, APIDesign
🔄 research.md → plan.md → 승인 → implementer-be → implementer-fe → code-reviewer → git-manager
📁 10+ files
📌 Plan:
  ○ Step 1: WebSocket Gateway 구현 (BE)
  ○ Step 2: 알림 Entity + Service (BE)
  ○ Step 3: 알림 UI 컴포넌트 (FE)
  ○ Step 4: 실시간 연결 + 상태 관리 (FE)
```