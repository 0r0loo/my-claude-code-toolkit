편집 범위를 특정 경로로 제한한다. 읽기는 허용하고, 지정 경로 외의 파일 수정/생성/삭제를 차단한다.

## 입력
- `/freeze [경로]` → 해당 경로 이하만 편집 허용
- `/freeze --status` → 현재 freeze 상태 확인
- `/freeze --off` → freeze 해제

---

## 동작 규칙

### `/freeze [경로]`

지정 경로를 편집 허용 범위로 설정한다.
설정 즉시 다음을 출력한다:

```
🔒 freeze 활성화
허용 경로: [경로]
허용: 읽기, [경로] 이하 파일 수정/생성/삭제
차단: [경로] 외부 파일 수정/생성/삭제
해제: /freeze --off
```

freeze 활성 중 허용 경로 외부를 수정하려 하면:
```
🚫 freeze 차단: [파일 경로]
현재 허용 경로: [경로]
이 파일을 편집하려면 /freeze --off로 해제하거나
/freeze [새 경로]로 범위를 변경하라
```

### `/freeze --status`

현재 상태를 출력한다.

활성 상태:
```
🔒 freeze 활성
허용 경로: [경로]
이 세션에서 수정된 파일:
  - [파일1]
  - [파일2]
```

비활성 상태:
```
🔓 freeze 비활성
모든 경로 편집 허용 중
```

### `/freeze --off`

freeze를 해제한다.

```
🔓 freeze 해제
모든 경로 편집이 다시 허용됩니다
```

---

## 적용 범위

| 작업 | freeze 활성 시 |
|------|----------------|
| 파일 읽기 (Read, Grep, Glob) | ✅ 항상 허용 |
| 허용 경로 내 파일 수정 | ✅ 허용 |
| 허용 경로 내 파일 생성 | ✅ 허용 |
| 허용 경로 내 파일 삭제 | ✅ 허용 |
| 허용 경로 외 파일 수정 | 🚫 차단 |
| 허용 경로 외 파일 생성 | 🚫 차단 |
| 허용 경로 외 파일 삭제 | 🚫 차단 |
| 터미널 명령 실행 | ✅ 허용 (파일 시스템 직접 변경 시 주의) |

---

## 예시

### /freeze src/components/Button
Button 컴포넌트 관련 파일만 편집 가능하도록 제한

```
🔒 freeze 활성화
허용 경로: src/components/Button
허용: 읽기, src/components/Button 이하 파일 수정/생성/삭제
차단: src/components/Button 외부 파일 수정/생성/삭제
해제: /freeze --off
```

이후 `src/utils/format.ts` 수정 시도 시:
```
🚫 freeze 차단: src/utils/format.ts
현재 허용 경로: src/components/Button
이 파일을 편집하려면 /freeze --off로 해제하거나
/freeze src/utils로 범위를 변경하라
```

### /freeze src/
src 디렉토리 전체를 허용 범위로 설정

### /freeze --status
현재 freeze 상태와 수정된 파일 목록 확인

### /freeze --off
제한 해제
