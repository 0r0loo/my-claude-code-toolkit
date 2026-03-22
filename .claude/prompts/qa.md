웹 애플리케이션을 브라우저로 QA 테스트한다. browse 도구로 실제 브라우저를 조작하여 사용자처럼 테스트한다.

## 입력
- $ARGUMENTS: 테스트할 URL (없으면 자동 탐지)

---

## 사전 조건: browse 바이너리 확인

```bash
B=""
for p in ".claude/tools/browse/dist/browse" "$HOME/.claude/tools/browse/dist/browse"; do
  [ -x "$p" ] && B="$p" && break
done
if [ -z "$B" ]; then
  echo "NEEDS_SETUP"
else
  echo "READY: $B"
fi
```

**NEEDS_SETUP**이면:
```
browse 도구가 설치되지 않았습니다.

설치 방법:
  1. Bun 설치: curl -fsSL https://bun.sh/install | bash
  2. toolkit 재설치: npx @choblue/claude-code-toolkit --tools=browse

또는 수동 빌드:
  bash .claude/tools/browse/setup.sh
```
출력 후 **중단**한다.

---

## 모드

### Diff-aware (URL 없이 피처 브랜치에서 실행)
1. `git diff main...HEAD --name-only`로 변경 파일 분석
2. 변경된 파일에서 영향받는 라우트/페이지 식별
3. 로컬 앱 자동 탐지 (localhost:3000, 4000, 8080)
4. 영향받는 페이지만 집중 테스트

### Full (URL 지정)
지정 URL의 모든 도달 가능한 페이지를 체계적으로 탐색

---

## 테스트 절차

### Phase 1 — 초기 탐색 (Orient)

```bash
$B goto [URL]
$B snapshot -i          # 인터랙티브 요소 파악
$B console --errors     # JS 에러 체크
$B links                # 네비게이션 구조 파악
```

### Phase 2 — 페이지별 탐색 (Explore)

각 페이지에서:
```bash
$B goto [페이지 URL]
$B snapshot -i -a -o [스크린샷 경로]
$B console --errors
```

**탐색 체크리스트**:
1. 시각적 확인 — 레이아웃 이상, 깨진 이미지, 텍스트 잘림
2. 인터랙티브 요소 — 버튼, 링크 동작 확인
3. 폼 — 입력, 제출, 빈값/잘못된 값 테스트
4. 상태 — 빈 상태, 로딩, 에러, 오버플로우
5. 콘솔 — 인터랙션 후 새 JS 에러 발생 여부

### Phase 3 — 인터랙션 테스트

```bash
# 폼 테스트 예시
$B snapshot                    # 기준 스냅샷
$B fill @e3 "test@email.com"  # 입력
$B click @e5                   # 제출
$B snapshot -D                 # 변경사항 diff
$B console --errors            # 에러 확인
```

### Phase 4 — 반응형 확인 (선택)

```bash
$B viewport 375x812           # 모바일
$B screenshot /tmp/mobile.png
$B viewport 1280x720          # 데스크톱 복원
```

### Phase 5 — 이슈 문서화

이슈 발견 시 즉시 문서화한다. 나중에 모아서 하지 않는다.

**증거 수집**:
```bash
$B screenshot /tmp/issue-001-before.png   # 액션 전
$B click @e5                               # 액션
$B screenshot /tmp/issue-001-after.png     # 액션 후
$B snapshot -D                             # diff
```

### Phase 6 — QA 리포트

```
## QA Report — [URL]
테스트 시각: [현재 시각]

### 요약
- 테스트 페이지: [N]개
- 발견 이슈: Critical [N] / High [N] / Medium [N] / Low [N]

### Health Score: [N]/100
| 카테고리 | 점수 | 가중치 |
|----------|------|--------|
| Console (JS 에러) | [N] | 15% |
| Links (깨진 링크) | [N] | 10% |
| Visual (레이아웃) | [N] | 10% |
| Functional (기능) | [N] | 20% |
| UX (사용성) | [N] | 15% |
| Performance (성능) | [N] | 10% |
| Content (콘텐츠) | [N] | 5% |
| Accessibility (접근성) | [N] | 15% |

### 이슈 목록

#### ISSUE-001: [제목]
- 심각도: [Critical/High/Medium/Low]
- 위치: [페이지/요소]
- 재현 단계:
  1. ...
  2. ...
- 스크린샷: [경로]
- 콘솔 에러: [있으면 표시]

### Top 3 수정 권장
1. ...
2. ...
3. ...

### 판정: PASS / NEEDS_FIX
```

---

## Health Score 계산

각 카테고리 100점에서 시작, 이슈별 차감:
- Critical: -25
- High: -15
- Medium: -8
- Low: -3

최종 점수 = 각 카테고리 점수 x 가중치의 합

---

## 규칙

1. **증거 필수** — 모든 이슈에 스크린샷 최소 1장
2. **재현 확인** — 1회 재시도로 재현 가능 여부 확인 후 문서화
3. **소스 코드 읽지 않기** — 사용자처럼 테스트. 개발자 관점 X
4. **콘솔 항상 확인** — 인터랙션 후 `$B console --errors` 필수
5. **수정하지 않기** — 발견과 문서화만. 수정은 `/fix`로
6. **스크린샷 보여주기** — `$B screenshot` 후 Read 도구로 사용자에게 표시

---

## browse 주요 명령어 참조

| 명령 | 설명 |
|------|------|
| `$B goto [url]` | 페이지 이동 |
| `$B snapshot -i` | 인터랙티브 요소 목록 (@e1, @e2...) |
| `$B snapshot -D` | 이전 스냅샷과 diff |
| `$B snapshot -i -a -o [path]` | 요소 표시된 annotated 스크린샷 |
| `$B click @e3` | 요소 클릭 |
| `$B fill @e3 "value"` | 입력 필드 채우기 |
| `$B screenshot [path]` | 스크린샷 저장 |
| `$B console --errors` | JS 에러 확인 |
| `$B links` | 모든 링크 목록 |
| `$B viewport WxH` | 뷰포트 크기 변경 |
| `$B text` | 페이지 텍스트 추출 |
| `$B is visible ".selector"` | 요소 가시성 확인 |

---

## 예시

### /qa http://localhost:3000
로컬 앱 전체 QA

### /qa https://staging.myapp.com
스테이징 환경 QA

### /qa
(피처 브랜치에서) diff-aware 모드로 변경 관련 페이지만 QA
