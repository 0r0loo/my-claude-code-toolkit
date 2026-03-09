# NestJS 캐싱 (Caching)

NestJS CacheModule + Redis 기반 캐싱 전략.

---

## 1. 기본 설정

```typescript
// app.module.ts
import { CacheModule } from '@nestjs/cache-manager';
import { redisStore } from 'cache-manager-redis-yet';

@Module({
  imports: [
    CacheModule.registerAsync({
      isGlobal: true,
      useFactory: async (configService: ConfigService) => ({
        store: await redisStore({
          socket: {
            host: configService.get('REDIS_HOST'),
            port: configService.get('REDIS_PORT'),
          },
        }),
        ttl: 60 * 1000, // 기본 TTL: 60초 (ms)
      }),
      inject: [ConfigService],
    }),
  ],
})
export class AppModule {}
```

---

## 2. 캐시 전략

### TTL 가이드

| 데이터 유형 | TTL | 예시 |
|-------------|-----|------|
| 거의 안 바뀜 | 1시간 ~ 24시간 | 카테고리 목록, 설정값 |
| 자주 조회, 가끔 변경 | 5분 ~ 30분 | 상품 목록, 게시글 |
| 자주 변경 | 30초 ~ 5분 | 랭킹, 알림 수 |
| 실시간 | 캐시 안 함 | 채팅, 재고 수량 |

### 캐시 키 네이밍

```typescript
// Bad - 충돌 가능
'users'
'user_1'

// Good - 네임스페이스 + 식별자
'users:list:page:1:limit:20'
'users:detail:${userId}'
'products:category:${categoryId}:page:${page}'
```

---

## 3. 사용 패턴

### Interceptor 기반 (자동)

```typescript
@Controller('products')
class ProductController {
  // GET 응답을 자동 캐싱
  @UseInterceptors(CacheInterceptor)
  @CacheTTL(300_000) // 5분
  @CacheKey('products:list')
  @Get()
  findAll() {
    return this.productService.findAll();
  }
}
```

### Service에서 직접 사용 (수동)

```typescript
@Injectable()
class ProductService {
  constructor(
    @Inject(CACHE_MANAGER) private readonly cache: Cache,
    private readonly productRepository: ProductRepository,
  ) {}

  async findById(id: string): Promise<Product> {
    const cacheKey = `products:detail:${id}`;

    // 캐시 조회
    const cached = await this.cache.get<Product>(cacheKey);
    if (cached) return cached;

    // DB 조회 + 캐시 저장
    const product = await this.productRepository.findById(id);
    if (product) {
      await this.cache.set(cacheKey, product, 300_000); // 5분
    }
    return product;
  }

  async update(id: string, dto: UpdateProductDto): Promise<Product> {
    const product = await this.productRepository.update(id, dto);

    // 캐시 무효화
    await this.cache.del(`products:detail:${id}`);
    await this.cache.del('products:list'); // 목록 캐시도 무효화

    return product;
  }
}
```

---

## 4. 캐시 무효화 전략

### 직접 무효화 (Write-Through)

```typescript
// 데이터 변경 시 관련 캐시를 즉시 삭제
async update(id: string, dto: UpdateDto): Promise<Entity> {
  const result = await this.repository.update(id, dto);
  await this.cache.del(`entity:${id}`);
  return result;
}
```

### 패턴 기반 무효화

```typescript
// Redis SCAN으로 패턴 매칭 삭제
async invalidatePattern(pattern: string): Promise<void> {
  const redis = (this.cache as any).store.client;
  let cursor = '0';
  do {
    const [nextCursor, keys] = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
    cursor = nextCursor;
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  } while (cursor !== '0');
}

// 사용: 특정 카테고리의 모든 상품 캐시 무효화
await this.invalidatePattern('products:category:electronics:*');
```

---

## 5. Cache-Aside vs Read-Through

### Cache-Aside (권장)

```
1. 클라이언트 → 캐시 조회
2. 캐시 MISS → DB 조회 → 캐시 저장 → 응답
3. 캐시 HIT → 바로 응답
```

애플리케이션이 캐시를 직접 관리. NestJS에서 가장 일반적.

### Read-Through

```
1. 클라이언트 → 캐시 조회
2. 캐시가 자동으로 DB 조회 → 저장 → 응답
```

캐시 레이어가 DB 조회를 담당. 설정이 복잡하지만 코드가 깔끔.

---

## 6. 주의사항

- 캐시 키에 사용자별 데이터를 포함할 때 **userId를 키에 포함**한다
- 민감한 데이터(토큰, 비밀번호)를 캐시에 저장하지 않는다
- 캐시 서버 장애 시에도 서비스가 동작해야 한다 (graceful degradation)
- 직렬화/역직렬화 비용을 고려한다 (큰 객체는 캐싱 효과가 낮을 수 있음)

---

## 7. 체크리스트

- [ ] TTL이 데이터 특성에 맞게 설정되어 있는가?
- [ ] 캐시 키가 네임스페이스로 구분되어 있는가?
- [ ] 데이터 변경 시 관련 캐시를 무효화하는가?
- [ ] 캐시 서버 장애 시 fallback이 있는가?
- [ ] 민감한 데이터가 캐시에 저장되지 않는가?
