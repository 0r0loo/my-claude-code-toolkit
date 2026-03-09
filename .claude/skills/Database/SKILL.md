---
name: database
description: 데이터베이스 설계 및 최적화 가이드. 스키마 설계, 정규화, 관계, 인덱싱, N+1 방지, 쿼리 최적화 등 언어/ORM 무관한 DB 원칙을 제공한다.
---

# Database Skill - DB 설계 & 최적화

언어/ORM에 무관한 데이터베이스 설계 원칙과 최적화 전략.

---

## 1. 테이블 설계

### 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 테이블 | `snake_case`, 복수형 | `users`, `order_items` |
| 컬럼 | `snake_case` | `created_at`, `user_id` |
| PK | `id` (단순) 또는 `테이블_id` | `id`, `user_id` |
| FK | `참조테이블_단수_id` | `user_id`, `category_id` |
| Boolean | `is_` 접두사 | `is_active`, `is_deleted` |
| 날짜 | `_at` 접미사 | `created_at`, `deleted_at` |

### 공통 컬럼

모든 테이블에 포함하는 기본 컬럼:

```sql
id          BIGINT PRIMARY KEY AUTO_INCREMENT,
created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

---

## 2. 정규화

### 단계별 가이드

| 정규형 | 규칙 | 실무 적용 |
|--------|------|-----------|
| **1NF** | 원자값만 저장 | JSON 배열 대신 별도 테이블 |
| **2NF** | 부분 종속 제거 | 복합키 → PK 분리 |
| **3NF** | 이행 종속 제거 | 파생 데이터 별도 저장 안 함 |

### 실무 원칙
- **3NF까지 정규화**한 후, 성능 필요 시 역정규화
- 역정규화 시 반드시 **트레이드 오프를 문서화**
- 역정규화 대상: 자주 JOIN하는 읽기 전용 데이터, 집계 값

```sql
-- Bad - 1NF 위반 (배열을 한 컬럼에)
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  tags VARCHAR(255)  -- "developer,frontend,react"
);

-- Good - 별도 테이블
CREATE TABLE user_tags (
  user_id BIGINT REFERENCES users(id),
  tag VARCHAR(50),
  PRIMARY KEY (user_id, tag)
);
```

---

## 3. 관계 설계

### 1:N (가장 흔함)

```sql
-- users 1 : N posts
CREATE TABLE posts (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  title VARCHAR(255) NOT NULL
);
```

### N:M (중간 테이블)

```sql
-- users N : M roles
CREATE TABLE user_roles (
  user_id BIGINT REFERENCES users(id),
  role_id BIGINT REFERENCES roles(id),
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id)
);
```

### 1:1 (드물게)

```sql
-- users 1 : 1 user_profiles
CREATE TABLE user_profiles (
  user_id BIGINT PRIMARY KEY REFERENCES users(id),
  bio TEXT,
  avatar_url VARCHAR(500)
);
```

### 규칙
- FK에는 반드시 인덱스를 건다
- `ON DELETE` 전략을 명시한다 (CASCADE, SET NULL, RESTRICT)
- 순환 참조를 피한다

---

## 4. Soft Delete

```sql
-- Soft Delete 패턴
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP NULL DEFAULT NULL;

-- 조회 시 항상 필터
SELECT * FROM users WHERE deleted_at IS NULL;
```

### 언제 사용하나?
- **Soft Delete**: 감사 로그 필요, 복구 가능성, 법적 보관 의무
- **Hard Delete**: 개인정보 삭제 요청 (GDPR), 임시 데이터

### 주의사항
- Unique 제약에 `deleted_at`을 포함해야 한다 (삭제 후 재생성 허용)
- 모든 쿼리에 `WHERE deleted_at IS NULL` 조건이 누락되지 않도록 한다
- ORM의 Global Filter/Scope 기능을 활용한다

---

## 5. 인덱싱 전략

### 인덱스를 걸어야 하는 곳
- WHERE 조건에 자주 사용되는 컬럼
- JOIN에 사용되는 FK 컬럼
- ORDER BY에 사용되는 컬럼
- Unique 제약이 필요한 컬럼

### 인덱스를 걸지 말아야 하는 곳
- 카디널리티가 낮은 컬럼 (Boolean, 상태값 2~3개)
- 자주 UPDATE되는 컬럼
- 테이블 크기가 작은 경우 (1000건 이하)

### 복합 인덱스

```sql
-- 쿼리: WHERE status = 'active' AND created_at > '2024-01-01' ORDER BY created_at
CREATE INDEX idx_status_created ON posts (status, created_at);
```

- **선행 컬럼 규칙**: 등호(=) 조건 컬럼을 앞에, 범위/정렬 컬럼을 뒤에
- **커버링 인덱스**: SELECT 컬럼까지 인덱스에 포함하면 테이블 접근 불필요

---

## 6. N+1 문제

```
# N+1 발생
1. SELECT * FROM posts LIMIT 10;              -- 1회
2. SELECT * FROM users WHERE id = ?;          -- x10회 (각 post의 author)
= 총 11회 쿼리

# 해결: JOIN 또는 IN
SELECT p.*, u.name FROM posts p
JOIN users u ON p.user_id = u.id
LIMIT 10;                                      -- 1회
```

### 해결 전략
- **Eager Loading**: JOIN으로 한 번에 가져오기
- **Batch Loading**: `WHERE id IN (...)` 로 묶어서 가져오기
- **DataLoader 패턴**: GraphQL 환경에서 자동 배칭

### ORM에서의 방지
- 쿼리 로그를 켜서 실제 실행 쿼리 수를 확인한다
- Lazy Loading 기본값을 의심한다
- 목록 API는 반드시 JOIN/Include 전략을 명시한다

---

## 7. 쿼리 최적화

### 기본 원칙
- `SELECT *` 금지 — 필요한 컬럼만 명시
- 서브쿼리보다 JOIN을 우선한다
- `LIKE '%keyword%'` 는 인덱스를 타지 않는다 → Full-text Search 고려
- `OFFSET`이 클수록 느려진다 → Cursor 기반 페이지네이션 고려

### EXPLAIN 활용

```sql
EXPLAIN ANALYZE SELECT * FROM posts WHERE user_id = 123 ORDER BY created_at DESC;
```

확인 포인트:
- `Seq Scan` → 인덱스 누락 의심
- `Nested Loop` + 큰 테이블 → JOIN 전략 재검토
- `Sort` → ORDER BY에 인덱스가 없음

---

## 8. 커넥션 풀

| 설정 | 권장값 | 설명 |
|------|--------|------|
| `min` | 2~5 | 유휴 시 유지할 최소 커넥션 |
| `max` | 10~20 | 최대 동시 커넥션 (CPU 코어 x 2~3) |
| `idleTimeout` | 30초 | 유휴 커넥션 해제 시간 |
| `connectionTimeout` | 5초 | 커넥션 획득 대기 시간 |

### 규칙
- `max`를 DB 서버의 `max_connections`보다 작게 설정
- 트랜잭션은 최대한 짧게 유지 (커넥션 점유 시간 최소화)
- 커넥션 누수를 모니터링한다 (사용 후 반환 확인)

---

## 9. 체크리스트

### 설계
- [ ] 테이블/컬럼 네이밍이 일관적인가?
- [ ] 3NF까지 정규화되었는가? (역정규화 시 근거 있는가?)
- [ ] FK에 인덱스가 있는가?
- [ ] ON DELETE 전략이 명시되어 있는가?
- [ ] Soft Delete가 필요한 테이블에 적용되었는가?

### 최적화
- [ ] N+1 쿼리가 없는가?
- [ ] 자주 사용되는 WHERE/ORDER BY에 인덱스가 있는가?
- [ ] `SELECT *` 를 사용하지 않는가?
- [ ] 페이지네이션이 적용되어 있는가? (대량 데이터)
- [ ] 커넥션 풀 설정이 적절한가?
