#!/bin/bash

set -e

cd `dirname $0`

cd ovpn.dec
tar -czf ovpn.tar.gz *.ovpn
cd -

mkdir -p nfs/ro/ovpn.enc
openssl aes-256-cbc -md sha512 -salt -pbkdf2 -iter 100000 -in ovpn.dec/ovpn.tar.gz -out nfs/ro/ovpn.enc/ovpn

