---
name: tanstack-query
description: API 데이터 페칭, 서버 상태 캐싱, useQuery/useMutation 작성 시 호출. queryKey 설계, Optimistic Update, Prefetching이 필요할 때 참조.
targetLib: "@tanstack/react-query@5"
user-invocable: true
lastUpdated: 2026-03-19
---

# TanStack Query Skill - 서버 상태 관리 규칙

TanStack Query (React Query)를 사용한 서버 상태 관리 규칙을 정의한다.
클라이언트 상태 관리는 `../Zustand/SKILL.md`를 참고한다.

> 코드 예시: `references/patterns.md` 참조

---

## 1. 기본 개념

- **서버 상태**: API에서 가져오는 데이터 (사용자 목록, 게시글 등)
- **클라이언트 상태**: UI에서만 존재하는 데이터 (모달, 폼 입력값 등)
- **Stale-While-Revalidate**: 캐시된 데이터를 먼저 보여주고, 백그라운드에서 최신 데이터를 가져온다

---

## 2. useQuery 규칙

- `queryKey`는 배열 형태. 첫 요소는 엔티티명(복수형), 이후 필터/파라미터
- `enabled`로 조건부 실행. `select`로 데이터 변환
- queryKey 컨벤션: `['users']`, `['users', { status }]`, `['users', userId]`, `['users', userId, 'posts']`

---

## 3. queryKey 팩토리 패턴

- queryKey를 객체로 중앙 관리하여 일관성과 재사용성을 확보한다
- `all`, `lists()`, `list(filters)`, `details()`, `detail(id)` 구조

---

## 4. useMutation 규칙

- `onSuccess`에서 반드시 캐시를 무효화한다

| 작업 | invalidateQueries 대상 |
|------|------------------------|
| 생성 | 목록 쿼리 (`lists()`) |
| 수정 | 목록 + 해당 상세 (`all`) 또는 정밀 지정 |
| 삭제 | 목록 쿼리 (`lists()`) |

---

## 5. Optimistic Update

- `onMutate`: 쿼리 취소 → 스냅샷 저장 → 캐시 낙관적 업데이트 → 롤백 컨텍스트 반환
- `onError`: 이전 데이터로 롤백
- `onSettled`: 성공/실패 무관하게 캐시 재검증

---

## 6. Prefetching & Suspense

- 마우스 호버 등에서 `prefetchQuery`로 미리 데이터를 가져온다
- `useSuspenseQuery`는 data가 항상 존재함을 보장 (타입 안전)
- 부모에서 `<Suspense>` + `<ErrorBoundary>`로 감싼다

---

## 7. QueryClient 설정

| 옵션 | 권장값 | 설명 |
|------|--------|------|
| `staleTime` | `5분` | 짧으면 요청 과다, 길면 데이터 지연 |
| `gcTime` | `30분` | staleTime보다 길어야 한다 |
| `retry` | `1` | 네트워크 오류 대비 최소 재시도 |
| `refetchOnWindowFocus` | `false` | 프로젝트 요구사항에 따라 조정 |

---

## 8. 캐시 전략 가이드

| 데이터 유형 | staleTime | 예시 |
|------------|-----------|------|
| 거의 안 바뀜 | `Infinity` | 코드 테이블, 카테고리, 약관 |
| 가끔 바뀜 | `10~30분` | 사용자 프로필, 설정 |
| 자주 바뀜 | `1~5분` | 게시글 목록, 댓글 |
| 실시간 필요 | `0` + `refetchInterval` | 채팅, 알림, 재고 |

---

## 9. 금지 사항

- `useEffect`로 데이터 페칭 금지 - TanStack Query를 사용한다
- queryKey 하드코딩 금지 - queryKey 팩토리 패턴을 사용한다
- `onSuccess` 안에서 상태 동기화 금지 (`useState`에 서버 데이터 복사 등)
- `queryFn` 안에서 에러를 삼키는 try-catch 금지
- `cacheTime` 사용 금지 - v5부터 `gcTime`으로 변경되었다

---

## ⚠️ AI 함정 목록

> AI가 자주 틀리는 실수. 새로운 실패 발견 시 한 줄씩 추가한다.

- `queryKey`에 객체를 넣을 때 속성 순서가 다르면 캐시 미스 → 팩토리 패턴으로 일관성 보장
- `enabled: false`일 때 `data`가 undefined인데 타입에서 누락 → `useSuspenseQuery` 사용 또는 early return
- Optimistic Update에서 `onMutate`의 `cancelQueries` 빠뜨리면 서버 응답이 낙관적 데이터를 덮어씀
- v5에서 `onSuccess`/`onError`/`onSettled` 콜백이 `useQuery` 옵션에서 제거됨 → `useMutation`에서만 사용