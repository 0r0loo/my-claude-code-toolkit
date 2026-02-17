# TypeORM Skill - TypeORM 규칙

NestJS와 함께 사용하는 TypeORM 패턴과 규칙을 정의한다.
NestJS 레이어 규칙은 `../Coding/backend.md`, 공통 코딩 원칙은 `../Coding/SKILL.md`를 함께 참고한다.

---

## 1. Entity 정의

### 기본 패턴

```typescript
// Good
@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'varchar', unique: true })
  email: string;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER })
  role: UserRole;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @DeleteDateColumn()
  deletedAt: Date | null;
}
```

### 컬럼 타입 명시
- 모든 `@Column`에 `type`을 명시한다
- TypeORM이 자동 추론하는 타입에 의존하지 않는다

```typescript
// Bad - 타입 추론에 의존
@Column()
name: string;

@Column()
age: number;

// Good - 타입 명시
@Column({ type: 'varchar', length: 255 })
name: string;

@Column({ type: 'int' })
age: number;
```

### nullable, default, unique 옵션
- `nullable`은 명시적으로 설정한다 (기본값 false)
- `default`를 사용하여 DB 레벨 기본값을 설정한다
- `unique` 제약은 `@Column`에 직접 설정하거나 `@Index`를 사용한다

```typescript
@Column({ type: 'varchar', nullable: true })
bio: string | null;

@Column({ type: 'int', default: 0 })
loginCount: number;

@Column({ type: 'varchar', unique: true })
email: string;
```

### Soft Delete
- `@DeleteDateColumn`을 사용하여 soft delete를 구현한다
- `softRemove`/`softDelete` 메서드를 사용한다
- `find` 시 삭제된 데이터는 자동으로 제외된다 (`withDeleted` 옵션으로 포함 가능)

### Entity 파일 네이밍
- `PascalCase` 클래스명 + `kebab-case.entity.ts` 파일명

```
user.entity.ts        -> User
user-profile.entity.ts -> UserProfile
order-item.entity.ts   -> OrderItem
```

---

## 2. 관계 (Relations)

### 기본 관계 데코레이터

```typescript
// OneToOne - User <-> Profile
@Entity()
export class User {
  @OneToOne(() => Profile, (profile) => profile.user, {
    cascade: ['insert', 'update'],
  })
  @JoinColumn() // 소유하는 쪽(FK가 있는 쪽)에 @JoinColumn 설정
  profile: Profile;
}

@Entity()
export class Profile {
  @OneToOne(() => User, (user) => user.profile)
  user: User;
}
```

```typescript
// OneToMany / ManyToOne - User <-> Post
@Entity()
export class User {
  @OneToMany(() => Post, (post) => post.author)
  posts: Post[];
}

@Entity()
export class Post {
  @ManyToOne(() => User, (user) => user.posts, { nullable: false })
  author: User;

  @Column({ type: 'uuid' })
  authorId: string; // FK 컬럼을 명시적으로 선언하면 relation 로딩 없이 FK 값 접근 가능
}
```

```typescript
// ManyToMany - Post <-> Tag
@Entity()
export class Post {
  @ManyToMany(() => Tag, (tag) => tag.posts)
  @JoinTable() // 소유하는 쪽에 @JoinTable 설정 (중간 테이블 생성)
  tags: Tag[];
}

@Entity()
export class Tag {
  @ManyToMany(() => Post, (post) => post.tags)
  posts: Post[];
}
```

### JoinColumn vs JoinTable
- `@JoinColumn`: OneToOne, ManyToOne 관계에서 FK를 소유하는 쪽에 설정한다
- `@JoinTable`: ManyToMany 관계에서 소유하는 쪽에 설정한다 (중간 테이블 자동 생성)

### eager vs lazy 로딩
- 기본은 **lazy** (관계를 자동 로딩하지 않음)
- `eager: true`는 남용하지 않는다
- 필요한 경우 `find`의 `relations` 옵션이나 `QueryBuilder`의 `leftJoinAndSelect`를 사용한다

```typescript
// Bad - eager 남용
@OneToMany(() => Post, (post) => post.author, { eager: true })
posts: Post[]; // User를 조회할 때마다 항상 posts를 로딩

// Good - 필요할 때만 관계 로딩
const user = await this.userRepository.findOne({
  where: { id: userId },
  relations: ['posts'],
});
```

### cascade 옵션
- `cascade: true`를 사용하지 않는다
- 필요한 동작만 개별적으로 설정한다

```typescript
// Bad - 무분별한 cascade
@OneToMany(() => Post, (post) => post.author, { cascade: true })
posts: Post[];

// Good - 필요한 동작만 설정
@OneToMany(() => Post, (post) => post.author, {
  cascade: ['insert', 'update'], // remove는 제외 - 의도치 않은 삭제 방지
})
posts: Post[];
```

---

## 3. Repository 패턴

### NestJS에서 Repository 주입

```typescript
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}
}
```

### Custom Repository

비즈니스에 특화된 쿼리가 많을 때 Custom Repository를 사용한다.

```typescript
// user.repository.ts
@Injectable()
export class UserRepository extends Repository<User> {
  constructor(private readonly dataSource: DataSource) {
    super(User, dataSource.createEntityManager());
  }

  async findActiveUsersByRole(role: UserRole): Promise<User[]> {
    return this.find({
      where: { isActive: true, role },
      order: { createdAt: 'DESC' },
    });
  }

  async findWithPosts(userId: string): Promise<User | null> {
    return this.findOne({
      where: { id: userId },
      relations: ['posts'],
    });
  }
}

// user.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UserService, UserRepository],
})
export class UserModule {}
```

### 기본 메서드 사용법

```typescript
// 단건 조회
const user = await this.userRepository.findOneBy({ id: userId });
const userWithRelation = await this.userRepository.findOne({
  where: { id: userId },
  relations: ['profile'],
});

// 목록 조회
const users = await this.userRepository.find({
  where: { isActive: true },
  order: { createdAt: 'DESC' },
  take: 20,
  skip: 0,
});

// 저장 (insert + update)
const user = this.userRepository.create({ name: '홍길동', email: 'hong@example.com' });
await this.userRepository.save(user);

// 삭제
await this.userRepository.remove(user);       // 하드 삭제
await this.userRepository.softRemove(user);    // 소프트 삭제

// 개수 조회
const count = await this.userRepository.count({ where: { isActive: true } });
```

### find 옵션

| 옵션 | 설명 | 예시 |
|------|------|------|
| `where` | 조건 필터링 | `{ isActive: true, role: UserRole.ADMIN }` |
| `relations` | 관계 로딩 | `['posts', 'profile']` |
| `order` | 정렬 | `{ createdAt: 'DESC' }` |
| `select` | 필요한 컬럼만 조회 | `{ id: true, name: true }` |
| `take` | 조회 개수 제한 | `20` |
| `skip` | 건너뛸 개수 | `0` |
| `withDeleted` | soft delete된 데이터 포함 | `true` |

---

## 4. QueryBuilder

### 기본 사용법

```typescript
const users = await this.userRepository
  .createQueryBuilder('user')
  .select(['user.id', 'user.name', 'user.email'])
  .where('user.isActive = :isActive', { isActive: true })
  .andWhere('user.role = :role', { role: UserRole.ADMIN })
  .orderBy('user.createdAt', 'DESC')
  .take(20)
  .skip(0)
  .getMany();
```

### JOIN

```typescript
// leftJoinAndSelect - 관계가 없어도 결과에 포함 (LEFT JOIN)
const users = await this.userRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.posts', 'post')
  .where('user.id = :id', { id: userId })
  .getOne();

// innerJoinAndSelect - 관계가 있는 경우만 포함 (INNER JOIN)
const usersWithPosts = await this.userRepository
  .createQueryBuilder('user')
  .innerJoinAndSelect('user.posts', 'post')
  .getMany();
```

### 서브쿼리

```typescript
// 서브쿼리로 특정 조건의 사용자 조회
const users = await this.userRepository
  .createQueryBuilder('user')
  .where((qb) => {
    const subQuery = qb
      .subQuery()
      .select('post.authorId')
      .from(Post, 'post')
      .where('post.createdAt > :date', { date: startDate })
      .getQuery();
    return `user.id IN ${subQuery}`;
  })
  .getMany();
```

### getOne vs getMany vs getRawOne vs getRawMany

| 메서드 | 반환 타입 | 용도 |
|--------|----------|------|
| `getOne()` | `Entity \| null` | Entity 단건 조회 |
| `getMany()` | `Entity[]` | Entity 목록 조회 |
| `getRawOne()` | `object \| undefined` | 가공된 데이터 단건 (집계 등) |
| `getRawMany()` | `object[]` | 가공된 데이터 목록 |

```typescript
// 집계 쿼리 - getRawOne 사용
const result = await this.postRepository
  .createQueryBuilder('post')
  .select('COUNT(post.id)', 'totalCount')
  .addSelect('AVG(post.viewCount)', 'avgViews')
  .where('post.authorId = :authorId', { authorId })
  .getRawOne();
// result: { totalCount: '42', avgViews: '128.5' }
```

### find vs QueryBuilder 가이드

| 상황 | 권장 방법 |
|------|----------|
| 단순 CRUD (조건 1~2개) | `find`, `findOne`, `findOneBy` |
| 단순 관계 로딩 | `find` + `relations` 옵션 |
| 복잡한 WHERE 조건 (OR, 중첩) | `QueryBuilder` |
| JOIN 조건이 복잡한 경우 | `QueryBuilder` |
| 집계 함수 (COUNT, SUM, AVG) | `QueryBuilder` + `getRawOne/getRawMany` |
| 서브쿼리가 필요한 경우 | `QueryBuilder` |
| 동적 조건 조합 | `QueryBuilder` |

---

## 5. 마이그레이션

### CLI 명령어

```bash
# 마이그레이션 자동 생성 (Entity 변경 감지)
npx typeorm migration:generate src/migrations/AddUserRole -d src/data-source.ts

# 마이그레이션 수동 생성 (빈 파일)
npx typeorm migration:create src/migrations/SeedInitialData

# 마이그레이션 실행
npx typeorm migration:run -d src/data-source.ts

# 마이그레이션 되돌리기 (가장 최근 1개)
npx typeorm migration:revert -d src/data-source.ts
```

### 마이그레이션 파일 작성 패턴

```typescript
export class AddUserRole1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'user',
      new TableColumn({
        name: 'role',
        type: 'enum',
        enum: ['user', 'admin', 'moderator'],
        default: `'user'`,
      }),
    );

    await queryRunner.createIndex(
      'user',
      new TableIndex({
        name: 'IDX_USER_ROLE',
        columnNames: ['role'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('user', 'IDX_USER_ROLE');
    await queryRunner.dropColumn('user', 'role');
  }
}
```

### 마이그레이션 원칙
- `up`과 `down`을 반드시 쌍으로 작성한다 (되돌릴 수 있어야 한다)
- `down`은 `up`의 역순으로 실행한다
- `synchronize: true`는 개발 환경에서만 사용한다 - 프로덕션에서는 마이그레이션만 사용한다

---

## 6. 트랜잭션

### DataSource.transaction() 패턴

가장 간결한 트랜잭션 패턴이다. 콜백 내에서 제공되는 `EntityManager`를 사용한다.

```typescript
@Injectable()
export class OrderService {
  constructor(private readonly dataSource: DataSource) {}

  async createOrder(dto: CreateOrderDto): Promise<Order> {
    return this.dataSource.transaction(async (manager) => {
      const order = manager.create(Order, {
        userId: dto.userId,
        totalAmount: dto.totalAmount,
      });
      await manager.save(order);

      const orderItems = dto.items.map((item) =>
        manager.create(OrderItem, { ...item, orderId: order.id }),
      );
      await manager.save(orderItems);

      await manager.decrement(
        Product,
        { id: In(dto.items.map((i) => i.productId)) },
        'stock',
        1,
      );

      return order;
    });
  }
}
```

### QueryRunner를 사용한 수동 트랜잭션

세밀한 제어가 필요한 경우 사용한다.

```typescript
async transferPoints(fromId: string, toId: string, amount: number): Promise<void> {
  const queryRunner = this.dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    await queryRunner.manager.decrement(User, { id: fromId }, 'points', amount);
    await queryRunner.manager.increment(User, { id: toId }, 'points', amount);

    await queryRunner.commitTransaction();
  } catch (error) {
    await queryRunner.rollbackTransaction();
    throw error;
  } finally {
    await queryRunner.release(); // 반드시 release
  }
}
```

### 트랜잭션 선택 가이드

| 상황 | 권장 패턴 |
|------|----------|
| 단순 다중 저장 | `DataSource.transaction()` |
| 조건부 커밋/롤백 | `QueryRunner` 수동 트랜잭션 |
| 중간에 외부 API 호출 필요 | `QueryRunner` (커밋 시점 제어) |

---

## 7. 성능 최적화

### N+1 문제 방지

```typescript
// Bad - N+1 문제 발생 (users를 조회 후 각 user마다 posts를 개별 조회)
const users = await this.userRepository.find();
for (const user of users) {
  const posts = await this.postRepository.find({ where: { authorId: user.id } });
}

// Good - relations으로 한 번에 조회
const users = await this.userRepository.find({
  relations: ['posts'],
});

// Good - QueryBuilder로 한 번에 조회
const users = await this.userRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.posts', 'post')
  .getMany();
```

### select로 필요한 컬럼만 조회

```typescript
// Bad - 모든 컬럼 조회
const users = await this.userRepository.find();

// Good - 필요한 컬럼만 조회
const users = await this.userRepository.find({
  select: { id: true, name: true, email: true },
});

// Good - QueryBuilder에서 select
const users = await this.userRepository
  .createQueryBuilder('user')
  .select(['user.id', 'user.name', 'user.email'])
  .getMany();
```

### 인덱스 설정

```typescript
@Entity()
@Index(['email'], { unique: true })
@Index(['isActive', 'role']) // 복합 인덱스 - 자주 함께 조회하는 컬럼
@Index(['createdAt'])         // 정렬에 자주 사용되는 컬럼
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar' })
  email: string;

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'enum', enum: UserRole })
  role: UserRole;

  @CreateDateColumn()
  createdAt: Date;
}
```

### 인덱스 설정 원칙
- WHERE 조건에 자주 사용되는 컬럼에 인덱스를 설정한다
- ORDER BY에 자주 사용되는 컬럼에 인덱스를 설정한다
- 복합 인덱스는 카디널리티가 높은 컬럼을 앞에 배치한다
- 불필요한 인덱스는 쓰기 성능을 저하시키므로 남용하지 않는다

### Pagination

```typescript
async findUsers(page: number, limit: number): Promise<{ data: User[]; total: number }> {
  const [data, total] = await this.userRepository.findAndCount({
    order: { createdAt: 'DESC' },
    take: limit,
    skip: (page - 1) * limit,
  });

  return { data, total };
}
```

---

## 8. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| Entity 클래스 | `PascalCase` | `User`, `UserProfile` |
| Entity 파일 | `kebab-case.entity.ts` | `user.entity.ts`, `user-profile.entity.ts` |
| 컬럼 (코드) | `camelCase` | `firstName`, `isActive`, `createdAt` |
| 컬럼 (DB) | `snake_case` 자동 변환 | `first_name`, `is_active`, `created_at` |
| 관계 필드 | 관련 Entity 이름 (camelCase) | `user`, `posts`, `profile`, `orderItems` |
| FK 컬럼 | 관계명 + `Id` | `authorId`, `categoryId` |
| Repository 파일 | `kebab-case.repository.ts` | `user.repository.ts` |
| 인덱스 이름 | `IDX_테이블_컬럼` | `IDX_USER_EMAIL`, `IDX_POST_CREATED_AT` |
| 마이그레이션 파일 | `타임스탬프-설명` | `1700000000000-AddUserRole.ts` |

### snake_case 자동 변환 설정

`data-source.ts`에서 `NamingStrategy`를 설정하여 코드의 camelCase가 DB에서 snake_case로 자동 변환되도록 한다.

```typescript
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';

export const dataSource = new DataSource({
  // ...
  namingStrategy: new SnakeNamingStrategy(),
});
```

---

## 9. 금지 사항

- `synchronize: true` 프로덕션 사용 금지 - 마이그레이션을 사용한다
- Raw SQL 직접 실행 금지 (`query()` 메서드 사용 금지) - QueryBuilder를 사용한다
- Entity에 비즈니스 로직 작성 금지 - Service 레이어에서 처리한다
- `any` 타입 사용 금지
- `cascade: true` 무분별 사용 금지 - 필요한 동작만 개별 설정한다 (`['insert', 'update']`)
- `eager: true` 남용 금지 - 필요할 때 `relations` 옵션으로 로딩한다
- `find` 시 `where` 조건 없이 전체 조회 금지 (대량 데이터 위험) - 반드시 조건 또는 pagination을 사용한다
- Repository 외 레이어에서 직접 쿼리 실행 금지 - `../Coding/backend.md` 레이어 규칙을 따른다
- 마이그레이션 `down` 메서드 누락 금지 - 항상 롤백 가능해야 한다
