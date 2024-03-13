#!/usr/bin/env bash

# Exit script on error
set -e

# Error handler
trap 'echo "An error occurred. Exiting..." >&2' ERR

# Variables
freebsd13_kernel="http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/amd64/13.1-RELEASE/kernel.txz"
freebsd13_qga_pkg="https://pkg.freebsd.org/FreeBSD:13:amd64/latest/All/qemu-guest-agent-8.2.2.pkg"
qga_backup_dir="/root/qga_backup"

# Download FreeBSD 13.1 kernel.txz and extract virtio_console.ko driver to /boot/kernel
echo -e "\nDownloading FreeBSD 13.1 kernel.txz and extracting virtio_console.ko driver to /boot/kernel..."
curl -#O ${freebsd13_kernel} --output-dir /tmp/
tar -xf /tmp/kernel.txz --strip-components=3 -C /boot/modules/ ./boot/kernel/virtio_console.ko 1> /dev/null

# Load virtio_console.ko driver
kldload /boot/modules/virtio_console.ko

# Download and install FreeBSD 13 qemu-guest-agent package
echo -e "\nDownloading and installing FreeBSD 13 qemu-guest-agent package..."
IGNORE_OSVERSION=yes pkg add ${freebsd13_qga_pkg} 1> /dev/null

# Create backup of qemu-guest-agent file
mkdir ${qga_backup_dir}
cp /usr/local/etc/rc.d/qemu-guest-agent ${qga_backup_dir}/

export TERM=dumb

# Create tunables for QEMU Guest Agent
echo -e "\nCreating tunables for QEMU Guest Agent..."
cli << EOF &> /dev/null
    system tunable create type=RC var="qemu_guest_agent_enable" value="YES" enabled=true
    system tunable create type=RC var="qemu_guest_agent_flags" value="-d -v -l /var/log/qemu-ga.log" enabled=true
    system tunable create type=LOADER var="virtio_console_load" value="YES" enabled=true
EOF

# Set un init/shutdown scripts for QEMU Guest Agent
echo -e "\nSetting init/shutdown scripts for QEMU Guest Agent..."
cli << EOF &> /dev/null
    system initshutdownscript create type=COMMAND command="service qemu-guest-agent start" when=POSTINIT enabled=true timeout=10 comment="start qemu-guest-agent on boot"
    system initshutdownscript create type=COMMAND command="cp ${qga_backup_dir}/qemu-guest-agent /usr/local/etc/rc.d" when=PREINIT enabled=true timeout=10 comment="copy qemu-guest-agent on boot"
EOF

# Ask user to reboot TrueNAS
echo -e "\nPlease reboot TrueNAS to apply changes."
