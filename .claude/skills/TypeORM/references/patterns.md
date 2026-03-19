# TypeORM 패턴 코드 예시

## 1. Entity 기본 패턴

```typescript
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

## 2. 컬럼 타입 명시

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

## 3. 관계 (Relations)

### OneToOne

```typescript
@Entity()
export class User {
  @OneToOne(() => Profile, (profile) => profile.user, {
    cascade: ['insert', 'update'],
  })
  @JoinColumn()
  profile: Profile;
}

@Entity()
export class Profile {
  @OneToOne(() => User, (user) => user.profile)
  user: User;
}
```

### OneToMany / ManyToOne

```typescript
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

### ManyToMany

```typescript
@Entity()
export class Post {
  @ManyToMany(() => Tag, (tag) => tag.posts)
  @JoinTable()
  tags: Tag[];
}

@Entity()
export class Tag {
  @ManyToMany(() => Post, (post) => post.tags)
  posts: Post[];
}
```

### eager vs lazy 로딩

```typescript
// Bad - eager 남용
@OneToMany(() => Post, (post) => post.author, { eager: true })
posts: Post[];

// Good - 필요할 때만 관계 로딩
const user = await this.userRepository.findOne({
  where: { id: userId },
  relations: ['posts'],
});
```

### cascade 옵션

```typescript
// Bad - 무분별한 cascade
@OneToMany(() => Post, (post) => post.author, { cascade: true })
posts: Post[];

// Good - 필요한 동작만 설정
@OneToMany(() => Post, (post) => post.author, {
  cascade: ['insert', 'update'],
})
posts: Post[];
```

## 4. Repository 패턴

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

```typescript
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

## 5. snake_case 자동 변환 설정

```typescript
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';

export const dataSource = new DataSource({
  // ...
  namingStrategy: new SnakeNamingStrategy(),
});
```