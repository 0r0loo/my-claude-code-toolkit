# Coding Skill - Backend (NestJS)

NestJS 백엔드 코드에 적용되는 규칙이다.
공통 원칙은 `SKILL.md`를 함께 참고한다.

---

## 1. 레이어별 책임

### Controller
- HTTP 요청/응답 변환
- DTO 유효성 검증 (데코레이터를 통해)
- 비즈니스 로직 없음
- 적절한 HTTP 데코레이터 사용 (`@Get`, `@Post`, `@Param`, `@Body` 등)

### Service
- 비즈니스 로직 처리
- 트랜잭션 관리
- 다른 Service 조합
- 순환 참조 금지

### Repository
- 데이터베이스 CRUD
- 쿼리 작성
- 데이터 매핑

### Guard / Interceptor / Pipe
- 횡단 관심사 (인증, 로깅, 변환)
- 재사용 가능하게 설계

---

## 2. DTO 작성

- `class-validator` 데코레이터로 유효성 검증을 선언한다
- `class-transformer`를 활용하여 변환한다
- Partial, Pick, Omit 등 mapped type을 활용한다

```typescript
export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsEmail()
  email: string;
}

export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

---

## 3. 에러 핸들링 (NestJS)

- NestJS 내장 `HttpException`을 사용한다
- 커스텀 예외는 `HttpException`을 상속한다
- 글로벌 Exception Filter를 활용한다
- Service에서 HttpException을 직접 던지지 않는다 (비즈니스 예외를 별도 정의)

```typescript
// Bad - Service에서 HTTP 의존
throw new NotFoundException('사용자를 찾을 수 없습니다');

// Good - 비즈니스 예외 정의 후 Controller/Filter에서 변환
throw new UserNotFoundException(userId);
```

---

## 4. 의존성 주입 (DI)

- `new`로 직접 생성하지 않는다 - DI를 통해 주입받는다
- 환경 변수는 `ConfigService`를 통해 접근한다
- 인터페이스 기반 주입을 권장한다

---

## 5. 네이밍 컨벤션 (BE)

| 대상 | 규칙 | 예시 |
|------|------|------|
| 파일 | `kebab-case` | `create-user.dto.ts` |
| 클래스 | `PascalCase` + 역할 접미사 | `UserService`, `CreateUserDto` |
| 메서드 | `camelCase` + 동사 | `findById`, `createUser` |
| 테스트 | `*.spec.ts` | `user.service.spec.ts` |
| 모듈 디렉토리 | `kebab-case` | `user-profile/` |

---

## 6. 금지 사항

- Controller에 비즈니스 로직 작성 금지
- Repository 외 레이어에서 직접 쿼리 실행 금지
- `any` 타입 사용 금지
- 환경 변수 직접 접근 (`process.env`) 금지 → `ConfigService` 사용
- 순환 의존 금지 (Module 간, Service 간)