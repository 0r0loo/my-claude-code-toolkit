#!/usr/bin/env bash
# project-map-detector.sh - PROJECT_MAP.md 구조 변경 감지 hook
# UserPromptSubmit hook으로 등록하여 매 프롬프트마다 실행된다.
# 구조 변경 감지 시 PROJECT_MAP.md 갱신을 안내한다.

# stdin으로 전달된 JSON을 읽어서 버린다 (hook 프로토콜 준수)
read -r INPUT 2>/dev/null || true

CLAUDE_DIR=".claude"
MAP_FILE="$CLAUDE_DIR/PROJECT_MAP.md"
CACHE_FILE="$CLAUDE_DIR/.project-map-cache"

# PROJECT_MAP.md 없으면 생성 안내
if [ ! -f "$MAP_FILE" ]; then
  echo "[PROJECT_MAP] PROJECT_MAP.md가 없습니다. 다음 명령으로 생성하세요:"
  echo "  .claude/scripts/generate-project-map.sh"
  exit 0
fi

# Git repo 아니면 조용히 종료
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  exit 0
fi

# 현재 HEAD 해시
CURRENT_HEAD="$(git rev-parse HEAD 2>/dev/null)" || exit 0

# 캐시 비교
if [ -f "$CACHE_FILE" ]; then
  CACHED_HEAD="$(cat "$CACHE_FILE" 2>/dev/null)"
  if [ "$CURRENT_HEAD" = "$CACHED_HEAD" ]; then
    # 캐시 히트 → 변경 없음
    exit 0
  fi
fi

# 캐시 미스 → git diff로 구조 변경 확인
# 이전 캐시가 없으면 현재 HEAD만 캐시하고 종료 (첫 실행)
if [ ! -f "$CACHE_FILE" ]; then
  printf '%s' "$CURRENT_HEAD" > "$CACHE_FILE"
  exit 0
fi

CACHED_HEAD="$(cat "$CACHE_FILE" 2>/dev/null)"

# 구조 변경 패턴 필터링
STRUCTURE_CHANGED=false

# 파일 추가/삭제/이동 감지 (A, D, R)
ADD_DEL="$(git diff --name-status "$CACHED_HEAD" "$CURRENT_HEAD" 2>/dev/null | grep -E '^[ADR]' | head -20)" || true

if [ -n "$ADD_DEL" ]; then
  STRUCTURE_CHANGED=true
fi

# 설정 파일 변경 감지
CONFIG_PATTERN="package\.json$|tsconfig\.json$|\.eslintrc|next\.config|vite\.config|nest-cli\.json|docker-compose"
CONFIG_CHANGED="$(git diff --name-only "$CACHED_HEAD" "$CURRENT_HEAD" 2>/dev/null | grep -E "$CONFIG_PATTERN" | head -5)" || true

if [ -n "$CONFIG_CHANGED" ]; then
  STRUCTURE_CHANGED=true
fi

# 캐시 업데이트
printf '%s' "$CURRENT_HEAD" > "$CACHE_FILE"

# 변경 감지 시 안내
if [ "$STRUCTURE_CHANGED" = true ]; then
  echo "[PROJECT_MAP] 프로젝트 구조 변경이 감지되었습니다. PROJECT_MAP.md 갱신을 권장합니다:"
  echo "  .claude/scripts/generate-project-map.sh"
fi