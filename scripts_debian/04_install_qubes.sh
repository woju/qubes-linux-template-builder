#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_groups" "prepared_groups installataion has not completed!... Exiting"

# Create system mount points
prepareChroot

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

# ==============================================================================
# Install Qubes Packages
# ==============================================================================
if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_qubes" ]; then
    debug "Installing Qubes modules"

    #### '----------------------------------------------------------------------
    info ' Trap ERR and EXIT signals and cleanup (umount)'
    #### '----------------------------------------------------------------------
    trap cleanup ERR
    trap cleanup EXIT

    #### '----------------------------------------------------------------------
    info ' Generate locales'
    #### '----------------------------------------------------------------------
    echo "en_US.UTF-8 UTF-8" >> "${INSTALLDIR}/etc/locale.gen"  # DEBIAN ONLY?
    chroot locale-gen en_US.UTF-8

    #### '----------------------------------------------------------------------
    info "Link mtab"
    #### '----------------------------------------------------------------------
    chroot rm -f /etc/mtab
    chroot ln -s /proc/self/mounts /etc/mtab

    #### '----------------------------------------------------------------------
    info ' Install Qubes packages listed in packages_qubes.list file(s)'
    #### '----------------------------------------------------------------------
    installQubesRepo
    aptUpdate
    installPackages packages_qubes.list
    uninstallQubesRepo

    #### '----------------------------------------------------------------------
    info ' Cleanup'
    #### '----------------------------------------------------------------------
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_qubes"
    trap - ERR EXIT
    trap
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"

# ==============================================================================
# Kill all processes and umount all mounts within ${INSTALLDIR}, but not 
# ${INSTALLDIR} itself (extra '/' prevents ${INSTALLDIR} from being umounted)
# ==============================================================================
umount_all "${INSTALLDIR}/" || true

