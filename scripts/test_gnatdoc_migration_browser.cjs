/* Expectations come only from original source and pristine native markup. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const oracle = JSON.parse(fs.readFileSync(process.env.DOC_ORACLE || 'obj/docs/browser-oracle.json'));
const base = process.env.DOC_URL || 'http://127.0.0.1:8071/api/index.html';
const evidence = process.env.DOC_EVIDENCE;
if (evidence) fs.mkdirSync(evidence, {recursive: true});
(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME, headless: true});
  const results = [];
  try {
    const widths = process.env.DOC_BROWSER_WIDTH ? [Number(process.env.DOC_BROWSER_WIDTH)] : [1280, 390];
    assert.ok(widths.every(width => [1280, 390].includes(width)));
    for (const width of widths) for (const colorScheme of ['light', 'dark'])
      for (const javaScriptEnabled of [true, false]) {
        const context = await browser.newContext({viewport: {width, height: 900}, colorScheme, javaScriptEnabled});
        const page = await context.newPage();
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        await page.goto(base);
        if (evidence) {
          await page.frameLocator('iframe').locator('h1').first().waitFor();
          await page.screenshot({
            path: `${evidence}/migration-${width}-${colorScheme}-${javaScriptEnabled ? 'js' : 'nojs'}.png`,
            animations: 'disabled'
          });
        }
        for (const expected of oracle.packages) {
          const link = page.locator('#compilation-units + ul a').filter({hasText: new RegExp('^' + expected.name.replaceAll('.', '\\.') + '$')});
          assert.equal(await link.getAttribute('href'), expected.page);
          await link.click();
          await page.frameLocator('iframe').locator('h1', {hasText: new RegExp('^' + expected.name.replaceAll('.', '\\.') + '$')}).waitFor();
          if (javaScriptEnabled) assert.equal(await page.locator('[aria-current="page"]').textContent(), expected.name);
        }
        for (const expected of oracle.instances) {
          await page.goto(new URL(expected.page, base).href);
          const section = page.locator('#instance-members-summary');
          assert.equal(await section.locator('a').filter({hasText: new RegExp('^' + expected.member + '$')}).getAttribute('href'), expected.template);
          await section.locator('a').filter({hasText: new RegExp('^' + expected.member + '$')}).click();
          assert.equal(new URL(page.url()).hash.slice(1), expected.template.split('#')[1]);
          await page.locator('h4:target', {hasText: expected.member}).waitFor();
        }
        for (const expected of oracle.size_references) {
          await page.goto(new URL(expected.page + '#' + expected.anchor, base).href);
          const reference = page.locator(`h4[id="${expected.anchor}"] + pre a[data-type="opencv.size"]`);
          assert.equal(await reference.getAttribute('href'), expected.destination);
          await reference.click();
          await page.locator('h4:target', {hasText: /^Size$/}).waitFor();
        }
        for (const expected of oracle.declarations) {
          const bookmark = new URL(expected.page + '#' + expected.anchor, base).href;
          await page.goto(bookmark);
          const target = page.locator('h4:target');
          assert.equal(await target.getAttribute('id'), expected.anchor);
          assert.equal(await target.textContent(), expected.name);
          await page.reload();
          assert.ok(await target.evaluate(e => { const r = e.getBoundingClientRect(); return r.top >= 0 && r.top < innerHeight; }));
          const fresh = await context.newPage();
          await fresh.goto(bookmark);
          assert.equal(await fresh.locator('h4:target').getAttribute('id'), expected.anchor);
          await fresh.close();
        }
        await page.goto(base);
        const keyboardLink = page.locator('#compilation-units + ul a').filter({hasText: /^OpenCV.Core.Sparse$/});
        await keyboardLink.focus();
        assert.equal(await keyboardLink.evaluate(e => getComputedStyle(e).outlineStyle), 'solid');
        await page.keyboard.press('Enter');
        await page.frameLocator('iframe').locator('h1', {hasText: /^OpenCV.Core.Sparse$/}).waitFor();
        if (javaScriptEnabled) {
          for (const expected of oracle.symbols) {
            await page.goto(base + '?symbol=' + expected.name);
            const target = page.frameLocator('iframe').locator('h4:target');
            await target.waitFor();
            assert.equal(await target.getAttribute('id'), expected.anchor);
            assert.equal(new URL(page.frame({name: 'document-content'}).url()).pathname.split('/').pop(), expected.page);
          }
          for (const query of ['package=OpenCV.Core&unknown=1', 'package=OpenCV.Core&package=OpenCV',
                               'symbol=OpenCV.Core.Mat&declaration=' + '0'.repeat(64),
                               'symbol=%4fpenCV.Core.Mat', 'package=../index.html', 'symbol=OpenCV.Absent']) {
            await page.goto(base + '?' + query + '#unapproved');
            await page.frameLocator('iframe').locator('h1', {hasText: /^OpenCV.Core$/}).waitFor();
            assert.equal(new URL(page.url()).search, '?package=OpenCV.Core');
            assert.equal(new URL(page.url()).hash, '');
            // A valid native click after fallback must not inherit dirty state.
            await page.frameLocator('iframe').locator('a[data-type="opencv.core.mat"]').first().click();
            await page.frameLocator('iframe').locator('h4:target', {hasText: /^Mat$/}).waitFor();
            assert.equal(new URL(page.url()).search, '?package=OpenCV.Core&symbol=OpenCV.Core.Mat');
            await page.reload();
            await page.frameLocator('iframe').locator('h4:target', {hasText: /^Mat$/}).waitFor();
          }
        }
        assert.deepEqual(errors, []);
        results.push({width, colorScheme, javaScriptEnabled, packages: oracle.packages.length,
                      summaries: oracle.instances.length, symbols: javaScriptEnabled ? oracle.symbols.length : 0});
        console.log('PASS', JSON.stringify(results.at(-1)));
        await context.close();
      }
  } finally {
    fs.writeFileSync(process.env.DOC_BROWSER_REPORT || 'obj/docs/browser-migration.json', JSON.stringify(results, null, 2) + '\n');
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });