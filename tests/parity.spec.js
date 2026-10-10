import fs from 'node:fs';
import { test, expect } from '@playwright/test';

const baseline = JSON.parse(fs.readFileSync(new URL('../evidence/production-comparison.json', import.meta.url), 'utf8'));
test('responsive geometry matches the observed production layout', async ({ page }, testInfo) => {
  test.skip(testInfo.project.name !== 'desktop', 'One browser exercises all four observed widths.');
  await page.emulateMedia({ reducedMotion: 'reduce' });
  for (const row of baseline.geometry) {
    await page.setViewportSize({ width: row.viewport[0], height: row.viewport[1] });
    await page.goto(row.route);
    await expect(page.locator('html')).toHaveAttribute('data-runtime', 'wasm-gc');
    await page.evaluate(() => document.fonts.ready);
    const geometry = await page.locator('main').evaluate(element => ({ height: element.getBoundingClientRect().height, overflow: document.documentElement.scrollWidth > innerWidth }));
    expect(geometry.overflow).toBe(false);
    // Headless Chromium uses overlay scrollbars; computer-use geometry is
    // compared separately in its original browser. These invariants hold in both.
    expect(await page.locator('body').evaluate(element => getComputedStyle(element).lineHeight)).toBe('24px');
    if (row.route === '/') {
      const image = page.getByRole('img', { name: 'Portrait of Victor Ginelli' });
      const dimensions = await image.evaluate(element => ({ width: element.getBoundingClientRect().width, height: element.getBoundingClientRect().height, ratio: element.naturalHeight / element.naturalWidth }));
      expect(Math.abs(dimensions.height - dimensions.width * dimensions.ratio)).toBeLessThan(1);
      expect(await page.getByRole('heading', { name: 'My recent highlights' }).evaluate(element => getComputedStyle(element).fontWeight)).toBe('400');
    } else {
      expect(await page.getByRole('heading', { level: 1 }).evaluate(element => getComputedStyle(element).fontWeight)).toBe('400');
    }
  }
});
