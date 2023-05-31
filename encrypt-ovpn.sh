#!/bin/bash

set -e

cd `dirname $0`

cd ovpn.dec
tar -czf ovpn.tar.gz *.ovpn
cd -

mkdir -p ovpn.enc
openssl aes-256-cbc -md sha512 -pbkdf2 -salt -in ovpn.dec/ovpn.tar.gz -out ovpn.enc/ovpn

