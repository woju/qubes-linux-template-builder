#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

# ------------------------------------------------------------------------------
# Global variables and functions
# ------------------------------------------------------------------------------

. ./functions.sh

# Temp directory to place installation files and progress markers
# XXX: TEMP move tmpdir
###TMPDIR="/tmp"
TMPDIR="/var/lib/qubes/install"

# Location to grab ubuntu packages
DEBIAN_MIRROR=http://archive.ubuntu.com/ubuntu

#APT_GET_OPTIONS="-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confnew" --force-yes -y"
APT_GET_OPTIONS="-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes -y"
