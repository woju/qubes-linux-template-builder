#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" "prepared_debootstrap installataion has not completed!... Exiting"

# Create system mount points
prepareChroot

# Make sure there is a resolv.conf with network of this AppVM for building
createResolvConf

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

# ==============================================================================
# Configure base system and install any adddtional packages which could
# include +TEMPLATE_FLAVOR such as gnome as set in configuration file
# ==============================================================================
if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_groups" ]; then
    debug "Configuring and Installing packages for ${DIST}"

    #### '----------------------------------------------------------------------
    info ' Trap ERR and EXIT signals and cleanup (umount)'
    #### '----------------------------------------------------------------------
    trap cleanup ERR
    trap cleanup EXIT

    #### '----------------------------------------------------------------------
    info ' Configure keyboard'
    #### '----------------------------------------------------------------------
    configureKeyboard

    info "Install extra packages in script_${DIST}/packages.list file"
    installPackages
    createSnapshot "packages"
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_packages"

    #### '----------------------------------------------------------------------
    info ' Execute any template flavor or sub flavor scripts after packages are installed'
    #### '----------------------------------------------------------------------
    buildStep "$0" "packages_installed"

    #### '----------------------------------------------------------------------
    info ' Distribution specific steps (install systemd, add sources, etc)'
    #### '----------------------------------------------------------------------
    buildStep "$0" "${DIST}"

    #### '----------------------------------------------------------------------
    info ' apt-get dist-upgrade'
    #### '----------------------------------------------------------------------
    aptDistUpgrade

    #### '----------------------------------------------------------------------
    info ' Cleanup'
    #### '----------------------------------------------------------------------
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_groups"
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

