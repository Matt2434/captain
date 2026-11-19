// usage: node sp-download.mjs "<server-relative path>" <outfile>
import { chromium } from 'playwright';
import fs from 'fs';
const [rel, out] = process.argv.slice(2);
const ctx = await chromium.launchPersistentContext(process.env.HOME + '/.local/share/capstone/pw-profile', { channel: 'chrome', headless: true });
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://__SP_HOST__/sites/__SP_SITE_NAME__/Shared%20Documents/Forms/AllItems.aspx', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(6000);
const b64 = await page.evaluate(async (rel) => {
  const r = await fetch("/sites/__SP_SITE_NAME__/_api/web/GetFileByServerRelativeUrl('" + rel.replace(/'/g, "''") + "')/$value");
  if (!r.ok) return 'ERR ' + r.status;
  const buf = new Uint8Array(await r.arrayBuffer()); let s=''; for (const b of buf) s += String.fromCharCode(b); return btoa(s);
}, rel);
if (b64.startsWith('ERR')) { console.log(b64); } else { fs.writeFileSync(out, Buffer.from(b64, 'base64')); console.log('saved', out); }
await ctx.close();
