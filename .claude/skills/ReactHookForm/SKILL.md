---
name: react-hook-form
description: React Hook Form + Zod 폼 검증 가이드. 폼 구현, Zod 스키마 정의, Controller 패턴, 동적 필드, 중첩 구조 등 폼 관련 작업 시 참조한다.
targetLib: "react-hook-form@7"
user-invocable: true
lastUpdated: 2026-03-19
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

### z.input vs z.output (z.infer) 구분

`.default()`, `.transform()`, `.preprocess()`를 사용하면 **입력 타입과 출력 타입이 달라진다.**
이때 `z.infer`(= `z.output`)만 사용하면 빌드 타임 타입 에러가 발생할 수 있다.

```typescript
const settingsSchema = z.object({
  theme: z.enum(['light', 'dark']).default('light'),
  pageSize: z.number().default(10),
  nickname: z.string(), // default 없음
});

// z.output (= z.infer) — 검증 후 출력 타입. default가 적용되므로 모두 required
type SettingsOutput = z.output<typeof settingsSchema>;
// { theme: 'light' | 'dark'; pageSize: number; nickname: string }

// z.input — 검증 전 입력 타입. default가 있는 필드는 optional
type SettingsInput = z.input<typeof settingsSchema>;
// { theme?: 'light' | 'dark'; pageSize?: number; nickname: string }
```

#### 폼에서의 올바른 사용

```typescript
// useForm의 제네릭과 defaultValues에는 input 타입을 사용한다
type SettingsFormInput = z.input<typeof settingsSchema>;
type SettingsFormOutput = z.output<typeof settingsSchema>;

function SettingsForm() {
  const { handleSubmit, register } = useForm<SettingsFormInput>({
    resolver: zodResolver(settingsSchema),
    defaultValues: {
      nickname: '',
      // theme, pageSize는 Zod default가 처리하므로 생략 가능
    },
  });

  // onSubmit의 data는 Zod 검증을 통과한 output 타입
  const onSubmit = (data: SettingsFormOutput) => {
    // data.theme은 반드시 'light' | 'dark' (undefined 아님)
    saveSettings(data);
  };

  return <form onSubmit={handleSubmit(onSubmit as any)}>{/* ... */}</form>;
}
```

#### 규칙

- `.default()` 사용 시 → `z.input`(폼 입력)과 `z.output`(검증 후 데이터) 타입을 **반드시 구분**한다
- `.default()` 미사용 시 → `z.infer` 하나로 충분하다 (input과 output이 동일)
- **빌드 에러가 나더라도 `.default()` 로직을 제거하지 않는다** — `z.input`/`z.output` 구분으로 해결한다
- `defaultValues`와 Zod `.default()`는 역할이 다르다:
  - `defaultValues`: 폼 UI의 초기값 (React Hook Form)
  - `.default()`: 검증 시 누락된 값을 채움 (Zod)

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
- 타입 에러 시 `.default()` 제거 금지 - `z.input`/`z.output` 구분으로 해결한다

---

## 심화 참조

- `references/advanced-patterns.md` - Controller 패턴, 에러 핸들링, 폼 검증 모드, 동적 필드(useFieldArray), 중첩 객체/배열 스키마
