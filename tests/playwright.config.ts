import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './frontend/playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'report/playwright' }],
    ['json', { outputFile: 'report/playwright-results.json' }]
  ],
  use: {
    baseURL: process.env.API_BASE_URL || 'http://localhost:8081',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: process.env.CI ? undefined : {
    command: 'dotnet run --project ../../src/Web',
    port: 8081,
    reuseExistingServer: !process.env.CI,
  },
});