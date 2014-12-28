#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

# Set verbose mode (-x or -e)
setVerboseMode

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" "prepared_debootstrap installataion has not completed!... Exiting"

# Create system mount points
prepareChroot

# Make sure there is a resolv.conf with network of this AppVM for building
createResolvConf

# Execute any template flavor or sub flavor 'pre' scripts
buildStep "$0" "pre"

if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_groups" ]; then
    info "Trap ERR and EXIT signals and cleanup (umount)"
    trap cleanup ERR
    trap cleanup EXIT

    # XXX: Now handled by umount_all
    # info "Set up a temporary dpkg-divert policy to prevent apt from starting services"
    # addDivertPolicy

    info "Add universe to sources.list"
    updateSourceList
    #if [ "${DIST}" == "trusty" ]; then
    #    cp "${SCRIPTSDIR}"/sources.list "${INSTALLDIR}"/etc/apt
    #fi

    info "Install Systemd"
    installSystemd

    # info "Ensure umask set in /etc/login.defs is used (022)"
    # configureUmask

    info "Configure keyboard"
    configureKeyboard

    info "Install extra packages in script_${DIST}/packages.list file"
    installPackages
    createSnapshot "packages"
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_packages"

    info "Execute any template flavor or sub flavor scripts after packages are installed"
    buildStep "$0" "packages_installed"

    info "apt-get dist-upgrade"
    aptDistUpgrade

    # XXX: Now handled by umount_all
    # info "Remove temporary dpkg-divert policy"
    # removeDivertPolicy

    info "Cleanup"
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_groups"
    trap - ERR EXIT
    trap

    # Kill all processes and umount all mounts within ${INSTALLDIR}, 
    # but not ${INSTALLDIR} itself (extra '/' prevents ${INSTALLDIR} from being
    # umounted itself)
    umount_all "${INSTALLDIR}/" || true
fi

# Execute any template flavor or sub flavor 'post' scripts
buildStep "$0" "post"
