#!/bin/zsh
# Connect Cisco Secure Client (STUDENT) with the password in Keychain item gmu-vpn; Duo is approved on the phone. Never prints the password.
P=$(security find-generic-password -a __SCHOOL_USER__ -s gmu-vpn -w 2>/dev/null); [ -n "$P" ] || { echo "no password in Keychain item gmu-vpn"; exit 2; }
V=/opt/cisco/secureclient/bin/vpn
osascript -e 'quit app "Cisco Secure Client"' >/dev/null 2>&1; sleep 3   # the open app blocks the command-line client
(printf '__SCHOOL_USER__\n'; sleep 4; printf '%s\n' "$P"; sleep 4; printf 'push\n'; sleep 60; printf 'y\n'; sleep 5) | perl -e 'alarm 90; exec @ARGV' $V -s connect STUDENT 2>&1 | grep -E 'state:|error|Login failed' | tail -3
