#!/usr/bin/env bash
# install.sh - Install my-claude-code-toolkit into .claude/
# Usage: ./install.sh [--global] [--fe] [--be] [--force] [--uninstall] [--skills=LIST] [--tools=LIST]

set -e

# Help
usage() {
  echo "Usage: $0 [init] [--global] [--fe] [--be] [--force] [--uninstall] [--skills=LIST]"
  echo ""
  echo "Modes:"
  echo "  init             Auto-detect stack and install matching skills (recommended)"
  echo "  (default)        Full install (common + FE + BE)"
  echo ""
  echo "Init options:"
  echo "  --yes, -y        Skip confirmation prompt"
  echo "  --dry-run        Show detection results without installing"
  echo "  --stack=LIST     Specify stacks (e.g., react,nestjs) — skip auto-detection"
  echo ""
  echo "Legacy stack selection:"
  echo "  --fe             Common + frontend skills only"
  echo "  --be             Common + backend skills only"
  echo "  --fe --be        Full install (same as default)"
  echo ""
  echo "Install location:"
  echo "  (default)        Project local (.claude/ in current directory)"
  echo "  --global         Global install (~/.claude/)"
  echo ""
  echo "Options:"
  echo "  --force          Overwrite user-modified files"
  echo "  --uninstall      Remove installed files using manifest"
  echo "  --skills=LIST    Install only specified skills (e.g., React,TailwindCSS)"
  echo "  --tools=LIST     Install optional tools (e.g., browse)"
  echo ""
  echo "Examples:"
  echo "  $0 init                          # Auto-detect and install (recommended)"
  echo "  $0 init --yes                    # Auto-detect, no prompt"
  echo "  $0 init --stack=react            # Install React stack"
  echo "  $0 init --dry-run                # Preview detection results"
  echo "  $0                               # Full install (FE + BE)"
  echo "  $0 --fe                          # Common + FE only"
  echo "  $0 --global --fe                 # Common + FE only (global)"
  echo "  $0 --skills=React,TailwindCSS    # Common + specified skills only"
  echo "  $0 --uninstall                   # Remove installed files"
  exit 0
}

# Parse arguments
INSTALL_MODE="local"
INSTALL_FE=false
INSTALL_BE=false
FORCE_OVERWRITE=false
UNINSTALL=false
CUSTOM_SKILLS=""
INSTALL_TOOLS=""
INIT_MODE=false
INIT_YES=false
INIT_DRY_RUN=false
INIT_STACKS=""

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
    --uninstall)
      UNINSTALL=true
      ;;
    --skills=*)
      CUSTOM_SKILLS="${arg#*=}"
      ;;
    --tools=*)
      INSTALL_TOOLS="${arg#*=}"
      ;;
    init)
      INIT_MODE=true
      ;;
    --yes|-y)
      INIT_YES=true
      ;;
    --dry-run)
      INIT_DRY_RUN=true
      ;;
    --stack=*)
      INIT_STACKS="${arg#*=}"
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Error: Unknown option '$arg'"
      usage
      ;;
  esac
done

# Default: install both FE and BE
if [ "$INSTALL_FE" = false ] && [ "$INSTALL_BE" = false ]; then
  INSTALL_FE=true
  INSTALL_BE=true
fi

# Stack label
if [ -n "$CUSTOM_SKILLS" ]; then
  STACK_LABEL="Custom ($CUSTOM_SKILLS)"
elif [ "$INSTALL_FE" = true ] && [ "$INSTALL_BE" = true ]; then
  STACK_LABEL="FE + BE (full)"
elif [ "$INSTALL_FE" = true ]; then
  STACK_LABEL="FE only"
else
  STACK_LABEL="BE only"
fi

# Preflight: global install requires jq
if [ "$INSTALL_MODE" = "global" ] && ! command -v jq &>/dev/null; then
  echo "Error: Global install requires jq for correct hook path resolution."
  echo "Install: brew install jq (macOS) or apt-get install jq (Linux)"
  exit 1
fi

if [ -n "$PACKAGE_ROOT" ]; then
  SOURCE_DIR="$PACKAGE_ROOT/.claude"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  SOURCE_DIR="$SCRIPT_DIR/.claude"
fi

if [ "$INSTALL_MODE" = "global" ]; then
  TARGET_DIR="$HOME/.claude"
  MODE_LABEL="Global (~/.claude/)"
else
  TARGET_DIR="$(pwd)/.claude"
  MODE_LABEL="Local ($(pwd)/.claude/)"
fi

# === Uninstall ===
uninstall_toolkit() {
  local manifest="$TARGET_DIR/.toolkit-manifest"
  if [ ! -f "$manifest" ]; then
    echo "Error: Manifest not found ($manifest)"
    echo "Please check your .claude/ directory manually."
    exit 1
  fi

  echo "=== Uninstalling my-claude-code-toolkit ==="
  echo ""

  local count=0
  while IFS=' ' read -r hash filepath; do
    [ -z "$filepath" ] && continue
    if [ -f "$TARGET_DIR/$filepath" ]; then
      rm "$TARGET_DIR/$filepath"
      echo "  Removed: $filepath"
      count=$((count + 1))
    fi
  done < "$manifest"

  # Clean up empty directories
  find "$TARGET_DIR" -type d -empty -delete 2>/dev/null

  # Remove manifest itself
  rm "$manifest"

  # Remove prompt-hook from settings.json and clean up empty arrays
  if [ -f "$TARGET_DIR/settings.json" ] && command -v jq &>/dev/null; then
    jq 'del(.hooks.UserPromptSubmit[] | select(.hooks[].command | contains("prompt-hook.sh")))
        | if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end
        | if .hooks == {} then del(.hooks) else . end' \
      "$TARGET_DIR/settings.json" > "${TARGET_DIR}/settings.json.tmp" \
      && mv "${TARGET_DIR}/settings.json.tmp" "$TARGET_DIR/settings.json"
    echo "  Cleaned: removed prompt-hook from settings.json"
  fi

  echo ""
  echo "=== Uninstall complete ($count files removed) ==="
}

if [ "$UNINSTALL" = true ]; then
  uninstall_toolkit
  exit 0
fi

echo "=== Installing my-claude-code-toolkit ==="
echo ""
echo "Mode:   $MODE_LABEL"
echo "Stack:  $STACK_LABEL"
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Verify source directory
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source directory not found ($SOURCE_DIR)"
  exit 1
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# === Hash function ===
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

# === Manifest management ===
MANIFEST_FILE="$TARGET_DIR/.toolkit-manifest"
NEW_MANIFEST=""

OLD_MANIFEST_CONTENT=""
if [ -f "$MANIFEST_FILE" ]; then
  OLD_MANIFEST_CONTENT="$(cat "$MANIFEST_FILE")"
fi

old_manifest_hash() {
  local path="$1"
  if [ -z "$OLD_MANIFEST_CONTENT" ]; then
    echo ""
    return
  fi
  echo "$OLD_MANIFEST_CONTENT" | grep " ${path}$" | head -1 | cut -d' ' -f1
}

# === Helper functions ===

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
      local current_hash
      current_hash="$(file_hash "$target_file")"

      if [ "$current_hash" = "$old_hash" ]; then
        cp "$source_file" "$target_file"
        echo "  Copied: $rel_path"
      else
        if [ "$FORCE_OVERWRITE" = true ]; then
          cp "$target_file" "$target_file.bak"
          cp "$source_file" "$target_file"
          echo "  Forced: $rel_path (user modification detected, backup created)"
        else
          echo "  Skipped: $rel_path (user modification detected, use --force to overwrite)"
          NEW_MANIFEST="${NEW_MANIFEST}${current_hash} ${rel_path}"$'\n'
          return
        fi
      fi
    else
      cp "$source_file" "$target_file"
      echo "  Copied: $rel_path"
    fi
  else
    cp "$source_file" "$target_file"
    echo "  Copied: $rel_path"
  fi

  local new_hash
  new_hash="$(file_hash "$target_file")"
  NEW_MANIFEST="${NEW_MANIFEST}${new_hash} ${rel_path}"$'\n'
}

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

# === Merge settings.json ===
merge_settings_json() {
  local source_file="$SOURCE_DIR/settings.json"
  local target_file="$TARGET_DIR/settings.json"

  if [ ! -f "$target_file" ]; then
    cp "$source_file" "$target_file"
    echo "  Copied: settings.json"
  else
    if grep -q "prompt-hook.sh" "$target_file" 2>/dev/null; then
      echo "  Skipped: settings.json (prompt-hook already registered)"
    else
      if command -v jq &>/dev/null; then
        local HOOK_CMD
        if [ "$INSTALL_MODE" = "global" ]; then
          HOOK_CMD="\$HOME/.claude/hooks/prompt-hook.sh"
        else
          HOOK_CMD=".claude/hooks/prompt-hook.sh"
        fi
        local HOOK_ENTRY="{\"matcher\":\"\",\"hooks\":[{\"type\":\"command\",\"command\":\"${HOOK_CMD}\"}]}"

        if jq -e '.hooks.UserPromptSubmit' "$target_file" &>/dev/null; then
          jq --argjson entry "$HOOK_ENTRY" \
            '.hooks.UserPromptSubmit += [$entry]' \
            "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        else
          jq --argjson entry "$HOOK_ENTRY" \
            '.hooks.UserPromptSubmit = [$entry]' \
            "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        fi
        echo "  Merged: settings.json (prompt-hook added)"
      else
        if [ "$INSTALL_MODE" = "global" ]; then
          echo "  Error: Global install requires jq for correct hook path. Install: brew install jq"
          exit 1
        fi
        cp "$target_file" "${target_file}.bak"
        cp "$source_file" "$target_file"
        echo "  Warning: settings.json backed up (.bak) and overwritten (install jq for merge support)"
      fi
    fi
  fi

  local new_hash
  new_hash="$(file_hash "$target_file")"
  NEW_MANIFEST="${NEW_MANIFEST}${new_hash} settings.json"$'\n'
}

# === Copy functions ===

# Common core (minimal — installed in --skills mode too)
copy_common_core() {
  echo "[Common core]"

  copy_file "CLAUDE.md"
  merge_settings_json

  copy_file "agents/code-reviewer.md"
  copy_file "agents/git-manager.md"
  copy_file "agents/tester.md"
  copy_file "agents/e2e-tester.md"

  copy_file "skills/Coding/SKILL.md"
  copy_dir "skills/TypeScript"
  copy_dir "skills/Git"
  copy_dir "skills/Planning"

  copy_dir "prompts"

  copy_dir "hooks"
  chmod +x "$TARGET_DIR/hooks/"*.sh

  copy_dir "scripts"
  chmod +x "$TARGET_DIR/scripts/"*.sh

  # Manifests (스택 감지 메타데이터)
  copy_dir "skills/manifests"
}

# Common full (for --fe/--be mode)
copy_common() {
  copy_common_core

  echo "[Common skills]"
  copy_dir "skills/TDD"
  copy_dir "skills/E2E"
  copy_dir "skills/APIDesign"
  copy_dir "skills/Database"
  copy_dir "skills/FailureRecovery"
  copy_dir "skills/Curation"
}

# FE (frontend)
copy_fe() {
  echo "[FE]"

  copy_file "agents/implementer-fe.md"

  copy_dir "skills/React"
  copy_dir "skills/NextJS"
  copy_dir "skills/TailwindCSS"
  copy_dir "skills/TanStackQuery"
  copy_dir "skills/Zustand"
  copy_dir "skills/ReactHookForm"
  copy_dir "skills/SVGIcon"
}

# BE (backend)
copy_be() {
  echo "[BE]"

  copy_file "agents/implementer-be.md"

  copy_dir "skills/NestJS"
  copy_dir "skills/TypeORM"
  copy_dir "skills/DDD"
}

# Auto-install agents based on selected skills
FE_SKILLS="React NextJS TailwindCSS TanStackQuery Zustand ReactHookForm SVGIcon"
BE_SKILLS="NestJS TypeORM DDD"

# === Tools installation ===
install_tools() {
  [ -z "$INSTALL_TOOLS" ] && return

  echo "[Tools]"
  IFS=',' read -ra TOOLS <<< "$INSTALL_TOOLS"
  for tool in "${TOOLS[@]}"; do
    tool=$(echo "$tool" | xargs)
    case "$tool" in
      browse)
        if [ -n "$PACKAGE_ROOT" ]; then
          local tool_source="$PACKAGE_ROOT/.claude/tools/browse"
        else
          local tool_source="$SOURCE_DIR/tools/browse"
        fi

        if [ ! -d "$tool_source/src" ]; then
          echo "  Warning: browse tool source not found at $tool_source"
          continue
        fi

        # 소스 복사
        copy_dir "tools/browse/src"
        copy_dir "tools/browse/scripts"
        copy_file "tools/browse/package.json"
        copy_file "tools/browse/setup.sh"
        chmod +x "$TARGET_DIR/tools/browse/setup.sh"
        chmod +x "$TARGET_DIR/tools/browse/scripts/"*.sh

        # Bun으로 빌드
        if command -v bun &>/dev/null; then
          echo "  browse: 빌드 중..."
          (cd "$TARGET_DIR/tools/browse" && bash setup.sh) 2>&1 | sed 's/^/  /'
        else
          echo ""
          echo "  browse: Bun이 설치되지 않아 빌드를 건너뜁니다."
          echo "  사용하려면:"
          echo "    1. curl -fsSL https://bun.sh/install | bash"
          echo "    2. bash $TARGET_DIR/tools/browse/setup.sh"
          echo ""
        fi
        ;;
      *)
        echo "  Warning: Unknown tool '$tool'. Available: browse"
        ;;
    esac
  done
}

install_agents_for_skills() {
  local skills="$1"
  local need_fe=false
  local need_be=false

  for skill in $(echo "$skills" | tr ',' ' '); do
    skill=$(echo "$skill" | xargs)
    for fs in $FE_SKILLS; do
      [ "$skill" = "$fs" ] && need_fe=true
    done
    for bs in $BE_SKILLS; do
      [ "$skill" = "$bs" ] && need_be=true
    done
  done

  if [ "$need_fe" = true ]; then
    echo "[Agents]"
    copy_file "agents/implementer-fe.md"
  fi
  if [ "$need_be" = true ]; then
    echo "[Agents]"
    copy_file "agents/implementer-be.md"
  fi
}

# === Init mode (manifest-based auto-detection) ===

run_init_mode() {
  local manifests_dir="$SOURCE_DIR/skills/manifests"

  if [ ! -d "$manifests_dir" ]; then
    echo "Error: Manifests directory not found ($manifests_dir)"
    exit 1
  fi

  # Source detect-stack.sh
  source "$SOURCE_DIR/scripts/detect-stack.sh"

  if [ -n "$INIT_STACKS" ]; then
    # --stack=react,nestjs → skip detection
    DETECTED_STACKS="$(echo "$INIT_STACKS" | tr ',' ' ')"
    DETECTED_SKILLS=""
    DETECTED_AGENTS=""
    for s in $DETECTED_STACKS; do
      local skills
      skills="$(get_stack_skills "$s" "$manifests_dir")"
      for sk in $skills; do
        if ! echo "$DETECTED_SKILLS" | grep -qw "$sk"; then
          DETECTED_SKILLS="$DETECTED_SKILLS $sk"
        fi
      done
      local agents
      agents="$(get_stack_agents "$s" "$manifests_dir")"
      for a in $agents; do
        if ! echo "$DETECTED_AGENTS" | grep -qw "$a"; then
          DETECTED_AGENTS="$DETECTED_AGENTS $a"
        fi
      done
    done
    DETECTED_STACKS="$(echo "$DETECTED_STACKS" | xargs)"
    DETECTED_SKILLS="$(echo "$DETECTED_SKILLS" | xargs)"
    DETECTED_AGENTS="$(echo "$DETECTED_AGENTS" | xargs)"
  else
    # Auto-detect
    detect_stacks "$(pwd)" "$manifests_dir"
  fi

  echo ""
  if [ -n "$DETECTED_STACKS" ]; then
    echo "  Detected stacks:"
    for s in $DETECTED_STACKS; do
      local display
      display="$(_json_string "$manifests_dir/${s}.json" "displayName")"
      echo "  ✅ ${display:-$s}"
    done
  else
    echo "  No stacks detected."
  fi
  echo ""
  echo "  Install plan:"
  echo "  📦 Core (워크플로우 엔진, 에이전트, hooks)"
  if [ -n "$DETECTED_STACKS" ]; then
    for s in $DETECTED_STACKS; do
      local display
      display="$(_json_string "$manifests_dir/${s}.json" "displayName")"
      local desc
      desc="$(_json_string "$manifests_dir/${s}.json" "description")"
      echo "  📦 ${display:-$s} ($desc)"
    done
  fi
  echo ""

  # Dry run stops here
  if [ "$INIT_DRY_RUN" = true ]; then
    echo "  (dry run — no files written)"
    exit 0
  fi

  # Confirm
  if [ "$INIT_YES" != true ]; then
    printf "? Install? [Y/n] "
    read -r answer
    case "$answer" in
      [nN]*) echo "Cancelled."; exit 0 ;;
    esac
  fi

  echo ""
  echo "Copying files..."
  echo ""

  # Core
  copy_common_core

  # Core skills from manifest
  echo ""
  echo "[Core skills]"
  local core_skills
  core_skills="$(get_core_skills "$manifests_dir")"
  for sk in $core_skills; do
    if [ -d "$SOURCE_DIR/skills/$sk" ]; then
      copy_dir "skills/$sk"
    fi
  done

  # Stack skills
  if [ -n "$DETECTED_STACKS" ]; then
    for s in $DETECTED_STACKS; do
      local display
      display="$(_json_string "$manifests_dir/${s}.json" "displayName")"
      echo ""
      echo "[${display:-$s}]"

      # Stack agents
      local agents
      agents="$(get_stack_agents "$s" "$manifests_dir")"
      for a in $agents; do
        if [ -f "$SOURCE_DIR/agents/$a" ]; then
          copy_file "agents/$a"
        fi
      done

      # Stack skills
      local skills
      skills="$(get_stack_skills "$s" "$manifests_dir")"
      for sk in $skills; do
        if [ -d "$SOURCE_DIR/skills/$sk" ]; then
          copy_dir "skills/$sk"
        fi
      done
    done
  fi

  echo ""

  # Tools (browse 등)
  install_tools
  echo ""

  # Update CLAUDE.md markers
  update_claude_md_markers

  # Write manifest
  printf '%s' "$NEW_MANIFEST" > "$MANIFEST_FILE"

  local file_count
  file_count=$(echo "$NEW_MANIFEST" | grep -c "." || true)

  echo "=== Installation complete ($MODE_LABEL) ==="
  echo ""
  echo "Stack: Core${DETECTED_STACKS:+ + $DETECTED_STACKS}"
  echo "Files: $file_count"
  echo ""
  echo "💡 Try these commands:"
  echo "  claude \"/feature 로그인 페이지\"  ← Build a feature"
  echo "  claude \"/review\"                 ← Code review"
  echo "  claude \"/ship\"                   ← Create PR"
}

# === Update CLAUDE.md markers ===
update_claude_md_markers() {
  local claude_md="$TARGET_DIR/CLAUDE.md"
  [ -f "$claude_md" ] || return

  # Check for AGENTS marker
  if grep -q "<!-- AGENTS:START" "$claude_md" 2>/dev/null; then
    # Build agents section from installed files
    local agents_content="<!-- AGENTS:START — install.sh init이 자동 갱신. 수동 편집 시 마커 유지 필요 -->"
    agents_content="${agents_content}\n### Agents (서브에이전트 프롬프트)"

    for agent_file in "$TARGET_DIR/agents/"*.md; do
      [ -f "$agent_file" ] || continue
      local name
      name="$(basename "$agent_file")"
      agents_content="${agents_content}\n- \`.claude/agents/${name}\`"
    done
    agents_content="${agents_content}\n- 탐색은 built-in \`Explore\` 에이전트를 사용 (별도 커스텀 agent 없음)"
    agents_content="${agents_content}\n<!-- AGENTS:END -->"

    # Replace between markers using awk
    awk -v new="$agents_content" '
      /<!-- AGENTS:START/ { print new; skip=1; next }
      /<!-- AGENTS:END/ { skip=0; next }
      !skip { print }
    ' "$claude_md" > "${claude_md}.tmp" && mv "${claude_md}.tmp" "$claude_md"
    echo "  Updated: CLAUDE.md (agents section)"
  else
    echo "  Warning: CLAUDE.md missing AGENTS markers — skipping dynamic update"
  fi

  # Check for SKILLS marker
  if grep -q "<!-- SKILLS:START" "$claude_md" 2>/dev/null; then
    local skills_content="<!-- SKILLS:START — install.sh init이 자동 갱신. 수동 편집 시 마커 유지 필요 -->"
    skills_content="${skills_content}\n### Skills (도메인 지식)"

    for skill_dir in "$TARGET_DIR/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      local skill_name
      skill_name="$(basename "$skill_dir")"
      [ "$skill_name" = "manifests" ] && continue
      if [ -f "$skill_dir/SKILL.md" ]; then
        skills_content="${skills_content}\n- \`.claude/skills/${skill_name}/SKILL.md\`"
      fi
    done
    skills_content="${skills_content}\n<!-- SKILLS:END -->"

    awk -v new="$skills_content" '
      /<!-- SKILLS:START/ { print new; skip=1; next }
      /<!-- SKILLS:END/ { skip=0; next }
      !skip { print }
    ' "$claude_md" > "${claude_md}.tmp" && mv "${claude_md}.tmp" "$claude_md"
    echo "  Updated: CLAUDE.md (skills section)"
  else
    echo "  Warning: CLAUDE.md missing SKILLS markers — skipping dynamic update"
  fi
}

if [ "$INIT_MODE" = true ]; then
  run_init_mode
  exit 0
fi

# === Execute (legacy mode) ===

echo "Copying files..."
echo ""

if [ -n "$CUSTOM_SKILLS" ]; then
  # --skills mode: core + specified skills only
  copy_common_core
  echo ""

  echo "[Custom skills]"
  IFS=',' read -ra SKILLS <<< "$CUSTOM_SKILLS"
  for skill in "${SKILLS[@]}"; do
    skill=$(echo "$skill" | xargs)
    if [ -d "$SOURCE_DIR/skills/$skill" ]; then
      copy_dir "skills/$skill"
    else
      echo "  Warning: Skill '$skill' not found. Available: $(ls -1 "$SOURCE_DIR/skills/" | tr '\n' ', ')"
    fi
  done
  echo ""

  install_agents_for_skills "$CUSTOM_SKILLS"
  echo ""
else
  # Default --fe/--be mode
  copy_common
  echo ""

  if [ "$INSTALL_FE" = true ]; then
    copy_fe
    echo ""
  fi

  if [ "$INSTALL_BE" = true ]; then
    copy_be
    echo ""
  fi
fi

# Tools (browse 등)
install_tools
echo ""

# === Clean up old files ===
if [ -n "$OLD_MANIFEST_CONTENT" ]; then
  while IFS=' ' read -r old_hash old_path; do
    [ -z "$old_path" ] && continue
    if ! echo "$NEW_MANIFEST" | grep -q " ${old_path}$"; then
      if [ -f "$TARGET_DIR/$old_path" ]; then
        rm "$TARGET_DIR/$old_path"
        echo "  Removed: $old_path (no longer used)"
      fi
    fi
  done <<< "$OLD_MANIFEST_CONTENT"

  # Clean up empty directories
  find "$TARGET_DIR/skills" -type d -empty -delete 2>/dev/null
  find "$TARGET_DIR/agents" -type d -empty -delete 2>/dev/null

  echo ""
fi

# === Write new manifest ===
printf '%s' "$NEW_MANIFEST" > "$MANIFEST_FILE"

echo "=== Installation complete ($MODE_LABEL) ==="
echo ""
echo "Stack: $STACK_LABEL"
echo ""
echo "Installed:"
echo "  $TARGET_DIR/CLAUDE.md"
echo "  $TARGET_DIR/settings.json"
echo "  $TARGET_DIR/agents/"
echo "  $TARGET_DIR/skills/"
echo "  $TARGET_DIR/hooks/"
echo "  $TARGET_DIR/scripts/"
if [ -n "$INSTALL_TOOLS" ]; then
  echo "  $TARGET_DIR/tools/"
fi
echo ""
if [ "$INSTALL_MODE" = "global" ]; then
  echo "Claude Code will now use these settings in any project."
else
  echo "Claude Code will use these settings in $(pwd)."
  echo "Use --global to apply to all projects."
fi
echo ""
echo "Generate PROJECT_MAP.md for faster code exploration:"
echo "  $TARGET_DIR/scripts/generate-project-map.sh"