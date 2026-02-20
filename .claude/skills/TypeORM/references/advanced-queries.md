# TypeORM Advanced Queries - QueryBuilder 고급 사용법 및 성능 최적화

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. QueryBuilder

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

## 2. 성능 최적화

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