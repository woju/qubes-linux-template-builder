#!/bin/sh
# vim: set ts=4 sw=4 sts=4 et :

source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"

# Set verbose mode (-x or -e)
setVerboseMode

# If .prepared_debootstrap has not been completed, don't continue
exitOnNoFile "${INSTALLDIR}/${TMPDIR}/.prepared_groups" "prepared_groups installataion has not completed!... Exiting"

# Create system mount points
prepareChroot

# Execute any template flavor or sub flavor 'pre' scripts
buildStep "$0" "pre"

# ------------------------------------------------------------------------------
# Install Qubes Packages
# ------------------------------------------------------------------------------
if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_qubes" ]; then
    debug "Installing qbues modules"

    # XXX: NEW; not sure if we should keep it
    info "Trap ERR and EXIT signals and cleanup (umount)"
    trap cleanup ERR
    trap cleanup EXIT

    info "Copy extra files to installation directory.  Contains: font fixes for display issues"
    copyTree "qubes-files" "${SCRIPTSDIR}" "${INSTALLDIR}"

    info "Generate locales"
    chroot locale-gen en_US.UTF-8

    info "Link mtab"
    chroot rm -f /etc/mtab
    chroot ln -s /proc/self/mounts /etc/mtab

    info "Installing qubes packages"
    export CUSTOMREPO="${PWD}/yum_repo_qubes/${DIST}"

    info "Installing keyrings"
    installKeyrings

    info "Mounting local qubes_repo"
    mkdir -p "${INSTALLDIR}/tmp/qubes_repo"
    mount --bind "${CUSTOMREPO}" "${INSTALLDIR}/tmp/qubes_repo"

    cat > "${INSTALLDIR}/etc/apt/sources.list.d/qubes-builder.list" <<EOF
deb file:/tmp/qubes_repo ${DIST} main
EOF

    info "apt-get upgrade"
    aptUpgrade || { umount_all; exit 1; }

    info "Install extra packages in packages_qubes.list file"
    installPackages ""${SCRIPTSDIR}"/packages_qubes.list" || { umount_all; exit 1; };

    info "Removing Quebes repo from sources.list.d"
    umount_all ""${INSTALLDIR}/${TMPDIR}/qubes_repo""
    rm -f "${INSTALLDIR}/etc/apt/sources.list.d/qubes-builder.list"

    info "apt-get update"
    aptUpdate

    info "Cleanup"
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_qubes"
    trap - ERR EXIT
    trap
fi

# ------------------------------------------------------------------------------
# Execute any template flavor or sub flavor 'post' scripts
# ------------------------------------------------------------------------------
buildStep "$0" "post"

# ------------------------------------------------------------------------------
# Kill all processes and umount all mounts within ${INSTALLDIR}, but not 
# ${INSTALLDIR} itself (extra '/' prevents ${INSTALLDIR} from being umounted itself)
# ------------------------------------------------------------------------------
umount_all "${INSTALLDIR}/" || true
