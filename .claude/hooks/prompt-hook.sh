#!/usr/bin/env bash
# prompt-hook.sh - UserPromptSubmit hook
# quality-gate + project-map-detector (Skills 2.0 자동 매칭으로 skill-detector 제거)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── stdin 읽기 (한 번만) ───
INPUT=$(cat)

# ─── JSON에서 prompt 필드 추출 ───
PROMPT=""
if command -v jq &>/dev/null; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
elif command -v python3 &>/dev/null; then
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)
fi
if [ -z "$PROMPT" ]; then
  # jq/python3 모두 없으면 sed fallback
  PROMPT=$(echo "$INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  [ -z "$PROMPT" ] && PROMPT="$INPUT"
fi
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ─── 1. Quality Gate (작업 키워드가 있을 때만) ───
ACTION_KEYWORDS="만들어|구현|추가|수정|삭제|리팩|refactor|변경|생성|fix|버그|개선|이동|제거|작성|빌드|배포|설치|업데이트|마이그|테스트 작성|연결|분리|통합|적용|개발"
if echo "$PROMPT_LOWER" | grep -qE "$ACTION_KEYWORDS"; then
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

# ─── 2. Project Map Detector ───
MAP_FILE="$CLAUDE_DIR/PROJECT_MAP.md"
CACHE_FILE="$CLAUDE_DIR/.project-map-cache"

if [ ! -f "$MAP_FILE" ]; then
  echo "[PROJECT_MAP] PROJECT_MAP.md가 없습니다: .claude/scripts/generate-project-map.sh"
elif git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)" || true

  if [[ -n "${CURRENT_HEAD:-}" ]]; then
    if [ -f "$CACHE_FILE" ]; then
      CACHED_HEAD="$(cat "$CACHE_FILE" 2>/dev/null)"
      if [ "$CURRENT_HEAD" != "$CACHED_HEAD" ]; then
        STRUCTURE_CHANGED=false
        ADD_DEL="$(git diff --name-status "$CACHED_HEAD" "$CURRENT_HEAD" 2>/dev/null | grep -E '^[ADR]' | head -20)" || true
        [ -n "$ADD_DEL" ] && STRUCTURE_CHANGED=true

        CONFIG_PATTERN="package\.json$|tsconfig\.json$|\.eslintrc|next\.config|vite\.config|nest-cli\.json|docker-compose"
        CONFIG_CHANGED="$(git diff --name-only "$CACHED_HEAD" "$CURRENT_HEAD" 2>/dev/null | grep -E "$CONFIG_PATTERN" | head -5)" || true
        [ -n "$CONFIG_CHANGED" ] && STRUCTURE_CHANGED=true

        printf '%s' "$CURRENT_HEAD" > "$CACHE_FILE"

        if [ "$STRUCTURE_CHANGED" = true ]; then
          echo "[PROJECT_MAP] 구조 변경 감지. 갱신 권장: .claude/scripts/generate-project-map.sh"
        fi
      fi
    else
      printf '%s' "$CURRENT_HEAD" > "$CACHE_FILE"
    fi
  fi
fi