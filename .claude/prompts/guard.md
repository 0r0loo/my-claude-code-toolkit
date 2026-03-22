`/careful` + `/freeze`를 동시에 활성화한다. 위험 명령 방어와 편집 범위 제한을 결합한 최대 안전 모드.

## 입력
- `/guard [경로]` → careful 세션 모드 + freeze를 지정 경로로 활성화
- `/guard --off` → careful + freeze 모두 해제

---

## 동작

### `/guard [경로]`

1. `/careful` 세션 모드를 활성화한다 (위험 명령 자동 감지)
2. `/freeze [경로]`를 활성화한다 (편집 범위 제한)
3. 결합 상태를 출력한다:

```
🛡️ guard 활성화
├── ⚠️ careful: 위험 명령 자동 감지 중
└── 🔒 freeze: [경로] 이하만 편집 허용

해제: /guard --off
```

### `/guard --off`

1. `/careful --off` 실행
2. `/freeze --off` 실행
3. 해제 상태를 출력한다:

```
🛡️ guard 해제
├── ✅ careful: 비활성화
└── 🔓 freeze: 모든 경로 편집 허용
```

---

## 규칙

- guard 활성 중에는 `/careful`과 `/freeze`의 모든 규칙이 동시에 적용된다
- `/careful --off` 또는 `/freeze --off`를 개별 실행하면 해당 기능만 해제된다
- `/guard --off`는 둘 다 해제한다

---

## 예시

### /guard src/modules/payment
결제 모듈 디버깅 시: payment 디렉토리만 편집 가능 + 위험 명령 경고

### /guard src/
src 전체를 편집 범위로 하되 위험 명령 보호

### /guard --off
모든 안전 제한 해제
