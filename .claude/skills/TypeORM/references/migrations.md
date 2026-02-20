# TypeORM Migrations - 마이그레이션 가이드

> 이 문서는 `../SKILL.md`의 참조 문서이다.

---

## 1. CLI 명령어

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

---

## 2. 마이그레이션 파일 작성 패턴

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

---

## 3. 마이그레이션 원칙

- `up`과 `down`을 반드시 쌍으로 작성한다 (되돌릴 수 있어야 한다)
- `down`은 `up`의 역순으로 실행한다
- `synchronize: true`는 개발 환경에서만 사용한다 - 프로덕션에서는 마이그레이션만 사용한다