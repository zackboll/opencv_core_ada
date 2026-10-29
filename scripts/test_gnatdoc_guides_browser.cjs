/* Optional, separately installed browser tooling; no site runtime dependencies. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const base = process.env.DOC_URL || 'http://127.0.0.1:8072/';
const evidence = process.env.DOC_EVIDENCE || '/tmp/core-doc-072-screenshots';
fs.mkdirSync(evidence, {recursive: true});
const names = ['ownership-and-views', 'typed-access-guide', 'core-operations-guide',
  'sparse-and-persistence-guide', 'interop-and-compatibility'];
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME || '/usr/bin/google-chrome', headless: true});
  try {
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark'])
      for (const javaScriptEnabled of [true, false]) {
        const context = await browser.newContext({viewport: {width, height: 900}, colorScheme, javaScriptEnabled});
        await context.route('**/favicon.ico', route => route.fulfill({status: 204}));
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', e => errors.push(e.message));
        page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
        await page.goto(base);
        assert.equal(await page.locator('#developer-guides + ul a').count(), 5);
        for (const name of names) {
          await page.locator(`a[href="guides/${name}.html"]`).click();
          assert.equal(await page.locator('main').count(), 1);
          assert.equal(await page.locator('h1').count(), 1);
          assert.equal(await page.locator('.guide-nav [aria-current="page"]').getAttribute('href'), name + '.html');
          assert.equal(await page.locator('.guide-source a').getAttribute('href'),
            `https://github.com/zackboll/opencv_core_ada/blob/main/docs/${name}.md`);
          assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
          assert.ok(await page.locator('pre').evaluateAll(es => es.every(e =>
            e.scrollWidth <= e.clientWidth || getComputedStyle(e).overflowX === 'auto')));
          assert.ok(await page.locator('.table-scroll').evaluateAll(es => es.every(e =>
            e.scrollWidth <= e.clientWidth || getComputedStyle(e).overflowX === 'auto')));
          const fragments = await page.locator('main a[href^="#"]').evaluateAll(es => es.map(e => e.getAttribute('href')));
          for (const fragment of fragments) {
            await page.locator(`main a[href="${fragment}"]`).first().click();
            assert.equal(new URL(page.url()).hash, fragment);
            assert.ok(await page.locator(fragment).evaluate(e => {
              const r = e.getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0;
            }));
          }
          const cross = await page.locator('main a[href*=".html"]').evaluateAll(es =>
            es.map(e => e.getAttribute('href')).filter(h => !h.startsWith('../') && !h.includes('://')));
          for (const destination of cross) {
            await page.goto(new URL('guides/' + name + '.html', base).href);
            await page.locator(`main a[href="${destination}"]`).first().click();
            assert.equal(new URL(page.url()).pathname.split('/').pop(), destination.split('#')[0]);
          }
          await page.goto(new URL('guides/' + name + '.html', base).href);
          const directHeading = await page.locator('main h2[id]').first().getAttribute('id');
          const directBookmark = page.url() + '#' + directHeading;
          await page.goto(directBookmark);
          await page.reload();
          assert.ok(await page.locator('#' + directHeading).evaluate(e => {
            const r = e.getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0;
          }));
          const fresh = await context.newPage();
          await fresh.goto(directBookmark);
          assert.equal(await fresh.locator('h1').textContent(), await page.locator('h1').textContent());
          await fresh.close();
          await page.getByRole('link', {name: 'Documentation home', exact: true}).click();
          await page.goBack();
          assert.equal(page.url(), directBookmark);
          await page.goForward();
          assert.equal(new URL(page.url()).pathname, new URL('index.html', base).pathname);
          await page.goto(new URL('guides/' + name + '.html', base).href);
          await page.keyboard.press('Tab');
          assert.equal(await page.evaluate(() => getComputedStyle(document.activeElement).outlineStyle), 'solid');
          const api = page.locator('section[aria-label="Native API entry points"] a').first();
          const identity = await api.textContent();
          await api.click();
          assert.equal(await page.locator('h1').textContent(), identity);
          await page.goto(new URL('guides/' + name + '.html', base).href);
          if (javaScriptEnabled) {
            if (name === 'typed-access-guide') await page.locator('#typed-access-matrix').scrollIntoViewIfNeeded();
            await page.screenshot({path: `${evidence}/${name}-${width}-${colorScheme}.png`});
          }
          await page.getByRole('link', {name: 'Documentation home', exact: true}).click();
        }
        assert.deepEqual(errors, []);
        console.log(`PASS ${width}px ${colorScheme} JS=${javaScriptEnabled}: five guides, fragments, cross-links, native API, focus, overflow`);
        await context.close();
      }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });