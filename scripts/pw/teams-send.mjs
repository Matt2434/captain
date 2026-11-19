import { chromium } from 'playwright';
const SEND = process.env.SEND === '1', S = process.env.S;
// Usage: MENTION=Alex MSG=/path/message.txt S=/path/screenshots [SEND=1] node scripts/pw/teams-send.mjs
// Optional LINK_URL=<address> LINK_TEXT=<display text> adds a hyperlink at the end (link dialog, Meta+K). Optional HEADER="text" goes first in bold, above the @mention. Dry run unless SEND=1. MSG lines are sent after the @mention. Only one Chrome can use pw-profile at a time.
import { readFileSync } from 'node:fs';
const { MENTION, MSG } = process.env;
const NOM = MENTION === 'none';
if (!MENTION || !MSG || !S) { console.error('Set MENTION (or MENTION=none), MSG and S'); process.exit(2); }
const lines = readFileSync(MSG, 'utf8').trimEnd().split('\n');
lines[0] = ' ' + lines[0];
const ctx = await chromium.launchPersistentContext(process.env.HOME + '/.local/share/capstone/pw-profile', { channel: 'chrome', headless: true, viewport: { width: 1440, height: 900 } });
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto('https://teams.microsoft.com/v2/', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(12000);
console.log('url', page.url().slice(0,70));
await page.getByRole('button', { name: /^Chat/ }).first().click().catch(async()=>{ await page.locator('[aria-label="Chat"]').first().click(); });
await page.waitForTimeout(5000);
// The chat list may be stuck on the "Meeting chats" filter, which hides the group chat; switch to "Chats".
await page.getByRole('button', { name: /^Chats$/ }).first().click().catch(()=>{}); await page.waitForTimeout(3000);
await page.getByText(process.env.CHAT || '__TEAMS_GROUP_CHAT__', { exact: false }).first().click(); console.log('chat', process.env.CHAT || '__TEAMS_GROUP_CHAT__');
await page.waitForTimeout(8000);
const box = page.locator('[data-tid="ckeditor"], [role="textbox"][contenteditable="true"]').last();
await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await page.waitForTimeout(800); console.log('boxBefore', JSON.stringify((await box.innerText()).trim().slice(0,40)));
if (process.env.HEADER) { await page.keyboard.press('Meta+B'); await page.keyboard.insertText(process.env.HEADER); await page.keyboard.press('Meta+B'); await page.keyboard.press('Shift+Enter'); await page.keyboard.press('Shift+Enter'); }
if (!NOM) { await page.keyboard.type('@' + MENTION, { delay: 60 });
await page.waitForTimeout(3000);
await page.keyboard.press('Enter');
await page.waitForTimeout(1000); }
for (let i=0;i<lines.length;i++){ await page.keyboard.insertText(lines[i]); if(i<lines.length-1) await page.keyboard.press('Shift+Enter'); }
// Optional hyperlink at the end of the message: LINK_URL=<address> [LINK_TEXT=<display text>]. Inserted with the
// compose box's own link dialog (Meta+K), typed with insertText, so the display text is a real link. Nothing is added after it.
let linkOk = true;
if (process.env.LINK_URL) {
  const LT = process.env.LINK_TEXT || process.env.LINK_URL, LU = process.env.LINK_URL;
  await page.keyboard.insertText(' ');
  await page.keyboard.press('Meta+K'); await page.waitForTimeout(2500);
  const inputs = page.locator('[role="dialog"] input:visible, [role="dialog"] textarea:visible');
  const n = await inputs.count();
  const labels = []; for (let i = 0; i < n; i++) labels.push((await inputs.nth(i).getAttribute('aria-label')) || (await inputs.nth(i).getAttribute('placeholder')) || '');
  console.log('linkDialogInputs', n, JSON.stringify(labels));
  await page.screenshot({ path: S + '/teams-linkdialog.png' });
  if (n >= 2) {
    const iText = Math.max(0, labels.findIndex(l => /text|display/i.test(l))), iUrl = labels.findIndex(l => /address|url|link/i.test(l));
    const t = inputs.nth(iText), u = inputs.nth(iUrl >= 0 && iUrl !== iText ? iUrl : (iText === 0 ? 1 : 0));
    await t.click(); await page.keyboard.press('Meta+A'); await page.keyboard.insertText(LT);
    await u.click(); await page.keyboard.press('Meta+A'); await page.keyboard.insertText(LU);
    await page.waitForTimeout(500); await page.screenshot({ path: S + '/teams-linkdialog-filled.png' });
    await page.locator('[role="dialog"]').getByRole('button', { name: /^(Insert|Save|Apply|Done|OK)$/i }).first().click().catch(async () => { await page.keyboard.press('Enter'); });
    await page.waitForTimeout(1500);
  } else { await page.keyboard.press('Escape'); }
  const hrefs = await box.evaluate(b => Array.from(b.querySelectorAll('a[href]')).map(a => [a.innerText, a.getAttribute('href')]));
  linkOk = hrefs.some(([t, h]) => t.trim() === LT && h === LU); console.log('link', linkOk, JSON.stringify(hrefs));
}
await page.waitForTimeout(1000);
const html = await box.innerHTML(); const mentionOk = /mention|itemtype|at-mention/i.test(html); const boldOk = !process.env.HEADER || /<(strong|b)\b/i.test(html); console.log('bold', boldOk); console.log('mention', mentionOk); console.log((await box.innerText()).slice(0,900));
const title = await page.evaluate(()=>document.title); console.log('title',title);
await page.screenshot({ path: S + '/teams-' + (SEND?'sent':'dry') + '.png' });
if (SEND) {
  if (!boldOk) { console.error('NOT SENT: header is not bold'); await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await ctx.close(); process.exit(1); }
  if (!linkOk) { console.error('NOT SENT: link was not inserted'); await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await ctx.close(); process.exit(1); }
  if (!mentionOk && !NOM) { console.error('NOT SENT: mention did not resolve'); await box.click(); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace'); await ctx.close(); process.exit(1); }
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
  const t = await page.evaluate(()=>Array.from(document.querySelectorAll('[data-tid="chat-pane-message"]')).slice(-1).map(e=>e.innerText)); console.log('LAST', String(t).slice(0,300)); if (process.env.LINK_URL) console.log('LASTLINKS', JSON.stringify(await page.evaluate(()=>Array.from(document.querySelectorAll('[data-tid="chat-pane-message"]')).slice(-1).flatMap(e=>Array.from(e.querySelectorAll('a[href]')).map(a=>[a.innerText,a.getAttribute('href')]))))); console.log('boxempty', !(await box.innerText()).trim()); console.log('copiesAdded', added); await page.screenshot({ path: S + '/teams-sent.png' });
  if (added !== 1) { console.error('CHECK CHAT: expected 1 new copy, found ' + added); process.exitCode = 1; }
}
await ctx.close();
