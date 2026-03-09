# NestJS 유효성 검증 (Validation)

class-validator + class-transformer 기반 유효성 검증 패턴.

---

## 1. 기본 설정

```typescript
// main.ts — 전역 ValidationPipe
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,           // DTO에 없는 속성 제거
    forbidNonWhitelisted: true, // DTO에 없는 속성 시 에러
    transform: true,            // 자동 타입 변환
    transformOptions: {
      enableImplicitConversion: true,
    },
  }),
);
```

### 규칙
- ValidationPipe는 전역 1회만 설정한다
- `whitelist: true`는 반드시 켠다 (Mass Assignment 방지)
- Controller에서 수동 검증하지 않는다 — Pipe에 위임

---

## 2. 데코레이터 패턴

### 기본 검증

```typescript
class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(50)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, {
    message: '비밀번호는 영문 대소문자와 숫자를 포함해야 합니다',
  })
  password: string;

  @IsEnum(UserRole)
  role: UserRole;

  @IsOptional()
  @IsString()
  bio?: string;
}
```

### 중첩 객체 검증

```typescript
class CreateOrderDto {
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  @ArrayMinSize(1)
  items: OrderItemDto[];

  @ValidateNested()
  @Type(() => AddressDto)
  shippingAddress: AddressDto;
}

class OrderItemDto {
  @IsString()
  productId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}
```

### 조건부 검증

```typescript
class PaymentDto {
  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  // method가 'card'일 때만 검증
  @ValidateIf((o) => o.method === 'card')
  @IsString()
  @IsCreditCard()
  cardNumber: string;

  // method가 'bank'일 때만 검증
  @ValidateIf((o) => o.method === 'bank')
  @IsString()
  accountNumber: string;
}
```

---

## 3. 커스텀 데코레이터

```typescript
// 커스텀 유효성 검증 데코레이터
function IsAfterDate(property: string, validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isAfterDate',
      target: object.constructor,
      propertyName,
      constraints: [property],
      options: validationOptions,
      validator: {
        validate(value: Date, args: ValidationArguments) {
          const [relatedPropertyName] = args.constraints;
          const relatedValue = (args.object as Record<string, unknown>)[relatedPropertyName];
          return value instanceof Date && relatedValue instanceof Date && value > relatedValue;
        },
        defaultMessage(args: ValidationArguments) {
          return `${args.property}은(는) ${args.constraints[0]} 이후여야 합니다`;
        },
      },
    });
  };
}

// 사용
class DateRangeDto {
  @IsDate()
  @Type(() => Date)
  startDate: Date;

  @IsDate()
  @Type(() => Date)
  @IsAfterDate('startDate')
  endDate: Date;
}
```

---

## 4. 쿼리 파라미터 검증

```typescript
class PaginationDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number = 1;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number = 20;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsEnum(SortOrder)
  sort?: SortOrder = SortOrder.DESC;
}

// Controller
@Get()
findAll(@Query() query: PaginationDto) {}
```

---

## 5. Mapped Types 활용

```typescript
// 전체 필드 DTO
class CreateProductDto {
  @IsString()
  name: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsString()
  description: string;
}

// 부분 수정 — 모든 필드 Optional
class UpdateProductDto extends PartialType(CreateProductDto) {}

// 특정 필드만 — name, price만 사용
class ProductSummaryDto extends PickType(CreateProductDto, ['name', 'price']) {}

// 특정 필드 제외
class ProductWithoutPriceDto extends OmitType(CreateProductDto, ['price']) {}

// 조합 — Partial + Pick
class UpdateProductNameDto extends PartialType(
  PickType(CreateProductDto, ['name', 'description']),
) {}
```

---

## 6. 에러 응답 커스터마이징

```typescript
// 전역 ValidationPipe에 exceptionFactory 추가
new ValidationPipe({
  exceptionFactory: (errors: ValidationError[]) => {
    const messages = errors.map((error) => ({
      field: error.property,
      errors: Object.values(error.constraints ?? {}),
    }));
    return new BadRequestException({ message: '입력값 검증 실패', details: messages });
  },
});

// 응답 예시
// {
//   "message": "입력값 검증 실패",
//   "details": [
//     { "field": "email", "errors": ["유효한 이메일 주소여야 합니다"] },
//     { "field": "name", "errors": ["이름은 비어있을 수 없습니다"] }
//   ]
// }
```

---

## 7. 체크리스트

- [ ] 전역 ValidationPipe가 설정되어 있는가?
- [ ] `whitelist: true`가 켜져 있는가?
- [ ] 중첩 객체에 `@ValidateNested()` + `@Type()`이 있는가?
- [ ] 쿼리 파라미터에 `@Type(() => Number)` 변환이 있는가?
- [ ] 에러 메시지가 사용자 친화적인가?
- [ ] Mapped Types를 활용하여 DTO 중복을 줄였는가?
