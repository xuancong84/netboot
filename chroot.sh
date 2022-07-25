#!/bin/bash

for p in sys proc dev tmp; do
	if ! mountpoint nfs/$p; then
		mount -v --bind /$p nfs/$p
	fi
done

chroot nfs bash -l

for p in sys proc dev tmp; do
	umount -f nfs/$p
done

