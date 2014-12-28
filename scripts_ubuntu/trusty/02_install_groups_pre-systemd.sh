#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

info "HACK: Copying utopic sources.list to install systemd"
cat > "${INSTALLDIR}/etc/apt/sources.list.d/systemd-utopic.list" <<EOF
deb http://mirror.csclub.uwaterloo.ca/ubuntu/ utopic main
EOF

info "apt-get update"
aptUpdate
