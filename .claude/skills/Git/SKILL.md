# Git Skill - Git 규칙

커밋, PR, 브랜치 관련 규칙을 정의한다.

---

## 1. 커밋 메시지

### 형식
```
<PREFIX>: <설명>

<본문 (선택)>
```

### PREFIX
| PREFIX | 용도 | 예시 |
|--------|------|------|
| `FEAT` | 새로운 기능 | `FEAT: 사용자 인증 기능 추가` |
| `FIX` | 버그 수정 | `FIX: 로그인 리다이렉트 무한 루프 수정` |
| `REFACTOR` | 리팩토링 (기능 변경 없음) | `REFACTOR: OrderService 쿼리 최적화` |
| `CHORE` | 빌드, 설정, 의존성 | `CHORE: ESLint 설정 업데이트` |
| `DOCS` | 문서 변경 | `DOCS: API 문서 업데이트` |
| `TEST` | 테스트 추가/수정 | `TEST: UserService 단위 테스트 추가` |
| `STYLE` | 포매팅 (코드 변경 없음) | `STYLE: import 정렬` |

### 작성 원칙
- 설명은 한국어로, 명령형으로 작성한다
- 본문은 "왜" 변경했는지를 설명한다
- 하나의 커밋은 하나의 논리적 변경만 포함한다

---

## 2. 브랜치 전략

### 형식
```
<type>/<description>
```

### 타입
| 타입 | 용도 |
|------|------|
| `feat/` | 기능 개발 |
| `fix/` | 버그 수정 |
| `refactor/` | 리팩토링 |
| `chore/` | 설정/환경 |

### 예시
```
feat/user-authentication
fix/login-redirect-loop
refactor/order-service-cleanup
```

---

## 3. PR 템플릿

### 제목
- 70자 이내
- PREFIX 포함 (e.g., "FEAT: 사용자 인증 기능 추가")

### 본문
```markdown
## Summary
- 변경 내용을 1-3개 bullet point로 요약

## Changes
- 주요 변경 사항 상세 설명

## Test Plan
- [ ] 테스트 항목 1
- [ ] 테스트 항목 2
```

---

## 4. 스테이징 규칙

- **`git add -A` 또는 `git add .`는 절대 사용하지 않는다**
- 변경된 파일을 하나씩 확인하고 관련 파일만 스테이징한다
- `.env`, credentials, 대용량 바이너리는 스테이징하지 않는다

---

## 5. 금지 사항

- `git push --force` (명시적 요청 없이)
- `git reset --hard` (명시적 요청 없이)
- `main`/`master` 브랜치에 직접 push
- 커밋 시 `--no-verify` 사용
- 빈 커밋 생성