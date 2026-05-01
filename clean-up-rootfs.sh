#!/bin/bash

rm -rf nfs/rw/var/cache/*
rm -rf nfs/rw/var/backups/*
rm -rf nfs/rw/var/log/*
rm -rf nfs/rw/var/tmp/*
rm -rf nfs/rw/var/lib/apt/lists/*
rm -rf nfs/rw/var/lib/*/.cache
rm -rf nfs/rw/var/home/*/.cache
rm -rf nfs/rw/var/home/*/.local
rm -rf nfs/ro/rootfs/root/.cache
find nfs -iname '.nfs*' | xargs rm -rf
rm -f _dnsmasq.conf
