---
name: typeorm
description: TypeORM Entity, Repository, QueryBuilder 가이드. NestJS에서 TypeORM을 사용한 Entity 정의, Relations, Repository 패턴, 마이그레이션, 트랜잭션 등 데이터베이스 작업 시 참조한다.
---

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

## 4. 네이밍 컨벤션

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

## 참조 문서

- **[Advanced Queries](./references/advanced-queries.md)** - QueryBuilder 고급 사용법, 서브쿼리, 성능 최적화, N+1 문제 해결
- **[Migrations](./references/migrations.md)** - 마이그레이션 생성, 실행, 롤백 및 작성 패턴
- **[Transactions](./references/transactions.md)** - 트랜잭션 패턴 및 사용 가이드

---

## 5. 금지 사항

- `synchronize: true` 프로덕션 사용 금지 - 마이그레이션을 사용한다
- Raw SQL 직접 실행 금지 (`query()` 메서드 사용 금지) - QueryBuilder를 사용한다
- Entity에 비즈니스 로직 작성 금지 - Service 레이어에서 처리한다
- `any` 타입 사용 금지
- `cascade: true` 무분별 사용 금지 - 필요한 동작만 개별 설정한다 (`['insert', 'update']`)
- `eager: true` 남용 금지 - 필요할 때 `relations` 옵션으로 로딩한다
- `find` 시 `where` 조건 없이 전체 조회 금지 (대량 데이터 위험) - 반드시 조건 또는 pagination을 사용한다
- Repository 외 레이어에서 직접 쿼리 실행 금지 - `../Coding/backend.md` 레이어 규칙을 따른다
- 마이그레이션 `down` 메서드 누락 금지 - 항상 롤백 가능해야 한다