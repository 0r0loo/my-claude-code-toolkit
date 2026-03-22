#!/usr/bin/env bash
# detect-stack.sh — manifest 기반 스택 감지
# Usage: source this file, then call detect_stacks <project_dir> <manifests_dir>
# Result: DETECTED_STACKS (space-separated stack names), DETECTED_SKILLS, DETECTED_AGENTS

DETECTED_STACKS=""
DETECTED_SKILLS=""
DETECTED_AGENTS=""
DETECTED_DETAILS="" # "stack:confidence" pairs

# Check if jq is available
_HAS_JQ=false
command -v jq &>/dev/null && _HAS_JQ=true

# Read JSON field (fallback to grep if no jq)
_json_array() {
  local file="$1" field="$2"
  if [ "$_HAS_JQ" = true ]; then
    jq -r ".$field // [] | .[]" "$file" 2>/dev/null
  else
    # Fallback: simple grep-based extraction for arrays
    grep -oP "\"$field\"\s*:\s*\[([^\]]*)\]" "$file" 2>/dev/null \
      | grep -oP '"[^"]*"' | tr -d '"'
  fi
}

_json_object_keys() {
  local file="$1" field="$2"
  if [ "$_HAS_JQ" = true ]; then
    jq -r ".$field // {} | keys[]" "$file" 2>/dev/null
  fi
}

_json_object_array() {
  local file="$1" field="$2" key="$3"
  if [ "$_HAS_JQ" = true ]; then
    jq -r ".$field[\"$key\"] // [] | .[]" "$file" 2>/dev/null
  fi
}

_json_string() {
  local file="$1" field="$2"
  if [ "$_HAS_JQ" = true ]; then
    jq -r ".$field // empty" "$file" 2>/dev/null
  else
    grep -oP "\"$field\"\s*:\s*\"([^\"]*)" "$file" 2>/dev/null | head -1 | sed 's/.*"//'
  fi
}

# Check if a dependency exists in package.json
_has_dep() {
  local pkg="$1" dep="$2"
  if [ "$_HAS_JQ" = true ]; then
    jq -e "(.dependencies[\"$dep\"] // .devDependencies[\"$dep\"]) // empty" "$pkg" &>/dev/null
  else
    grep -q "\"$dep\"" "$pkg" 2>/dev/null
  fi
}

_has_dev_dep() {
  local pkg="$1" dep="$2"
  if [ "$_HAS_JQ" = true ]; then
    jq -e ".devDependencies[\"$dep\"] // empty" "$pkg" &>/dev/null
  else
    grep -q "\"$dep\"" "$pkg" 2>/dev/null
  fi
}

# Check if a file matches a glob pattern in the project
_has_file() {
  local project_dir="$1" pattern="$2"
  # Use ls with glob (supports * patterns)
  ls "$project_dir"/$pattern &>/dev/null 2>&1
}

# Check if a file contains a keyword
_file_contains() {
  local filepath="$1" keyword="$2"
  [ -f "$filepath" ] && grep -q "$keyword" "$filepath" 2>/dev/null
}

# Detect stacks from manifests
# Args: $1 = project directory, $2 = manifests directory
detect_stacks() {
  local project_dir="${1:-.}"
  local manifests_dir="$2"

  DETECTED_STACKS=""
  DETECTED_SKILLS=""
  DETECTED_AGENTS=""
  DETECTED_DETAILS=""

  local pkg="$project_dir/package.json"
  local has_pkg=false
  [ -f "$pkg" ] && has_pkg=true

  for manifest in "$manifests_dir"/*.json; do
    [ -f "$manifest" ] || continue

    local name
    name="$(_json_string "$manifest" "name")"

    # Skip core manifest (always installed)
    [ "$name" = "core" ] && continue

    local total_rules=0
    local matched_rules=0

    # Check dependencies
    local deps
    deps="$(_json_array "$manifest" "detect.dependencies")"
    if [ -n "$deps" ]; then
      for dep in $deps; do
        total_rules=$((total_rules + 1))
        if [ "$has_pkg" = true ] && _has_dep "$pkg" "$dep"; then
          matched_rules=$((matched_rules + 1))
        fi
      done
    fi

    # Check devDependencies
    local dev_deps
    dev_deps="$(_json_array "$manifest" "detect.devDependencies")"
    if [ -n "$dev_deps" ]; then
      for dep in $dev_deps; do
        total_rules=$((total_rules + 1))
        if [ "$has_pkg" = true ] && _has_dev_dep "$pkg" "$dep"; then
          matched_rules=$((matched_rules + 1))
        fi
      done
    fi

    # Check files
    local files
    files="$(_json_array "$manifest" "detect.files")"
    if [ -n "$files" ]; then
      for pattern in $files; do
        total_rules=$((total_rules + 1))
        if _has_file "$project_dir" "$pattern"; then
          matched_rules=$((matched_rules + 1))
        fi
      done
    fi

    # Check fileContains
    if [ "$_HAS_JQ" = true ]; then
      local fc_keys
      fc_keys="$(_json_object_keys "$manifest" "detect.fileContains")"
      if [ -n "$fc_keys" ]; then
        for fc_file in $fc_keys; do
          local keywords
          keywords="$(_json_object_array "$manifest" "detect.fileContains" "$fc_file")"
          for keyword in $keywords; do
            total_rules=$((total_rules + 1))
            if _file_contains "$project_dir/$fc_file" "$keyword"; then
              matched_rules=$((matched_rules + 1))
            fi
          done
        done
      fi
    fi

    # Calculate confidence
    if [ "$total_rules" -gt 0 ]; then
      # Bash integer math: multiply by 100 for percentage
      local confidence_pct=$(( (matched_rules * 100) / total_rules ))

      if [ "$confidence_pct" -ge 50 ]; then
        DETECTED_STACKS="${DETECTED_STACKS} ${name}"
        DETECTED_DETAILS="${DETECTED_DETAILS} ${name}:${matched_rules}/${total_rules}"

        # Collect skills
        local skills
        skills="$(_json_array "$manifest" "skills")"
        for s in $skills; do
          if ! echo "$DETECTED_SKILLS" | grep -qw "$s"; then
            DETECTED_SKILLS="${DETECTED_SKILLS} ${s}"
          fi
        done

        # Collect agents
        if [ "$_HAS_JQ" = true ]; then
          local agent_values
          agent_values="$(jq -r '.agents // {} | values[]' "$manifest" 2>/dev/null)"
          for a in $agent_values; do
            if ! echo "$DETECTED_AGENTS" | grep -qw "$a"; then
              DETECTED_AGENTS="${DETECTED_AGENTS} ${a}"
            fi
          done
        fi
      fi
    fi
  done

  # Trim leading spaces
  DETECTED_STACKS="$(echo "$DETECTED_STACKS" | xargs)"
  DETECTED_SKILLS="$(echo "$DETECTED_SKILLS" | xargs)"
  DETECTED_AGENTS="$(echo "$DETECTED_AGENTS" | xargs)"
  DETECTED_DETAILS="$(echo "$DETECTED_DETAILS" | xargs)"
}

# Get skills for a specific stack by name
get_stack_skills() {
  local stack_name="$1"
  local manifests_dir="$2"
  local manifest="$manifests_dir/${stack_name}.json"

  if [ -f "$manifest" ]; then
    _json_array "$manifest" "skills"
  fi
}

# Get agents for a specific stack by name
get_stack_agents() {
  local stack_name="$1"
  local manifests_dir="$2"
  local manifest="$manifests_dir/${stack_name}.json"

  if [ -f "$manifest" ] && [ "$_HAS_JQ" = true ]; then
    jq -r '.agents // {} | values[]' "$manifest" 2>/dev/null
  fi
}

# Get core skills
get_core_skills() {
  local manifests_dir="$1"
  local manifest="$manifests_dir/core.json"

  if [ -f "$manifest" ]; then
    _json_array "$manifest" "skills"
  fi
}

# Get core agents
get_core_agents() {
  local manifests_dir="$1"
  local manifest="$manifests_dir/core.json"

  if [ -f "$manifest" ]; then
    _json_array "$manifest" "agents"
  fi
}

# Map legacy flag to stack name
legacy_flag_to_stack() {
  local flag="$1"
  local manifests_dir="$2"

  for manifest in "$manifests_dir"/*.json; do
    [ -f "$manifest" ] || continue
    local lf
    lf="$(_json_string "$manifest" "legacyFlag")"
    if [ "$lf" = "$flag" ]; then
      _json_string "$manifest" "name"
      return
    fi
  done
}
