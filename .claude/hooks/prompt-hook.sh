#!/usr/bin/env bash
# prompt-hook.sh - 통합 UserPromptSubmit hook
# quality-gate + skill-detector + project-map-detector를 하나로 합친다.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── stdin 읽기 (한 번만) ───
INPUT=$(cat)

# ─── 1. Quality Gate ───
cat << 'EOF'
[Quality Gate] 티어를 판단하고 워크플로우를 따르라.
- S (1-2파일, 단순수정): Main Agent 직접 처리
- M (3-5파일, 명확한 기능): code-writer → git-manager
- L (6+파일, 설계 필요): 풀 프로세스 (TDD → 구현 → 리뷰)
EOF

# ─── 2. Skill Detector ───
CONF_FILE="${SCRIPT_DIR}/skill-keywords.conf"
if [[ -f "$CONF_FILE" ]]; then
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "$INPUT")

  if [[ -n "$PROMPT" ]]; then
    PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

    declare -a SKILL_NAMES=()
    declare -a SKILL_COMMANDS=()
    declare -a SKILL_SCORES=()

    while IFS= read -r line; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      SKILL_NAME=$(echo "$line" | cut -d'|' -f1)
      SKILL_CMD=$(echo "$line" | cut -d'|' -f2)
      KEYWORDS_STR=$(echo "$line" | cut -d'|' -f3)

      SCORE=0
      for keyword in $KEYWORDS_STR; do
        if [[ "$PROMPT_LOWER" == *"$keyword"* ]]; then
          SCORE=$((SCORE + 1))
        fi
      done

      if ((SCORE > 0)); then
        SKILL_NAMES+=("$SKILL_NAME")
        SKILL_COMMANDS+=("$SKILL_CMD")
        SKILL_SCORES+=("$SCORE")
      fi
    done < "$CONF_FILE"

    if ((${#SKILL_NAMES[@]} > 0)); then
      SORTED_INDICES=()
      for i in "${!SKILL_SCORES[@]}"; do
        SORTED_INDICES+=("$i")
      done

      for ((i = 0; i < ${#SORTED_INDICES[@]}; i++)); do
        for ((j = i + 1; j < ${#SORTED_INDICES[@]}; j++)); do
          idx_i=${SORTED_INDICES[$i]}
          idx_j=${SORTED_INDICES[$j]}
          if ((SKILL_SCORES[idx_j] > SKILL_SCORES[idx_i])); then
            SORTED_INDICES[$i]=$idx_j
            SORTED_INDICES[$j]=$idx_i
          fi
        done
      done

      MAX=5
      if ((${#SORTED_INDICES[@]} < MAX)); then
        MAX=${#SORTED_INDICES[@]}
      fi

      echo "[Skill Detector] 다음 스킬을 참조하라:"
      for ((i = 0; i < MAX; i++)); do
        idx=${SORTED_INDICES[$i]}
        echo "- ${SKILL_NAMES[$idx]}: /skill ${SKILL_COMMANDS[$idx]}"
      done
    fi
  fi
fi

# ─── 3. Project Map Detector ───
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