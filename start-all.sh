#!/bin/bash

session_name=netboot
if [ "`tmux ls | grep $session_name`" ]; then
	echo "The service already started!" >&2
	exit 1
fi

ifaces=(`ls /sys/class/net | grep ^e`)

if [ ${#ifaces[@]} == 0 ]; then
	echo "No interfaces found for hosting PXE"
	exit
elif [ ${#ifaces[@]} -gt 1 ]; then
	echo "More than 1 interfaces found: ${ifaces[@]}"
	echo "Which one do you want to use for hosting PXE?"
	read iface
	while [ ! "`echo ${ifaces[@]} | grep $iface`" ]; do
		echo "Must choose from ${ifaces[@]}"
		read iface
	done
else
	iface=${ifaces[0]}
fi


cmds=(
"ifconfig $iface down;ifconfig $iface 192.168.101.1 netmask 255.255.255.0 broadcast 192.168.101.255 up"
"while [ 1 ]; do date -Is | nc -q 1 -l 192.168.101.1 9001; done"
"sed "s:eth0:$iface:g" dnsmasq.conf>_dnsmasq.conf ; dnsmasq -d -q -k --enable-dbus --user=dnsmasq -C _dnsmasq.conf --pid-file"
"openvpn --cd etc/openvpn/server/ --config server.conf"
"systemctl restart nfs-kernel-server;systemctl status nfs-kernel-server"
)


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


