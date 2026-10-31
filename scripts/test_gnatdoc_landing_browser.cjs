/* Core-owned visual contract; original Core CSS, never enhancer defaults, is the oracle. */
const {chromium} = require(process.env.PLAYWRIGHT_MODULE);
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
// PNG decoder already shipped by the workflow's pinned Playwright 1.64.1.
const {PNG} = require(path.resolve(process.env.PLAYWRIGHT_MODULE, '../playwright-core/lib/utilsBundle.js'));
const root = path.resolve(__dirname, '..');
const base = process.env.DOC_URL || 'http://127.0.0.1:8071/';
const evidence = process.env.DOC_EVIDENCE || path.join(root, 'obj/docs/browser-screenshots');
const css = fs.readFileSync(path.join(root, 'docs/assets/gnatdoc-theme.css'));
assert.equal(createHash('sha256').update(css).digest('hex'),
  'fa265d63e73436a6a449fd16011c3db68a5430e7fa6a98ea8eb0fd6821dca9b2');
fs.mkdirSync(evidence, {recursive: true});

function pixels(before, after, authorized) {
  const a = PNG.sync.read(before), b = PNG.sync.read(after);
  const width = Math.max(a.width, b.width), height = Math.max(a.height, b.height);
  let changed = 0, outsideChangedPixels = 0, absoluteChannelDelta = 0;
  const diff = new PNG({width, height});
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    let delta = 0;
    for (let c = 0; c < 4; c++) {
      const av = x < a.width && y < a.height ? a.data[(y * a.width + x) * 4 + c] : 0;
      const bv = x < b.width && y < b.height ? b.data[(y * b.width + x) * 4 + c] : 0;
      delta += Math.abs(av - bv);
    }
    if (delta) {
      changed++;
      if (!authorized || x < authorized.x || x >= authorized.x + authorized.width ||
          y < authorized.y || y >= authorized.y + authorized.height) outsideChangedPixels++;
    }
    absoluteChannelDelta += delta;
    const i = (y * width + x) * 4;
    diff.data[i] = delta ? 255 : 0;
    diff.data[i + 1] = delta ? 0 : 255;
    diff.data[i + 2] = 0;
    diff.data[i + 3] = 255;
  }
  return {width, height, changedPixels: changed, changedFraction: changed / (width * height),
    outsideChangedPixels, authorized, absoluteChannelDelta, image: PNG.sync.write(diff)};
}

async function layout(page) {
  return page.evaluate(() => {
    const selectors = ['.landing', '.eyebrow', 'h1', '.lead', '.api-button', 'h2', '.landing nav'];
    const result = {};
    for (const selector of selectors) {
      const e = document.querySelector(selector), s = getComputedStyle(e), r = e.getBoundingClientRect();
      result[selector] = {x: r.x, y: r.y, width: r.width, height: r.height,
        paddingLeft: s.paddingLeft, paddingRight: s.paddingRight, fontSize: s.fontSize,
        lineHeight: s.lineHeight, fontWeight: s.fontWeight, letterSpacing: s.letterSpacing,
        textTransform: s.textTransform, color: s.color, background: s.backgroundColor,
        display: s.display, borderRadius: s.borderRadius};
    }
    result.body = {color: getComputedStyle(document.documentElement).color,
      background: getComputedStyle(document.documentElement).backgroundColor,
      scrollWidth: document.documentElement.scrollWidth, viewport: innerWidth};
    return result;
  });
}

function contrast(a, b) {
  const luminance = color => color.match(/[\d.]+/g).slice(0, 3).map(Number)
    .map(v => v / 255).map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4)
    .reduce((sum, v, i) => sum + v * [.2126, .7152, .0722][i], 0);
  const x = luminance(a), y = luminance(b);
  return (Math.max(x, y) + .05) / (Math.min(x, y) + .05);
}

function qualify(metrics, width) {
  const landing = metrics['.landing'], button = metrics['.api-button'];
  assert.equal(landing.width, Math.min(width, 1024), 'original maximum width');
  assert.equal(landing.x, (width - landing.width) / 2, 'centered homepage');
  assert.ok(parseFloat(landing.paddingLeft) >= 16, 'comfortable horizontal padding');
  assert.equal(landing.paddingLeft, landing.paddingRight);
  assert.equal(button.display, 'inline-block', 'prominent API button');
  assert.equal(button.borderRadius, '8px');
  assert.ok(button.height >= 44, 'accessible button target');
  assert.equal(metrics['.eyebrow'].textTransform, 'uppercase');
  assert.equal(metrics['.lead'].fontSize, '19.2px');
  assert.equal(metrics['.landing nav'].display, 'flex');
  assert.ok(metrics.body.scrollWidth <= width, 'no horizontal page overflow');
  const ratios = {
    text: contrast(metrics.body.color, metrics.body.background),
    eyebrow: contrast(metrics['.eyebrow'].color, metrics.body.background),
    button: contrast(button.color, button.background)
  };
  for (const [name, ratio] of Object.entries(ratios)) assert.ok(ratio >= 4.5, `${name} contrast ${ratio}`);
  return ratios;
}

(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROME, headless: true});
  const results = [];
  try {
    for (const width of [1280, 390]) for (const colorScheme of ['light', 'dark'])
      for (const javaScriptEnabled of [true, false]) {
        const context = await browser.newContext({viewport: {width, height: 900}, colorScheme, javaScriptEnabled});
        await context.route('**/favicon.ico', route => route.fulfill({status: 204}));
        const label = `landing-${width}-${colorScheme}-${javaScriptEnabled ? 'js' : 'nojs'}`;
        async function capture(kind, url, override) {
          const page = await context.newPage(), errors = [], resources = [];
          page.on('pageerror', e => errors.push(e.message));
          page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
          page.on('requestfailed', r => errors.push(r.url() + ': ' + r.failure().errorText));
          page.on('response', r => {
            if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`);
            if (r.request().resourceType() === 'stylesheet') resources.push({url: r.url(), status: r.status()});
          });
          if (override) await page.route('**/api/gnatdoc-theme.css', route =>
            route.fulfill({status: 200, contentType: 'text/css', body: override}));
          if (kind === 'original' || kind === 'missing-rules') await page.route(url, route =>
            route.fulfill({status: 200, contentType: 'text/html',
              body: fs.readFileSync(path.join(root, 'docs/index.html'))}));
          await page.goto(url);
          await page.evaluate(() => document.fonts.ready);
          const metrics = await layout(page);
          const image = await page.screenshot({path: `${evidence}/${label}-${kind}.png`,
            fullPage: true, animations: 'disabled'});
          assert.deepEqual(errors, [], `${kind} resource/browser errors`);
          const styles = ['api/gnatdoc-theme.css'];
          if (kind === 'after' || kind === 'unauthorized-css') styles.push('assets/gnatdoc-examples.css');
          assert.deepEqual(resources.map(r => new URL(r.url).pathname).sort(),
            styles.map(s => new URL(s, url).pathname).sort(), 'only approved CSS resources');
          assert.ok(resources.every(r => r.status === 200));
          const example = await page.locator('pre').nth(1).evaluate(e => {
            const r = e.getBoundingClientRect();
            return {x: r.x + scrollX, y: r.y + scrollY, width: r.width, height: r.height};
          });
          return {page, metrics, image, resources, example};
        }
        const original = await capture('original', base, css);
        const after = await capture('after', base);
        assert.deepEqual(after.metrics, original.metrics, 'original Core geometry and typography');
        assert.deepEqual(after.example, original.example, 'authorized example geometry unchanged');
        const difference = pixels(original.image, after.image, original.example);
        assert.ok(difference.changedPixels > 0, 'highlighting must actually render');
        assert.equal(difference.outsideChangedPixels, 0, 'pixel-exact outside authorized Ada example');
        fs.writeFileSync(`${evidence}/${label}-diff.png`, difference.image);
        delete difference.image;
        const ratios = qualify(after.metrics, width);
        await after.page.keyboard.press('Tab');
        assert.equal(await after.page.locator(':focus').getAttribute('class'), 'api-button');
        const focus = await after.page.locator(':focus').evaluate(e => {
          const s = getComputedStyle(e);
          return {style: s.outlineStyle, width: s.outlineWidth, color: s.outlineColor};
        });
        assert.equal(focus.style, 'solid');
        assert.equal(focus.width, '3px');
        assert.ok(contrast(focus.color, after.metrics.body.background) >= 3);
        await after.page.screenshot({path: `${evidence}/${label}-focus.png`, animations: 'disabled'});
        await after.page.keyboard.press('Enter');
        await after.page.waitForURL(url => url.pathname === new URL('api/index.html', base).pathname);
        assert.equal(new URL(after.page.url()).pathname, new URL('api/index.html', base).pathname);
        // Prove this gate detects the exact missing-selector regression, even if CSS is rehashed.
        const brokenCSS = css.toString().replace(/^\.(?:landing|eyebrow|lead|api-button)[^\n]*\n/gm, '');
        const mutation = await capture('missing-rules', base, brokenCSS);
        assert.throws(() => qualify(mutation.metrics, width));
        const unauthorized = await capture('unauthorized-css', base,
          css.toString() + '\n.lead { color: rgb(255, 0, 0) !important; }\n');
        const unauthorizedDelta = pixels(after.image, unauthorized.image, after.example);
        assert.ok(unauthorizedDelta.outsideChangedPixels > 0, 'out-of-example CSS mutation detected');
        fs.writeFileSync(`${evidence}/${label}-unauthorized-css-diff.png`, unauthorizedDelta.image);
        delete unauthorizedDelta.image;
        const result = {width, colorScheme, javaScriptEnabled, browser: browser.version(),
          original: original.metrics, after: after.metrics, contrast: ratios, focus,
          resources: after.resources, originalChangedPixels: difference.changedPixels,
          originalPixelDifference: difference,
          missingRulesRejected: true, unauthorizedCSSRejected: true, unauthorizedDelta};
        if (process.env.DOC_BEFORE_URL) {
          const before = await capture('before', process.env.DOC_BEFORE_URL);
          const delta = pixels(before.image, after.image, before.example);
          fs.writeFileSync(`${evidence}/${label}-diff.png`, delta.image);
          delete delta.image;
          result.before = before.metrics;
          result.beforeAfterPixels = delta;
          result.layoutDelta = Object.fromEntries(Object.keys(after.metrics).filter(k => k !== 'body')
            .map(k => [k, Object.fromEntries(['x', 'y', 'width', 'height'].map(p =>
              [p, after.metrics[k][p] - before.metrics[k][p]]))]));
          assert.equal(delta.outsideChangedPixels, 0, 'historical homepage pixel parity outside Ada example');
          assert.deepEqual(before.metrics, after.metrics, 'qualified v0.1.2 homepage layout parity');
        }
        results.push(result);
        console.log(`PASS ${label}: original pixels/layout, focus, contrast, resources, missing-rule mutation`);
        await context.close();
      }
  } finally {
    fs.writeFileSync(path.join(evidence, 'landing-visual.json'), JSON.stringify(results, null, 2) + '\n');
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });