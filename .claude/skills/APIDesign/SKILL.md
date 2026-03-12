---
name: api-design
description: REST API 설계 가이드. URL 구조, HTTP 메서드, 응답 포맷, 페이지네이션, 에러 코드, 버저닝 등 언어/프레임워크 무관한 API 설계 원칙을 제공한다.
lastUpdated: 2025-03-01
---

# API Design Skill - REST API 설계

언어/프레임워크에 무관한 REST API 설계 원칙.

---

## 1. URL 설계

### 규칙
- **명사 복수형**으로 리소스를 표현한다
- 동사를 URL에 넣지 않는다 (HTTP 메서드가 동사 역할)
- 계층 관계는 중첩으로 표현하되, **2단계까지만**

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

### 네이밍
- URL은 `kebab-case` (`/user-profiles`, `/order-items`)
- 쿼리 파라미터는 `snake_case` 또는 `camelCase` (프로젝트 내 통일)
- 약어 소문자 (`/api`, `/dto` — NOT `/API`, `/DTO`)

---

## 2. HTTP 메서드

| 메서드 | 용도 | 멱등성 | 요청 Body |
|--------|------|--------|-----------|
| `GET` | 조회 | O | X |
| `POST` | 생성 | X | O |
| `PUT` | 전체 교체 | O | O |
| `PATCH` | 부분 수정 | O | O |
| `DELETE` | 삭제 | O | X |

### 규칙
- `GET`에 Body를 넣지 않는다
- `POST`는 생성에만 사용한다 (조회용 POST 금지, 복잡한 필터는 쿼리 파라미터)
- `PUT` vs `PATCH`: 전체 교체 vs 부분 수정을 명확히 구분한다
- `DELETE` 응답은 `200` + 삭제된 리소스 반환 (FE 캐시 무효화에 id 필요)

---

## 3. 응답 포맷

### 타입 정의

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

### 규칙
- **모든 성공 응답은 `data`로 감싼다** (단일, 목록, 삭제 모두)
- **`data` 래핑은 개별 핸들러에서 수동으로 하지 않는다.** 프레임워크가 제공하는 공통 응답 처리 계층(미들웨어, 인터셉터, 필터 등)에서 일괄 적용한다
- **인프라 엔드포인트(health check, version 등)는 `data` 래핑 대상이 아니다.** 비즈니스 리소스 API에만 적용한다
- 목록은 `data` + `meta`, 단일은 `data`만
- 날짜는 **ISO 8601** 형식 (`2024-01-15T09:30:00Z`)
- 필드명은 `camelCase`
- `null` 대신 필드를 생략하거나, 프로젝트 내 통일
- 빈 목록은 `[]` 반환 (null 아님)
- DELETE 응답은 삭제된 리소스의 id를 반환한다 (FE 캐시 무효화용)

---

## 4. 페이지네이션

### Offset 기반 (일반적)

```
GET /users?page=2&limit=20
```

- 장점: 구현 간단, 특정 페이지로 점프 가능
- 단점: 대량 데이터에서 성능 저하 (OFFSET이 커질수록)
- 사용: 관리자 페이지, 데이터가 1만건 이하

### Cursor 기반 (대량 데이터)

```
GET /users?cursor=eyJpZCI6MTIzfQ&limit=20
```

- 장점: 일관된 성능, 실시간 데이터에 적합
- 단점: 특정 페이지 점프 불가
- 사용: 피드, 타임라인, 무한 스크롤

### 응답

```json
{
  "data": [...],
  "meta": {
    "nextCursor": "eyJpZCI6MTQzfQ",
    "hasNext": true
  }
}
```

---

## 5. 에러 응답

### 표준 포맷

```json
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
```

- `code` — 머신 친화적 에러 코드 (`VALIDATION_ERROR`, `FORBIDDEN`, `NOT_FOUND`)
- `message` — 사용자에게 보여줄 메시지
- `details` — 필드별 에러 (선택, 유효성 검증/비즈니스 규칙 위반 시)
  - `field` — 에러 필드 경로 (`email`, `address.zipCode`, `items[0].quantity`)
  - `reason` — 머신 친화적 사유 (`required`, `too_short`, `invalid_format`, `already_exists`)

### 예시

```json
// 403 Forbidden — details 없음
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

### HTTP 상태 코드

| 코드 | 의미 | 사용 |
|------|------|------|
| `200` | 성공 | 조회, 수정, 삭제 성공 |
| `201` | 생성 성공 | POST로 리소스 생성 |
| `400` | 잘못된 요청 | 유효성 검증 실패 |
| `401` | 인증 필요 | 토큰 없음/만료 |
| `403` | 권한 없음 | 인증됐지만 권한 부족 |
| `404` | 없음 | 리소스 미존재 |
| `409` | 충돌 | 중복 데이터, 비즈니스 규칙 위반 |
| `429` | 요청 과다 | Rate Limit 초과 |
| `500` | 서버 에러 | 예기치 않은 에러 |

### 규칙
- `details.reason`은 **머신 친화적** — FE에서 i18n 매핑하여 표시
- `message`는 **사용자 친화적** — fallback 메시지로 바로 표시 가능
- 500 에러에 스택 트레이스를 노출하지 않는다
- 401 vs 403을 명확히 구분한다 (인증 vs 인가)
- `details.field`는 FE 폼 라이브러리의 `setError(field, ...)`와 직접 매핑 가능한 경로를 사용

---

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

### 규칙
- 필터는 쿼리 파라미터로 전달한다 (Body 금지)
- 정렬 기본값을 항상 정의한다 (`createdAt DESC` 등)
- 검색은 `search` 또는 `q` 파라미터로 통일

---

## 7. 버저닝

### URL 접두사 (권장)

```
/api/v1/users
/api/v2/users
```

- 장점: 명확, 라우팅 간단
- 단점: URL이 길어짐

### 규칙
- 하위 호환 변경 (필드 추가)은 버전을 올리지 않는다
- 호환 깨지는 변경 (필드 삭제, 타입 변경)만 새 버전
- 이전 버전은 **최소 6개월** 유지 후 폐기

---

## 8. 체크리스트

- [ ] URL이 명사 복수형이고 동사가 없는가?
- [ ] HTTP 메서드가 용도에 맞게 사용되었는가?
- [ ] 응답 포맷이 프로젝트 내 일관적인가?
- [ ] 에러 응답에 code + message가 있는가?
- [ ] 페이지네이션이 적용되어 있는가? (목록 API)
- [ ] 날짜가 ISO 8601 형식인가?
- [ ] 500 에러에 내부 정보가 노출되지 않는가?
