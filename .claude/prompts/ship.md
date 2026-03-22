현재 브랜치를 릴리스한다. main 동기화 → 테스트 → 코드 리뷰 → PR 생성 순으로 진행한다.

## 입력
- 브랜치: 현재 브랜치 (또는 $ARGUMENTS로 지정)

## 파이프라인

각 Phase는 순서대로 실행한다. 실패 시 해당 Phase에서 멈추고 원인을 보고한다.

### Phase 1 — main 동기화 (Sync)
1. `git fetch origin main`으로 최신 main을 가져온다
2. 현재 브랜치와 main의 차이를 확인한다 (`git log origin/main..HEAD`)
3. 머지 충돌이 예상되면 사용자에게 알리고 중단한다
4. 충돌 없으면 Phase 2로 진행

### Phase 2 — 테스트 (Test)
1. `tester` 에이전트를 호출하여 현재 변경사항에 대한 테스트를 실행한다
2. 테스트 실패 시 → 실패 목록을 출력하고 **중단**
   ```
   ❌ Phase 2 실패: 테스트 [N]개 실패
   실패 목록:
   - [테스트명]: [에러 메시지]
   수정 후 /ship을 다시 실행하라
   ```
3. 전체 통과 시 Phase 3으로 진행

### Phase 3 — 코드 리뷰 (Review)
1. `code-reviewer` 에이전트를 호출하여 변경사항을 리뷰한다
2. 필수 수정 항목이 있으면 → **중단**
   ```
   ❌ Phase 3 실패: 필수 수정 [N]건
   - [파일:라인] 문제 설명
   수정 후 /ship을 다시 실행하라
   ```
3. 권장/제안 항목만 있으면 → 목록을 출력하고 Phase 4로 진행 (사용자 선택)

### Phase 4 — 커버리지 확인 (Coverage)
1. 커버리지 설정이 있는 경우에만 실행 (`jest --coverage` 또는 동등한 커맨드)
2. 커버리지 임계값 미달 시 → 경고 출력 후 사용자에게 계속 진행 여부 확인
   ```
   ⚠️ Phase 4 경고: 커버리지 [N]% (임계값: [M]%)
   계속 진행하시겠습니까? (yes/no)
   ```
3. 커버리지 설정이 없으면 이 Phase를 건너뛴다

### Phase 5 — PR 생성 (Pull Request)
1. `git-manager` 에이전트를 호출하여 PR을 생성한다
2. PR 제목/본문은 커밋 내역을 기반으로 자동 작성한다
3. PR URL을 출력한다
   ```
   ✅ 릴리스 파이프라인 완료
   PR: [URL]
   ```

## 실패 보고 형식

```
🚢 릴리스 파이프라인 — [브랜치명]

Phase 1 (Sync)    ✅
Phase 2 (Test)    ❌ ← 여기서 중단
Phase 3 (Review)  ⏸ 미실행
Phase 4 (Coverage)⏸ 미실행
Phase 5 (PR)      ⏸ 미실행

원인: [구체적인 실패 이유]
```

## 전체 성공 형식

```
🚢 릴리스 파이프라인 — [브랜치명]

Phase 1 (Sync)     ✅ main과 [N]커밋 차이
Phase 2 (Test)     ✅ [N]개 통과
Phase 3 (Review)   ✅ 필수 수정 없음
Phase 4 (Coverage) ✅ [N]% / ⏭ 건너뜀
Phase 5 (PR)       ✅ [PR URL]
```

## 예시

### /ship
현재 브랜치(`feature/user-auth`)를 대상으로 파이프라인 전체 실행

### /ship feature/payment
지정한 브랜치를 대상으로 파이프라인 실행
