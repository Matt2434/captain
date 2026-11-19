import { chromium } from 'playwright';
const SEND = process.env.SEND === '1', S = process.env.S;
// teams-dm.mjs: like teams-send.mjs but CHAT=<chat name> picks the chat (default __TEAMS_GROUP_CHAT__); MENTION optional (skip for 1:1 chats).
// Usage: MENTION=Alex MSG=/path/message.txt S=/path/screenshots [SEND=1] node scripts/pw/teams-send.mjs
// Optional HEADER="text" goes first in bold, above the @mention. Dry run unless SEND=1. MSG lines are sent after the @mention. Only one Chrome can use pw-profile at a time.
import { readFileSync } from 'node:fs';
const { MENTION, MSG } = process.env;
if (!MSG || !S) { console.error('Set MSG and S'); process.exit(2); }
const lines = readFileSync(MSG, 'utf8').trimEnd().split('\n');
if (MENTION) lines[0] = ' ' + lines[0];
const ctx = await chromium.launchPersistentContext(process.env.HOME + '/.local/share/capstone/pw-profile', { channel: 'chrome', headless: true, viewport: { width: 1440, height: 900 } });
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://teams.microsoft.com/v2/', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(12000);
console.log('url', page.url().slice(0,70));
if (process.env.CLEAR_GROUP) { await page.getByRole('button', { name: /^Chat/ }).first().click().catch(()=>{}); await page.waitForTimeout(4000); await page.getByText('Team Climate', { exact: false }).first().click(); await page.waitForTimeout(6000); const gb = page.locator('[data-tid="ckeditor"], [role="textbox"][contenteditable="true"]').last(); await gb.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await page.waitForTimeout(1500); console.log('groupBoxCleared', JSON.stringify((await gb.innerText()).trim().slice(0,30))); }
if (process.env.USERS) {
  // Deep links land on a launcher interstitial in headless Chrome; use the New message flow instead.
  await page.getByRole('button', { name: /^Chat/ }).first().click().catch(()=>{}); await page.waitForTimeout(4000);
  const to = page.locator('[data-tid="people-picker-input"], input[aria-label*="To"], input[placeholder*="name"]').first();
  await page.locator('button[aria-label="New message"]').first().click().catch(()=>{}); await page.getByText('New message', { exact: true }).first().click().catch(()=>{}); await page.waitForTimeout(4000);
  // Chips in the To row (top ~150px of the pane): a prior draft may already hold the recipient.
  const chips = await page.evaluate(()=>Array.from(document.querySelectorAll('span,div,button')).filter(e=>{const r=e.getBoundingClientRect(); return r.top>90&&r.bottom<140&&r.left>450&&e.children.length===0&&e.innerText.trim();}).map(e=>e.innerText.trim()));
  console.log('toRow', JSON.stringify(chips));
  const preset = process.env.EXPECT && chips.includes(process.env.EXPECT) && chips.filter(c=>c!=='To:').length===1;
  if (!preset) for (let i = 0; i < 3 && !(await to.isVisible().catch(()=>false)); i++) {
    await page.locator('button[aria-label="New message"]').first().click().catch(()=>{}); await page.waitForTimeout(3000);
    if (!(await to.isVisible().catch(()=>false))) { await page.getByText('New message', { exact: true }).first().click().catch(()=>{}); await page.waitForTimeout(3000); }
  }
  if (!preset && !(await to.isVisible().catch(()=>false))) { await page.screenshot({ path: S + '/teams-noto.png' }); console.error('No To field'); await ctx.close(); process.exit(3); }
  if (!preset) { await to.click(); await page.keyboard.type(process.env.USERS, { delay: 50 }); await page.waitForTimeout(4000);
  const opt = page.locator('[role="option"]').filter({ hasText: process.env.EXPECT || process.env.USERS.split('@')[0] });
  if ((await opt.count()) !== 1) { console.error('NOT ONE MATCH for recipient:', await opt.count()); await ctx.close(); process.exit(3); }
  await opt.first().click(); await page.waitForTimeout(5000); }
  await page.keyboard.press('Escape'); await page.waitForTimeout(1500);
  const hdr = (await page.evaluate(()=>document.body.innerText)).replace(/\s+/g,' ');
  console.log('expectedNameShown', !!process.env.EXPECT && hdr.includes(process.env.EXPECT));
  if (process.env.EXPECT && !hdr.includes(process.env.EXPECT)) { console.error('NOT IN EXPECTED CHAT'); await page.screenshot({ path: S + '/teams-wrongchat.png' }); await ctx.close(); process.exit(3); }
} else {
await page.getByRole('button', { name: /^Chat/ }).first().click().catch(async()=>{ await page.locator('[aria-label="Chat"]').first().click(); });
await page.waitForTimeout(5000);
await page.getByText(process.env.CHAT || '__TEAMS_GROUP_CHAT__', { exact: false }).first().click(); }
await page.waitForTimeout(8000);
const box = page.locator('[data-tid="ckeditor"], [role="textbox"][contenteditable="true"]').last();
await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await page.waitForTimeout(800); console.log('boxBefore', JSON.stringify((await box.innerText()).trim().slice(0,40)));
if (process.env.HEADER) { await page.keyboard.press('Meta+B'); await page.keyboard.insertText(process.env.HEADER); await page.keyboard.press('Meta+B'); await page.keyboard.press('Shift+Enter'); await page.keyboard.press('Shift+Enter'); }
if (MENTION) { await page.keyboard.type('@' + MENTION, { delay: 60 });
await page.waitForTimeout(3000);
await page.keyboard.press('Enter'); }
await page.waitForTimeout(1000);
for (let i=0;i<lines.length;i++){ await page.keyboard.insertText(lines[i]); if(i<lines.length-1) await page.keyboard.press('Shift+Enter'); }
await page.waitForTimeout(1000);
const html = await box.innerHTML(); const mentionOk = !MENTION || /mention|itemtype|at-mention/i.test(html); const boldOk = !process.env.HEADER || /<(strong|b)\b/i.test(html); console.log('bold', boldOk); console.log('mention', mentionOk); console.log((await box.innerText()).slice(0,900));
const title = await page.evaluate(()=>document.title); console.log('title',title);
await page.screenshot({ path: S + '/teams-' + (SEND?'sent':'dry') + '.png' });
if (SEND) {
  if (!boldOk) { console.error('NOT SENT: header is not bold'); await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await ctx.close(); process.exit(1); }
  if (!mentionOk) { console.error('NOT SENT: mention did not resolve'); await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await ctx.close(); process.exit(1); }
  // Count copies by the first line, so a double send is reported, not hidden.
  const key = lines[0].trim().slice(0, 60);
  const copies = () => page.evaluate(k => Array.from(document.querySelectorAll('[data-tid="chat-pane-message"]')).filter(e => e.innerText.includes(k)).length, key);
  const boxEmptyWithin = async ms => { for (let t = 0; t < ms; t += 250) { if (!(await box.innerText()).trim()) return true; await page.waitForTimeout(250); } return false; };
  const before = await copies();
  await page.keyboard.press('Control+Enter');
  // Teams can take seconds to clear the box; clicking Send too soon sends twice.
  if (!(await boxEmptyWithin(8000))) { console.log('fallback: Send button'); await page.locator('[data-tid="newMessageCommands-send"],[name="send"]').first().click(); await boxEmptyWithin(8000); }
  await page.waitForTimeout(6000);
  const after = await copies(); const added = after - before;
  const t = await page.evaluate(()=>Array.from(document.querySelectorAll('[data-tid="chat-pane-message"]')).slice(-1).map(e=>e.innerText)); console.log('LAST', String(t).slice(0,300)); console.log('boxempty', !(await box.innerText()).trim()); console.log('copiesAdded', added); await page.screenshot({ path: S + '/teams-sent.png' });
  if (added !== 1) { console.error('CHECK CHAT: expected 1 new copy, found ' + added); process.exitCode = 1; }
}
await ctx.close();
