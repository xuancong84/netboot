#!/bin/bash

if [ $# != 2 ]; then
	echo "Usage: $0 input-dir output-file"
	exit 1
fi

OUT="`readlink -f \"$2\"`"

set -e -x -o pipefail

rm -rf "$OUT"


if [ -d $1/early ] && [ -d $1/main ]; then
	for f in $1/early*; do
		cd $f
		find . -print0 | cpio --null --create --format=newc >>"$OUT"
		cd -
	done
	cd $1/main && find . | cpio --create --format=newc | gzip >>"$OUT"
else
	cd $1
	find . -print0 | cpio --null --create --format=newc | gzip >"$OUT"
	cd -
fi
