#!/bin/zsh
# Called by a review before VM tests. Exit 0 if the VM is reachable, logging in if needed: VPN + one-off Astra Duo tap + pane login.
# At most 3 login tries per hour, one at a time. Exit 1 means VM tests stay not verified.
D=$(dirname $0); VM=__VM_HOST__; ST=~/.config/capstone-vm-tries; LK=/tmp/capstone-vm-login
up(){ nc -z -G 4 $VM 22 >/dev/null 2>&1; }
up && exit 0
if ! mkdir $LK 2>/dev/null; then for i in {1..36}; do sleep 5; [ -d $LK ] || break; done; up && exit 0; echo "another login failed"; exit 1; fi
trap 'rmdir $LK' EXIT
now=$(date +%s); touch $ST; recent=$(awk -v n=$now 'n-$1<3600' $ST | wc -l | tr -d ' ')
[ "$recent" -ge 3 ] && { echo "3 login tries in the last hour: stopped, Matt must connect"; exit 1; }
echo $now >> $ST
L=$(mktemp); $D/astra_duo.sh $L & A=$!
sleep 12; $D/vpn_connect.sh
for i in {1..100}; do up && break; sleep 1; done
wait $A; tail -1 $L | cut -c1-160; rm -f $L
up || { echo "VM still unreachable"; exit 1; }
python3 $D/setup.py >/dev/null 2>&1; echo "VM connected"
