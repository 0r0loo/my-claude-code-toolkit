---
name: react-hook-form
description: React Hook Form + Zod 폼 검증 가이드. 폼 구현, Zod 스키마 정의, Controller 패턴, 동적 필드, 중첩 구조 등 폼 관련 작업 시 참조한다.
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

## 4. Controller 패턴

`register`를 사용할 수 없는 제어 컴포넌트 (Select, DatePicker, 커스텀 UI 라이브러리 등)에 사용한다.

```typescript
import { Controller, useForm } from 'react-hook-form';

function UserForm() {
  const { control, handleSubmit } = useForm<UserFormValues>({
    resolver: zodResolver(userSchema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        name="role"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <>
            <Select
              value={field.value}
              onChange={field.onChange}
              options={roleOptions}
            />
            {error && <span>{error.message}</span>}
          </>
        )}
      />

      <Controller
        name="birthDate"
        control={control}
        render={({ field, fieldState: { error } }) => (
          <>
            <DatePicker
              selected={field.value}
              onChange={field.onChange}
            />
            {error && <span>{error.message}</span>}
          </>
        )}
      />
    </form>
  );
}
```

---

## 5. 에러 핸들링

### errors 객체로 직접 표시

```typescript
// 간단한 에러 표시
{errors.email && <span className="error">{errors.email.message}</span>}
```

### 재사용 가능한 에러 컴포넌트

```typescript
interface FieldErrorProps {
  error?: FieldError;
}

function FieldError({ error }: FieldErrorProps) {
  if (!error) return null;
  return <span className="field-error">{error.message}</span>;
}

// 사용
<input {...register('email')} />
<FieldError error={errors.email} />
```

---

## 6. 폼 검증 모드

### mode 옵션

| mode | 동작 | 용도 |
|------|------|------|
| `onSubmit` (기본) | 제출 시에만 검증 | 대부분의 폼 |
| `onBlur` | 포커스를 벗어날 때 검증 | 긴 폼, 단계별 입력 |
| `onChange` | 입력할 때마다 검증 | 실시간 피드백이 필요한 필드 |
| `onTouched` | 첫 blur 이후부터 onChange로 검증 | 사용자 친화적 검증 |

```typescript
const { register, handleSubmit } = useForm<FormValues>({
  resolver: zodResolver(schema),
  mode: 'onBlur', // 포커스를 벗어날 때 검증
});
```

---

## 7. 동적 필드 (useFieldArray)

반복되는 필드 그룹을 동적으로 추가/삭제한다.

```typescript
const orderSchema = z.object({
  items: z.array(
    z.object({
      productId: z.string().min(1, '상품을 선택해주세요'),
      quantity: z.number().min(1, '수량은 1개 이상이어야 합니다'),
    })
  ).min(1, '최소 1개 이상의 상품을 추가해주세요'),
});

type OrderForm = z.infer<typeof orderSchema>;

function OrderForm() {
  const { control, register, handleSubmit } = useForm<OrderForm>({
    resolver: zodResolver(orderSchema),
    defaultValues: { items: [{ productId: '', quantity: 1 }] },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'items',
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {fields.map((field, index) => (
        <div key={field.id}>
          <input {...register(`items.${index}.productId`)} />
          <input
            type="number"
            {...register(`items.${index}.quantity`, { valueAsNumber: true })}
          />
          <button type="button" onClick={() => remove(index)}>
            삭제
          </button>
        </div>
      ))}
      <button type="button" onClick={() => append({ productId: '', quantity: 1 })}>
        상품 추가
      </button>
    </form>
  );
}
```

---

## 8. 중첩 객체 / 배열 스키마

### 중첩 객체

```typescript
const addressSchema = z.object({
  zipCode: z.string().length(5, '우편번호는 5자리입니다'),
  city: z.string().min(1, '도시를 입력해주세요'),
  detail: z.string().min(1, '상세 주소를 입력해주세요'),
});

const userSchema = z.object({
  name: z.string().min(1),
  address: addressSchema,       // 중첩 객체
  tags: z.array(z.string()),    // 문자열 배열
});

type UserForm = z.infer<typeof userSchema>;

// register로 점 표기법 사용
<input {...register('address.zipCode')} />
<input {...register('address.city')} />
<input {...register('address.detail')} />

// 에러 접근도 점 표기법
{errors.address?.zipCode && <span>{errors.address.zipCode.message}</span>}
```

### 스키마 재사용

```typescript
// 공통 스키마를 조합하여 재사용한다
const baseUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});

const createUserSchema = baseUserSchema.extend({
  password: z.string().min(8),
});

const updateUserSchema = baseUserSchema.partial(); // 모든 필드 optional
```

---

## 9. 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 스키마 변수 | camelCase + `Schema` | `createUserSchema` |
| 폼 타입 | PascalCase + `Form` | `CreateUserForm` |
| 스키마 파일 | 도메인 + `.schema.ts` | `user.schema.ts` |
| 폼 컴포넌트 | PascalCase + `Form` | `CreateUserForm.tsx` |

---

## 10. 금지 사항

- 스키마 없이 수동 검증 금지 - 반드시 Zod 스키마를 정의하고 `zodResolver`를 사용한다
- `any` 타입 사용 금지 - `z.infer<typeof schema>`로 타입을 추론한다
- `register` 없이 `<input>` 사용 금지 - 모든 입력 필드는 `register` 또는 `Controller`로 연결한다
- `handleSubmit` 없이 `onSubmit` 직접 처리 금지 - `handleSubmit`이 검증을 수행한다
- 폼 타입과 스키마를 별도로 정의 금지 - 타입 불일치 위험이 있으므로 `z.infer`를 사용한다
- 에러 메시지 하드코딩 금지 - Zod 스키마에 메시지를 정의한다
