# API Design 패턴 코드 예시

## 1. URL 설계

```
# Bad
GET  /getUsers
POST /createUser
GET  /users/123/orders/456/items/789/reviews

# Good
GET  /users
POST /users
GET  /orders/456/items
GET  /reviews?item_id=789
```

## 2. 응답 포맷 타입 정의

```typescript
// 성공 응답 — 단일/목록 모두 data로 감싼다
type ApiResponse<T> = {
  data: T;
};

// 목록 응답 — data + meta
type ListResponse<T> = {
  data: T[];
  meta: {
    page: number;
    limit: number;
    totalCount: number;
    totalPages: number;
  };
};

// 에러 응답
type ApiError = {
  error: {
    code: string;
    message: string;
    details?: Array<{ field: string; reason: string }>;
  };
};
```

## 3. 응답 예시

### 단일 리소스

```json
// GET /users/abc123 → 200
{ "data": { "id": "abc123", "name": "홍길동", "email": "hong@example.com", "createdAt": "2024-01-15T09:30:00Z" } }

// POST /users → 201
{ "data": { "id": "abc123", "name": "홍길동", "email": "hong@example.com" } }

// DELETE /posts/abc-123 → 200
{ "data": { "id": "abc-123" } }
```

### 목록

```json
// GET /users?page=1&limit=20 → 200
{
  "data": [
    { "id": "abc123", "name": "홍길동" },
    { "id": "def456", "name": "김철수" }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "totalCount": 150,
    "totalPages": 8
  }
}
```

## 4. 페이지네이션

### Cursor 기반 응답

```json
{
  "data": [...],
  "meta": {
    "nextCursor": "eyJpZCI6MTQzfQ",
    "hasNext": true
  }
}
```

## 5. 에러 응답 예시

```json
// 400 Validation Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "입력값을 확인해주세요.",
    "details": [
      { "field": "email", "reason": "invalid_format" },
      { "field": "password", "reason": "too_short" }
    ]
  }
}

// 403 Forbidden
{ "error": { "code": "FORBIDDEN", "message": "삭제 권한이 없습니다." } }

// 409 Conflict — 비즈니스 규칙 위반
{
  "error": {
    "code": "INSUFFICIENT_STOCK",
    "message": "재고가 부족합니다.",
    "details": [
      { "field": "items[0].quantity", "reason": "exceeds_stock" },
      { "field": "items[2].quantity", "reason": "exceeds_stock" }
    ]
  }
}
```

## 6. 필터링, 정렬, 검색

```
# 필터링
GET /products?category=electronics&min_price=10000

# 정렬
GET /products?sort=price&order=asc
GET /products?sort=-createdAt          # 접두사 -는 DESC

# 검색
GET /products?search=키보드

# 조합
GET /products?category=electronics&sort=-price&page=1&limit=20
```