# E2E 패턴 코드 예시

## 1. Page Object Model

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(private readonly page: Page) {
    this.emailInput = page.getByLabel('이메일');
    this.passwordInput = page.getByLabel('비밀번호');
    this.submitButton = page.getByRole('button', { name: '로그인' });
    this.errorMessage = page.getByTestId('error-message');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async getErrorMessage() {
    return this.errorMessage.textContent();
  }
}
```

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';

test.describe('로그인', () => {
  test('유효한 자격증명으로 로그인 성공', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user@example.com', 'password123');

    await page.waitForURL('/dashboard');
    await expect(page.getByText('대시보드')).toBeVisible();
  });

  test('잘못된 비밀번호로 로그인 실패', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('user@example.com', 'wrong');

    await expect(loginPage.errorMessage).toBeVisible();
    await expect(loginPage.errorMessage).toContainText('비밀번호가 일치하지 않습니다');
  });
});
```

## 2. Fixture 패턴

```typescript
// e2e/fixtures/auth.fixture.ts
import { test as base } from '@playwright/test';

type AuthFixtures = {
  testUser: { email: string; password: string };
  authenticatedPage: Page;
};

export const test = base.extend<AuthFixtures>({
  testUser: async ({}, use) => {
    // 테스트 전: 사용자 생성
    const user = await createTestUser();
    await use(user);
    // 테스트 후: 사용자 삭제
    await deleteTestUser(user.email);
  },

  authenticatedPage: async ({ page, testUser }, use) => {
    // 로그인된 상태로 제공
    await page.goto('/login');
    await page.getByLabel('이메일').fill(testUser.email);
    await page.getByLabel('비밀번호').fill(testUser.password);
    await page.getByRole('button', { name: '로그인' }).click();
    await page.waitForURL('/dashboard');
    await use(page);
  },
});
```

## 3. storageState로 인증 재사용

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  projects: [
    // 글로벌 setup: 로그인 → storageState 저장
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        storageState: 'e2e/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
});
```

```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const authFile = 'e2e/.auth/user.json';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('이메일').fill('user@example.com');
  await page.getByLabel('비밀번호').fill('password123');
  await page.getByRole('button', { name: '로그인' }).click();
  await page.waitForURL('/dashboard');

  await page.context().storageState({ path: authFile });
});
```

## 4. Waiting 전략

```typescript
// Bad - 고정 대기
await page.waitForTimeout(3000);

// Good - URL 변경 대기
await page.waitForURL('/dashboard');

// Good - 요소 표시 대기
await expect(page.getByText('환영합니다')).toBeVisible();

// Good - API 응답 대기
const responsePromise = page.waitForResponse('**/api/users');
await page.getByRole('button', { name: '저장' }).click();
const response = await responsePromise;
expect(response.status()).toBe(200);
```

## 5. 네트워크 모킹

```typescript
// 외부 API 모킹
await page.route('**/api/payments/**', async (route) => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ success: true, transactionId: 'mock-123' }),
  });
});

// 에러 시나리오 테스트
await page.route('**/api/users', async (route) => {
  await route.fulfill({
    status: 500,
    body: JSON.stringify({ error: { code: 'SERVER_ERROR', message: '서버 에러' } }),
  });
});

// 느린 네트워크 시뮬레이션
await page.route('**/api/data', async (route) => {
  await new Promise((resolve) => setTimeout(resolve, 3000));
  await route.continue();
});
```

## 6. 접근성 테스트

```typescript
import AxeBuilder from '@axe-core/playwright';

test('페이지 접근성 검증', async ({ page }) => {
  await page.goto('/');

  const results = await new AxeBuilder({ page })
    .exclude('#third-party-widget')
    .analyze();

  expect(results.violations).toEqual([]);
});
```

## 7. playwright.config.ts 기본 설정

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? 'github' : 'html',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'mobile', use: { ...devices['iPhone 14'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```
