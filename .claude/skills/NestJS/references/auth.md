# NestJS 인증/인가 (Auth)

NestJS 환경의 인증(Authentication)과 인가(Authorization) 패턴.

---

## 1. 핵심 개념

| 용어 | 의미 | 예시 |
|------|------|------|
| **인증(Authentication)** | "누구인가?" — 신원 확인 | 로그인, JWT 검증 |
| **인가(Authorization)** | "할 수 있는가?" — 권한 확인 | 역할(Role) 체크, 리소스 소유자 확인 |

인증 → 인가 순서를 항상 지킨다. 인가는 인증 이후에만 수행한다.

---

## 2. JWT 인증

### 토큰 구조

```typescript
// Access Token — 짧은 수명, 요청마다 전송
type AccessTokenPayload = {
  sub: string;       // 사용자 ID
  role: string;      // 역할
  iat: number;       // 발급 시각
  exp: number;       // 만료 시각
};

// Refresh Token — 긴 수명, Access Token 갱신용
type RefreshTokenPayload = {
  sub: string;
  tokenId: string;   // 토큰 식별자 (revoke용)
  iat: number;
  exp: number;
};
```

### 토큰 수명 가이드

| 토큰 | 수명 | 저장 위치 |
|------|------|-----------|
| Access Token | 15분 ~ 1시간 | Authorization 헤더 (Bearer) |
| Refresh Token | 7일 ~ 30일 | httpOnly 쿠키 또는 DB |

### 금지 사항
- Access Token에 민감 정보 넣지 않는다 (비밀번호, 개인정보)
- Refresh Token을 localStorage에 저장하지 않는다
- 토큰 만료 검증을 클라이언트에만 의존하지 않는다

---

## 3. Guard 패턴

### AuthGuard (인증)

```typescript
@Injectable()
class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    // Public 엔드포인트는 인증 건너뛰기
    const isPublic = this.reflector.getAllAndOverride<boolean>(
      IS_PUBLIC_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest();
    const token = this.extractToken(request);
    if (!token) throw new UnauthorizedException();

    const payload = this.jwtService.verify(token);
    request.user = payload;
    return true;
  }

  private extractToken(request: Request): string | null {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : null;
  }
}
```

### RoleGuard (인가)

```typescript
// 데코레이터 정의
const ROLES_KEY = 'roles';
const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);

// Guard
@Injectable()
class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles) return true;

    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.includes(user.role);
  }
}
```

### 사용

```typescript
// 전역 적용 (AppModule)
providers: [
  { provide: APP_GUARD, useClass: JwtAuthGuard },
  { provide: APP_GUARD, useClass: RolesGuard },
]

// Public 엔드포인트
@Public()
@Post('auth/login')
login(@Body() dto: LoginDto) {}

// Role 제한
@Roles('admin')
@Delete('users/:id')
deleteUser(@Param('id') id: string) {}
```

---

## 4. 커스텀 데코레이터

### 현재 사용자 추출

```typescript
const CurrentUser = createParamDecorator(
  (data: keyof AccessTokenPayload | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);

// 사용
@Get('profile')
getProfile(@CurrentUser() user: AccessTokenPayload) {}

@Get('my-posts')
getMyPosts(@CurrentUser('sub') userId: string) {}
```

### Public 데코레이터

```typescript
const IS_PUBLIC_KEY = 'isPublic';
const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
```

---

## 5. 리소스 소유자 확인

Role만으로 부족할 때 — "이 리소스의 소유자인가?"를 확인한다.

```typescript
// Bad - Controller에서 직접 확인
@Patch('posts/:id')
async updatePost(
  @Param('id') id: string,
  @CurrentUser('sub') userId: string,
  @Body() dto: UpdatePostDto,
) {
  const post = await this.postService.findById(id);
  if (post.authorId !== userId) throw new ForbiddenException();
  return this.postService.update(id, dto);
}

// Good - Guard로 분리
@UseGuards(ResourceOwnerGuard)
@Patch('posts/:id')
async updatePost(
  @Param('id') id: string,
  @Body() dto: UpdatePostDto,
) {
  return this.postService.update(id, dto);
}
```

---

## 6. 비밀번호 처리

```typescript
// 해싱 — bcrypt 사용
import * as bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

async function verifyPassword(plain: string, hashed: string): Promise<boolean> {
  return bcrypt.compare(plain, hashed);
}
```

### 규칙
- 평문 비밀번호를 DB에 저장하지 않는다
- 평문 비밀번호를 로그에 출력하지 않는다
- Salt는 bcrypt 내장 사용 (직접 생성 금지)
- 비밀번호 검증 실패 시 "비밀번호 틀림"이 아닌 "이메일 또는 비밀번호가 올바르지 않습니다" 응답 (정보 노출 방지)

---

## 7. 토큰 갱신 흐름

```
1. 클라이언트 → [Access Token] → 서버
2. 서버: Access Token 만료 → 401 응답
3. 클라이언트 → [Refresh Token] → POST /auth/refresh
4. 서버: Refresh Token 검증 → 새 Access Token 발급
5. (선택) Refresh Token Rotation: 새 Refresh Token도 함께 발급
```

### Refresh Token Rotation
- 갱신 시 기존 Refresh Token을 무효화하고 새 토큰 발급
- 탈취된 토큰 재사용 방지
- DB에 토큰 ID를 저장하여 revoke 관리

---

## 8. 파일 구조

```
src/
  auth/
    auth.module.ts
    auth.controller.ts
    auth.service.ts
    guards/
      jwt-auth.guard.ts
      roles.guard.ts
      resource-owner.guard.ts
    decorators/
      current-user.decorator.ts
      public.decorator.ts
      roles.decorator.ts
    strategies/           # Passport 사용 시
      jwt.strategy.ts
      local.strategy.ts
    dto/
      login.dto.ts
      register.dto.ts
      refresh-token.dto.ts
    types/
      token-payload.ts
```

---

## 9. 체크리스트

- [ ] Access Token 수명이 1시간 이하인가?
- [ ] Refresh Token이 httpOnly 쿠키 또는 DB에 저장되는가?
- [ ] 비밀번호가 bcrypt로 해싱되는가?
- [ ] Public 엔드포인트가 명시적으로 표시되는가?
- [ ] 인증 실패 시 구체적 정보를 노출하지 않는가?
- [ ] Guard가 전역 적용되고, 예외만 @Public()으로 처리하는가?
- [ ] 토큰 payload에 민감 정보가 없는가?
