/* Two origins serving the actual generated Core site, not a mock browser. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const base = process.env.DOC_URL || 'http://127.0.0.1:8071/api/index.html';
const foreign = new URL(base);
foreign.hostname = foreign.hostname === '127.0.0.1' ? 'localhost' : '127.0.0.1';
foreign.search = '?package=OpenCV.Core.Sparse';
async function visible(page, symbol) {
  assert.equal(new URL(page.url()).searchParams.get('symbol'), symbol);
  const simple = symbol.slice(symbol.lastIndexOf('.') + 1);
  const frame = page.frameLocator('iframe[name="document-content"]');
  await frame.locator('h4:target', {hasText: new RegExp(`^${simple}$`)}).waitFor();
  assert.match(await frame.locator('h4:target + pre').textContent(),
    new RegExp(`^type ${simple}\\b`));
  await page.frame({name: 'document-content'}).waitForFunction(() => {
    const r = document.querySelector('h4:target')?.getBoundingClientRect();
    return r && r.top >= 0 && r.top < innerHeight;
  });
}
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME, headless: true});
  try {
    for (const width of [1280, 390]) {
      const context = await browser.newContext({viewport: {width, height: 900}});
      const page = await context.newPage();
      page.setDefaultTimeout(15000);
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      for (const symbol of ['OpenCV.Rect', 'OpenCV.Angle_Unit', 'OpenCV.Core.Mat']) {
        await page.goto(foreign.href);
        await page.goto(base + '?symbol=' + symbol);
        await visible(page, symbol);
        await page.reload();
        await visible(page, symbol);
        const bookmark = page.url();
        await page.getByRole('link', {name: 'OpenCV.Core.Sparse', exact: true}).click();
        await page.frameLocator('iframe').locator('h1', {hasText: /^OpenCV.Core.Sparse$/}).waitFor();
        await page.goBack();
        await visible(page, symbol);
        // Seed a stale persisted offset deterministically. A stable symbol
        // bookmark must select its declaration even when the URL already
        // matches and native history restores an unrelated scroll position.
        await page.frame({name: 'document-content'}).evaluate(() => scrollTo(0, 0));
        await page.goBack();
        assert.equal(new URL(page.url()).origin, foreign.origin);
        await page.goForward();
        await visible(page, symbol);
        // Exercise the already-loaded/BFCache pageshow path independently of
        // Chromium's nondeterministic choice of persisted child scroll data.
        await page.frame({name: 'document-content'}).evaluate(() => scrollTo(0, 0));
        await page.evaluate(() => dispatchEvent(new PageTransitionEvent('pageshow', {persisted: true})));
        await visible(page, symbol);
        const fresh = await context.newPage();
        await fresh.goto(bookmark);
        await visible(fresh, symbol);
        await fresh.close();
      }
      assert.deepEqual(errors, []);
      await context.close();
      console.log(`PASS ${width}px cross-origin declaration history/stale offset/reload/fresh tab`);
    }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });