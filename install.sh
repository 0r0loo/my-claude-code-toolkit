#!/usr/bin/env bash
# install.sh - Install my-claude-code-toolkit into .claude/
# Usage: ./install.sh [--global] [--fe] [--be] [--force] [--uninstall] [--skills=LIST]

set -e

# Help
usage() {
  echo "Usage: $0 [--global] [--fe] [--be] [--force] [--uninstall] [--skills=LIST]"
  echo ""
  echo "Stack selection:"
  echo "  (default)      Full install (common + FE + BE)"
  echo "  --fe           Common + frontend skills only"
  echo "  --be           Common + backend skills only"
  echo "  --fe --be      Full install (same as default)"
  echo ""
  echo "Install location:"
  echo "  (default)      Project local (.claude/ in current directory)"
  echo "  --global       Global install (~/.claude/)"
  echo ""
  echo "Options:"
  echo "  --force        Overwrite user-modified files"
  echo "  --uninstall    Remove installed files using manifest"
  echo "  --skills=LIST  Install only specified skills (e.g., React,TailwindCSS)"
  echo ""
  echo "Examples:"
  echo "  $0                              # Full install (local)"
  echo "  $0 --fe                         # Common + FE only (local)"
  echo "  $0 --be                         # Common + BE only (local)"
  echo "  $0 --global --fe                # Common + FE only (global)"
  echo "  $0 --force                      # Force overwrite modified files"
  echo "  $0 --skills=React,TailwindCSS   # Common + specified skills only"
  echo "  $0 --uninstall                  # Remove installed files"
  exit 0
}

# Parse arguments
INSTALL_MODE="local"
INSTALL_FE=false
INSTALL_BE=false
FORCE_OVERWRITE=false
UNINSTALL=false
CUSTOM_SKILLS=""

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

  copy_file "agents/explore.md"
  copy_file "agents/code-reviewer.md"
  copy_file "agents/git-manager.md"

  copy_file "skills/Coding/SKILL.md"
  copy_dir "skills/TypeScript"
  copy_dir "skills/Git"
  copy_dir "skills/Planning"

  copy_dir "prompts"

  copy_dir "hooks"
  chmod +x "$TARGET_DIR/hooks/"*.sh

  copy_dir "scripts"
  chmod +x "$TARGET_DIR/scripts/"*.sh
}

# Common full (for --fe/--be mode)
copy_common() {
  copy_common_core

  echo "[Common skills]"
  copy_dir "skills/TDD"
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

# === Execute ===

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
echo ""
if [ "$INSTALL_MODE" = "global" ]; then
  echo "Claude Code will now use these settings in any project."
else
  echo "Claude Code will use these settings in $(pwd)."
  echo "Use --global to apply to all projects."
fi
echo ""
echo "Generate PROJECT_MAP.md for faster explore agent:"
echo "  $TARGET_DIR/scripts/generate-project-map.sh"