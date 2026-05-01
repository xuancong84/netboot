#!/bin/bash

cd "`dirname $0`"

if [ "$1" == start ]; then
	systemctl unmask systemd-journald.socket
	systemctl unmask systemd-journald
	systemctl start systemd-journald.socket
	systemctl start systemd-journald
	rm ../etc/X11/xinit/xserverrc
elif [ "$1" == stop ]; then
	systemctl mask systemd-journald.socket
	systemctl mask systemd-journald
	systemctl disable --now systemd-journald.socket
	systemctl disable --now systemd-journald
else
	echo "Usage: $0 start|stop"
	echo "This script enables/disables journal logging for debugging."
	echo "This script shall be run in the PXE TTY console."
	exit
fi
