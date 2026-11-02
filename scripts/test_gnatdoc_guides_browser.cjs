/* Optional, separately installed browser tooling; no site runtime dependencies. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const base = process.env.DOC_URL || 'http://127.0.0.1:8072/';
const evidence = process.env.DOC_EVIDENCE || '/tmp/core-doc-072-screenshots';
fs.mkdirSync(evidence, {recursive: true});
const names = ['ownership-and-views', 'typed-access-guide', 'core-operations-guide',
  'sparse-and-persistence-guide', 'interop-and-compatibility'];
const stylesheets = ['../api/gnatdoc-theme.css', 'gnatdoc-guides.css', '../assets/gnatdoc-examples.css'];
function observeStylesheets(page) {
  const resources = new Map();
  page.on('response', response => {
    if (response.request().resourceType() === 'stylesheet') resources.set(response.url(), {
      status: response.status(), ok: response.ok(), redirected: !!response.request().redirectedFrom()
    });
  });
  page.on('requestfailed', request => {
    if (request.resourceType() === 'stylesheet') resources.set(request.url(), {failure: request.failure()});
  });
  return resources;
}
async function guideReadiness(page, expectedURL, resources, timeout = 15000) {
  let state;
  const snapshot = async () => ({
    ...await page.evaluate(required => ({
      url: location.href, readyState: document.readyState,
      scrollWidth: document.documentElement.scrollWidth, viewport: innerWidth,
      stylesheets: required.map(href => {
        const expected = new URL(href, location.href).href;
        const links = [...document.querySelectorAll('link[rel="stylesheet"]')]
          .filter(link => link.getAttribute('href') === href);
        const link = links[0], sheet = link?.sheet;
        return {href, expected, count: links.length, resolved: link?.href,
          attached: !!sheet && [...document.styleSheets].includes(sheet), sheetURL: sheet?.href};
      })
    }), stylesheets),
    resources: Object.fromEntries(resources)
  });
  try {
    // A click may return at DOMContentLoaded, before render-blocking CSS arrives.
    // Wait for the exact destination's load event, never for overflow to disappear.
    await page.waitForURL(expectedURL, {waitUntil: 'load', timeout});
    state = await snapshot();
    assert.equal(state.url, expectedURL);
    assert.equal(state.readyState, 'complete');
    for (const sheet of state.stylesheets) {
      assert.equal(sheet.count, 1, `required stylesheet link: ${sheet.href}`);
      assert.equal(sheet.resolved, sheet.expected);
      assert.equal(sheet.sheetURL, sheet.expected);
      assert.equal(sheet.attached, true, `CSSOM attachment: ${sheet.href}`);
      assert.equal(resources.get(sheet.expected)?.ok, true, `stylesheet response: ${sheet.href}`);
      assert.equal(resources.get(sheet.expected)?.redirected, false, `stylesheet identity: ${sheet.href}`);
    }
    return state;
  } catch (error) {
    state = state || await snapshot().catch(diagnosticError => ({
      url: page.url(), diagnosticError: diagnosticError.message, resources: Object.fromEntries(resources)
    }));
    throw new Error(`Guide readiness failed for ${expectedURL}: ${error.message}\n${JSON.stringify(state, null, 2)}`,
      {cause: error});
  }
}
// Native fragment scrolling can finish after load/reload; observe arrival,
// never scroll from the test or accept an off-screen bookmark.
const expectFragmentArrival = (page, fragment) => page.waitForFunction(fragment => {
  const target = document.querySelector(fragment);
  if (!target) return false;
  const r = target.getBoundingClientRect();
  return r.top < innerHeight && r.bottom > 0;
}, fragment, {timeout: 5000});
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME || '/usr/bin/google-chrome', headless: true});
  try {
    await require('./test_gnatdoc_guides_readiness.cjs')({browser, observeStylesheets, guideReadiness, evidence});
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark'])
      for (const javaScriptEnabled of [true, false]) {
        const context = await browser.newContext({viewport: {width, height: 900}, colorScheme, javaScriptEnabled});
        await context.route('**/favicon.ico', route => route.fulfill({status: 204}));
        const page = await context.newPage();
        const resources = observeStylesheets(page);
        const errors = [];
        page.on('pageerror', e => errors.push(e.message));
        page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
        await page.goto(base);
        assert.equal(await page.locator('#developer-guides + ul a').count(), 5);
        for (const name of names) {
          resources.clear();
          await page.locator(`a[href="guides/${name}.html"]`).click();
          await guideReadiness(page, new URL(`guides/${name}.html`, base).href, resources);
          assert.equal(await page.locator('main').count(), 1);
          assert.equal(await page.locator('h1').count(), 1);
          assert.equal(await page.locator('.guide-nav [aria-current="page"]').getAttribute('href'), name + '.html');
          assert.equal(await page.locator('.guide-source a').getAttribute('href'),
            `https://github.com/zackboll/opencv_core_ada/blob/main/docs/${name}.md`);
          try {
            assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
            assert.ok(await page.locator('pre').evaluateAll(es => es.every(e =>
              e.scrollWidth <= e.clientWidth || getComputedStyle(e).overflowX === 'auto')));
            assert.ok(await page.locator('.table-scroll').evaluateAll(es => es.every(e =>
              e.scrollWidth <= e.clientWidth || getComputedStyle(e).overflowX === 'auto')));
          } catch (error) {
            console.error('Guide layout failure:', JSON.stringify(await guideReadiness(page,
              new URL(`guides/${name}.html`, base).href, resources), null, 2));
            throw error;
          }
          const fragments = await page.locator('main a[href^="#"]').evaluateAll(es => es.map(e => e.getAttribute('href')));
          for (const fragment of fragments) {
            await page.locator(`main a[href="${fragment}"]`).first().click();
            assert.equal(new URL(page.url()).hash, fragment);
            await expectFragmentArrival(page, fragment);
            assert.ok(await page.locator(fragment).evaluate(e => {
              const r = e.getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0;
            }));
          }
          const cross = await page.locator('main a[href*=".html"]').evaluateAll(es =>
            es.map(e => e.getAttribute('href')).filter(h => !h.startsWith('../') && !h.includes('://')));
          for (const destination of cross) {
            await page.goto(new URL('guides/' + name + '.html', base).href);
            resources.clear();
            await page.locator(`main a[href="${destination}"]`).first().click();
            await guideReadiness(page, new URL(destination, new URL(`guides/${name}.html`, base)).href, resources);
            assert.equal(new URL(page.url()).pathname.split('/').pop(), destination.split('#')[0]);
          }
          await page.goto(new URL('guides/' + name + '.html', base).href);
          const directHeading = await page.locator('main h2[id]').first().getAttribute('id');
          const directBookmark = page.url() + '#' + directHeading;
          await page.goto(directBookmark);
          await expectFragmentArrival(page, '#' + directHeading);
          await page.reload();
          await expectFragmentArrival(page, '#' + directHeading);
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