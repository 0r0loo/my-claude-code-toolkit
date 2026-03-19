---
name: typeorm
description: TypeORM Entity, Repository, QueryBuilder 가이드. NestJS에서 TypeORM을 사용한 Entity 정의, Relations, Repository 패턴, 마이그레이션, 트랜잭션 등 데이터베이스 작업 시 참조한다.
targetLib: "typeorm@0.3"
user-invocable: true
lastUpdated: 2026-03-19
---

# TypeORM Skill - TypeORM 규칙

NestJS와 함께 사용하는 TypeORM 패턴과 규칙을 정의한다.
NestJS 레이어 규칙은 `../Coding/backend.md`, 공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

> 코드 예시: `references/patterns.md` 참조

---

## 1. Entity 정의

- 모든 `@Column`에 `type`을 명시한다 (자동 추론에 의존 금지)
- `nullable`은 명시적으로 설정한다 (기본값 false)
- `default`를 사용하여 DB 레벨 기본값을 설정한다
- `@DeleteDateColumn`을 사용하여 soft delete를 구현한다
- 파일 네이밍: `PascalCase` 클래스명 + `kebab-case.entity.ts` 파일명

---

## 2. 관계 (Relations)

- `@JoinColumn`: OneToOne, ManyToOne 관계에서 FK 소유 쪽에 설정
- `@JoinTable`: ManyToMany 관계에서 소유 쪽에 설정 (중간 테이블 자동 생성)
- 기본은 **lazy** (관계를 자동 로딩하지 않음). `eager: true`는 남용하지 않는다
- `cascade: true`를 사용하지 않는다. 필요한 동작만 개별 설정 (`['insert', 'update']`)
- FK 컬럼을 명시적으로 선언하면 relation 로딩 없이 FK 값 접근 가능

---

## 3. Repository 패턴

- `@InjectRepository(Entity)`로 주입한다
- 비즈니스 특화 쿼리가 많으면 Custom Repository 사용 (`extends Repository<T>`)
- Custom Repository는 `DataSource`를 주입받아 `super(Entity, dataSource.createEntityManager())` 호출

### find 옵션

| 옵션 | 설명 | 예시 |
|------|------|------|
| `where` | 조건 필터링 | `{ isActive: true, role: UserRole.ADMIN }` |
| `relations` | 관계 로딩 | `['posts', 'profile']` |
| `order` | 정렬 | `{ createdAt: 'DESC' }` |
| `select` | 필요한 컬럼만 조회 | `{ id: true, name: true }` |
| `take` / `skip` | 페이지네이션 | `20` / `0` |
| `withDeleted` | soft delete 포함 | `true` |

---

## 4. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| Entity 클래스 | `PascalCase` | `User`, `UserProfile` |
| Entity 파일 | `kebab-case.entity.ts` | `user.entity.ts` |
| 컬럼 (코드) | `camelCase` | `firstName`, `isActive` |
| 컬럼 (DB) | `snake_case` 자동 변환 | `first_name`, `is_active` |
| 관계 필드 | 관련 Entity 이름 | `user`, `posts`, `orderItems` |
| FK 컬럼 | 관계명 + `Id` | `authorId`, `categoryId` |
| 인덱스 이름 | `IDX_테이블_컬럼` | `IDX_USER_EMAIL` |
| 마이그레이션 | `타임스탬프-설명` | `1700000000000-AddUserRole.ts` |

- `SnakeNamingStrategy`로 camelCase → snake_case 자동 변환 설정

---

## 참조 문서

- **[패턴 코드 예시](./references/patterns.md)** - Entity, Relations, Repository의 Bad/Good 코드 예시
- **[Advanced Queries](./references/advanced-queries.md)** - QueryBuilder 고급 사용법, 서브쿼리, N+1 해결
- **[Migrations](./references/migrations.md)** - 마이그레이션 생성, 실행, 롤백
- **[Transactions](./references/transactions.md)** - 트랜잭션 패턴 및 사용 가이드

---

## 5. 금지 사항

- `synchronize: true` 프로덕션 사용 금지 - 마이그레이션을 사용한다
- Raw SQL 직접 실행 금지 - QueryBuilder를 사용한다
- Entity에 비즈니스 로직 작성 금지 - Service 레이어에서 처리한다
- `any` 타입 사용 금지
- `cascade: true` 무분별 사용 금지 - 필요한 동작만 개별 설정
- `eager: true` 남용 금지 - 필요할 때 `relations` 옵션으로 로딩
- `find` 시 `where` 조건 없이 전체 조회 금지 - 반드시 조건 또는 pagination 사용
- Repository 외 레이어에서 직접 쿼리 실행 금지
- 마이그레이션 `down` 메서드 누락 금지 - 항상 롤백 가능해야 한다