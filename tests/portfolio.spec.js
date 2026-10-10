import fs from 'node:fs';
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const content = JSON.parse(fs.readFileSync(new URL('../content/site.json', import.meta.url), 'utf8'));
const resume = JSON.parse(fs.readFileSync(new URL('../content/resume.json', import.meta.url), 'utf8'));
const routes = ['/', ...content.projects.map(project => `/work/${project.slug}`), '/resume'];

async function ready(page) {
  await expect(page.locator('html')).toHaveAttribute('data-runtime', 'wasm-gc');
}

for (const route of routes) {
  test(`${route} preserves content, images, and accessibility in both themes`, async ({ page }, testInfo) => {
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    expect((await page.goto(route))?.status()).toBe(200);
    await ready(page);
    await expect(page.getByRole('heading', { level: 1 })).toHaveCount(1);
    const project = content.projects.find(project => route.endsWith(`/work/${project.slug}`));
    if (project) {
      await expect(page.getByRole('heading', { name: project.title, exact: true, level: 1 })).toBeVisible();
      for (const contribution of project.contributions) await expect(page.getByText(contribution.detail, { exact: true })).toBeVisible();
    } else if (route === '/resume') {
      for (const experience of resume.experience) {
        await expect(page.getByRole('heading', { name: experience.company, exact: true })).toBeVisible();
        for (const bullet of experience.bullets) await expect(page.getByText(bullet, { exact: true })).toBeVisible();
      }
      for (const skill of resume.skills) await expect(page.locator('.resume-columns p').filter({ hasText: skill.items })).toBeVisible();
    } else {
      await expect(page.getByRole('heading', { name: 'My recent highlights' })).toBeVisible();
      await expect(page.getByRole('link', { name: 'Project details' })).toHaveCount(content.projects.length);
      await expect(page.locator('[data-artwork]')).toHaveCount(5);
    }
    await page.locator('img').evaluateAll(images => images.forEach(image => { image.loading = 'eager'; }));
    await expect.poll(() => page.locator('img').evaluateAll(images => images.every(image => image.complete && image.naturalWidth > 0))).toBe(true);
    for (const theme of ['light', 'dark']) {
      if (await page.locator('html').getAttribute('data-theme') !== theme) await page.getByRole('button', { name: /Switch to .* theme/ }).click();
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
      const analysis = await new AxeBuilder({ page }).analyze();
      expect(analysis.violations.filter(item => ['critical', 'serious'].includes(item.impact))).toEqual([]);
      if (route === '/') {
        fs.mkdirSync('evidence/screenshots', { recursive: true });
        await page.screenshot({ path: `evidence/screenshots/${testInfo.project.name}-${theme}.png`, animations: 'disabled' });
      }
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    expect(errors).toEqual([]);
  });
}

test('MoonBit navigation restores the selected work position and browser history', async ({ page }) => {
  await page.goto('/');
  await ready(page);
  const details = page.getByRole('link', { name: 'Project details' }).first();
  await details.scrollIntoViewIfNeeded();
  const originalScroll = await page.evaluate(() => scrollY);
  await details.click();
  await expect(page).toHaveURL(/\/work\/send$/);
  await expect(page.getByRole('heading', { name: 'What Victor built' })).toBeVisible();
  await page.getByRole('link', { name: 'All work' }).click();
  await expect(page).toHaveURL(/\/$/);
  await expect.poll(() => page.evaluate(() => scrollY)).toBeGreaterThan(originalScroll - 3);
  await expect.poll(() => page.evaluate(() => scrollY)).toBeLessThan(originalScroll + 3);
  await page.goForward();
  await expect(page).toHaveURL(/\/work\/send$/);
  await expect(page.getByRole('heading', { name: 'Send', exact: true, level: 1 })).toBeVisible();
});

test('theme persists and responsive navigation has keyboard focus', async ({ page }, testInfo) => {
  await page.goto('/');
  await ready(page);
  await page.getByRole('button', { name: 'Switch to dark theme' }).click();
  await page.reload();
  await ready(page);
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  if (testInfo.project.name === 'mobile') {
    const menu = page.getByRole('button', { name: 'Toggle navigation' });
    await menu.click();
    await expect(menu).toHaveAttribute('aria-expanded', 'true');
    await expect(page.getByRole('navigation', { name: 'Primary' }).getByRole('link', { name: 'Work', exact: true })).toBeFocused();
    await page.keyboard.press('Escape');
    await expect(menu).toHaveAttribute('aria-expanded', 'false');
    await expect(menu).toBeFocused();
    await menu.click();
  }
  await page.getByRole('navigation', { name: 'Primary' }).getByRole('link', { name: 'Resume', exact: true }).click();
  await expect(page).toHaveURL(/\/resume$/);
  await expect(page.getByRole('link', { name: 'Download PDF' })).toBeVisible();
});

test('reduced motion keeps artwork static and readable', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  await ready(page);
  await page.getByRole('heading', { name: 'Winner, Aragon Hack for Freedom' }).scrollIntoViewIfNeeded();
  expect(await page.evaluate(() => document.getAnimations().filter(animation => animation.playState === 'running').length)).toBe(0);
  await expect(page.getByRole('heading', { name: 'Winner, Aragon Hack for Freedom' })).toBeVisible();
});

test('Wasm GC and JavaScript render the same portfolio content', async ({ page }) => {
  await page.goto('/');
  await ready(page);
  const mismatches = await page.evaluate(async paths => {
    const [wasmResponse, siteResponse, resumeResponse, js] = await Promise.all([
      fetch('/runtime/portfolio.wasm'), fetch('/content/site.json'), fetch('/content/resume.json'), import('/runtime/portfolio.js'),
    ]);
    const { instance } = await WebAssembly.instantiate(await wasmResponse.arrayBuffer(), {}, { builtins: ['js-string'], importedStringConstants: '_' });
    const wasm = instance.exports;
    const site = await siteResponse.text();
    const resume = await resumeResponse.text();
    const year = new Date().getFullYear();
    return paths.filter(path => wasm.render_page(path, site, resume, year) !== js.render_page(path, site, resume, year));
  }, [...routes, '/unknown?foo=bar']);
  expect(mismatches).toEqual([]);
});

test('JavaScript backend preserves navigation when Wasm cannot initialize', async ({ page }) => {
  await page.route('**/runtime/portfolio.wasm', route => route.fulfill({ status: 200, contentType: 'application/wasm', body: 'invalid-wasm-for-fallback-test' }));
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('data-runtime', 'js');
  await page.getByRole('button', { name: 'Switch to dark theme' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.getByRole('link', { name: 'Project details' }).first().click();
  await expect(page.getByRole('heading', { name: 'Send', level: 1, exact: true })).toBeVisible();
});

test('metadata, PDF, and unknown routes have correct HTTP behavior', async ({ request, page }) => {
  for (const route of routes) {
    const response = await request.get(route);
    expect(response.status()).toBe(200);
    const html = await response.text();
    expect(html).toContain(`href="${content.site.url}${route}"`);
    expect(html).toContain('name="twitter:card" content="summary_large_image"');
    const project = content.projects.find(project => route === `/work/${project.slug}`);
    expect(html).toContain(`name="twitter:image" content="${content.site.url}${project?.screenshot.src || content.site.socialImage}"`);
  }
  const pdf = await request.get(content.site.resume);
  expect(pdf.status()).toBe(200);
  expect((await pdf.body()).subarray(0, 4).toString()).toBe('%PDF');
  expect((await page.goto('/missing-project'))?.status()).toBe(404);
  await expect(page.getByRole('link', { name: /Return home/ })).toBeVisible();
});

test.describe('prerendering without JavaScript', () => {
  test.use({ javaScriptEnabled: false });
  test('all six routes and mobile navigation remain usable', async ({ page }) => {
    for (const route of routes) {
      await page.goto(route);
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
      await expect(page.getByRole('navigation', { name: 'Primary' }).getByRole('link', { name: 'Resume', exact: true })).toBeVisible();
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    }
  });
});
