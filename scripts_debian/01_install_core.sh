#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

# Source external scripts
source "${SCRIPTSDIR}/vars.sh"
source "${SCRIPTSDIR}/functions.sh"
source ./umount_kill.sh >/dev/null

# TMPDIR is set in vars.  /tmp should not be used since it will be cleared
# if building template with LXC contaniners on a reboot
mkdir -p "${INSTALLDIR}/${TMPDIR}"

# ==============================================================================
# Execute any template flavor or sub flavor 'pre' scripts
# ==============================================================================
buildStep "${0}" "pre"

# ==============================================================================
# Install base system using debootstrap
# ==============================================================================
if ! [ -f "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap" ]; then

    if [ "${LXC_ENABLE}" == "1" ]; then
        #### ' ------------------------------------------------------------------
        info "$(templateName): LXC: Installing base '${DISTRIBUTION}-${DIST}' system"
        #### ' ------------------------------------------------------------------
        lxc-create -P "${LXC_DIR}" --dir="${INSTALLDIR}" -t download -n "${DIST}" -- \
            --dist "${DISTRIBUTION}" --release "${DIST}" --arch amd64

    else

        #### ' ------------------------------------------------------------------
        info "$(templateName): Installing base '${DISTRIBUTION}-${DIST}' system"
        #### ' ------------------------------------------------------------------
        COMPONENTS="" debootstrap --arch=amd64 --include=ncurses-term --components=main \
            --keyring="${SCRIPTSDIR}/keys/${DIST}-${DISTRIBUTION}-archive-keyring.gpg" \
            "${DIST}" "${INSTALLDIR}" "${DEBIAN_MIRROR}" || { error "Debootstrap failed!"; exit 1; }

    fi

    # Mark section as complete
    touch "${INSTALLDIR}/${TMPDIR}/.prepared_debootstrap"

    # If SNAPSHOT=1, Create a snapshot of the already debootstraped image
    createSnapshot "debootstrap"
fi

# ==============================================================================
# Execute any template flavor or sub flavor 'post' scripts
# ==============================================================================
buildStep "${0}" "post"

