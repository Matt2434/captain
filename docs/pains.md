# Known pains (and fixes)

| Pain | What happens | Fix |
|---|---|---|
| Duo expires | Push times out after ~60 s | Start the Duo helper **before** the VPN login; keep the phone nearby |
| Cisco app blocks the CLI | `vpn` CLI can't connect while the app is open | `vpn_connect.sh` quits the app first |
| VPN drops overnight | Right panes disconnect | `/captain` again; `setup.py` re-logs idle panes |
| Nested SSH | Sending `ssh` into a pane already on the VM causes host-key prompts | Check the prompt for `@<vm>` first (setup.py does) |
| Microsoft login expires | Teams/SharePoint scripts fail every few weeks | Log in again in the Playwright profile (Duo) |
| Profile lock | "profile in use" from Playwright | Only one script at a time; wait and retry |
| Pasted @mentions | Become plain text in Teams | Type the mention key by key and pick the suggestion (the script does) |
| launchd can't read ~/Desktop | Pollers die with EX_CONFIG | Keep scripts/tokens in `~/bin` and `~/.config`, data in `~/.local/share` |
| Mac sleeps | Long runs and watchers die | ☕ workspace with `caffeinate -dimsu` |
| CI disk full (ENOSPC) | Large evidence files fill the tmpfs | Keep big JSON out of PRs; size the CI tmpfs |
| Shared LLM instance | Parallel requests time out | Send requests one at a time |
| Duplicate watchers | Two `watch_prs.py` open duplicate workspaces | `pgrep -fl watch_prs` before starting |
| Context bloat | Long sessions slow down | Write STATE.md, `/clear`, reopen with `task_open.sh` |
