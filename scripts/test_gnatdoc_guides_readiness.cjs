/* Test-owned responses only: no publication files or browser assertions are changed. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
module.exports = async ({browser, observeStylesheets, guideReadiness, evidence}) => {
  const base = 'https://guide-readiness.invalid/';
  const expectedURL = base + 'guides/typed-access-guide.html';
  const required = ['../api/gnatdoc-theme.css', 'gnatdoc-guides.css', '../assets/gnatdoc-examples.css'];
  const results = [];
  for (const javaScriptEnabled of [true, false]) {
    for (const fault of ['delayed', 'missing-link', 'wrong-identity', 'http-404', 'aborted', 'timeout', 'overflow']) {
      const context = await browser.newContext({viewport: {width: 1280, height: 900}, javaScriptEnabled});
      let release;
      const held = new Promise(resolve => { release = resolve; });
      try {
        await context.route('**/*', async route => {
          const url = route.request().url();
          if (url === base) return route.fulfill({contentType: 'text/html',
            body: '<a href="guides/typed-access-guide.html">Guide</a>'});
          if (url === expectedURL) {
            const links = required.filter(href => fault !== 'missing-link' || href !== 'gnatdoc-guides.css')
              .map(href => fault === 'wrong-identity' && href === 'gnatdoc-guides.css' ? href + '?wrong' : href);
            return route.fulfill({contentType: 'text/html', body: '<!doctype html><html><head>' +
              links.map(href => `<link rel="stylesheet" href="${href}">`).join('') +
              '</head><body style="margin:0"><div class="wide" style="min-width:1394px">Guide</div></body></html>'});
          }
          if (route.request().resourceType() === 'stylesheet') {
            if (fault === 'delayed' || fault === 'timeout') await held;
            if (fault === 'aborted' && url.endsWith('/gnatdoc-guides.css')) return route.abort();
            return route.fulfill({status: fault === 'http-404' && url.endsWith('/gnatdoc-guides.css') ? 404 : 200,
              contentType: 'text/css', body: fault === 'overflow' ? 'body { margin: 0; }' :
                '.wide { min-width: 0 !important; width: 100%; }'});
          }
          return route.fulfill({status: 204});
        });
        const page = await context.newPage();
        const resources = observeStylesheets(page);
        await page.goto(base);
        await page.getByRole('link', {name: 'Guide', exact: true}).click({noWaitAfter: true});
        let early;
        if (fault === 'delayed' || fault === 'timeout') {
          await page.waitForURL(expectedURL, {waitUntil: 'domcontentloaded', timeout: 5000});
          early = await page.evaluate(() => ({url: location.href, readyState: document.readyState,
            sheets: [...document.styleSheets].map(sheet => sheet.href),
            scrollWidth: document.documentElement.scrollWidth, viewport: innerWidth}));
          assert.equal(early.readyState, 'interactive');
          assert.deepEqual(early.sheets, []);
          assert.equal(early.scrollWidth, 1394);
          assert.equal(early.viewport, 1280);
        }
        if (fault === 'timeout') {
          await assert.rejects(guideReadiness(page, expectedURL, resources, 1000), error => {
            assert.match(error.message, /Guide readiness failed/);
            assert.match(error.message, /"readyState": "interactive"/);
            assert.match(error.message, /"scrollWidth": 1394/);
            return true;
          });
        } else if (fault === 'delayed' || fault === 'overflow') {
          const ready = guideReadiness(page, expectedURL, resources);
          release();
          const loaded = await ready;
          assert.equal(loaded.readyState, 'complete');
          assert.equal(loaded.stylesheets.filter(sheet => sheet.attached).length, 3);
          if (fault === 'overflow') {
            await assert.rejects(async () => {
              assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
            }, {code: 'ERR_ASSERTION'});
          } else {
            assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
            assert.equal(loaded.scrollWidth, 1280);
          }
          results.push({fault, javaScriptEnabled, early, loaded});
        } else {
          await assert.rejects(guideReadiness(page, expectedURL, resources), error => {
            assert.match(error.message, /Guide readiness failed/);
            assert.match(error.message, /"readyState": "complete"/);
            assert.match(error.message, /"stylesheets":/);
            assert.match(error.message, /"scrollWidth":/);
            return true;
          });
        }
        console.log(`PASS guide readiness fixture JS=${javaScriptEnabled}: ${fault}`);
      } finally {
        release();
        await context.close();
      }
    }
  }
  fs.writeFileSync(`${evidence}/guide-readiness.json`, JSON.stringify(results, null, 2) + '\n');
};