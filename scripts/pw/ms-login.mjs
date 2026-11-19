// One-time Microsoft login for the Teams/SharePoint scripts.
// Opens a visible Chrome with the shared profile; sign in (Duo too), wait until Teams loads, then close the window.
// Usage: node scripts/pw/ms-login.mjs
import { chromium } from 'playwright';
import os from 'os';
const profile = `${os.homedir()}/.local/share/capstone/pw-profile`;
const ctx = await chromium.launchPersistentContext(profile, { headless: false, channel: 'chrome' }).catch(() =>
  chromium.launchPersistentContext(profile, { headless: false }));
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://teams.microsoft.com');
console.log(`Sign in in the browser window. Close it when Teams has loaded. Profile: ${profile}`);
await new Promise(r => ctx.on('close', r));
console.log('Saved. Teams and SharePoint scripts can now run headless.');
