#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

# If .prepared_debootstrap has not been completed, don't continue
# exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_qubes" "prepared_qubes installataion has not completed!... Exiting"

# ------------------------------------------------------------------------------
# XXX: Create a snapshot - Only for DEBUGGING!
# ------------------------------------------------------------------------------
# Only execute if SNAPSHOT is set
#if [ "${SNAPSHOT}" == "1" ]; then
#    splitPath "${IMG}" path_parts
#    PREPARED_IMG="${path_parts[dir]}${path_parts[base]}-updated${path_parts[dotext]}"
#
#    if ! [ -f "${PREPARED_IMG}" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ]; then
#        umount_kill "${INSTALLDIR}" || :
#        warn "Copying ${IMG} to ${PREPARED_IMG}"
#        cp -f "${IMG}" "${PREPARED_IMG}"
#        mount -o loop "${IMG}" "${INSTALLDIR}" || exit 1
#        for fs in /dev /dev/pts /proc /sys /run; do mount -B $fs "${INSTALLDIR}/$fs"; done
#    fi
#fi

# ------------------------------------------------------------------------------
# chroot Whonix build script
# ------------------------------------------------------------------------------
read -r -d '' WHONIX_BUILD_SCRIPT <<'EOF' || true
################################################################################
# Pre Fixups
sudo mkdir --parents --mode=g+rw "/tmp/uwt"

# Change hostname
# XXX: This is not working from here; going to set via chroot
# sudo /bin/hostname host
# sudo echo 'host' > /etc/hostname

# Whonix expects haveged to be started
sudo /etc/init.d/haveged start

# Fake grub installation since Whonix has depends on grub-pc
sudo mkdir -p /boot/grub
sudo cp /usr/lib/grub/i386-pc/* /boot/grub
sudo rm -f /usr/sbin/update-grub
sudo ln -s /bin/true /usr/sbin/update-grub
sudo touch /boot/grub/grub.cfg

################################################################################
# Whonix installation
export WHONIX_BUILD_UNATTENDED_PKG_INSTALL="1"

pushd ~/Whonix
sudo ~/Whonix/whonix_build \
    --build $1 \
    --64bit-linux \
    --current-sources \
    --enable-whonix-apt-repository \
    --whonix-apt-repository-distribution $2 \
    --install-to-root \
    --skip-verifiable \
    --minimal-report \
    --skip-sanity-tests || { exit 1; }
popd
EOF

# ------------------------------------------------------------------------------
# Cleanup function
# ------------------------------------------------------------------------------
function cleanup() {
    error "Whonix error; umounting ${INSTALLDIR} to prevent further writes"
    umount_kill "${INSTALLDIR}" || :
    exit 1
}
trap cleanup ERR
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Mount devices, etc required for Whonix installation
# ------------------------------------------------------------------------------
if ! [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ]; then
    debug "Preparing Whonix system"

    #### '----------------------------------------------------------------------
    info ' Initialize Whonix submodules'
    #### '----------------------------------------------------------------------
    pushd "${WHONIX_DIR}"
        # Disabled Makefile for now
        # git add Makefile || true
        # git commit Makefile -m 'Added Makefile' || true
        su $(logname) -c "git submodule update --init --recursive"
    popd

    #### '----------------------------------------------------------------------
    info ' Change hostname to "host"'
    #### '----------------------------------------------------------------------
    #XXX:  Build will fail unless a host is set
    #      + cp --no-clobber --recursive --preserve /etc/hostname /etc/hostname.backup
    #      cp: cannot stat `/etc/hostname': No such file or directory
    echo "host" > "${INSTALLDIR}/etc/hostname"
    chroot sudo hostname host

    #### '----------------------------------------------------------------------
    info ' Whonix system config dependancies'
    #### '----------------------------------------------------------------------

    # Qubes needs a user named 'user'
    info "Whonix Add user"
    chroot id -u 'user' >/dev/null 2>&1 || \
    {
        # UID needs match host user to have access to Whonix sources
        chroot groupadd -f user
        [ -n "$SUDO_UID" ] && USER_OPTS="-u $SUDO_UID"
        chroot useradd -g user $USER_OPTS -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev -m -s /bin/bash user
        if [ `chroot id -u user` != 1000 ]; then
            chroot useradd -g user -u 1000 -M -s /bin/bash user-placeholder
        fi
    }

    #### '----------------------------------------------------------------------
    info ' Install Whonix build scripts'
    #### '----------------------------------------------------------------------
    echo "${WHONIX_BUILD_SCRIPT}" > "${INSTALLDIR}/home/user/whonix_build.sh"
    chmod 0755 "${INSTALLDIR}/home/user/whonix_build.sh"

    # Add a temporary sudo rule to allow Whonix build
    # echo "user ALL=(ALL) NOPASSWD: ALL" > "${INSTALLDIR}/etc/sudoers.d/whonix_build"
    # chmod 0440 "${INSTALLDIR}/etc/sudoers.d/whonix_build"

    touch "${INSTALLDIR}/tmp/.whonix_prepared"
fi

# ------------------------------------------------------------------------------
# Install Whonix
# ------------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/tmp/.whonix_prepared" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_installed" ]; then
    debug "Installing Whonix system"

    #### '----------------------------------------------------------------------
    info ' Install Whonix code base'
    #### '----------------------------------------------------------------------
    if ! [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        info "Installing Whonix build environment..."
        chroot su user -c 'mkdir /home/user/Whonix'
    fi

    if [ -d "${INSTALLDIR}/home/user/Whonix" ]; then
        info "Building Whonix..."
        mount --bind "../Whonix" "${INSTALLDIR}/home/user/Whonix"
    fi

    if [ "${TEMPLATE_FLAVOR}" == "whonix-gateway" ]; then
        BUILD_TYPE="--torgateway"
        echo "10.152.152.10" > "${INSTALLDIR}/etc/whonix-netvm-gateway"
    elif [ "${TEMPLATE_FLAVOR}" == "whonix-workstation" ]; then
        BUILD_TYPE="--torworkstation"
        echo "10.152.152.11" > "${INSTALLDIR}/etc/whonix-netvm-gateway"
    else
        error "Incorrent Whonix type \"${TEMPLATE_FLAVOR}\" selected.  Not building Whonix modules"
        error "You need to set TEMPLATE_FLAVOR environment variable to either"
        error "whonix-gateway OR whonix-workstation"
        error "Example: wheezy+whonix-gateway OR wheezy+whonix-workstation"
        exit 1
    fi
    touch "${INSTALLDIR}/tmp/.whonix_custom_configurations"

    # XXX
    chroot su user -c "cd ~; ./whonix_build.sh ${BUILD_TYPE} ${DIST}" || { exit 1; }
    #chroot sudo -u user /home/user/whonix_build.sh ${BUILD_TYPE} ${DIST} || { exit 1; }

    touch "${INSTALLDIR}/tmp/.whonix_installed"
fi

# ------------------------------------------------------------------------------
# Whonix Post Installation Configurations
# ------------------------------------------------------------------------------
if [ -f "${INSTALLDIR}/tmp/.whonix_installed" ] && ! [ -f "${INSTALLDIR}/tmp/.whonix_post" ]; then
    debug "Post Configuring Whonix System"

    #DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    #    chroot apt-get.anondist-orig update

    #### '----------------------------------------------------------------------
    info ' Install whonix-qubes package'
    #### '----------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot apt-get ${APT_GET_OPTIONS} install whonix-qubes

    # Remove apt-cacher-ng
    chroot systemctl stop apt-cacher-ng || :
    chroot systemctl disable apt-cacher-ng || :
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
        chroot apt-get.anondist-orig -y --force-yes remove --purge apt-cacher-ng

    # Remove original sources.list
    rm -f "${INSTALLDIR}/etc/apt/sources.list"

    #### '----------------------------------------------------------------------
    info ' Restore default user UID to have the same in all builds regardless of build host'
    #### '----------------------------------------------------------------------
    if [ -n "`chroot id -u user-placeholder`" ]; then
        chroot userdel user-placeholder
        chroot usermod -u 1000 user
    fi

    #### '----------------------------------------------------------------------
    info ' Enable aliases in .bashrc'
    #### '----------------------------------------------------------------------
    sed -i "s/^# export/export/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# eval/eval/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^# alias/alias/g" "${INSTALLDIR}/root/.bashrc"
    sed -i "s/^#force_color_prompt/force_color_prompt/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/#alias/alias/g" "${INSTALLDIR}/home/user/.bashrc"
    sed -i "s/alias l='ls -CF'/alias l='ls -l'/g" "${INSTALLDIR}/home/user/.bashrc"

    #### '----------------------------------------------------------------------
    info ' Use gdialog as an alternative for dialog'
    #### '----------------------------------------------------------------------
    mv -f "${INSTALLDIR}/usr/bin/dialog" "${INSTALLDIR}/usr/bin/dialog.dist"
    chroot update-alternatives --force --install /usr/bin/dialog dialog /usr/bin/gdialog 999

    #### '----------------------------------------------------------------------
    info ' Fake that initializer was already run'
    #### '----------------------------------------------------------------------
    mkdir -p "${INSTALLDIR}/root/.whonix"
    touch "${INSTALLDIR}/root/.whonix/first_run_initializer.done"

    #### '----------------------------------------------------------------------
    info ' Prevent whonixcheck error'
    #### '----------------------------------------------------------------------
    echo 'WHONIXCHECK_NO_EXIT_ON_UNSUPPORTED_VIRTUALIZER="1"' >> "${INSTALLDIR}/etc/whonix.d/30_whonixcheck_default"

    #### '----------------------------------------------------------------------
    info ' Disable unwanted applications'
    #### '----------------------------------------------------------------------
    chroot systemctl disable network-manager || :
    chroot systemctl disable spice-vdagent || :
    chroot systemctl disable swap-file-creator || :
    chroot systemctl disable whonix-initializer || :

    #### '----------------------------------------------------------------------
    info ' Tor will be re-enabled upon initial configuration'
    #### '----------------------------------------------------------------------
    chroot systemctl disable tor || :
    chroot systemctl disable sdwdate || :

    #### '----------------------------------------------------------------------
    info ' Cleanup Whonix Installation'
    #### '----------------------------------------------------------------------
    umount_kill "${INSTALLDIR}"/home/user/Whonix || :
    rm -rf "${INSTALLDIR}"/home/user/Whonix
    rm -rf "${INSTALLDIR}"/home/user/whonix_binary
    rm -f "${INSTALLDIR}"/home/user/whonix_fix
    rm -f "${INSTALLDIR}"/home/user/whonix_build.sh
fi


#### '--------------------------------------------------------------------------
info ' Finish'
#### '--------------------------------------------------------------------------
touch "${INSTALLDIR}/${TMPDIR}/.prepared_whonix"
trap - ERR EXIT
trap

