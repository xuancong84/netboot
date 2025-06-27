#!/bin/bash

rm -rf nfs/rw/var/cache/*
rm -rf nfs/rw/var/log/*
rm -rf nfs/rw/var/tmp/*
rm -rf nfs/rw/var/lib/apt/lists/*
rm -rf nfs/rw/var/home/*/.cache
rm -rf nfs/rw/var/lib/*/.cache
find nfs -iname '.nfs0*' | xargs rm
