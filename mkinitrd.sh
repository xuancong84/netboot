#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 input-dir output-file <compress-cmd=gzip>"
	exit 1
fi

ccmd=gzip
if [ "$3" ]; then
	ccmd="$3"
	if [ "$ccmd" == xz ];then
		ccmd="xz --check=crc32"
	fi
fi


OUT="`readlink -f \"$2\"`"

set -e -x -o pipefail

rm -rf "$OUT"


if [ -d $1/early ] && [ -d $1/main ]; then
	for f in $1/early*; do
		cd $f
		find . -print0 | cpio --null --create --format=newc | $ccmd >>"$OUT"
		cd -
	done
	cd $1/main && find . | cpio --create --format=newc | $ccmd >>"$OUT"
else
	cd $1
	find . -print0 | cpio --null --create --format=newc | $ccmd >"$OUT"
	cd -
fi
