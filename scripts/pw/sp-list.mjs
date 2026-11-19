import { chromium } from 'playwright';
const rel = process.argv[2];
const ctx = await chromium.launchPersistentContext(process.env.HOME + '/.local/share/capstone/pw-profile', { channel: 'chrome', headless: true });
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://__SP_HOST__/sites/__SP_SITE_NAME__/Shared%20Documents/Forms/AllItems.aspx', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(6000);
const out = await page.evaluate(async (rel) => {
  const q = (u) => fetch(u, { headers: { Accept: 'application/json;odata=nometadata' } }).then(r => r.json());
  const base = "/sites/__SP_SITE_NAME__/_api/web/GetFolderByServerRelativeUrl('" + rel.replace(/'/g, "''") + "')";
  const files = await q(base + "/Files?$select=Name,Length,TimeLastModified,LinkingUrl,ServerRelativeUrl");
  const folders = await q(base + "/Folders?$select=Name,ServerRelativeUrl");
  return { files: files.value, folders: folders.value };
}, rel);
console.log(JSON.stringify(out, null, 1));
await ctx.close();
