/* Actual HTTP publication; expectations reconstructed from source/native by Core. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const base = process.env.DOC_URL || 'http://127.0.0.1:8071/';
const evidence = process.env.DOC_EVIDENCE || path.resolve(__dirname, '../obj/docs/browser-screenshots');
const oracle = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../obj/docs/browser-examples-oracle.json')));
const palette = {
  light: {keyword: '#7442a7', string: '#14663e', character: '#14663e', number: '#95520c',
    attribute: '#925100', comment: '#53657b', operator: '#415572', link: '#15559f'},
  dark: {keyword: '#cfa8ff', string: '#8ddfb7', character: '#8ddfb7', number: '#ffc48e',
    attribute: '#ffd184', comment: '#b4c2d4', operator: '#c0cfe4', link: '#8bc4ff'}
};
const rgb = hex => 'rgb(' + hex.slice(1).match(/../g).map(v => parseInt(v, 16)).join(', ') + ')';
fs.mkdirSync(evidence, {recursive: true});
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME, headless: true});
  const results = [];
  try {
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark'])
      for (const javaScriptEnabled of [true, false]) {
        const context = await browser.newContext({viewport: {width, height: 900}, colorScheme,
          javaScriptEnabled, permissions: ['clipboard-read', 'clipboard-write']});
        const errors = [], external = [], seen = new Set();
        await context.route('**/*', route => {
          const url = new URL(route.request().url());
          if (url.origin !== new URL(base).origin) {
            external.push(url.href); return route.abort();
          }
          if (url.pathname.endsWith('/favicon.ico')) return route.fulfill({status: 204});
          return route.continue();
        });
        const page = await context.newPage();
        page.on('pageerror', e => errors.push(e.message));
        page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
        page.on('response', r => { if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`); });
        const label = `examples-${width}-${colorScheme}-${javaScriptEnabled ? 'js' : 'nojs'}`;
        let blocks = 0, links = 0, copied = 0;
        for (const [name, expected] of Object.entries(oracle)) {
          const url = new URL(name, base).href;
          await page.goto(url);
          assert.equal(await page.locator('.ada-example').count(), expected.length, name);
          assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), name);
          if (name === 'index.html') {
            assert.equal(await page.locator('pre').first().textContent(), 'alr with opencv_core');
            assert.equal(await page.locator('pre').first().getAttribute('class'), null);
            assert.equal(await page.locator('pre').first().locator('*').count(), 0);
          } else {
            assert.equal(await page.locator('h1').count(), 1);
            assert.equal(await page.locator('.guide-nav a').count(), 5);
            assert.ok(await page.locator('main h2').count() > 0);
            assert.ok(await page.locator('main a:not(.ada-api-reference)').count() > 0);
            assert.ok(await page.locator('.table-scroll').evaluateAll(es => es.every(e =>
              e.scrollWidth <= e.clientWidth || getComputedStyle(e).overflowX === 'auto')));
          }
          for (let i = 0; i < expected.length; i++) {
            const block = page.locator('.ada-example').nth(i), spec = expected[i];
            assert.equal(await block.textContent(), spec.text, `${name} block ${i} exact characters`);
            assert.equal(await block.getAttribute('tabindex'), '0');
            const actualLinks = await block.locator('a').evaluateAll(es => es.map(e =>
              ({href: e.getAttribute('href'), text: e.textContent})));
            assert.deepEqual(actualLinks, spec.links, 'only independently authorized API references');
            assert.equal(await block.locator('a a').count(), 0, 'no nested API links');
            assert.ok(await block.locator('a').evaluateAll(es => es.every((e, i) => {
              const a = e.getBoundingClientRect();
              return es.slice(i + 1).every(other => {
                const b = other.getBoundingClientRect();
                return a.right <= b.left || b.right <= a.left || a.bottom <= b.top || b.bottom <= a.top;
              });
            })), 'no overlapping API links');
            for (const kind of Object.keys(palette[colorScheme]).filter(k => k !== 'link')) {
              const spans = block.locator(`.ada-${kind}`);
              assert.equal(await spans.count(), spec.tokens[kind] || 0);
              if (spec.tokens[kind]) {
                seen.add(kind);
                assert.ok((await spans.evaluateAll(es => es.map(e => getComputedStyle(e).color)))
                  .every(color => color === rgb(palette[colorScheme][kind])), `${kind} foreground`);
              }
            }
            assert.ok((await block.locator('a').evaluateAll(es => es.map(e => getComputedStyle(e).color)))
              .every(color => color === rgb(palette[colorScheme].link)));
            await block.scrollIntoViewIfNeeded();
            const selection = await block.evaluate(e => {
              const range = document.createRange(); range.selectNodeContents(e);
              const selection = getSelection(); selection.removeAllRanges(); selection.addRange(range);
              return selection.toString();
            });
            assert.equal(selection, spec.text, 'native selection preserves all characters including final LF');
            await page.keyboard.press('Control+c');
            assert.equal(await page.evaluate(() => navigator.clipboard.readText()), spec.text, 'native clipboard');
            copied++;
            await page.evaluate(() => getSelection().removeAllRanges());
            await block.focus();
            if (spec.links.length) {
              await page.keyboard.press('Tab');
              assert.equal(await page.locator(':focus').getAttribute('href'), spec.links[0].href);
              assert.equal(await page.locator(':focus').evaluate(e => getComputedStyle(e).outlineWidth), '3px');
            }
            blocks++;
          }
          await page.screenshot({path: `${evidence}/${label}-${name.replaceAll('/', '-')}.png`,
            fullPage: true, animations: 'disabled'});
          // Every authorized occurrence must support keyboard activation and
          // arrive at the observed native anchor; no guessed filename/hash.
          for (let i = 0; i < expected.length; i++) for (let j = 0; j < expected[i].links.length; j++) {
            await page.goto(url);
            await page.locator('.ada-example').nth(i).focus();
            for (let k = 0; k <= j; k++) await page.keyboard.press('Tab');
            const link = expected[i].links[j];
            assert.equal(await page.locator(':focus').getAttribute('href'), link.href);
            await page.keyboard.press('Enter');
            const destination = new URL(link.href, url);
            await page.waitForURL(destination.href);
            assert.equal(await page.locator('h4:target').getAttribute('id'), destination.hash.slice(1));
            if (name === 'index.html') {
              const calls = JSON.parse(fs.readFileSync(path.join(root, 'obj/docs/browser-compiler-oracle.json')));
              const call = calls.find(c => `api/${c.href}` === link.href);
              if (call) {
                const profile = await page.locator('h4:target + pre').textContent();
                assert.equal(profile, call.profile, 'complete exact compiler-selected native profile');
                if (call.text === 'Clone') assert.ok(!profile.includes('UMat'), 'reject UMat Clone');
                await page.goto(url);
                await page.locator('.ada-example a').filter({hasText: new RegExp(`^${call.text}$`)}).click();
                await page.waitForURL(destination.href);
                assert.equal(await page.locator('h4:target + pre').textContent(), call.profile,
                  'mouse activation reaches exact declaration too');
              }
            }
            links++;
          }
        }
        assert.deepEqual(errors, [], 'no browser/HTTP errors');
        assert.deepEqual(external, [], 'no external network requests');
        results.push({width, colorScheme, javaScriptEnabled, browser: browser.version(), blocks, links,
          copied, tokenClassesPresent: [...seen].sort(),
          tokenClassesAbsent: Object.keys(palette.light).filter(k => k !== 'link' && !seen.has(k)),
          errors, external});
        console.log(`PASS ${label}: ${blocks} exact/copyable blocks, ${links} keyboard API arrivals`);
        await context.close();
      }
  } finally {
    fs.writeFileSync(`${evidence}/examples-browser.json`, JSON.stringify(results, null, 2) + '\n');
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
