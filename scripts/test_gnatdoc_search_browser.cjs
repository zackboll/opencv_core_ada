/* Consumer-owned released-search qualification, served only over localhost. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const base = process.env.DOC_URL || 'http://127.0.0.1:8071/api/index.html';
const evidence = process.env.DOC_EVIDENCE || path.resolve(__dirname, '../obj/docs/browser-screenshots');
const site = path.resolve(__dirname, '../_site');
const indexBytes = fs.readFileSync(path.join(site, 'api/gnatdoc-search-index.json'));
const index = JSON.parse(indexBytes);
assert.equal(index.records.length, 1487);
const sha = b => createHash('sha256').update(b).digest('hex');
fs.mkdirSync(evidence, {recursive: true});
const results = [];
const sleepFreeStatus = page => page.waitForFunction(() => {
  const status = document.getElementById('package-results').textContent;
  return status && !status.startsWith('Loading');
});
async function query(page, text) {
  await page.locator('#package-search').fill(text);
  await sleepFreeStatus(page);
}
async function target(page, record) {
  const href = new URL(record.href, base).href;
  await page.waitForFunction(href => {
    const frame = document.querySelector('iframe');
    return frame?.contentWindow?.location.href === href;
  }, href);
  const frame = page.frame({name: 'document-content'});
  if (record.href.includes('#')) {
    await frame.waitForFunction(anchor => {
      const el = document.querySelector('h4:target');
      const r = el?.getBoundingClientRect();
      return el?.id === anchor && r.top >= 0 && r.top < innerHeight;
    }, record.href.split('#')[1]);
  }
}
function expected(query) {
  const q = query.toLowerCase(), words = q.split(/\s+/);
  const score = r => {
    const name = r.name.toLowerCase();
    return name === q || name.split('.').at(-1) === q ? 0 : name.includes(q) ? 1 : 2;
  };
  return index.records.filter(r => words.every(w => (r.name + ' ' + r.text).toLowerCase().includes(w)))
    .sort((a, b) => score(a) - score(b));
}
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME, headless: true});
  try {
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark']) {
      const context = await browser.newContext({viewport: {width, height: 900}, colorScheme});
      const errors = [], external = [];
      await context.route('**/favicon.ico', r => r.fulfill({status: 204}));
      context.on('request', r => { if (new URL(r.url()).origin !== new URL(base).origin) external.push(r.url()); });
      const page = await context.newPage();
      page.on('pageerror', e => errors.push(e.message));
      page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
      await page.goto(base);
      await sleepFreeStatus(page);
      const initial = page.url();
      const cases = {};
      for (const term of ['Create', 'Clone', 'Mat', 'OpenCV.Core.Mat', 'Sparse', 'ownership']) {
        await query(page, term);
        const matches = expected(term), shown = matches.slice(0, 50);
        const items = page.locator('#documentation-search-results li');
        assert.equal(await items.count(), shown.length);
        assert.equal(page.url(), initial, 'typing never navigates');
        assert.deepEqual(await items.locator('a').allTextContents(), shown.map(r => r.label));
        assert.deepEqual(await items.locator('.search-kind').allTextContents(), shown.map(r => r.kind));
        assert.deepEqual(await items.locator('small').allTextContents(),
          shown.map(r => r.text.length > 350 ? r.text.slice(0, 350) + '…' : r.text));
        assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
        cases[term] = {matches: matches.length, first: shown[0]};
        if (term === 'Create') {
          const operations = shown.filter(r => r.kind === 'operation' && r.name.endsWith('.Create'));
          assert.ok(operations.length > 2);
          assert.equal(new Set(operations.map(r => r.href)).size, operations.length);
          const overloads = operations.filter(r => r.name === 'OpenCV.Core.Create');
          assert.ok(overloads.length >= 2 && overloads.every(r => /overload \d+\/\d+/.test(r.label)));
        }
        if (term === 'Clone') assert.ok(shown.some(r => r.kind === 'operation' && r.name.endsWith('.Clone')));
        if (term === 'Mat' || term === 'OpenCV.Core.Mat') {
          assert.ok(shown.some(r => r.kind === 'symbol' && r.name === 'OpenCV.Core.Mat'));
        }
        if (term === 'Sparse') assert.equal(shown[0].name, 'OpenCV.Core.Sparse');
        if (term === 'ownership') assert.ok(shown.some(r => r.href === '../guides/ownership-and-views.html'));
        await page.screenshot({path: `${evidence}/search-${width}-${colorScheme}-${term.replaceAll('.', '-')}.png`});
      }
      // Actual keyboard activation of distinct operation overloads and symbols.
      for (const term of ['Create', 'Clone', 'OpenCV.Core.Mat']) {
        await query(page, term);
        const record = expected(term)[0];
        const input = page.locator('#package-search');
        await input.focus();
        await page.keyboard.press('ArrowDown');
        const links = page.locator('#documentation-search-results a');
        assert.equal(await links.first().evaluate(e => e === document.activeElement), true);
        assert.equal(await links.first().evaluate(e => getComputedStyle(e).outlineStyle), 'solid');
        await page.keyboard.press('End');
        assert.equal(await links.last().evaluate(e => e === document.activeElement), true);
        await page.keyboard.press('Home');
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('ArrowUp');
        await page.keyboard.press('Escape');
        assert.equal(await input.evaluate(e => e === document.activeElement), true);
        await page.keyboard.press('Enter');
        const canonical = await links.first().getAttribute('href');
        assert.equal(new URL(canonical).origin, new URL(base).origin);
        await page.keyboard.press('Enter');
        await target(page, record);
        assert.equal(page.url(), canonical);
        await page.reload();
        await target(page, record);
        const fresh = await context.newPage();
        await fresh.goto(canonical);
        await target(fresh, record);
        await fresh.close();
        await sleepFreeStatus(page);
        await query(page, 'Sparse');
        await page.locator('#documentation-search-results a').first().click();
        await target(page, expected('Sparse')[0]);
        await page.goBack();
        await target(page, record);
        await page.goForward();
        await target(page, expected('Sparse')[0]);
      }
      await query(page, 'OpenCV.Core.Create');
      const overloads = expected('OpenCV.Core.Create').filter(r => r.name === 'OpenCV.Core.Create');
      for (const r of overloads) {
        await page.locator('#documentation-search-results').getByRole('link', {name: r.label, exact: true}).click();
        await target(page, r);
      }
      await query(page, 'ownership');
      await page.locator('#documentation-search-results a', {hasText: /^Ownership and views$/}).click();
      await page.waitForURL(new URL('../guides/ownership-and-views.html', base).href);
      await page.locator('main h1').waitFor();
      assert.equal(await page.locator('iframe').count(), 0);
      await page.goto(base);
      await sleepFreeStatus(page);
      await query(page, 'unknown_nonexistent_xyz');
      assert.equal(await page.locator('#package-results').textContent(), 'No matching documentation.');
      for (const malicious of ['<img src=x onerror=alert(1)>', 'https://example.com/', '../private', 'x'.repeat(257)]) {
        await query(page, malicious);
        assert.equal(await page.locator('#documentation-search-results a').count(), 0);
      }
      await page.locator('#package-clear').click();
      assert.equal(await page.locator('#package-search').inputValue(), '');
      assert.equal(await page.locator('#package-search').evaluate(e => e === document.activeElement), true);
      assert.match(await page.locator('#package-results').textContent(), /^Search public API/);
      await query(page, 'Create');
      await page.locator('#package-search').press('Escape');
      assert.equal(await page.locator('#package-search').inputValue(), '');
      await query(page, 'OpenCV.Core.Mat');
      const unchanged = page.url();
      await page.locator('#documentation-search-results a').first().evaluate(a => {
        a.href = 'https://example.com/forged';
      });
      await page.locator('#documentation-search-results a').first().click();
      assert.equal(page.url(), unchanged, 'modified result href cannot navigate');
      assert.deepEqual(errors, []);
      assert.deepEqual(external, []);
      results.push({width, colorScheme, javaScriptEnabled: true, cases, errors, external});
      await context.close();
      console.log(`PASS search ${width} ${colorScheme}: queries/ranking/overloads/keyboard/history/guides`);
    }
    // A cache rehash does not authorize a destination absent from the shell.
    for (const fault of ['missing', 'corrupt', 'duplicate', 'cross-origin', 'unauthorized', 'wrong-kind',
                         'cross-origin-authority']) {
      const context = await browser.newContext();
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      const forged = structuredClone(index);
      if (fault === 'duplicate') forged.records[1] = forged.records[0];
      if (fault === 'cross-origin') forged.records[0].href = 'https://example.com/stolen';
      if (fault === 'unauthorized') forged.records[0].href = '../guides/private.html';
      if (fault === 'wrong-kind') forged.records[0].kind = 'operation';
      const bytes = Buffer.from(fault === 'corrupt' ? '{broken' : JSON.stringify(forged));
      await context.route('**/gnatdoc-search-index.json', r => r.fulfill({
        status: fault === 'missing' ? 404 : 200, contentType: 'application/json', body: bytes}));
      if (!['missing', 'corrupt'].includes(fault)) {
        await context.route('**/api/index.html*', async r => {
          const response = await r.fetch();
          let body = (await response.text()).replace(sha(indexBytes), sha(bytes));
          if (fault === 'cross-origin-authority') {
            body = body.replace(/(id="documentation-search-authority"[^>]*><a href=")[^"]+/, '$1https://example.com/forged');
          }
          await r.fulfill({response, body});
        });
      }
      await page.goto(base);
      await sleepFreeStatus(page);
      assert.match(await page.locator('#package-results').textContent(), /^Documentation search unavailable/);
      assert.equal(await page.locator('#documentation-search-results a').count(), 0);
      await page.locator('#compilation-units + ul a', {hasText: /^OpenCV.Core.Sparse$/}).click();
      await page.frameLocator('iframe').locator('h1', {hasText: /^OpenCV.Core.Sparse$/}).waitFor();
      assert.deepEqual(errors, []);
      results.push({fault, rejected: true, nativeFallback: true});
      await context.close();
    }
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark']) {
      const context = await browser.newContext({javaScriptEnabled: false, viewport: {width, height: 900}, colorScheme});
      const page = await context.newPage();
      await page.goto(base);
      assert.equal(await page.locator('#package-navigation').isVisible(), false);
      assert.equal(await page.locator('#compilation-units + ul a').count(), 195);
      await page.locator('#compilation-units + ul a', {hasText: /^OpenCV.Core.Sparse$/}).click();
      await page.frameLocator('iframe').locator('h1', {hasText: /^OpenCV.Core.Sparse$/}).waitFor();
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      await page.screenshot({path: `${evidence}/search-${width}-${colorScheme}-nojs.png`});
      results.push({width, colorScheme, javaScriptEnabled: false, nativeFallback: true});
      await context.close();
    }
  } finally {
    fs.writeFileSync(path.join(evidence, 'search-browser.json'), JSON.stringify(results, null, 2) + '\n');
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });