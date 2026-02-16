# TDD Skill - 핵심 원칙

이 문서는 모든 테스트 코드 작성 시 적용되는 공통 원칙을 정의한다.
FE/BE별 상세 규칙은 각각의 파일을 참고한다.
- `frontend.md` - React Testing Library 기반 프론트엔드 테스트 규칙
- `backend.md` - NestJS 백엔드 테스트 규칙

---

## 1. TDD 핵심 사이클

모든 기능 구현은 Red-Green-Refactor 사이클을 따른다.

### Red (실패하는 테스트 작성)
- 구현 코드보다 **테스트를 먼저** 작성한다
- 테스트가 실패하는 것을 확인한 뒤 다음 단계로 진행한다
- 실패 이유가 "기능이 없어서"여야 한다 (문법 에러가 아님)

### Green (최소한의 코드로 통과)
- 테스트를 통과시키는 **가장 단순한** 코드를 작성한다
- 완벽한 설계나 최적화를 고려하지 않는다
- 하드코딩이라도 괜찮다 - 목표는 "초록불"이다

### Refactor (리팩토링)
- 테스트가 통과하는 상태를 유지하면서 코드를 개선한다
- 중복을 제거하고, 네이밍을 개선하고, 구조를 정리한다
- 리팩토링 후 반드시 테스트를 다시 실행한다

```
[Red] 실패하는 테스트 작성
  ↓
[Green] 최소 구현으로 통과
  ↓
[Refactor] 코드 개선 (테스트 유지)
  ↓
[Red] 다음 테스트 작성 ...
```

---

## 2. FIRST 원칙

좋은 테스트는 다음 5가지 특성을 갖는다.

| 원칙 | 설명 | 위반 예시 |
|------|------|-----------|
| **Fast** | 빠르게 실행된다 | DB 연결, 네트워크 호출이 포함된 단위 테스트 |
| **Isolated** | 다른 테스트에 의존하지 않는다 | 테스트 실행 순서에 따라 결과가 달라짐 |
| **Repeatable** | 어떤 환경에서도 동일한 결과를 낸다 | 현재 시각, 랜덤 값에 의존하는 테스트 |
| **Self-validating** | 성공/실패가 자동 판별된다 | console.log로 결과를 수동 확인 |
| **Timely** | 구현 코드와 함께(또는 먼저) 작성된다 | 구현 완료 후 나중에 테스트 추가 |

---

## 3. AAA 패턴 (Arrange-Act-Assert)

모든 테스트는 3단계로 구성한다. 각 단계를 빈 줄로 구분하여 가독성을 높인다.

```typescript
it('should calculate total price with discount', () => {
  // Arrange - 테스트 전제 조건을 설정한다
  const cart = new Cart();
  cart.addItem({ name: 'Book', price: 10000 });
  const discount = 0.1;

  // Act - 테스트 대상을 실행한다
  const totalPrice = cart.calculateTotal(discount);

  // Assert - 기대 결과를 검증한다
  expect(totalPrice).toBe(9000);
});
```

### 규칙
- **Arrange**: 테스트에 필요한 데이터, Mock, 환경을 준비한다
- **Act**: 테스트 대상 함수/메서드를 **한 번만** 호출한다
- **Assert**: 결과를 검증한다. 하나의 테스트에서 관련된 단언만 포함한다
- 빈 줄 또는 주석(`// Arrange`, `// Act`, `// Assert`)으로 구분한다

---

## 4. 테스트 네이밍

### describe-it 패턴

```typescript
describe('CartService', () => {
  describe('calculateTotal', () => {
    it('should return 0 when cart is empty', () => {});
    it('should sum all item prices', () => {});
    it('should apply discount rate to total', () => {});
    it('should throw error when discount is negative', () => {});
  });

  describe('addItem', () => {
    it('should add item to cart', () => {});
    it('should increase quantity when same item is added', () => {});
  });
});
```

### 규칙
- `describe`: 테스트 대상 (클래스명, 함수명, 컴포넌트명)
- `it`: `should` + 동작을 서술한다
- 중첩 `describe`로 메서드/시나리오를 그룹핑한다
- 테스트 이름만으로 **어떤 상황에서 어떤 결과가 나오는지** 파악할 수 있어야 한다

---

## 5. Mock / Stub / Spy 가이드라인

### 용어 정의

| 종류 | 역할 | 사용 시점 |
|------|------|-----------|
| **Stub** | 정해진 값을 반환한다 | 외부 의존성의 반환값을 제어할 때 |
| **Mock** | 호출 여부/인자를 검증한다 | 특정 함수가 호출되었는지 확인할 때 |
| **Spy** | 실제 구현을 유지하면서 호출을 추적한다 | 실제 동작은 유지하되 호출 여부만 확인할 때 |

### 사용해야 하는 경우
- 외부 시스템 호출 (API, DB, 파일 시스템)
- 비결정적 동작 (현재 시각, 랜덤 값)
- 느린 의존성 (네트워크, 디스크 I/O)
- 에러/예외 시나리오 재현

### 피해야 하는 경우
- 테스트 대상 자체를 Mock하는 것 (의미 없는 테스트)
- 내부 구현 세부사항을 Mock하는 것 (리팩토링에 취약)
- 과도한 Mock으로 실제 동작과 괴리가 생기는 것

```typescript
// Bad - 내부 구현을 Mock하여 리팩토링 시 테스트가 깨짐
jest.spyOn(service, 'privateHelper');
expect(service['privateHelper']).toHaveBeenCalled();

// Good - 공개 인터페이스의 결과를 검증
const result = service.processOrder(orderDto);
expect(result.status).toBe('COMPLETED');
```

### 원칙
- **Mock은 경계(boundary)에서만 사용한다** (외부 시스템과의 접점)
- **공개 인터페이스를 통해 검증한다** (구현이 아닌 행동을 테스트)
- Mock이 많아지면 설계를 의심한다 (의존성이 과도한 신호)

---

## 6. 테스트 품질 체크리스트

테스트 작성/리뷰 시 다음을 확인한다:

- [ ] 테스트가 구현 없이 실패하는가? (Red 단계 확인)
- [ ] 하나의 테스트가 하나의 동작만 검증하는가?
- [ ] AAA 패턴이 명확하게 구분되는가?
- [ ] 테스트 이름만으로 시나리오를 이해할 수 있는가?
- [ ] Mock이 경계(외부 의존성)에서만 사용되었는가?
- [ ] 테스트 간 의존성이 없는가? (실행 순서 무관)
- [ ] 테스트가 구현 세부사항이 아닌 행동을 검증하는가?
- [ ] 엣지 케이스가 포함되어 있는가? (빈 값, null, 경계값)
- [ ] 에러/예외 케이스가 포함되어 있는가?
- [ ] 불필요한 테스트 코드 중복이 없는가? (`beforeEach` 활용)