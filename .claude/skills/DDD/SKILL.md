---
name: ddd
description: DDD 전술적 패턴 가이드. Entity, Value Object, Aggregate, Repository, Domain Service, Domain Event 등 도메인 모델링 시 참조한다.
user-invocable: true
lastUpdated: 2026-03-19
---

# DDD Skill - DDD 전술적 패턴 규칙

도메인 주도 설계(DDD)의 전술적 패턴과 규칙을 정의한다.
NestJS 레이어 규칙은 `../Coding/backend.md`, 공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

> Bad/Good 코드 예시: `references/patterns.md` 참조

---

## 1. Entity

- 식별자(id)로 구분되는 도메인 객체. 동등성 비교는 id로 한다
- 비즈니스 로직을 Entity 내부에 캡슐화한다 (Rich Domain Model)
- Entity는 자신의 상태를 스스로 보호한다 (불변식 보호)
- 외부에서 직접 상태를 변경하지 못하게 한다 (setter 노출 금지)

---

## 2. Value Object

- 불변(immutable) 객체. 속성 기반 동등성으로 비교한다
- 생성 시 자기 검증을 수행한다 (잘못된 상태로 생성 불가)
- 생성자를 `private`으로 두고 `static create` 팩토리 메서드로 유효성 검사를 강제한다
- 상태 변경이 필요하면 새로운 인스턴스를 반환한다
- 도메인 연산(add, multiply 등)을 Value Object 메서드로 제공한다

---

## 3. Aggregate

- Aggregate Root를 통해서만 내부 Entity에 접근한다
- 일관성 경계(consistency boundary) = 트랜잭션 범위
- Aggregate 간 참조는 ID로만 한다 (직접 참조 금지)
- 하나의 트랜잭션에서 하나의 Aggregate만 변경한다
- Aggregate를 작게 설계한다 (필요한 Entity만 포함)

---

## 4. Repository

- 도메인 관점의 컬렉션 인터페이스. 도메인 레이어에 인터페이스 정의
- 인프라 레이어에서 구현한다 (의존성 역전)
- Aggregate Root 단위로 정의한다 (내부 Entity용 Repository 금지)
- Mapper를 사용하여 도메인 모델과 영속성 모델(ORM Entity)을 분리한다

---

## 5. Domain Service

- Entity나 Value Object에 속하지 않는 도메인 로직을 담당한다
- 여러 Aggregate를 조율하는 로직을 수행한다
- 상태를 가지지 않는다 (stateless)
- 단일 Entity에 속하는 로직은 해당 Entity에 둔다 (Domain Service 아님)
- Domain Service(순수 도메인 로직)와 Application Service(유스케이스 흐름)를 혼동하지 않는다

---

## 6. Domain Event

- 도메인에서 발생한 중요한 변경을 알리는 불변 메시지
- 이벤트 이름은 과거형으로 작성한다 (OrderPlaced, not PlaceOrder)
- Aggregate 내부에서 이벤트를 수집하고, Application 레이어에서 발행한다
- 이벤트 핸들러 간에는 순서 의존성을 두지 않는다
- 이벤트를 통해 Aggregate 간 결합도를 낮춘다

---

## 7. 레이어 구조

```
Presentation → Application → Domain ← Infrastructure
```

| 레이어 | 역할 | 포함 요소 |
|--------|------|-----------|
| **Domain** | 핵심 비즈니스 규칙 | Entity, VO, Aggregate, Domain Service, Domain Event, Repository 인터페이스 |
| **Application** | 유스케이스 흐름 조율 | Application Service, DTO, 트랜잭션 관리, 이벤트 발행 |
| **Infrastructure** | 기술적 구현 | Repository 구현, ORM Entity, 외부 API 클라이언트 |
| **Presentation** | 외부 인터페이스 | Controller, Request/Response DTO, 인증/인가 |

- Domain 레이어는 외부에 의존하지 않는다 (순수 TypeScript)
- Infrastructure는 Domain의 인터페이스를 구현한다 (의존성 역전)

---

## 8. 금지 사항

- Entity에 getter/setter만 두고 로직을 Service에 몰아넣기 금지 (Anemic Domain Model)
- 도메인 레이어에서 인프라 기술(ORM 데코레이터 등)에 직접 의존 금지
- Aggregate 간 직접 객체 참조 금지 - ID 참조를 사용한다
- Aggregate 경계를 넘는 트랜잭션 금지 - 도메인 이벤트로 처리한다
- Application Service에 도메인 로직 작성 금지

---

## 참조 문서

- **[패턴 코드 예시](./references/patterns.md)** - 각 패턴의 Bad/Good 코드 예시
- **[Entity & Value Object 심화](./references/entity-vo.md)** - Entity 확장 패턴, Money 패턴 심화
- **[Aggregate & Repository 심화](./references/aggregate-repository.md)** - 불변식 보호, Repository 구현 패턴
- **[Domain Service & Domain Event 심화](./references/domain-events.md)** - 이벤트 발행/구독 패턴, AggregateRoot 기반