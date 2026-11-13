// Heap growth test (Chromium only: uses CDP). Blocks on a leak.
// The app exposes window.__test in test mode (see logspace:perf SKILL.md).
import { expect, test, type Page } from '@playwright/test';

const CYCLES = 5;
const MAX_GROWTH_MB = 3; // .logspace/budgets.json → heapGrowthMBAfter5Cycles

type TestHooks = {
  startLevel(id: number): Promise<void>;
  finishLevel(): Promise<void>;
  toMenu(): Promise<void>;
  stats?(): { geometries: number; textures: number };
};
declare global {
  interface Window {
    __test: TestHooks;
  }
}

async function heapMB(page: Page): Promise<number> {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('HeapProfiler.collectGarbage');
  const { usedSize } = await cdp.send('Runtime.getHeapUsage');
  await cdp.detach();
  return usedSize / 1024 / 1024;
}

async function playCycle(page: Page): Promise<void> {
  await page.evaluate(async () => {
    await window.__test.startLevel(1);
    await window.__test.finishLevel();
    await window.__test.toMenu();
  });
}

test.use({ browserName: 'chromium' }); // CDP heap metrics are Chromium-only: force it, never skip

test('memory does not grow over repeated play cycles', async ({ page }) => {
  await page.goto('/?e2e=1');
  await page.waitForFunction(() => window.__test !== undefined);

  await playCycle(page); // warm-up: caches, lazy init
  const before = await heapMB(page);
  const gpuBefore = await page.evaluate(() => window.__test.stats?.());

  for (let i = 0; i < CYCLES; i++) await playCycle(page);

  const after = await heapMB(page);
  expect(after - before, `heap grew ${(after - before).toFixed(1)} MB`).toBeLessThan(MAX_GROWTH_MB);

  // Three.js: GPU resources must return to baseline (renderer.info.memory).
  const gpuAfter = await page.evaluate(() => window.__test.stats?.());
  if (gpuBefore && gpuAfter) expect(gpuAfter).toEqual(gpuBefore);
});
