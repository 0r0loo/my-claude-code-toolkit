# my-claude-code-toolkit 프로젝트 규칙

이 파일은 `.claude/CLAUDE.md`(글로벌 규칙)를 **오버라이드**한다.

---

## install.sh 동기화 규칙

`install.sh`는 스킬/에이전트/프롬프트 파일을 사용자 프로젝트에 복사하는 스크립트다.
**파일 구조가 변경될 때 반드시 install.sh를 함께 수정해야 한다.**

### 동기화가 필요한 변경
- 스킬 추가/삭제/이동 (skills/ 하위)
- 에이전트 추가/삭제 (agents/ 하위)
- 프롬프트 추가/삭제 (prompts/ 하위)
- hooks, scripts 추가/삭제

### install.sh 구조
- `copy_common_core()` — 최소 공통 (--skills 모드에서도 설치)
- `copy_common()` — 전체 공통 (기존 --fe/--be 모드)
- `copy_fe()` — FE 전용 파일 (--fe)
- `copy_be()` — BE 전용 파일 (--be)
- `merge_settings_json()` — settings.json 머지 (기존 설정 보존)
- `uninstall_toolkit()` — 매니페스트 기반 제거 (--uninstall)
- `copy_dir "path"` — 디렉토리 전체를 재귀 복사 (references/ 포함)
- `copy_file "path"` — 개별 파일 복사

### 규칙
- 새 스킬 디렉토리 추가 시: `copy_dir "skills/스킬명"`을 적절한 함수에 추가
- 스킬 삭제/이동 시: 기존 `copy_dir`/`copy_file` 경로를 수정
- references/ 하위 파일은 `copy_dir`이 재귀 처리하므로 개별 추가 불필요
- **변경 후 반드시 테스트**: `cd /tmp && mkdir test && cd test && bash /path/to/install.sh`

---

## 배포 체크리스트

커밋/푸시/배포 요청 시 다음을 순서대로 확인한다:

1. install.sh가 현재 파일 구조와 일치하는가?
2. README.md 구조도가 최신인가?
3. CHANGELOG.md에 변경사항이 기록되었는가?
4. `.claude/CLAUDE.md` 문서 참조 가이드가 최신인가?
