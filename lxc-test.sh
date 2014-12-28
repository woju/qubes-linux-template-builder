#!/bin/bash

ins="mnt"

function test() {
	local dir="${1}"
	if [[ "${dir}" =~ ${ins}(|\/)$ ]]; then
		echo "THEY MATCH"
	else
		echo "NO MATCH!!!!"
	fi
}

test "mnt"
test "mnt/"
test "mnt/h"

exit 0
source ./functions.sh

DIST=trusty
LXC_DIR="$(readlink -m .)/lxc"
if=eth0

if [ ! 'mnt/etc/resolv.conf' ]; then
    info "Mounting INSTALLDIR..."
    mount -o loop prepared_images/ubuntu-trusty-x64.img mnt
fi

info "Launching lxc-wait in background..."
lxc-wait -P "${LXC_DIR}" -n "${DIST}" -s RUNNING &
lxc_wait_pid=$!

info "Starting LXC container..."
lxc-start -d -P "${LXC_DIR}" -n "${DIST}"

info "Waiting for LXC container RUNNING state..."
wait $lxc_wait_pid

info "Waiting for LXC container network ${if} up state..."
lxc-attach -P "${LXC_DIR}" -n "${DIST}" -- \
    su -c "while ! ip a | sed -rn '/: '"$if"':.*state UP/{N;N;s/.*inet (\S*).*/\1/p}' | grep -q '.'; do printf '.'; sleep 1; done; echo ''"

info "Network state is active."

info "Testing network connection..."
lxc-attach -P "${LXC_DIR}" -n "${DIST}" -- apt-get update

exit 0
