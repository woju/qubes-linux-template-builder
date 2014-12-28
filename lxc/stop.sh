#!/bin/sh

source ./current

lxc-stop --kill -P $(readlink -m .)/lxc --name ${CURRENT}
