#!/bin/bash

session_name=netboot
cmds=(
"ifconfig eth0 down;ifconfig eth0 192.168.101.1 netmask 255.255.255.0 broadcast 192.168.101.255 up"
"dnsmasq -d -q -k --enable-dbus --user=dnsmasq -C dnsmasq.conf --pid-file"
"openvpn --cd etc/openvpn/server/ --config server.conf"
"systemctl restart nfs-kernel-server;systemctl status nfs-kernel-server"
)

if [ "`tmux ls | grep $session_name`" ]; then
	echo "The service already started!" >&2
	exit 1
fi

tmux new-session -s $session_name -d -x 240 -y 60

for i in `seq 0 $[${#cmds[*]}-1]`; do
	sleep 0.5
	tmux split-window
	sleep 0.5
	tmux select-layout tile
	sleep 0.5
	tmux send-keys -l "${cmds[i]}"
	sleep 0.5
	tmux send-keys Enter
done


