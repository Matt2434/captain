# VPN, Duo and phone setup

The team VM is only reachable on the school VPN (Cisco Secure Client) with a Duo push. Reviews need the VM, so the system can log in on its own.

## How it fits together

```
review needs VM ─► vm_ensure.sh ─► VM reachable? ── yes ─► run tests
                                     │ no
                                     ├─ astra_duo.sh  (starts first, waits for the push)
                                     └─ vpn_connect.sh (Cisco CLI: user, Keychain password, "push")
                                              │
                                     Duo push to phone ─► approved ─► VPN up ─► setup.py logs panes in
```

- `vpn_connect.sh` quits the Cisco app (it blocks the CLI), reads the password from the macOS Keychain, and answers the CLI prompts. It never prints the password.
- `vm_ensure.sh` allows at most **3 login tries per hour** and one at a time. If it fails, VM results are marked "not verified".

## One-time setup (macOS)

1. Install Cisco Secure Client from your school IT portal. Note the profile name (ours: `STUDENT`).
2. Save the VPN password in Keychain (it never goes in a file):
   ```bash
   security add-generic-password -a <netid> -s school-vpn -w   # prompts for the password
   ```
3. Put your SSH public key on the VM (`ssh-copy-id <netid>@<vm>`), so panes log in with no password.

## Phone: iPhone

The Duo push lands on your phone. To approve it without picking up the phone:

1. Enable **iPhone Mirroring** (macOS 15+, same Apple ID, iPhone locked nearby).
2. Install Duo Mobile and turn on push.
3. `astra_duo.sh` runs a one-shot Codex/Astra session with computer use: open iPhone Mirroring → Duo → approve **exactly one** request, and only if it shows the VPN host, your username and a time within 3 minutes of the login. Anything else is refused.

Or just approve it on the phone yourself; the CLI waits 60 s.

## Phone: Android

There's no iPhone Mirroring, so pick one:

- **Approve by hand** (simplest). The script waits 60 s for the tap.
- **Phone Link** (Windows) or **scrcpy** (`brew install scrcpy`, USB debugging on) mirrors the Android screen to the computer; point the Duo helper at that window instead of iPhone Mirroring.
- **Duo passcode instead of push:** if your school allows it, change `push` in `vpn_connect.sh` to a code from the Duo app (still needs you).

Never automate approval of a push you didn't just start. The helper checks host, user and time for that reason.

## Running from your phone

- Claude mobile app → Remote Control into the running session (voice works).
- Backup: Tailscale SSH to the Mac, then `tmux attach`.
