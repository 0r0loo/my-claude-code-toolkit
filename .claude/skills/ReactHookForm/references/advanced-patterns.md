# React Hook Form 심화 패턴

## 1. Controller 패턴

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

## 2. 에러 핸들링

### errors 객체로 직접 표시

```typescript
// 간단한 에러 표시
{errors.email && <span className="error">{errors.email.message}</span>}
```

### 재사용 가능한 에러 컴포넌트

```typescript
type FieldErrorProps = {
  error?: FieldError;
};

function FieldError({ error }: FieldErrorProps) {
  if (!error) return null;
  return <span className="field-error">{error.message}</span>;
}

// 사용
<input {...register('email')} />
<FieldError error={errors.email} />
```

---

## 3. 폼 검증 모드

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

## 4. 동적 필드 (useFieldArray)

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

## 5. 중첩 객체 / 배열 스키마

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
