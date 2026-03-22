#!/usr/bin/env bash
# browse 도구 빌드 스크립트
# 사용법: bash .claude/tools/browse/setup.sh
set -e

BROWSE_DIR="$(cd "$(dirname "$0")" && pwd)"
BROWSE_BIN="$BROWSE_DIR/dist/browse"

# Bun 체크
if ! command -v bun >/dev/null 2>&1; then
  echo "Error: Bun이 필요합니다."
  echo "설치: curl -fsSL https://bun.sh/install | bash"
  exit 1
fi

# 빌드 필요 여부 확인
NEEDS_BUILD=0
if [ ! -x "$BROWSE_BIN" ]; then
  NEEDS_BUILD=1
elif [ -n "$(find "$BROWSE_DIR/src" -type f -newer "$BROWSE_BIN" -print -quit 2>/dev/null)" ]; then
  NEEDS_BUILD=1
elif [ "$BROWSE_DIR/package.json" -nt "$BROWSE_BIN" ]; then
  NEEDS_BUILD=1
fi

if [ "$NEEDS_BUILD" -eq 0 ]; then
  echo "browse: 이미 빌드됨 ($BROWSE_BIN)"
  exit 0
fi

echo "browse: 빌드 중..."
cd "$BROWSE_DIR"
bun install
bun run build

if [ ! -x "$BROWSE_BIN" ]; then
  echo "Error: 빌드 실패 — $BROWSE_BIN 생성 안 됨"
  exit 1
fi

# Playwright Chromium 설치 확인
echo "browse: Playwright Chromium 확인 중..."
if ! bun --eval 'import { chromium } from "playwright"; const b = await chromium.launch(); await b.close();' >/dev/null 2>&1; then
  echo "browse: Chromium 설치 중..."
  bunx playwright install chromium
fi

echo "browse: 준비 완료 ($BROWSE_BIN)"
