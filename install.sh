#!/usr/bin/env bash
# install.sh - my-claude-code-toolkit을 .claude/에 설치한다
# Usage: ./install.sh [--global] [--fe] [--be] [--force]
#   기본값: 현재 디렉토리의 .claude/에 전체 설치 (프로젝트 로컬)
#   --global: ~/.claude/에 설치 (글로벌)
#   --fe: 공통 + 프론트엔드 스킬만 설치
#   --be: 공통 + 백엔드 스킬만 설치
#   --fe --be: 전체 설치 (= 기본값)
#   --force: 사용자 수정 파일도 강제 덮어쓰기

set -e

# 도움말 출력
usage() {
  echo "Usage: $0 [--global] [--fe] [--be] [--force]"
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
  echo "옵션:"
  echo "  --force        사용자 수정 파일도 강제 덮어쓰기"
  echo ""
  echo "예시:"
  echo "  $0                    # 전체 설치 (로컬)"
  echo "  $0 --fe               # 공통 + FE만 (로컬)"
  echo "  $0 --be               # 공통 + BE만 (로컬)"
  echo "  $0 --global --fe      # 공통 + FE만 (글로벌)"
  echo "  $0 --force            # 수정된 파일도 강제 덮어쓰기"
  exit 0
}

# 인자 파싱
INSTALL_MODE="local"
INSTALL_FE=false
INSTALL_BE=false
FORCE_OVERWRITE=false

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
    --force)
      FORCE_OVERWRITE=true
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
  MODE_LABEL="글로벌 설치 (~/.claude/)"
else
  TARGET_DIR="$(pwd)/.claude"
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

# TARGET_DIR 생성
mkdir -p "$TARGET_DIR"

# === 해시 함수 ===
file_hash() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    # fallback: md5
    md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1
  fi
}

# === 매니페스트 관리 ===
MANIFEST_FILE="$TARGET_DIR/.toolkit-manifest"
NEW_MANIFEST=""

# 이전 매니페스트 로드 (grep 기반으로 bash 3.x 호환)
# OLD_MANIFEST_CONTENT: 한 줄에 "<sha256hash> <relative_path>" 형식
OLD_MANIFEST_CONTENT=""
if [ -f "$MANIFEST_FILE" ]; then
  OLD_MANIFEST_CONTENT="$(cat "$MANIFEST_FILE")"
fi

# 이전 매니페스트에서 특정 파일의 해시를 조회
old_manifest_hash() {
  local path="$1"
  if [ -z "$OLD_MANIFEST_CONTENT" ]; then
    echo ""
    return
  fi
  echo "$OLD_MANIFEST_CONTENT" | grep " ${path}$" | head -1 | cut -d' ' -f1
}

# === 헬퍼 함수 ===

# 개별 파일 복사 (상대경로 기준, 매니페스트 체크섬 비교)
copy_file() {
  local rel_path="$1"
  local dir
  dir="$(dirname "$rel_path")"
  mkdir -p "$TARGET_DIR/$dir"

  local target_file="$TARGET_DIR/$rel_path"
  local source_file="$SOURCE_DIR/$rel_path"

  if [ -f "$target_file" ]; then
    local old_hash
    old_hash="$(old_manifest_hash "$rel_path")"

    if [ -n "$old_hash" ]; then
      # 매니페스트에 기록이 있음 → 사용자 수정 여부 확인
      local current_hash
      current_hash="$(file_hash "$target_file")"

      if [ "$current_hash" = "$old_hash" ]; then
        # 사용자가 수정하지 않음 → 새 버전으로 덮어씀
        cp "$source_file" "$target_file"
        echo "  복사: $rel_path"
      else
        # 사용자가 수정함
        if [ "$FORCE_OVERWRITE" = true ]; then
          cp "$target_file" "$target_file.bak"
          cp "$source_file" "$target_file"
          echo "  ⚠️  $rel_path - 사용자 수정 감지, 강제 덮어씀"
        else
          echo "  ⚠️  $rel_path - 사용자 수정 감지, 건너뜀 (강제: --force)"
          # 건너뛴 파일도 매니페스트에는 현재 해시로 기록 (추적 유지)
          NEW_MANIFEST="${NEW_MANIFEST}${current_hash} ${rel_path}"$'\n'
          return
        fi
      fi
    else
      # 매니페스트에 기록 없음 (첫 설치 or 매니페스트 없음) → 그냥 복사
      cp "$source_file" "$target_file"
      echo "  복사: $rel_path"
    fi
  else
    # 대상 파일이 존재하지 않음 → 그냥 복사
    cp "$source_file" "$target_file"
    echo "  복사: $rel_path"
  fi

  # 복사 성공한 파일의 해시를 새 매니페스트에 추가
  local new_hash
  new_hash="$(file_hash "$target_file")"
  NEW_MANIFEST="${NEW_MANIFEST}${new_hash} ${rel_path}"$'\n'
}

# 디렉토리 전체 복사 (개별 파일 단위로 처리하여 매니페스트에 기록)
copy_dir() {
  local rel_path="$1"
  local file
  for file in "$SOURCE_DIR/$rel_path/"*; do
    if [ -f "$file" ]; then
      local filename
      filename="$(basename "$file")"
      copy_file "$rel_path/$filename"
    elif [ -d "$file" ]; then
      local dirname
      dirname="$(basename "$file")"
      copy_dir "$rel_path/$dirname"
    fi
  done
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
  copy_dir "skills/Planning"
  copy_dir "skills/TDD"
  copy_dir "skills/FailureRecovery"
  copy_dir "skills/Curation"

  # 커스텀 커맨드
  copy_dir "prompts"

  # hooks
  copy_dir "hooks"
  chmod +x "$TARGET_DIR/hooks/"*.sh

  # scripts
  copy_dir "scripts"
  chmod +x "$TARGET_DIR/scripts/"*.sh
}

# FE (프론트엔드)
copy_fe() {
  echo "[FE]"

  # FE 에이전트
  copy_file "agents/code-writer-fe.md"
  copy_file "agents/implementer-fe.md"

  # FE 스킬 (디렉토리 전체)
  copy_dir "skills/React"
  copy_dir "skills/NextJS"
  copy_dir "skills/TailwindCSS"
  copy_dir "skills/TanStackQuery"
  copy_dir "skills/Zustand"
  copy_dir "skills/ReactHookForm"

}

# BE (백엔드)
copy_be() {
  echo "[BE]"

  # BE 에이전트
  copy_file "agents/code-writer-be.md"
  copy_file "agents/implementer-be.md"

  # BE 스킬 (디렉토리 전체)
  copy_dir "skills/NestJS"
  copy_dir "skills/TypeORM"
  copy_dir "skills/DDD"
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

# === 오래된 파일 정리 ===
# 이전 매니페스트에는 있지만 새 매니페스트에는 없는 파일 삭제
if [ -n "$OLD_MANIFEST_CONTENT" ]; then
  while IFS=' ' read -r old_hash old_path; do
    [ -z "$old_path" ] && continue
    # 새 매니페스트에 해당 경로가 없으면 삭제
    if ! echo "$NEW_MANIFEST" | grep -q " ${old_path}$"; then
      if [ -f "$TARGET_DIR/$old_path" ]; then
        rm "$TARGET_DIR/$old_path"
        echo "  🗑️  $old_path - 더 이상 사용하지 않는 파일 삭제"
      fi
    fi
  done <<< "$OLD_MANIFEST_CONTENT"
  echo ""
fi

# === 새 매니페스트 작성 ===
printf '%s' "$NEW_MANIFEST" > "$MANIFEST_FILE"

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
echo "  $TARGET_DIR/scripts/"
echo ""
if [ "$INSTALL_MODE" = "global" ]; then
  echo "이제 어떤 프로젝트에서든 Claude Code를 실행하면 자동으로 적용됩니다."
else
  echo "현재 프로젝트($(pwd))에서 Claude Code를 실행하면 자동으로 적용됩니다."
  echo "다른 프로젝트에도 적용하려면 --global 옵션을 사용하세요."
fi
echo ""
echo "PROJECT_MAP.md를 생성하면 explore 에이전트가 더 빠르게 동작합니다:"
echo "  $TARGET_DIR/scripts/generate-project-map.sh"
