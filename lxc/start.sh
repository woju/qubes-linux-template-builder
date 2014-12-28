#!/bin/sh

source ./current

if ! [ -d 'mnt/etc' ]; then
    mount -o loop prepared_images/ubuntu-utopic-x64.img mnt
fi

lxc-start -P $(readlink -m .)/lxc --name ${CURRENT}
