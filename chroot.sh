#!/bin/bash

for p in sys proc dev tmp; do
	if ! mountpoint nfs/ro/rootfs/$p; then
		mount -v --bind /$p nfs/ro/rootfs/$p
	fi
done

chroot nfs bash -l

for p in sys proc dev tmp; do
	umount -f nfs/$p
done

