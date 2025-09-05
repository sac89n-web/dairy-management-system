import { test, expect } from '@playwright/test';

test.describe('Milk Collection UI', () => {
  const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8081';

  test.beforeEach(async ({ page }) => {
    // Navigate to login page
    await page.goto(`${API_BASE_URL}/login`);
    
    // Login with test credentials
    await page.fill('[data-testid="username"]', 'admin');
    await page.fill('[data-testid="password"]', 'admin123');
    await page.click('[data-testid="login-button"]');
    
    // Wait for dashboard
    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('should create milk collection successfully', async ({ page }) => {
    // Navigate to collections page
    await page.click('[data-testid="collections-menu"]');
    await expect(page).toHaveURL(/.*collections/);

    // Click add collection button
    await page.click('[data-testid="add-collection-button"]');

    // Fill collection form
    await page.selectOption('[data-testid="farmer-select"]', '1');
    await page.selectOption('[data-testid="shift-select"]', '1');
    await page.fill('[data-testid="collection-date"]', '2025-01-09');
    await page.fill('[data-testid="weight-input"]', '25.5');
    await page.fill('[data-testid="fat-input"]', '4.2');
    await page.fill('[data-testid="snf-input"]', '8.8');

    // Submit form
    await page.click('[data-testid="save-collection-button"]');

    // Verify success message
    await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    await expect(page.locator('[data-testid="success-message"]')).toContainText('Collection saved successfully');

    // Verify collection appears in list
    await expect(page.locator('[data-testid="collection-list"]')).toContainText('25.5');
  });

  test('should validate fat percentage limits', async ({ page }) => {
    await page.click('[data-testid="collections-menu"]');
    await page.click('[data-testid="add-collection-button"]');

    // Fill form with invalid fat percentage
    await page.selectOption('[data-testid="farmer-select"]', '1');
    await page.selectOption('[data-testid="shift-select"]', '1');
    await page.fill('[data-testid="collection-date"]', '2025-01-09');
    await page.fill('[data-testid="weight-input"]', '25.5');
    await page.fill('[data-testid="fat-input"]', '16.0'); // Invalid - too high
    await page.fill('[data-testid="snf-input"]', '8.8');

    await page.click('[data-testid="save-collection-button"]');

    // Verify validation error
    await expect(page.locator('[data-testid="fat-error"]')).toBeVisible();
    await expect(page.locator('[data-testid="fat-error"]')).toContainText('Fat percentage must be between 0 and 15');
  });

  test('should calculate rate automatically', async ({ page }) => {
    await page.click('[data-testid="collections-menu"]');
    await page.click('[data-testid="add-collection-button"]');

    // Fill quality parameters
    await page.selectOption('[data-testid="farmer-select"]', '1');
    await page.selectOption('[data-testid="shift-select"]', '1');
    await page.fill('[data-testid="collection-date"]', '2025-01-09');
    await page.fill('[data-testid="weight-input"]', '25.5');
    await page.fill('[data-testid="fat-input"]', '4.2');
    await page.fill('[data-testid="snf-input"]', '8.8');

    // Wait for rate calculation
    await page.waitForTimeout(1000);

    // Verify rate is calculated
    const rate = await page.locator('[data-testid="calculated-rate"]').textContent();
    expect(parseFloat(rate || '0')).toBeGreaterThan(0);

    // Verify amount is calculated
    const amount = await page.locator('[data-testid="calculated-amount"]').textContent();
    expect(parseFloat(amount || '0')).toBeGreaterThan(0);
  });

  test('should filter collections by date', async ({ page }) => {
    await page.click('[data-testid="collections-menu"]');

    // Apply date filter
    await page.fill('[data-testid="date-filter"]', '2025-01-09');
    await page.click('[data-testid="apply-filter-button"]');

    // Verify filtered results
    const collectionRows = page.locator('[data-testid="collection-row"]');
    const count = await collectionRows.count();
    
    // Should show only collections for the selected date
    if (count > 0) {
      await expect(collectionRows.first()).toContainText('2025-01-09');
    }
  });

  test('should show collection slip after creation', async ({ page }) => {
    await page.click('[data-testid="collections-menu"]');
    await page.click('[data-testid="add-collection-button"]');

    // Create collection
    await page.selectOption('[data-testid="farmer-select"]', '1');
    await page.selectOption('[data-testid="shift-select"]', '1');
    await page.fill('[data-testid="collection-date"]', '2025-01-09');
    await page.fill('[data-testid="weight-input"]', '20.0');
    await page.fill('[data-testid="fat-input"]', '4.0');
    await page.fill('[data-testid="snf-input"]', '8.5');

    await page.click('[data-testid="save-collection-button"]');

    // Verify slip is generated
    await expect(page.locator('[data-testid="collection-slip"]')).toBeVisible();
    await expect(page.locator('[data-testid="slip-number"]')).toBeVisible();
    
    // Verify slip contains collection details
    await expect(page.locator('[data-testid="collection-slip"]')).toContainText('20.0');
    await expect(page.locator('[data-testid="collection-slip"]')).toContainText('4.0');
    await expect(page.locator('[data-testid="collection-slip"]')).toContainText('8.5');
  });
});