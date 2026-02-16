# TDD Agent - Backend (NestJS)

NestJS 기반 백엔드 테스트를 작성할 때 이 규칙을 따른다.
공통 규칙은 `common.md`를 함께 참고한다.

---

## 테스트 우선순위

NestJS 레이어별 테스트 중요도에 따라 우선순위를 정한다:

1. **Service** - 비즈니스 로직이 집중된 핵심 레이어 (필수)
2. **Controller** - 요청/응답 매핑, DTO 바인딩 검증 (권장)
3. **Guard / Interceptor / Pipe** - 횡단 관심사 검증 (필요 시)
4. **E2E** - 전체 요청 흐름 통합 검증 (주요 시나리오)

---

## 단위 테스트 패턴

### Test.createTestingModule 사용
```typescript
import { Test, TestingModule } from '@nestjs/testing';

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

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
```

### Mock 패턴: Provider 오버라이드
```typescript
// 방법 1: useValue - 직접 Mock 객체 제공
{
  provide: UserRepository,
  useValue: {
    findById: jest.fn().mockResolvedValue(mockUser),
  },
}

// 방법 2: useClass - Mock 클래스 제공
{
  provide: UserRepository,
  useClass: MockUserRepository,
}

// 방법 3: useFactory - 동적 Mock 생성
{
  provide: UserRepository,
  useFactory: () => ({
    findById: jest.fn(),
  }),
}
```

### jest.Mocked 타입 활용
```typescript
// 타입 안전한 Mock 사용
let repository: jest.Mocked<UserRepository>;

// 자동 완성과 타입 체크가 가능하다
repository.findById.mockResolvedValue(mockUser);
expect(repository.findById).toHaveBeenCalledWith('1');
```

### Controller 테스트
```typescript
describe('UserController', () => {
  let controller: UserController;
  let service: jest.Mocked<UserService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UserController],
      providers: [
        {
          provide: UserService,
          useValue: {
            getUserById: jest.fn(),
            createUser: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<UserController>(UserController);
    service = module.get(UserService);
  });

  describe('GET /users/:id', () => {
    it('should return user when valid id is given', async () => {
      const mockUser = { id: '1', name: 'Alice' };
      service.getUserById.mockResolvedValue(mockUser);

      const result = await controller.getUserById('1');

      expect(result).toEqual(mockUser);
    });
  });
});
```

---

## E2E 테스트 패턴

### supertest + INestApplication
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('UserController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/users (GET) should return user list', () => {
    return request(app.getHttpServer())
      .get('/users')
      .expect(200)
      .expect((res) => {
        expect(Array.isArray(res.body)).toBe(true);
      });
  });

  it('/users (POST) should create a new user', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ name: 'Alice', email: 'alice@example.com' })
      .expect(201)
      .expect((res) => {
        expect(res.body).toHaveProperty('id');
        expect(res.body.name).toBe('Alice');
      });
  });
});
```

---

## 파일 네이밍

### 단위 테스트 (co-located)
```
src/
├── modules/
│   └── user/
│       ├── user.service.ts
│       ├── user.service.spec.ts        # Service 테스트
│       ├── user.controller.ts
│       └── user.controller.spec.ts     # Controller 테스트
```

### E2E 테스트
```
test/
├── user.e2e-spec.ts
├── auth.e2e-spec.ts
└── jest-e2e.json
```

---

## 규칙

- 단위 테스트 파일명은 `*.spec.ts`로 소스 파일 옆에 배치한다 (co-located)
- E2E 테스트 파일명은 `*.e2e-spec.ts`로 `test/` 디렉토리에 배치한다
- `Test.createTestingModule`로 의존성을 격리한다 - 직접 `new`로 생성하지 않는다
- DB 의존 테스트는 테스트용 DB 또는 인메모리 DB를 사용한다
- E2E 테스트에서 `afterAll`로 반드시 앱을 종료(`app.close()`)한다
- `.claude/skills/TDD/backend.md`의 규칙을 따른다