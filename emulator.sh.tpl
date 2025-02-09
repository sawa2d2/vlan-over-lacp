#!/bin/bash

# Delete the existing OVS ports
ovs-vsctl del-port ovsbr0 bond-vm${vm_index}

# Delete the existing ports
ovs-vsctl del-port ovsbr0 tap${vm_index}p1
ovs-vsctl del-port ovsbr0 tap${vm_index}p2

# Execute QEMU
if [[ -x /usr/libexec/qemu-kvm ]]; then
    QEMU_BIN="/usr/libexec/qemu-kvm"
elif [[ -x /usr/bin/qemu-system-x86_64 ]]; then
    QEMU_BIN="/usr/bin/qemu-system-x86_64"
else
    echo "Error: Neither /usr/libexec/qemu-kvm nor /usr/bin/qemu-system-x86_64 is available."
    exit 1
fi

exec "$QEMU_BIN" "$@"
