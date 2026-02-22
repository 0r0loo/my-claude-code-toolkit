#!/usr/bin/env bash
# Skill Detector Hook
# 사용자 프롬프트를 분석하여 관련 스킬을 자동 추천한다.
# UserPromptSubmit hook으로 등록하여 사용한다.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/skill-keywords.conf"

if [[ ! -f "$CONF_FILE" ]]; then
  exit 0
fi

# stdin에서 프롬프트 읽기 (JSON 형태: {"prompt": "..."})
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "$INPUT")

if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# 소문자 변환
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# 스킬별 점수 계산
declare -a SKILL_NAMES=()
declare -a SKILL_COMMANDS=()
declare -a SKILL_SCORES=()

while IFS= read -r line; do
  # 빈 줄, 주석 건너뛰기
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

# 매칭된 스킬이 없으면 침묵
if ((${#SKILL_NAMES[@]} == 0)); then
  exit 0
fi

# 점수 기준 내림차순 정렬 (상위 5개)
SORTED_INDICES=()
for i in "${!SKILL_SCORES[@]}"; do
  SORTED_INDICES+=("$i")
done

# 버블 정렬 (점수 내림차순)
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

# 상위 5개만
MAX=5
if ((${#SORTED_INDICES[@]} < MAX)); then
  MAX=${#SORTED_INDICES[@]}
fi

# 출력
echo "[Skill Detector]"
echo "프롬프트 분석 결과, 다음 스킬을 반드시 참조하라:"
for ((i = 0; i < MAX; i++)); do
  idx=${SORTED_INDICES[$i]}
  echo "- ${SKILL_NAMES[$idx]}: /skill ${SKILL_COMMANDS[$idx]}"
done
echo "구현 전에 위 스킬을 로드하여 패턴을 따르라."