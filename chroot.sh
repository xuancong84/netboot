#!/bin/bash

safe_umount() {
	if ! umount "$@"; then
		umount -fl "$@"
	fi
}


cd "`dirname $0`"

for p in sys proc dev tmp; do
	if ! mountpoint nfs/ro/rootfs/$p; then
		mount -v --bind /$p nfs/ro/rootfs/$p
	fi
done
mount -v --bind nfs/rw/var nfs/ro/rootfs/var

chroot nfs/ro/rootfs bash -l

umount -f nfs/ro/rootfs/var
for p in sys proc dev tmp; do
	umount -f nfs/ro/rootfs/$p
done

