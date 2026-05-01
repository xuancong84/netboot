#!/bin/bash

safe_umount() {
	if ! umount "$@"; then
		umount -fl "$@"
	fi
}


cd "`dirname $0`"

for p in sys proc dev dev/pts; do
	if ! mountpoint nfs/ro/rootfs/$p 2>&1 >/dev/null; then
		mount -v --bind /$p nfs/ro/rootfs/$p
	fi
done
mount -v --bind nfs/rw/var nfs/ro/rootfs/var

chroot nfs/ro/rootfs "$@"

safe_umount nfs/ro/rootfs/var
for p in sys proc dev dev/pts; do
	safe_umount nfs/ro/rootfs/$p
done

