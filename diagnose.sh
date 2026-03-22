#!/usr/bin/env bash
# diagnose.sh - Diagnose project readiness for AI-assisted development
# Usage: bash diagnose.sh [project_dir]
# Or:    npx @choblue/claude-code-toolkit --diagnose

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Target directory
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Counters
PASS=0
FAIL=0
WARN=0

# Results storage
QUICK_WINS=""
RECOMMENDED_SKILLS=""

# === Helper functions ===

check_pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo -e "  ${RED}✗${NC} $1"
  FAIL=$((FAIL + 1))
}

check_warn() {
  echo -e "  ${YELLOW}⚠${NC} $1"
  WARN=$((WARN + 1))
}

add_quick_win() {
  QUICK_WINS="${QUICK_WINS}\n  ${CYAN}→${NC} $1"
}

add_skill() {
  local skill="$1"
  if ! echo "$RECOMMENDED_SKILLS" | grep -q "$skill"; then
    RECOMMENDED_SKILLS="${RECOMMENDED_SKILLS} ${skill}"
  fi
}

file_exists() {
  [ -f "$PROJECT_DIR/$1" ]
}

dir_exists() {
  [ -d "$PROJECT_DIR/$1" ]
}

# === Header ===

echo ""
echo -e "${BOLD}🔍 Project Diagnostics${NC}"
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Path: ${BLUE}$PROJECT_DIR${NC}"
echo ""

# === 1. Tech Stack Detection (manifest-based) ===

echo -e "${BOLD}📦 Tech Stack${NC}"

STACK=""

# Source manifest-based detector
DETECT_SCRIPT=""
if [ -f "$PROJECT_DIR/.claude/scripts/detect-stack.sh" ]; then
  DETECT_SCRIPT="$PROJECT_DIR/.claude/scripts/detect-stack.sh"
elif [ -n "${PACKAGE_ROOT:-}" ] && [ -f "$PACKAGE_ROOT/.claude/scripts/detect-stack.sh" ]; then
  DETECT_SCRIPT="$PACKAGE_ROOT/.claude/scripts/detect-stack.sh"
elif [ -f "$(dirname "$0")/.claude/scripts/detect-stack.sh" ]; then
  DETECT_SCRIPT="$(dirname "$0")/.claude/scripts/detect-stack.sh"
fi

if [ -n "$DETECT_SCRIPT" ]; then
  # Manifest-based detection
  MANIFESTS_DIR="$(dirname "$DETECT_SCRIPT")/../skills/manifests"
  source "$DETECT_SCRIPT"
  detect_stacks "$PROJECT_DIR" "$MANIFESTS_DIR"

  for s in $DETECTED_STACKS; do
    _display="$(_json_string "$MANIFESTS_DIR/${s}.json" "displayName" 2>/dev/null)"
    STACK="${STACK} ${_display:-$s}"
  done

  for sk in $DETECTED_SKILLS; do
    add_skill "$sk"
  done
fi

# Non-manifest detection (Python, Go, Rust, TypeScript, Git)
if file_exists "tsconfig.json"; then
  if ! echo "$STACK" | grep -qi "typescript"; then
    STACK="${STACK} TypeScript"
    add_skill "TypeScript"
  fi
fi

if file_exists "requirements.txt" || file_exists "pyproject.toml" || file_exists "setup.py"; then
  STACK="${STACK} Python"
fi

if file_exists "go.mod"; then
  STACK="${STACK} Go"
fi

if file_exists "Cargo.toml"; then
  STACK="${STACK} Rust"
fi

if dir_exists ".git"; then
  STACK="${STACK} Git"
fi

if [ -n "$STACK" ]; then
  echo -e "  Detected:${BOLD}${STACK}${NC}"
else
  echo -e "  ${DIM}No known stack detected${NC}"
fi
echo ""

# === 2. Agent Entry Point ===

echo -e "${BOLD}📄 Agent Entry Point${NC}"

# CLAUDE.md or AGENTS.md
if file_exists ".claude/CLAUDE.md"; then
  check_pass "CLAUDE.md exists (.claude/CLAUDE.md)"
elif file_exists "CLAUDE.md"; then
  check_pass "CLAUDE.md exists (root)"
elif file_exists "AGENTS.md"; then
  check_pass "AGENTS.md exists"
else
  check_fail "No CLAUDE.md or AGENTS.md found"
  add_quick_win "Create CLAUDE.md with project overview, build commands, and conventions"
fi

# Build/test commands in entry point
ENTRY_FILE=""
for f in ".claude/CLAUDE.md" "CLAUDE.md" "AGENTS.md"; do
  if file_exists "$f"; then
    ENTRY_FILE="$PROJECT_DIR/$f"
    break
  fi
done

if [ -n "$ENTRY_FILE" ]; then
  if grep -qiE "(npm run|yarn |pnpm |make |cargo |go build|pytest|jest)" "$ENTRY_FILE" 2>/dev/null; then
    check_pass "Build/test commands documented"
  else
    check_warn "No build/test commands found in entry point"
    add_quick_win "Add build/test commands to CLAUDE.md (copy-paste ready)"
  fi
fi

echo ""

# === 3. Code Quality Tools (Invariant Enforcement) ===

echo -e "${BOLD}🔧 Invariant Enforcement${NC}"

# Linter
if file_exists ".eslintrc.js" || file_exists ".eslintrc.json" || file_exists ".eslintrc.cjs" || file_exists "eslint.config.js" || file_exists "eslint.config.mjs" || file_exists ".eslintrc.yml" || file_exists "biome.json"; then
  check_pass "Linter configured"
else
  check_fail "No linter found (ESLint / Biome)"
  add_quick_win "Set up ESLint or Biome for automatic code quality checks"
fi

# Formatter
if file_exists ".prettierrc" || file_exists ".prettierrc.js" || file_exists ".prettierrc.json" || file_exists ".prettierrc.cjs" || file_exists "biome.json"; then
  check_pass "Formatter configured"
else
  check_warn "No formatter found (Prettier / Biome)"
fi

# TypeScript strict
if file_exists "tsconfig.json"; then
  if grep -q '"strict":\s*true' "$PROJECT_DIR/tsconfig.json" 2>/dev/null || grep -q '"strict": true' "$PROJECT_DIR/tsconfig.json" 2>/dev/null; then
    check_pass "TypeScript strict mode enabled"
  else
    check_warn "TypeScript strict mode not enabled"
    add_quick_win "Enable \"strict\": true in tsconfig.json"
  fi
fi

# Pre-commit hooks
if dir_exists ".husky" || file_exists ".pre-commit-config.yaml" || file_exists ".lefthook.yml"; then
  check_pass "Pre-commit hooks configured"
else
  check_fail "No pre-commit hooks found"
  add_quick_win "Set up husky + lint-staged for pre-commit checks"
fi

# CI/CD
if dir_exists ".github/workflows" || file_exists ".gitlab-ci.yml" || file_exists "Jenkinsfile" || file_exists ".circleci/config.yml"; then
  check_pass "CI/CD pipeline configured"
else
  check_warn "No CI/CD pipeline found"
fi

echo ""

# === 4. Project Structure ===

echo -e "${BOLD}📂 Project Structure${NC}"

# README
if file_exists "README.md"; then
  check_pass "README.md exists"
else
  check_warn "No README.md"
fi

# .gitignore
if file_exists ".gitignore"; then
  check_pass ".gitignore exists"
else
  check_warn "No .gitignore"
fi

# Environment variables
if file_exists ".env.example" || file_exists ".env.sample" || file_exists ".env.template"; then
  check_pass "Environment template exists (.env.example)"
elif file_exists ".env"; then
  check_warn ".env exists but no .env.example template for documentation"
  add_quick_win "Create .env.example with variable names (without secrets)"
fi

# Tests
if dir_exists "__tests__" || dir_exists "test" || dir_exists "tests" || dir_exists "spec" || dir_exists "src/__tests__"; then
  check_pass "Test directory exists"
elif find "$PROJECT_DIR/src" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | head -1 | grep -q .; then
  check_pass "Test files found (co-located)"
else
  check_warn "No test files found"
fi

echo ""

# === 5. Claude Code Integration ===

echo -e "${BOLD}🤖 Claude Code Integration${NC}"

if dir_exists ".claude"; then
  check_pass ".claude/ directory exists"

  if dir_exists ".claude/skills"; then
    SKILL_COUNT=$(find "$PROJECT_DIR/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    check_pass "Skills installed (${SKILL_COUNT} found)"
  else
    check_warn "No skills installed"
    add_quick_win "Install toolkit: npx @choblue/claude-code-toolkit --fe (or --be)"
  fi

  if dir_exists ".claude/agents"; then
    check_pass "Agents configured"
  else
    check_warn "No agents configured"
  fi

  if file_exists ".claude/settings.json"; then
    if grep -q "hooks" "$PROJECT_DIR/.claude/settings.json" 2>/dev/null; then
      check_pass "Hooks registered in settings.json"
    else
      check_warn "No hooks in settings.json"
    fi
  fi

  if file_exists ".claude/PROJECT_MAP.md"; then
    check_pass "PROJECT_MAP.md exists (faster exploration)"
  else
    check_warn "No PROJECT_MAP.md"
    add_quick_win "Generate PROJECT_MAP.md: bash .claude/scripts/generate-project-map.sh"
  fi
else
  check_fail "No .claude/ directory"
  add_quick_win "Install toolkit: npx @choblue/claude-code-toolkit"
fi

echo ""

# === Results ===

TOTAL=$((PASS + FAIL + WARN))
SCORE=0
if [ "$TOTAL" -gt 0 ]; then
  SCORE=$(( (PASS * 100) / TOTAL ))
fi

# Maturity level
if [ "$SCORE" -ge 80 ]; then
  LEVEL="L5: Autonomous"
  LEVEL_COLOR="$GREEN"
elif [ "$SCORE" -ge 60 ]; then
  LEVEL="L4: Optimized"
  LEVEL_COLOR="$GREEN"
elif [ "$SCORE" -ge 40 ]; then
  LEVEL="L3: Structured"
  LEVEL_COLOR="$YELLOW"
elif [ "$SCORE" -ge 20 ]; then
  LEVEL="L2: Basic"
  LEVEL_COLOR="$YELLOW"
else
  LEVEL="L1: None"
  LEVEL_COLOR="$RED"
fi

echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}📊 Results${NC}"
echo ""
echo -e "  ${GREEN}✓ ${PASS} passed${NC}  ${RED}✗ ${FAIL} failed${NC}  ${YELLOW}⚠ ${WARN} warnings${NC}"
echo ""
echo -e "  Score: ${BOLD}${SCORE}/100${NC}  Level: ${LEVEL_COLOR}${BOLD}${LEVEL}${NC}"
echo ""

# Recommended skills
if [ -n "$RECOMMENDED_SKILLS" ]; then
  echo -e "${BOLD}📌 Recommended Skills${NC}"
  echo -e "  ${DIM}Based on detected stack:${NC}${BOLD}${RECOMMENDED_SKILLS}${NC}"
  echo ""
  SKILLS_CSV="$(echo "$RECOMMENDED_SKILLS" | xargs | tr ' ' ',')"
  echo -e "  ${DIM}Install:${NC} npx @choblue/claude-code-toolkit --skills=${SKILLS_CSV}"
  echo ""
fi

# Quick wins
if [ -n "$QUICK_WINS" ]; then
  echo -e "${BOLD}🔧 Quick Wins${NC}"
  echo -e "$QUICK_WINS"
  echo ""
fi