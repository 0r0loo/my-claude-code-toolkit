#!/bin/bash
# quality-gate.sh
# UserPromptSubmit hook - 매 프롬프트마다 실행되어 품질 체크 프로토콜을 상기시킨다.

# 사용자 프롬프트를 stdin으로 받는다
PROMPT=$(cat)

# 품질 체크 메시지를 출력한다 (Claude가 읽는 컨텍스트)
cat << 'EOF'
[Quality Gate Reminder]
- 작업 전: 적절한 Agent/Skill이 있는지 확인하라
- 코드 구현: code-writer 에이전트에 위임하라 (직접 작성 금지)
- 코드 수정 후: code-reviewer 에이전트로 리뷰하라
- Git 작업: git-manager 에이전트에 위임하라
- Context 절약: 탐색은 explore 에이전트에 위임하라
EOF