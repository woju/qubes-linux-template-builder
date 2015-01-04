#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

debug "Installing custom packages and customizing ${DIST}"

#### '--------------------------------------------------------------------------
info ' Adding debian-security repository.'
#### '--------------------------------------------------------------------------
source="deb http://security.debian.org ${DEBIANVERSION}/updates main"
if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
    touch "${INSTALLDIR}/etc/apt/sources.list"
    echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
fi

source="deb-src http://security.debian.org ${DEBIANVERSION}/updates main"
if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
    touch "${INSTALLDIR}/etc/apt/sources.list"
    echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
fi

#### '--------------------------------------------------------------------------
info ' Remove sysvinit'
#### '--------------------------------------------------------------------------
echo 'Yes, do as I say!' | aptRemove sysvinit

#### '--------------------------------------------------------------------------
info ' Preventing sysvinit re-installation'
#### '--------------------------------------------------------------------------
chroot apt-mark hold sysvinit

#### '--------------------------------------------------------------------------
info ' Pin sysvinit to prevent being re-installed'
#### '--------------------------------------------------------------------------
cat > "${INSTALLDIR}/etc/apt/preferences.d/qubes_sysvinit" <<EOF
Package: sysvinit
Pin: version *
Pin-Priority: -100
EOF
chmod 0644 "${INSTALLDIR}/etc/apt/preferences.d/qubes_sysvinit"

#### '--------------------------------------------------------------------------
info ' Install Systemd'
#### '--------------------------------------------------------------------------
aptUpdate
aptInstall systemd-sysv

#### '--------------------------------------------------------------------------
info ' Set multu-user.target as the default target (runlevel 3)'
#### '--------------------------------------------------------------------------
chroot rm -f /etc/systemd/system/default.target
chroot ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

#### '--------------------------------------------------------------------------
info ' Adding wheezy backports repository.'
#### '--------------------------------------------------------------------------
source="deb ${DEBIAN_MIRROR} wheezy-backports main"

if ! grep -r -q "$source" "${INSTALLDIR}/etc/apt/sources.list"*; then
    touch "${INSTALLDIR}/etc/apt/sources.list"
    echo "$source" >> "${INSTALLDIR}/etc/apt/sources.list"
fi

aptUpdate

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    chroot apt-get ${APT_GET_OPTIONS} -t wheezy-backports install init-system-helpers

