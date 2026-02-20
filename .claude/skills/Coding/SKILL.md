---
name: coding
description: 공통 코딩 원칙과 패턴. 코드 작성 시 항상 참조하며, SRP, 네이밍 컨벤션, 에러 처리, 코드 품질 체크리스트를 제공한다.
---

# Coding Skill - 공통 원칙

이 문서는 모든 코드 작성 시 적용되는 공통 원칙을 정의한다.
FE/BE별 상세 규칙은 각각의 파일을 참고한다.
- `frontend.md` - React 프론트엔드 규칙
- `backend.md` - NestJS 백엔드 규칙

---

## 1. 설계 원칙

### SRP (Single Responsibility Principle)
- 함수는 하나의 작업만 수행한다
- 클래스/모듈은 하나의 책임만 갖는다
- "이 함수가 하는 일"을 한 문장으로 설명할 수 없으면 분리한다

### 결합도(Coupling)와 응집도(Cohesion)
- **낮은 결합도**: 모듈 간 의존성을 최소화한다
  - 인터페이스/추상화를 통해 의존한다
  - 구현 세부사항에 직접 의존하지 않는다
- **높은 응집도**: 관련 있는 로직을 같은 모듈에 모은다
  - 하나의 모듈 안에서 데이터와 동작이 밀접하게 관련된다

### DRY (Don't Repeat Yourself)
- 동일한 로직이 3번 이상 반복되면 추출한다
- 단, 2번까지는 중복을 허용한다 (섣부른 추상화 방지)

---

## 2. 네이밍 컨벤션

### 일반 규칙
- 의도를 드러내는 이름을 사용한다
- 축약어를 피한다 (`btn` → `button`, `msg` → `message`)
- 단, 관례적 축약은 허용한다 (`id`, `url`, `api`, `dto`)

### 변수/함수
```
// Bad
const d = new Date();
const list = getItems();
function process(data) {}

// Good
const createdAt = new Date();
const activeUsers = getActiveUsers();
function validateUserInput(input) {}
```

### Boolean
- `is`, `has`, `can`, `should` 접두사를 사용한다
```
isActive, hasPermission, canEdit, shouldRender
```

### 함수
- 동사로 시작한다
- 반환값이 예측 가능한 이름을 사용한다
```
getUserById()    // User 반환
calculateTotal() // number 반환
isValid()        // boolean 반환
```

---

## 3. 에러 핸들링

### 원칙
- 시스템 경계(외부 API, 사용자 입력, 파일 I/O)에서 에러를 처리한다
- 내부 로직에서 불필요한 try-catch를 남발하지 않는다
- 에러 메시지는 디버깅에 도움되는 정보를 포함한다

### 패턴
```typescript
// Bad - 에러를 삼킴
try {
  await saveUser(user);
} catch (e) {
  // do nothing
}

// Bad - 원본 에러 정보 손실
try {
  await saveUser(user);
} catch (e) {
  throw new Error('저장 실패');
}

// Good - 원본 에러 보존
try {
  await saveUser(user);
} catch (e) {
  throw new Error(`사용자 저장 실패: ${user.id}`, { cause: e });
}
```

---

## 4. 코드 품질 체크리스트

코드 작성/리뷰 시 다음을 확인한다:
- [ ] 함수/클래스가 SRP를 지키는가?
- [ ] 네이밍이 의도를 드러내는가?
- [ ] 시스템 경계에서 에러 핸들링이 되어 있는가?
- [ ] 불필요한 복잡도가 없는가?
- [ ] `any` 타입을 사용하지 않았는가?
- [ ] 기존 프로젝트 패턴과 일관성이 있는가?