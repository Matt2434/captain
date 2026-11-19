// Upload a local file to the Team Aurora SharePoint site.
// usage: node scripts/pw/sp-upload.mjs <local file> [server-relative folder]
// default folder = /sites/__SP_SITE_NAME__/Shared Documents/DRAFTS/__YOUR_FOLDER__
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
const [local, folderArg] = process.argv.slice(2);
const folder = folderArg || '/sites/__SP_SITE_NAME__/Shared Documents/DRAFTS/__YOUR_FOLDER__';
const name = path.basename(local);
const b64 = fs.readFileSync(local).toString('base64');
const ctx = await chromium.launchPersistentContext(process.env.HOME + '/.local/share/capstone/pw-profile', { channel: 'chrome', headless: true });
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://__SP_HOST__/sites/__SP_SITE_NAME__/Shared%20Documents/Forms/AllItems.aspx', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(6000);
const out = await page.evaluate(async ({ folder, name, b64 }) => {
  const site = '/sites/__SP_SITE_NAME__';
  const ci = await fetch(site + '/_api/contextinfo', { method: 'POST', headers: { Accept: 'application/json;odata=nometadata' } }).then(r => r.json());
  const digest = ci.FormDigestValue;
  const bin = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
  const esc = s => s.replace(/'/g, "''");
  // ensure the folder exists (create missing leaf folders one level at a time)
  const parts = folder.split('/'); let cur = parts.slice(0, 5).join('/');
  for (const p of parts.slice(5)) {
    const probe = await fetch(site + "/_api/web/GetFolderByServerRelativeUrl('" + esc(cur + '/' + p) + "')/Exists", { headers: { Accept: 'application/json;odata=nometadata' } }).then(r => r.json());
    if (!probe.value) await fetch(site + "/_api/web/GetFolderByServerRelativeUrl('" + esc(cur) + "')/Folders/add(url='" + esc(p) + "')", { method: 'POST', headers: { Accept: 'application/json;odata=nometadata', 'X-RequestDigest': digest } });
    cur = cur + '/' + p;
  }
  const url = site + "/_api/web/GetFolderByServerRelativeUrl('" + esc(folder) + "')/Files/Add(url='" + esc(name) + "',overwrite=true)?$select=Name,ServerRelativeUrl,LinkingUrl,Length";
  const r = await fetch(url, { method: 'POST', headers: { Accept: 'application/json;odata=nometadata', 'X-RequestDigest': digest }, body: bin });
  const t = await r.text();
  return { status: r.status, body: t.slice(0, 600) };
}, { folder, name, b64 });
console.log(JSON.stringify(out, null, 1));
await ctx.close();
