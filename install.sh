#!/bin/bash
# install.sh - my-claude-code-toolkit을 .claude/에 설치한다
# Usage: ./install.sh [--global] [--fe] [--be]
#   기본값: 현재 디렉토리의 .claude/에 전체 설치 (프로젝트 로컬)
#   --global: ~/.claude/에 설치 (글로벌)
#   --fe: 공통 + 프론트엔드 스킬만 설치
#   --be: 공통 + 백엔드 스킬만 설치
#   --fe --be: 전체 설치 (= 기본값)

set -e

# 도움말 출력
usage() {
  echo "Usage: $0 [--global] [--fe] [--be]"
  echo ""
  echo "스택 선택:"
  echo "  (기본값)       전체 설치 (공통 + FE + BE)"
  echo "  --fe           공통 + 프론트엔드만 설치"
  echo "  --be           공통 + 백엔드만 설치"
  echo "  --fe --be      전체 설치 (= 기본값)"
  echo ""
  echo "설치 위치:"
  echo "  (기본값)       현재 디렉토리의 .claude/에 설치 (프로젝트 로컬)"
  echo "  --global       ~/.claude/에 설치 (글로벌)"
  echo ""
  echo "예시:"
  echo "  $0                    # 전체 설치 (로컬)"
  echo "  $0 --fe               # 공통 + FE만 (로컬)"
  echo "  $0 --be               # 공통 + BE만 (로컬)"
  echo "  $0 --global --fe      # 공통 + FE만 (글로벌)"
  exit 0
}

# 인자 파싱
INSTALL_MODE="local"
INSTALL_FE=false
INSTALL_BE=false

for arg in "$@"; do
  case "$arg" in
    --global)
      INSTALL_MODE="global"
      ;;
    --fe)
      INSTALL_FE=true
      ;;
    --be)
      INSTALL_BE=true
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

# --fe도 --be도 지정하지 않으면 둘 다 true (전체 설치)
if [ "$INSTALL_FE" = false ] && [ "$INSTALL_BE" = false ]; then
  INSTALL_FE=true
  INSTALL_BE=true
fi

# 스택 라벨 결정
if [ "$INSTALL_FE" = true ] && [ "$INSTALL_BE" = true ]; then
  STACK_LABEL="FE + BE (전체)"
elif [ "$INSTALL_FE" = true ]; then
  STACK_LABEL="FE만"
else
  STACK_LABEL="BE만"
fi

if [ -n "$PACKAGE_ROOT" ]; then
  SOURCE_DIR="$PACKAGE_ROOT/.claude"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  SOURCE_DIR="$SCRIPT_DIR/.claude"
fi

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
echo "스택:   $STACK_LABEL"
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

# === 헬퍼 함수 ===

# 개별 파일 복사 (상대경로 기준)
copy_file() {
  local rel_path="$1"
  local dir
  dir="$(dirname "$rel_path")"
  mkdir -p "$TARGET_DIR/$dir"
  cp "$SOURCE_DIR/$rel_path" "$TARGET_DIR/$rel_path"
  echo "  복사: $rel_path"
}

# 디렉토리 전체 복사 (상대경로 기준)
copy_dir() {
  local rel_path="$1"
  mkdir -p "$TARGET_DIR/$rel_path"
  cp -r "$SOURCE_DIR/$rel_path/"* "$TARGET_DIR/$rel_path/"
  echo "  복사: $rel_path/"
}

# === 복사 함수 ===

# 공통 (항상 설치)
copy_common() {
  echo "[공통]"

  # 루트 설정 파일
  copy_file "CLAUDE.md"
  copy_file "settings.json"

  # 공통 에이전트
  copy_file "agents/explore.md"
  copy_file "agents/code-reviewer.md"
  copy_file "agents/git-manager.md"

  # 공통 스킬
  copy_file "skills/Coding/SKILL.md"
  copy_dir "skills/TypeScript"
  copy_dir "skills/Git"
  copy_file "skills/TDD/SKILL.md"

  # hooks
  copy_dir "hooks"
  chmod +x "$TARGET_DIR/hooks/"*.sh
}

# FE (프론트엔드)
copy_fe() {
  echo "[FE]"

  # FE 에이전트
  copy_file "agents/code-writer-fe.md"
  copy_file "agents/test-writer-fe.md"

  # FE 스킬 (디렉토리 전체)
  copy_dir "skills/React"
  copy_dir "skills/NextJS"
  copy_dir "skills/TailwindCSS"
  copy_dir "skills/TanStackQuery"
  copy_dir "skills/Zustand"
  copy_dir "skills/ReactHookForm"

  # FE 개별 스킬 파일
  copy_file "skills/TDD/frontend.md"
  copy_file "skills/Coding/frontend.md"
}

# BE (백엔드)
copy_be() {
  echo "[BE]"

  # BE 에이전트
  copy_file "agents/code-writer-be.md"
  copy_file "agents/test-writer-be.md"

  # BE 스킬 (디렉토리 전체)
  copy_dir "skills/TypeORM"

  # BE 개별 스킬 파일
  copy_file "skills/Coding/backend.md"
  copy_file "skills/TDD/backend.md"
}

# === 실행 ===

echo "파일을 복사합니다..."
echo ""

# 공통은 항상 설치
copy_common
echo ""

# 선택된 스택 설치
if [ "$INSTALL_FE" = true ]; then
  copy_fe
  echo ""
fi

if [ "$INSTALL_BE" = true ]; then
  copy_be
  echo ""
fi

echo "=== 설치 완료 ($MODE_LABEL) ==="
echo ""
echo "스택: $STACK_LABEL"
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
