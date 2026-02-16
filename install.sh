#!/bin/bash
# install.sh - my-claude-code-toolkit을 .claude/에 설치한다
# Usage: ./install.sh [--global]
#   기본값: 현재 디렉토리의 .claude/에 설치 (프로젝트 로컬)
#   --global: ~/.claude/에 설치 (글로벌)

set -e

# 도움말 출력
usage() {
  echo "Usage: $0 [--global]"
  echo ""
  echo "  (기본값)   현재 디렉토리의 .claude/에 설치 (프로젝트 로컬)"
  echo "  --global   ~/.claude/에 설치 (글로벌)"
  exit 0
}

# 인자 파싱
INSTALL_MODE="local"
for arg in "$@"; do
  case "$arg" in
    --global)
      INSTALL_MODE="global"
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Error: 알 수 없는 옵션 '$arg'"
      usage
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude"

if [ "$INSTALL_MODE" = "global" ]; then
  TARGET_DIR="$HOME/.claude"
  BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d_%H%M%S)"
  MODE_LABEL="글로벌 설치 (~/.claude/)"
else
  TARGET_DIR="$(pwd)/.claude"
  BACKUP_DIR="$(pwd)/.claude-backup-$(date +%Y%m%d_%H%M%S)"
  MODE_LABEL="로컬 설치 ($(pwd)/.claude/)"
fi

echo "=== my-claude-code-toolkit 설치 ==="
echo ""
echo "모드:   $MODE_LABEL"
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Source 디렉토리 존재 확인
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: $SOURCE_DIR 디렉토리를 찾을 수 없습니다."
  exit 1
fi

# 기존 파일 백업
if [ -d "$TARGET_DIR" ]; then
  # 백업할 파일이 있는지 확인 (agents, skills, hooks, CLAUDE.md, settings.json)
  HAS_EXISTING=false
  for item in CLAUDE.md settings.json agents skills hooks; do
    if [ -e "$TARGET_DIR/$item" ]; then
      HAS_EXISTING=true
      break
    fi
  done

  if [ "$HAS_EXISTING" = true ]; then
    echo "기존 설정 파일이 발견되었습니다. 백업합니다..."
    mkdir -p "$BACKUP_DIR"
    for item in CLAUDE.md settings.json agents skills hooks; do
      if [ -e "$TARGET_DIR/$item" ]; then
        cp -r "$TARGET_DIR/$item" "$BACKUP_DIR/"
        echo "  백업: $item → $BACKUP_DIR/$item"
      fi
    done
    echo ""
    echo "백업 완료: $BACKUP_DIR"
    echo ""
  fi
else
  mkdir -p "$TARGET_DIR"
fi

# 파일 복사
echo "파일을 복사합니다..."

# CLAUDE.md
cp "$SOURCE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
echo "  복사: CLAUDE.md"

# settings.json
cp "$SOURCE_DIR/settings.json" "$TARGET_DIR/settings.json"
echo "  복사: settings.json"

# agents/
mkdir -p "$TARGET_DIR/agents"
cp -r "$SOURCE_DIR/agents/"* "$TARGET_DIR/agents/"
echo "  복사: agents/"

# skills/
mkdir -p "$TARGET_DIR/skills/Coding" "$TARGET_DIR/skills/Git"
cp -r "$SOURCE_DIR/skills/"* "$TARGET_DIR/skills/"
echo "  복사: skills/"

# hooks/
mkdir -p "$TARGET_DIR/hooks"
cp -r "$SOURCE_DIR/hooks/"* "$TARGET_DIR/hooks/"
chmod +x "$TARGET_DIR/hooks/"*.sh
echo "  복사: hooks/"

echo ""
echo "=== 설치 완료 ($MODE_LABEL) ==="
echo ""
echo "설치된 파일:"
echo "  $TARGET_DIR/CLAUDE.md"
echo "  $TARGET_DIR/settings.json"
echo "  $TARGET_DIR/agents/"
echo "  $TARGET_DIR/skills/"
echo "  $TARGET_DIR/hooks/"
echo ""
if [ "$INSTALL_MODE" = "global" ]; then
  echo "이제 어떤 프로젝트에서든 Claude Code를 실행하면 자동으로 적용됩니다."
else
  echo "현재 프로젝트($(pwd))에서 Claude Code를 실행하면 자동으로 적용됩니다."
  echo "다른 프로젝트에도 적용하려면 --global 옵션을 사용하세요."
fi
