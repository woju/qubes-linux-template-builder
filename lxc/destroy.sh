#!/bin/bash

source ./current

./umount_kill.sh mnt/

lxc-stop --kill -P $(readlink -m .)/lxc --name ${CURRENT}
./umount_kill.sh mnt

rm -r lxc/${CURRENT}
rm -r prepared_images/*
rm -r qubeized_images/*
rm rpm/noarch/*
rm -rf mnt/*
