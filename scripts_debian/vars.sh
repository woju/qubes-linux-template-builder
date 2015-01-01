#!/bin/bash -e

source ./functions.sh

# ------------------------------------------------------------------------------
# Global variables and functions
# ------------------------------------------------------------------------------

# Temp directory to place installation files and progress markers
# (Do not use /tmp since if built in a real VM, /tmp will be empty on a reboot)
TMPDIR="/var/lib/qubes/install"

# The codename of the debian version to install.
# jessie = testing, wheezy = stable
DEBIANVERSION=${DIST}

# Location to grab debian packages
# TODO:  Create an array of mirrors in case of failure
DEBIAN_MIRROR=http://ftp.us.debian.org/debian
#DEBIAN_MIRROR=http://http.debian.net/debian
#DEBIAN_MIRROR=http://ftp.ca.debian.org/debian

# Ubuntu
APT_GET_OPTIONS="-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes -y"

# Original Debian
# APT_GET_OPTIONS="-o Dpkg::Options::="--force-confnew" --force-yes -y"

# Experimential
# APT_GET_OPTIONS="-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confnew" --force-yes -y"

