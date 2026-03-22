#!/usr/bin/env bash
# install-test.sh — install.sh 회귀 테스트
# Usage: bash test/install-test.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$PROJECT_DIR/install.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0
TESTS=()

assert_file_exists() {
  if [ -f "$1" ]; then
    return 0
  else
    echo "  Expected file: $1"
    return 1
  fi
}

assert_file_not_exists() {
  if [ ! -f "$1" ]; then
    return 0
  else
    echo "  Unexpected file: $1"
    return 1
  fi
}

assert_dir_exists() {
  if [ -d "$1" ]; then
    return 0
  else
    echo "  Expected dir: $1"
    return 1
  fi
}

assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    return 0
  else
    echo "  Expected '$2' in $1"
    return 1
  fi
}

run_test() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $name"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $name"
    "$@" 2>&1 | head -3
    FAIL=$((FAIL + 1))
  fi
}

setup_test_dir() {
  local dir
  dir=$(mktemp -d)
  echo "$dir"
}

cleanup() {
  rm -rf "$1"
}

echo ""
echo "=== install.sh Regression Tests ==="
echo ""

# ─── T1: Default install (FE + BE) ───
echo "[T1] Default install (FE + BE)"
T1_DIR=$(setup_test_dir)
(cd "$T1_DIR" && bash "$INSTALL_SH" >/dev/null 2>&1)
run_test "CLAUDE.md installed" assert_file_exists "$T1_DIR/.claude/CLAUDE.md"
run_test "settings.json installed" assert_file_exists "$T1_DIR/.claude/settings.json"
run_test "implementer-fe.md installed" assert_file_exists "$T1_DIR/.claude/agents/implementer-fe.md"
run_test "implementer-be.md installed" assert_file_exists "$T1_DIR/.claude/agents/implementer-be.md"
run_test "code-reviewer.md installed" assert_file_exists "$T1_DIR/.claude/agents/code-reviewer.md"
run_test "React skill installed" assert_dir_exists "$T1_DIR/.claude/skills/React"
run_test "NestJS skill installed" assert_dir_exists "$T1_DIR/.claude/skills/NestJS"
run_test "Coding skill installed" assert_dir_exists "$T1_DIR/.claude/skills/Coding"
run_test "TypeScript skill installed" assert_dir_exists "$T1_DIR/.claude/skills/TypeScript"
run_test "prompts installed" assert_dir_exists "$T1_DIR/.claude/prompts"
run_test "hooks installed" assert_dir_exists "$T1_DIR/.claude/hooks"
run_test "manifest file created" assert_file_exists "$T1_DIR/.claude/.toolkit-manifest"
cleanup "$T1_DIR"
echo ""

# ─── T2: --fe only ───
echo "[T2] --fe only"
T2_DIR=$(setup_test_dir)
(cd "$T2_DIR" && bash "$INSTALL_SH" --fe >/dev/null 2>&1)
run_test "implementer-fe.md installed" assert_file_exists "$T2_DIR/.claude/agents/implementer-fe.md"
run_test "implementer-be.md NOT installed" assert_file_not_exists "$T2_DIR/.claude/agents/implementer-be.md"
run_test "React skill installed" assert_dir_exists "$T2_DIR/.claude/skills/React"
run_test "NestJS skill NOT installed" assert_file_not_exists "$T2_DIR/.claude/skills/NestJS/SKILL.md"
run_test "Coding skill installed (common)" assert_dir_exists "$T2_DIR/.claude/skills/Coding"
cleanup "$T2_DIR"
echo ""

# ─── T3: --be only ───
echo "[T3] --be only"
T3_DIR=$(setup_test_dir)
(cd "$T3_DIR" && bash "$INSTALL_SH" --be >/dev/null 2>&1)
run_test "implementer-be.md installed" assert_file_exists "$T3_DIR/.claude/agents/implementer-be.md"
run_test "implementer-fe.md NOT installed" assert_file_not_exists "$T3_DIR/.claude/agents/implementer-fe.md"
run_test "NestJS skill installed" assert_dir_exists "$T3_DIR/.claude/skills/NestJS"
run_test "React skill NOT installed" assert_file_not_exists "$T3_DIR/.claude/skills/React/SKILL.md"
cleanup "$T3_DIR"
echo ""

# ─── T4: --skills=React,TailwindCSS ───
echo "[T4] --skills=React,TailwindCSS"
T4_DIR=$(setup_test_dir)
(cd "$T4_DIR" && bash "$INSTALL_SH" --skills=React,TailwindCSS >/dev/null 2>&1)
run_test "React skill installed" assert_dir_exists "$T4_DIR/.claude/skills/React"
run_test "TailwindCSS skill installed" assert_dir_exists "$T4_DIR/.claude/skills/TailwindCSS"
run_test "NestJS skill NOT installed" assert_file_not_exists "$T4_DIR/.claude/skills/NestJS/SKILL.md"
run_test "implementer-fe.md auto-installed" assert_file_exists "$T4_DIR/.claude/agents/implementer-fe.md"
run_test "Coding skill installed (core)" assert_dir_exists "$T4_DIR/.claude/skills/Coding"
cleanup "$T4_DIR"
echo ""

# ─── T5: --uninstall ───
echo "[T5] --uninstall"
T5_DIR=$(setup_test_dir)
(cd "$T5_DIR" && bash "$INSTALL_SH" >/dev/null 2>&1)
(cd "$T5_DIR" && bash "$INSTALL_SH" --uninstall >/dev/null 2>&1)
run_test "CLAUDE.md removed" assert_file_not_exists "$T5_DIR/.claude/CLAUDE.md"
run_test "agents removed" assert_file_not_exists "$T5_DIR/.claude/agents/implementer-fe.md"
run_test "manifest removed" assert_file_not_exists "$T5_DIR/.claude/.toolkit-manifest"
cleanup "$T5_DIR"
echo ""

# ─── T6: Re-install preserves user modifications ───
echo "[T6] Re-install preserves user modifications"
T6_DIR=$(setup_test_dir)
(cd "$T6_DIR" && bash "$INSTALL_SH" --fe >/dev/null 2>&1)
echo "# User added this line" >> "$T6_DIR/.claude/CLAUDE.md"
(cd "$T6_DIR" && bash "$INSTALL_SH" --fe >/dev/null 2>&1)
run_test "User modification preserved" assert_file_contains "$T6_DIR/.claude/CLAUDE.md" "User added this line"
cleanup "$T6_DIR"
echo ""

# ─── T7: --force overwrites user modifications ───
echo "[T7] --force overwrites"
T7_DIR=$(setup_test_dir)
(cd "$T7_DIR" && bash "$INSTALL_SH" --fe >/dev/null 2>&1)
echo "# User added this line" >> "$T7_DIR/.claude/CLAUDE.md"
(cd "$T7_DIR" && bash "$INSTALL_SH" --fe --force >/dev/null 2>&1)
run_test "Backup created on force" assert_file_exists "$T7_DIR/.claude/CLAUDE.md.bak"
cleanup "$T7_DIR"
echo ""

# ─── T8: settings.json merge (existing settings preserved) ───
echo "[T8] settings.json merge"
T8_DIR=$(setup_test_dir)
mkdir -p "$T8_DIR/.claude"
echo '{"permissions":{"allow":["Edit"]}}' > "$T8_DIR/.claude/settings.json"
(cd "$T8_DIR" && bash "$INSTALL_SH" --fe >/dev/null 2>&1)
run_test "Existing permissions preserved" assert_file_contains "$T8_DIR/.claude/settings.json" "Edit"
run_test "Hook added" assert_file_contains "$T8_DIR/.claude/settings.json" "prompt-hook"
cleanup "$T8_DIR"
echo ""

# ─── T9: manifests directory is installed ───
# NOTE: T9 tests manifest installation which requires install.sh refactor (Step 4)
echo "[T9] manifests directory installed"
T9_DIR=$(setup_test_dir)
(cd "$T9_DIR" && bash "$INSTALL_SH" >/dev/null 2>&1)
run_test "manifests dir exists" assert_dir_exists "$T9_DIR/.claude/skills/manifests"
run_test "core.json installed" assert_file_exists "$T9_DIR/.claude/skills/manifests/core.json"
run_test "react.json installed" assert_file_exists "$T9_DIR/.claude/skills/manifests/react.json"
run_test "nestjs.json installed" assert_file_exists "$T9_DIR/.claude/skills/manifests/nestjs.json"
run_test "detect-stack.sh installed" assert_file_exists "$T9_DIR/.claude/scripts/detect-stack.sh"
cleanup "$T9_DIR"
echo ""

# ─── Results ───
TOTAL=$((PASS + FAIL))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC} / ${TOTAL} total"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
