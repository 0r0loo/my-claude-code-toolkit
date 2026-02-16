# TDD Skill - Backend (NestJS)

NestJS 백엔드 테스트에 적용되는 규칙이다.
공통 원칙은 `SKILL.md`를 함께 참고한다.

---

## 1. 레이어별 테스트 전략

### 우선순위

테스트 작성 우선순위는 비즈니스 로직이 집중된 레이어 순서로 한다.

| 우선순위 | 레이어 | 이유 |
|----------|--------|------|
| 1 | **Service** | 비즈니스 로직의 핵심. 가장 많은 분기와 로직이 존재한다 |
| 2 | **Controller** | 요청/응답 변환, DTO 유효성 검증 확인 |
| 3 | **Guard / Pipe** | 인증/인가, 데이터 변환 등 횡단 관심사 |
| 4 | **Repository** | 복잡한 쿼리가 있는 경우에 한정 |

---

## 2. NestJS Testing Module

### 기본 설정

NestJS는 `@nestjs/testing`을 사용하여 DI 컨테이너를 구성한다.

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { UserService } from './user.service';
import { UserRepository } from './user.repository';

describe('UserService', () => {
  let service: UserService;
  let repository: jest.Mocked<UserRepository>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: UserRepository,
          useValue: {
            findById: jest.fn(),
            save: jest.fn(),
            delete: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    repository = module.get(UserRepository);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });
});
```

### 규칙
- 테스트 대상 클래스는 실제 구현체를 사용한다
- 의존성(DI로 주입되는 것)은 Mock으로 대체한다
- `afterEach`에서 `jest.clearAllMocks()`를 호출하여 테스트 간 격리를 보장한다

---

## 3. DI Mock 패턴

### Provider 오버라이드

```typescript
// 방법 1: useValue - 필요한 메서드만 Mock 객체로 제공
{
  provide: UserRepository,
  useValue: {
    findById: jest.fn(),
    save: jest.fn(),
  },
}

// 방법 2: useClass - Mock 클래스를 정의하여 제공
{
  provide: UserRepository,
  useClass: MockUserRepository,
}

// 방법 3: useFactory - 동적으로 Mock 생성
{
  provide: UserRepository,
  useFactory: () => ({
    findById: jest.fn().mockResolvedValue(mockUser),
    save: jest.fn().mockResolvedValue(mockUser),
  }),
}
```

### Token 기반 주입 Mock

```typescript
// 인터페이스 기반 주입인 경우
{
  provide: 'USER_REPOSITORY',
  useValue: {
    findById: jest.fn(),
  },
}

// ConfigService Mock
{
  provide: ConfigService,
  useValue: {
    get: jest.fn((key: string) => {
      const config = { JWT_SECRET: 'test-secret', DB_HOST: 'localhost' };
      return config[key];
    }),
  },
}
```

---

## 4. Service 테스트

### 비즈니스 로직 테스트

```typescript
describe('UserService', () => {
  describe('findById', () => {
    it('should return user when user exists', async () => {
      // Arrange
      const mockUser = { id: '1', name: 'John', email: 'john@test.com' };
      repository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await service.findById('1');

      // Assert
      expect(result).toEqual(mockUser);
      expect(repository.findById).toHaveBeenCalledWith('1');
    });

    it('should throw UserNotFoundException when user does not exist', async () => {
      // Arrange
      repository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(service.findById('999')).rejects.toThrow(
        UserNotFoundException,
      );
    });
  });
});
```

---

## 5. DTO 검증 테스트

`class-validator`와 `ValidationPipe`를 활용한 DTO 유효성 검증을 테스트한다.

```typescript
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { CreateUserDto } from './create-user.dto';

describe('CreateUserDto', () => {
  it('should pass validation with valid data', async () => {
    // Arrange
    const dto = plainToInstance(CreateUserDto, {
      name: 'John',
      email: 'john@test.com',
    });

    // Act
    const errors = await validate(dto);

    // Assert
    expect(errors).toHaveLength(0);
  });

  it('should fail validation when email is invalid', async () => {
    // Arrange
    const dto = plainToInstance(CreateUserDto, {
      name: 'John',
      email: 'invalid-email',
    });

    // Act
    const errors = await validate(dto);

    // Assert
    expect(errors).toHaveLength(1);
    expect(errors[0].property).toBe('email');
  });

  it('should fail validation when name is empty', async () => {
    // Arrange
    const dto = plainToInstance(CreateUserDto, {
      name: '',
      email: 'john@test.com',
    });

    // Act
    const errors = await validate(dto);

    // Assert
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('name');
  });
});
```

---

## 6. 비동기 테스트 패턴

### async/await

```typescript
// 성공 케이스
it('should create user successfully', async () => {
  repository.save.mockResolvedValue(mockUser);

  const result = await service.createUser(createUserDto);

  expect(result).toEqual(mockUser);
});

// 에러 케이스
it('should throw error when save fails', async () => {
  repository.save.mockRejectedValue(new Error('DB connection failed'));

  await expect(service.createUser(createUserDto)).rejects.toThrow(
    'DB connection failed',
  );
});
```

### Promise 체이닝 (레거시 코드 테스트 시)

```typescript
it('should resolve with user data', () => {
  repository.findById.mockResolvedValue(mockUser);

  return service.findById('1').then((result) => {
    expect(result).toEqual(mockUser);
  });
});
```

### 규칙
- `async/await`를 기본으로 사용한다
- 비동기 테스트에서 `await`를 빠뜨리지 않는다 (테스트가 항상 통과하는 위험)
- 에러 케이스는 `rejects.toThrow()`로 검증한다

---

## 7. E2E 테스트

### 기본 설정

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('UserController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /users', () => {
    it('should create a new user (201)', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ name: 'John', email: 'john@test.com' })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('id');
          expect(res.body.name).toBe('John');
        });
    });

    it('should return 400 when email is invalid', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ name: 'John', email: 'invalid' })
        .expect(400);
    });
  });

  describe('GET /users/:id', () => {
    it('should return user by id (200)', () => {
      return request(app.getHttpServer())
        .get('/users/1')
        .expect(200)
        .expect((res) => {
          expect(res.body.id).toBe('1');
        });
    });

    it('should return 404 when user not found', () => {
      return request(app.getHttpServer())
        .get('/users/999')
        .expect(404);
    });
  });
});
```

### 규칙
- E2E 테스트 파일은 `test/` 디렉토리에 `*.e2e-spec.ts`로 배치한다
- `ValidationPipe` 등 글로벌 설정을 테스트 앱에도 동일하게 적용한다
- `beforeAll`에서 앱을 초기화하고 `afterAll`에서 반드시 종료한다
- HTTP 상태 코드와 응답 본문을 모두 검증한다

---

## 8. 파일 위치 및 네이밍

| 대상 | 위치 | 예시 |
|------|------|------|
| 단위 테스트 | 소스 파일과 같은 디렉토리 (co-located) | `user.service.spec.ts` |
| E2E 테스트 | `test/` 디렉토리 | `test/user.e2e-spec.ts` |
| 테스트 유틸/팩토리 | `test/utils/` 또는 `test/factories/` | `test/factories/user.factory.ts` |

### 규칙
- 단위 테스트 파일 확장자: `*.spec.ts`
- E2E 테스트 파일 확장자: `*.e2e-spec.ts`
- 테스트 파일은 테스트 대상과 같은 이름을 사용한다

---

## 9. 금지 사항

- 테스트에서 실제 데이터베이스에 직접 연결 금지 (단위 테스트)
- `setTimeout`으로 비동기 대기 금지 (`mockResolvedValue` 등을 사용)
- 테스트 간 상태 공유 금지 (각 테스트는 독립적이어야 함)
- 구현 세부사항 테스트 금지 (private 메서드 직접 테스트 등)
- `any` 타입 사용 금지 (Mock 타입도 명시)