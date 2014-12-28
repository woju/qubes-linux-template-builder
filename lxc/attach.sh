#!/bin/sh

source ./current

lxc-attach -P $(readlink -m .)/lxc --name ${CURRENT}
