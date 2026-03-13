# 개선 계획서 — my-claude-code-toolkit

> 작성일: 2026-03-12
> 기반: review-report.md 분석 결과
> 원칙: 각 항목은 **독립적으로 작업 가능**하고, **구체적인 코드 변경 위치**를 명시한다.

---

## Phase 1: 긴급 수정 (v1.4.0)

이 Phase의 항목들은 현재 사용자에게 실질적 피해를 줄 수 있는 버그/문제다.

---

### 1-1. settings.json 머지 로직 도입

**파일**: `install.sh`
**문제**: `copy_file "settings.json"`이 기존 사용자의 settings.json을 통째로 덮어씀
**영향**: 사용자가 이미 추가한 다른 hook이나 설정이 날아감

**변경 방안**:

`copy_common()` 함수에서 `copy_file "settings.json"` 대신 전용 머지 함수를 호출한다.

```bash
# install.sh — copy_common() 안에서 settings.json 처리 부분을 교체

# 기존 (삭제)
copy_file "settings.json"

# 신규 (추가)
merge_settings_json
```

`merge_settings_json` 함수를 `copy_common()` 위에 추가:

```bash
# === settings.json 머지 ===
merge_settings_json() {
  local source_file="$SOURCE_DIR/settings.json"
  local target_file="$TARGET_DIR/settings.json"

  if [ ! -f "$target_file" ]; then
    # 기존 파일 없음 → 그냥 복사
    cp "$source_file" "$target_file"
    echo "  복사: settings.json"
  else
    # 기존 파일 있음 → hook이 이미 등록되어 있는지 확인
    if grep -q "prompt-hook.sh" "$target_file" 2>/dev/null; then
      echo "  건너뜀: settings.json (prompt-hook 이미 등록됨)"
    else
      # jq가 있으면 머지, 없으면 수동 안내
      if command -v jq &>/dev/null; then
        local HOOK_ENTRY='{"matcher":"","hooks":[{"type":"command","command":".claude/hooks/prompt-hook.sh"}]}'

        # 기존에 UserPromptSubmit 키가 있는지 확인
        if jq -e '.hooks.UserPromptSubmit' "$target_file" &>/dev/null; then
          # 배열에 추가
          jq --argjson entry "$HOOK_ENTRY" \
            '.hooks.UserPromptSubmit += [$entry]' \
            "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        else
          # hooks 객체가 없거나 UserPromptSubmit이 없으면 생성
          jq --argjson entry "$HOOK_ENTRY" \
            '.hooks.UserPromptSubmit = [$entry]' \
            "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        fi
        echo "  머지: settings.json (prompt-hook 추가)"
      else
        # jq 없음 → 백업 후 덮어쓰기 + 경고
        cp "$target_file" "${target_file}.bak"
        cp "$source_file" "$target_file"
        echo "  ⚠️  settings.json - 기존 파일 백업(.bak) 후 덮어씀 (jq 설치 시 머지 가능)"
      fi
    fi
  fi

  # 매니페스트에 기록
  local new_hash
  new_hash="$(file_hash "$target_file")"
  NEW_MANIFEST="${NEW_MANIFEST}${new_hash} settings.json"$'\n'
}
```

**테스트 방법**:
```bash
# Case 1: settings.json 없는 프로젝트
mkdir -p /tmp/test1 && cd /tmp/test1 && bash /path/to/install.sh
cat .claude/settings.json  # prompt-hook 포함 확인

# Case 2: 기존 settings.json이 있는 프로젝트
mkdir -p /tmp/test2/.claude && cd /tmp/test2
echo '{"hooks":{"PreToolUse":[{"matcher":"","hooks":[{"type":"command","command":"echo hi"}]}]}}' > .claude/settings.json
bash /path/to/install.sh
cat .claude/settings.json  # PreToolUse 유지 + UserPromptSubmit 추가 확인

# Case 3: 이미 prompt-hook이 있는 프로젝트
cd /tmp/test1 && bash /path/to/install.sh  # "건너뜀" 메시지 확인
```

---

### 1-2. prompt-hook.sh 조건부 Quality Gate

**파일**: `.claude/hooks/prompt-hook.sh`
**문제**: 모든 프롬프트에 Quality Gate가 무조건 출력됨 (질문에도 "티어 판단하라" 출력)

**변경 방안**:

Quality Gate 출력 전에 "작업 키워드 감지" 로직을 추가한다.

```bash
# prompt-hook.sh — 현재 14~22번 라인 (Quality Gate 출력) 을 교체

# 기존 (삭제):
# cat << 'EOF'
# [Quality Gate] 코드 작성 전 반드시 다음을 수행하라:
# ...
# EOF

# 신규 (교체):
# ─── 1. Quality Gate (작업 프롬프트에만) ───
PROMPT_FOR_CHECK=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "$INPUT")
PROMPT_LOWER_CHECK=$(echo "$PROMPT_FOR_CHECK" | tr '[:upper:]' '[:lower:]')

# 작업 키워드가 있을 때만 Quality Gate 출력
ACTION_KEYWORDS="만들어|구현|추가|수정|삭제|리팩|refactor|변경|생성|fix|버그|개선|이동|제거|작성|빌드|배포|설치|업데이트|마이그|테스트 작성|연결|분리|통합|적용|개발"
if echo "$PROMPT_LOWER_CHECK" | grep -qE "$ACTION_KEYWORDS"; then
  cat << 'EOF'
[Quality Gate] 코드 작성 전 반드시 다음을 수행하라:
1. 티어 판단 → Task Header 출력
   - S: 📋 ⚡ 📁
   - M: 📋 ⚡ 📚 🔄 📁
   - L: 📋 ⚡ 📚 🔄 📁 📌Plan
2. 관련 스킬이 있으면 반드시 Read한 후 규칙을 따르라
3. M 이상은 에이전트 위임을 우선하라. 직접 구현 시에도 스킬 규칙 필수
EOF
fi
```

**참고**: `PROMPT_FOR_CHECK`는 이후 Skill Detector에서도 재활용 가능하므로, Skill Detector에서 중복 파싱을 제거할 수 있다.

---

### 1-3. prompt-hook.sh python3 의존성 제거

**파일**: `.claude/hooks/prompt-hook.sh`
**문제**: JSON 파싱에 python3 의존. 없으면 raw JSON이 PROMPT에 들어가 키워드 매칭 오염

**변경 방안**:

27번 라인의 python3 파싱을 `jq` 우선 + bash fallback으로 교체한다.

```bash
# 기존 (삭제):
# PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "$INPUT")

# 신규 (교체):
if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
elif command -v python3 &>/dev/null; then
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)
fi
# jq도 python3도 없으면 raw input에서 prompt 필드만 추출 시도
if [ -z "$PROMPT" ]; then
  # JSON에서 "prompt":"..." 패턴을 sed로 추출 (단순 fallback)
  PROMPT=$(echo "$INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  [ -z "$PROMPT" ] && PROMPT="$INPUT"
fi
```

---

### 1-4. Skill Detector의 `/skill` 명령어 포맷 수정

**파일**: `.claude/hooks/prompt-hook.sh`
**문제**: 81번 라인에서 `/skill React` 형태로 출력하지만, Claude Code에 `/skill` 명령은 없음

**변경 방안**:

```bash
# 기존 (81번 라인):
echo "- ${SKILL_NAMES[$idx]}: /skill ${SKILL_COMMANDS[$idx]}"

# 신규:
echo "- ${SKILL_NAMES[$idx]}: Read .claude/skills/${SKILL_COMMANDS[$idx]}/SKILL.md"
```

---

## Phase 2: 구조 개선 (v1.5.0)

사용자 경험과 유지보수성을 크게 개선하는 항목들.

---

### 2-1. code-writer와 implementer 통합

**파일**: `agents/code-writer-fe.md`, `agents/implementer-fe.md`, `agents/code-writer-be.md`, `agents/implementer-be.md`
**문제**: code-writer와 implementer 내용의 ~70%가 동일. 유지보수 시 4개 파일을 동시에 수정해야 함

**변경 방안**:

code-writer를 삭제하고, implementer에 `--no-test` 모드 개념을 추가한다.

**Step 1**: `implementer-fe.md`에 모드 설명 추가 (상단):

```markdown
## 실행 모드

Main Agent가 위임 시 모드를 지정한다:

- **기본 모드 (M 티어)**: 구현만 수행. 테스트는 작성하지 않는다.
- **테스트 포함 모드 (L 티어)**: 구현 + 테스트를 동시에 수행한다.

Main Agent 위임 예시:
- M 티어: "UserCard 컴포넌트를 구현하라. 테스트 없이 구현만."
- L 티어: "UserCard 컴포넌트를 구현하고 테스트도 작성하라."
```

**Step 2**: `implementer-fe.md`의 "작업 절차"를 분기 처리:

```markdown
### 2. 구현 (기본 모드)
- 기존 패턴과 일관된 스타일로 구현 코드를 작성한다
- 구현 순서: 타입 → 훅 → 컴포넌트 → 페이지

### 2-A. 구현 + 테스트 (테스트 포함 모드)
- 구현 코드와 테스트를 함께 작성한다
- 테스트는 해당 구현 파일 작성 직후 바로 작성한다
```

**Step 3**: code-writer에 있던 FE 패턴 가이드 중 implementer에 빠진 부분 머지:
- `code-writer-fe.md`의 "커스텀 훅", "상태 관리", "에러 핸들링" 섹션을 `implementer-fe.md`에 추가
- `code-writer-be.md`의 "DTO 작성", "Service 레이어", "Controller 레이어" 섹션을 `implementer-be.md`에 추가

**Step 4**: `code-writer-fe.md`, `code-writer-be.md` 삭제

**Step 5**: `.claude/CLAUDE.md` 워크플로우 업데이트:
```
# 기존:
# M 티어 → code-writer 에이전트
# L 티어 → implementer 에이전트

# 신규:
# M 티어 → implementer 에이전트 (구현만)
# L 티어 → implementer 에이전트 (구현 + 테스트)
```

**Step 6**: 다음 파일도 함께 업데이트:
- `install.sh`: `copy_file "agents/code-writer-fe.md"` 등 삭제
- `skill-keywords.conf`: 변경 불필요 (에이전트는 키워드로 감지하지 않음)
- `prompts/feature.md`, `prompts/fix.md`: 에이전트 이름 참조 업데이트
- `README.md`: 에이전트 목록 업데이트

---

### 2-2. explore 출력에 기계 파싱 가능 섹션 추가

**파일**: `agents/explore.md`
**문제**: 출력이 마크다운 테이블이라 Main Agent가 파싱 시 정보 손실 가능

**변경 방안**:

출력 형식 끝에 구조화된 섹션을 추가한다.

```markdown
## 출력 형식

... (기존 마크다운 테이블 유지) ...

### Structured Summary (Main Agent용)
출력 마지막에 반드시 아래 포맷을 포함한다. Main Agent가 에이전트 위임 시 이 블록을 그대로 전달한다:

\`\`\`yaml
# Explore Result
tier: M
skills:
  - name: React
    path: .claude/skills/React/SKILL.md
    references:
      - .claude/skills/React/references/state-hooks.md
  - name: TDD
    path: .claude/skills/TDD/SKILL.md
    references:
      - .claude/skills/TDD/references/frontend.md
agent_flow:
  - implementer-fe
  - git-manager
estimated_files: 3
patterns:
  - "기존 컴포넌트는 src/components/domain/ 하위에 위치"
  - "커스텀 훅은 use + PascalCase 네이밍"
\`\`\`
```

---

### 2-3. code-reviewer PASS/NEEDS_FIX 기준 명확화

**파일**: `agents/code-reviewer.md`
**문제**: Warning이 몇 개까지 PASS인지 기준 없음

**변경 방안**:

92~94번 라인(규칙 섹션)을 교체:

```markdown
## 판정 기준

| 조건 | 판정 |
|------|------|
| Critical ≥ 1 | **NEEDS_FIX** |
| Warning ≥ 5 | **NEEDS_FIX** |
| Warning 1~4, Critical 0 | **PASS** (수정 권장 사항 명시) |
| Warning 0, Critical 0 | **PASS** |

- Lint/TypeScript 에러가 1건이라도 있으면 `NEEDS_FIX`
- Info는 판정에 영향을 주지 않는다
```

---

### 2-4. --uninstall 옵션 추가

**파일**: `install.sh`
**문제**: 설치만 있고 깔끔한 제거 기능이 없음

**변경 방안**:

인자 파싱에 `--uninstall` 추가하고, 매니페스트 기반 삭제 함수를 구현한다.

```bash
# 인자 파싱에 추가
UNINSTALL=false
# ... case 분기에 추가:
    --uninstall)
      UNINSTALL=true
      ;;

# 실행 섹션 시작 부분에 분기 추가
if [ "$UNINSTALL" = true ]; then
  uninstall_toolkit
  exit 0
fi

# uninstall 함수
uninstall_toolkit() {
  local manifest="$TARGET_DIR/.toolkit-manifest"
  if [ ! -f "$manifest" ]; then
    echo "Error: 매니페스트를 찾을 수 없습니다. ($manifest)"
    echo "수동으로 .claude/ 디렉토리를 확인하세요."
    exit 1
  fi

  echo "=== my-claude-code-toolkit 제거 ==="
  echo ""

  local count=0
  while IFS=' ' read -r hash filepath; do
    [ -z "$filepath" ] && continue
    if [ -f "$TARGET_DIR/$filepath" ]; then
      rm "$TARGET_DIR/$filepath"
      echo "  삭제: $filepath"
      count=$((count + 1))
    fi
  done < "$manifest"

  # 빈 디렉토리 정리
  find "$TARGET_DIR" -type d -empty -delete 2>/dev/null

  # 매니페스트 자체도 삭제
  rm "$manifest"

  # settings.json에서 prompt-hook 제거
  if [ -f "$TARGET_DIR/settings.json" ] && command -v jq &>/dev/null; then
    jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[].command | contains("prompt-hook.sh")))' \
      "$TARGET_DIR/settings.json" > "${TARGET_DIR}/settings.json.tmp" \
      && mv "${TARGET_DIR}/settings.json.tmp" "$TARGET_DIR/settings.json"
    echo "  정리: settings.json에서 prompt-hook 제거"
  fi

  echo ""
  echo "=== 제거 완료 ($count개 파일) ==="
}
```

---

### 2-5. 오래된 파일 삭제 후 빈 디렉토리 정리

**파일**: `install.sh`
**문제**: 326번 라인 이후에 빈 디렉토리가 남음

**변경 방안**:

326번 라인 `echo ""` 직전에 추가:

```bash
  # 빈 디렉토리 정리
  find "$TARGET_DIR/skills" -type d -empty -delete 2>/dev/null
  find "$TARGET_DIR/agents" -type d -empty -delete 2>/dev/null
```

---

### 2-6. 스킬 frontmatter에 버전/날짜 추가

**파일**: 모든 `skills/*/SKILL.md`
**문제**: 스킬이 어떤 라이브러리 버전을 기준으로 작성됐는지 알 수 없음

**변경 방안**:

각 SKILL.md frontmatter에 필드를 추가한다. 전체 목록:

```yaml
# React/SKILL.md
---
name: react
description: ...
targetLib: "react@18"
lastUpdated: 2025-03-01
---

# NextJS/SKILL.md
---
targetLib: "next@14"
lastUpdated: 2025-03-01
---

# TailwindCSS/SKILL.md
---
targetLib: "tailwindcss@3"
lastUpdated: 2025-03-01
---

# TanStackQuery/SKILL.md
---
targetLib: "@tanstack/react-query@5"
lastUpdated: 2025-03-01
---

# NestJS/SKILL.md
---
targetLib: "@nestjs/core@10"
lastUpdated: 2025-03-01
---

# TypeORM/SKILL.md
---
targetLib: "typeorm@0.3"
lastUpdated: 2025-03-01
---

# 라이브러리 무관 스킬 (Coding, TDD, DDD, Planning 등)
---
lastUpdated: 2025-03-01
---
```

이렇게 하면 나중에 `generate-project-map.sh`나 별도 스크립트에서 "이 프로젝트의 실제 버전 vs 스킬 기준 버전"을 비교하여 경고를 출력할 수 있다.

---

## Phase 3: 확장성 (v2.0.0)

스택 무관 프레임워크로 진화하기 위한 항목들.

---

### 3-1. 스킬 선택 설치 지원

**파일**: `install.sh`
**문제**: --fe/--be만 있어서 React+NestJS 외 스택에는 불필요한 스킬이 대량 설치됨

**변경 방안**:

`--skills` 옵션을 추가하여 개별 스킬을 선택 설치할 수 있게 한다.

```bash
# 인자 파싱에 추가
CUSTOM_SKILLS=""

# case 분기에 추가:
    --skills)
      shift
      CUSTOM_SKILLS="$1"
      ;;
    --skills=*)
      CUSTOM_SKILLS="${arg#*=}"
      ;;

# 실행 섹션에 분기 추가
if [ -n "$CUSTOM_SKILLS" ]; then
  echo "[커스텀 스킬]"
  copy_common_core  # CLAUDE.md, settings.json, hooks, scripts, agents/explore, agents/git-manager, Coding 스킬만
  IFS=',' read -ra SKILLS <<< "$CUSTOM_SKILLS"
  for skill in "${SKILLS[@]}"; do
    skill=$(echo "$skill" | xargs)  # trim
    if [ -d "$SOURCE_DIR/skills/$skill" ]; then
      copy_dir "skills/$skill"
    else
      echo "  ⚠️  스킬 '$skill'을 찾을 수 없습니다. (사용 가능: $(ls -1 "$SOURCE_DIR/skills/" | tr '\n' ', '))"
    fi
  done
  # 스킬에 맞는 에이전트도 설치
  install_agents_for_skills "$CUSTOM_SKILLS"
else
  # 기존 --fe/--be 로직
  copy_common
  ...
fi
```

**사용 예시**:
```bash
npx @choblue/claude-code-toolkit --skills React,TailwindCSS,Zustand
npx @choblue/claude-code-toolkit --skills NestJS,TypeORM,DDD
npx @choblue/claude-code-toolkit --skills React,NestJS  # 풀스택 최소
```

**함께 변경**: `copy_common()`을 `copy_common_core()` (최소 공통)과 `copy_common_full()` (전체 공통)으로 분리.

---

### 3-2. FailureRecovery 스킬 보강

**파일**: `.claude/skills/FailureRecovery/SKILL.md`
**문제**: 47줄로 가장 얇은 스킬. 구체적 시나리오 없음

**변경 방안**:

실제 실패 시나리오와 처방 예시를 추가한다.

```markdown
## 4. 흔한 실패 시나리오와 처방

### TypeORM Migration 실패
- **증상**: `QueryFailedError: relation "xxx" already exists`
- **원인**: 마이그레이션이 꼬여서 이미 적용된 마이그레이션을 재실행
- **처방**:
  1. `typeorm migration:show`로 적용 상태 확인
  2. 문제 마이그레이션의 down() 실행
  3. 마이그레이션 파일 수정 후 재실행

### React Hydration Mismatch
- **증상**: `Text content did not match. Server: "X" Client: "Y"`
- **원인**: SSR/CSR 결과 불일치 (Date, Math.random, window 접근 등)
- **처방**:
  1. 에러 메시지에서 불일치 위치 확인
  2. 해당 컴포넌트에서 서버/클라이언트 분기 코드 찾기
  3. `useEffect` + `useState`로 클라이언트 전용 값 처리
  4. 또는 `suppressHydrationWarning` (최후의 수단)

### NestJS Circular Dependency
- **증상**: `Nest can't resolve dependencies of the XService`
- **원인**: A→B→A 순환 참조
- **처방**:
  1. `@Inject(forwardRef(() => XService))` 임시 해결
  2. 근본적: 공통 로직을 별도 서비스로 추출하여 순환 제거
  3. 이벤트 기반으로 변경 (EventEmitter2)

### 빌드는 되지만 런타임 에러
- **증상**: `TypeError: Cannot read properties of undefined`
- **원인**: 타입 시스템을 우회하는 런타임 값 (API 응답, 옵셔널 체이닝 누락)
- **처방**:
  1. 에러 스택 트레이스에서 정확한 위치 확인
  2. 해당 값의 타입과 실제 런타임 값 비교
  3. 옵셔널 체이닝(`?.`) 또는 null guard 추가
  4. API 응답 타입과 실제 응답의 불일치면 DTO/타입 수정
```

---

### 3-3. Planning 스킬과 CLAUDE.md 중복 제거

**파일**: `.claude/skills/Planning/SKILL.md`, `.claude/CLAUDE.md`
**문제**: 티어 판단 기준, Task Header, 작업 분해 원칙이 양쪽에 중복됨

**변경 방안**:

`Planning/SKILL.md`를 "실행 가이드" 중심으로 재구성하고, CLAUDE.md에서는 요약만 유지한다.

**CLAUDE.md** (변경):
```markdown
## 1. 작업 복잡도 티어

> 상세 기준과 템플릿: `.claude/skills/Planning/SKILL.md` 참조

| 티어 | 기준 | 워크플로우 |
|------|------|-----------|
| S | 단순 수정 | Main Agent 직접 |
| M | 단일 레이어 | Task Header → implementer → git-manager |
| L | 설계 필요 | research.md → plan.md → 승인 → implementer |
```

**Planning/SKILL.md** (유지, 정본 역할):
- 티어 판단 기준 (상세)
- Task Header 템플릿
- 작업 분해 원칙 + 예시
- plan.md / research.md 작성 가이드

---

### 3-4. 프롬프트(/feature, /fix, /review) 예시 보강

**파일**: `.claude/prompts/feature.md`, `.claude/prompts/fix.md`, `.claude/prompts/review.md`

**변경 방안**:

각 프롬프트에 "예시 시나리오" 섹션을 추가한다.

**feature.md 추가**:
```markdown
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
```

**fix.md 추가**:
```markdown
## 예시

### /fix 로그인 후 리다이렉트 안 됨
1. 에러/증상 분석: "로그인 성공 후 / 페이지에 머묾"
2. 탐색: auth 관련 코드, redirect 로직 검색
3. 원인: `router.push`가 `await` 없이 호출 → 상태 업데이트 전 리다이렉트
4. 범위: S (auth.ts 파일 1개)
5. 직접 수정 후 확인
```

---

### 3-5. package.json에 engines 필드 추가

**파일**: `package.json`

**변경 방안**:
```json
{
  "engines": {
    "node": ">=16"
  }
}
```

---

### 3-6. generate-project-map.sh depth 설정 가능하게

**파일**: `.claude/scripts/generate-project-map.sh`
**문제**: find depth가 3으로 고정

**변경 방안**:

인자로 depth를 받을 수 있게 한다.

```bash
# 기존:
# DEPTH=3

# 신규:
DEPTH=${1:-3}  # 첫 번째 인자가 없으면 기본값 3
```

사용: `.claude/scripts/generate-project-map.sh 5`

---

## Phase 4: 장기 비전 (v3.0+)

구조적 변화가 필요한 큰 방향성 제안. 상세 설계는 착수 시점에 진행한다.

---

### 4-1. 스킬 레지스트리 (커뮤니티 스킬 공유)

**아이디어**: npm처럼 스킬을 공유/설치할 수 있는 생태계

```bash
# 상상 속 UX
npx @choblue/claude-code-toolkit add-skill @community/prisma-skill
npx @choblue/claude-code-toolkit add-skill @community/remix-skill
```

**필요한 것**: 스킬 패키지 포맷 표준화, 레지스트리 서버 (또는 GitHub 기반), 의존성 관리

---

### 4-2. 스택 프리셋

```bash
npx @choblue/claude-code-toolkit --preset nextjs-prisma
npx @choblue/claude-code-toolkit --preset remix-drizzle
npx @choblue/claude-code-toolkit --preset nestjs-typeorm  # 현재 기본값
```

**필요한 것**: 프리셋 정의 파일 (`presets/nextjs-prisma.json`), 스킬 선택 설치(3-1)가 선행 필요

---

### 4-3. 프로젝트 자동 분석 → 스킬 추천

```bash
npx @choblue/claude-code-toolkit --auto
# → package.json을 읽고 → react, tailwind, prisma 감지 → 해당 스킬만 설치
```

**필요한 것**: 패키지명→스킬 매핑 테이블, 스킬 선택 설치(3-1)가 선행 필요

---

## 작업 순서 요약

```
Phase 1 (v1.4.0) — ✅ 완료
├── ✅ 1-1. settings.json 머지
├── ✅ 1-2. Quality Gate 조건부 출력
├── ✅ 1-3. python3 의존성 제거
└── ✅ 1-4. /skill 포맷 수정

Phase 2 (v1.4.0) — ✅ 완료
├── ✅ 2-1. code-writer/implementer 통합
├── ✅ 2-2. explore 출력 구조화
├── ✅ 2-3. code-reviewer 기준 명확화
├── ✅ 2-4. --uninstall 옵션
├── ✅ 2-5. 빈 디렉토리 정리
└── ✅ 2-6. 스킬 frontmatter 버전 추가

Phase 3 (v1.4.0) — ✅ 완료
├── ✅ 3-1. --skills 선택 설치
├── ✅ 3-2. FailureRecovery 보강
├── ✅ 3-3. Planning/CLAUDE.md 중복 제거
├── ✅ 3-4. 프롬프트 예시 보강
├── ✅ 3-5. engines 필드 추가
└── ✅ 3-6. generate-project-map depth

추가 완료:
├── ✅ GitHub Actions CI 추가
└── ✅ install.sh 에러 메시지 영어화
```
