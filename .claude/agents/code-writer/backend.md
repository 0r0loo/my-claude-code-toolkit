# Code Writer Agent - Backend (NestJS)

NestJS 기반 백엔드 코드를 구현할 때 이 규칙을 따른다.
공통 규칙은 `common.md`를 함께 참고한다.

---

## 구현 순서

NestJS의 모듈 구조를 따라 아래 순서로 구현한다:

1. **Module** - 기능 단위 모듈 정의, 의존성 등록
2. **DTO** - 요청/응답 데이터 형식 정의 (class-validator 데코레이터)
3. **Entity** - 데이터베이스 엔티티 정의 (TypeORM/Prisma)
4. **Repository** - 데이터 접근 로직 (Custom Repository 필요 시)
5. **Service** - 비즈니스 로직
6. **Controller** - 엔드포인트 정의, DTO 바인딩
7. **Guard / Interceptor / Pipe** - 횡단 관심사 (필요 시)

---

## NestJS 패턴 가이드

### 모듈 구조
```
src/
├── modules/
│   └── user/
│       ├── user.module.ts
│       ├── user.controller.ts
│       ├── user.service.ts
│       ├── user.repository.ts (선택)
│       ├── dto/
│       │   ├── create-user.dto.ts
│       │   └── update-user.dto.ts
│       └── entities/
│           └── user.entity.ts
├── common/
│   ├── guards/
│   ├── interceptors/
│   ├── pipes/
│   ├── filters/
│   └── decorators/
└── config/
```

### DTO 작성
- `class-validator` 데코레이터로 유효성 검증을 선언한다
- `class-transformer`를 활용하여 변환한다
- Partial, Pick, Omit 등 mapped type을 활용한다

```typescript
// 예시
export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEmail()
  email: string;
}
```

### Service 레이어
- Service는 비즈니스 로직만 담당한다
- 다른 Service를 주입받을 수 있지만, 순환 참조를 피한다
- 트랜잭션이 필요하면 Service 레벨에서 관리한다

### Controller 레이어
- Controller는 요청/응답 변환만 담당한다
- 비즈니스 로직을 Controller에 넣지 않는다
- 적절한 HTTP 데코레이터를 사용한다 (`@Get`, `@Post`, `@Param`, `@Body` 등)

### 에러 핸들링
- NestJS 내장 HttpException을 사용한다
- 커스텀 예외는 `HttpException`을 상속한다
- 글로벌 Exception Filter를 활용한다

---

## 네이밍 컨벤션

- 파일: `kebab-case` (e.g., `create-user.dto.ts`, `user.service.ts`)
- 클래스: `PascalCase` + 역할 접미사 (e.g., `UserService`, `CreateUserDto`)
- 메서드: `camelCase` + 동사 시작 (e.g., `findById`, `createUser`)
- 테스트: `*.spec.ts` (e.g., `user.service.spec.ts`)

---

## 규칙

- NestJS CLI가 생성하는 기본 구조를 따른다
- DI(의존성 주입)를 적극 활용한다 - `new`로 직접 생성하지 않는다
- 환경 변수는 `ConfigService`를 통해 접근한다
- 데이터베이스 쿼리는 Repository/ORM 레이어에서만 수행한다