#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

info "HACK: Commenting out utopic sources.list used to install systemd"
sed -i "s/^deb/#deb/" "${INSTALLDIR}"/etc/apt/sources.list.d/systemd-utopic.list

info "apt-get update"
aptUpdate
