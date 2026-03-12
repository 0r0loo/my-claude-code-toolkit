---
name: react-hook-form
description: React Hook Form + Zod 폼 검증 가이드. 폼 구현, Zod 스키마 정의, Controller 패턴, 동적 필드, 중첩 구조 등 폼 관련 작업 시 참조한다.
targetLib: "react-hook-form@7"
lastUpdated: 2025-03-01
---

# React Hook Form Skill - 폼 관리 규칙

React Hook Form + Zod를 사용한 폼 관리 규칙을 정의한다.
공통 코딩 원칙은 `../Coding/SKILL.md`를 참고한다.

---

## 1. Zod 스키마 정의

### 기본 스키마

```typescript
import { z } from 'zod';

const createUserSchema = z.object({
  name: z.string().min(1, '이름을 입력해주세요').max(50, '이름은 50자 이내로 입력해주세요'),
  email: z.string().email('올바른 이메일 형식이 아닙니다'),
  age: z.number().min(1, '나이는 1 이상이어야 합니다').max(150, '올바른 나이를 입력해주세요'),
  role: z.enum(['admin', 'user', 'guest']),
});
```

### Refinement와 Transform

```typescript
const signupSchema = z
  .object({
    password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다'),
    confirmPassword: z.string(),
    phone: z.string().transform((val) => val.replace(/-/g, '')), // 하이픈 제거
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: '비밀번호가 일치하지 않습니다',
    path: ['confirmPassword'], // 에러가 표시될 필드
  });
```

---

## 2. 타입 추론

Zod 스키마에서 폼 타입을 자동으로 추론한다. 별도의 타입을 수동으로 정의하지 않는다.

```typescript
// Good - 스키마에서 타입 추론
const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
});

type CreateUserForm = z.infer<typeof createUserSchema>;
// { name: string; email: string; }

// Bad - 수동으로 타입 정의 (스키마와 불일치 위험)
interface CreateUserForm {
  name: string;
  email: string;
}
```

---

## 3. zodResolver 연동

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

function CreateUserForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateUserForm>({
    resolver: zodResolver(createUserSchema),
    defaultValues: {
      name: '',
      email: '',
    },
  });

  const onSubmit = async (data: CreateUserForm) => {
    // data는 스키마 검증을 통과한 안전한 데이터
    await createUser(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}

      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        생성
      </button>
    </form>
  );
}
```

---

## 4. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 스키마 변수 | camelCase + `Schema` | `createUserSchema` |
| 폼 타입 | PascalCase + `Form` | `CreateUserForm` |
| 스키마 파일 | 도메인 + `.schema.ts` | `user.schema.ts` |
| 폼 컴포넌트 | PascalCase + `Form` | `CreateUserForm.tsx` |

---

## 5. 금지 사항

- 스키마 없이 수동 검증 금지 - 반드시 Zod 스키마를 정의하고 `zodResolver`를 사용한다
- `any` 타입 사용 금지 - `z.infer<typeof schema>`로 타입을 추론한다
- `register` 없이 `<input>` 사용 금지 - 모든 입력 필드는 `register` 또는 `Controller`로 연결한다
- `handleSubmit` 없이 `onSubmit` 직접 처리 금지 - `handleSubmit`이 검증을 수행한다
- 폼 타입과 스키마를 별도로 정의 금지 - 타입 불일치 위험이 있으므로 `z.infer`를 사용한다
- 에러 메시지 하드코딩 금지 - Zod 스키마에 메시지를 정의한다

---

## 심화 참조

- `references/advanced-patterns.md` - Controller 패턴, 에러 핸들링, 폼 검증 모드, 동적 필드(useFieldArray), 중첩 객체/배열 스키마
