# TrueNAS 13 QEMU Guest Agent

This is a guide for Installing and Configuring QEMU Guest Agent for TrueNAS 13. It is based on the **QEMU Guest Agent** and **VirtIO Console driver** from **FreeBSD 13**.

## Requirements

Due to the TrueNAS kernel lacking certain FreeBSD drivers, it's necessary to download the FreeBSD 13 kernel, extract the VirtIO Console driver and integrate it into the TrueNAS system. This ensures TrueNAS compatibility with virtualized environments.

Required packages for this guide:
- VirtIO Console driver: [Man Page](https://man.freebsd.org/cgi/man.cgi?query=virtio_console)
- QEMU Guest Agent: [Man Page](https://freebsd.pkgs.org/13/freebsd-amd64/qemu-guest-agent-8.1.3.pkg.html)

FreeBSD 13 Binary Packages:
- FreeBSD 13.1 Kernel: [Package](http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/amd64/13.1-RELEASE/kernel.txz)
- QEMU Guest Agent: [Package](https://pkg.freebsd.org/FreeBSD:13:amd64/latest/All/qemu-guest-agent-9.0.0.pkg)
  - If the link is dead, replace the package version in the url with the latest one found here: [Package](https://ports.freebsd.org/cgi/ports.cgi?query=qemu-guest-agent&stype=all&sektion=all)

## Manual Installation

1. Download FreeBSD 13.1 kernel.txz and extract `./boot/kernel/virtio_console.ko` driver to `/boot/modules/` directory.

2. Load the VirtIO Console driver with
    ```bash
    kldload /boot/modules/virtio_console.ko
    ```

3. Download FreeBSD 13 QEMU Guest Agent package.

4. Install downloaded `qemu-guest-agent` package using `pkg add`.

5. Backup installed `/usr/local/etc/rc.d/qemu-guest-agent` to `/root/qga_backup/`. This will be a copy that is re-added to the rc.d directory each time TrueNAS boots.

6. Create the following Tunables in the TrueNAS web UI under **System** -> **Tunables**:
    1. Variable: `qemu_guest_agent_enable`, Value: `YES`, Type: `RC`, Enabled: `yes`
    2. Variable: `qemu_guest_agent_flags`, Value: `-d -v -l /var/log/qemu-ga.log`, Type: `RC`, Enabled: `yes`
    3. Variable: `virtio_console_load`, Value: `YES`, Type: `LOADER`, Enabled: `yes`

7. Set up Init/Shutdown Scripts in **Tasks** -> **Init/Shutdown Scripts**:
    1. Type: `Command`, Command: `service qemu-guest-agent start`, When: `POSTINIT`, Enabled: `yes`, Timeout: `10`
    2. Type: `Command`, Command: `cp /root/qga_backup/qemu-guest-agent /usr/local/etc/rc.d`, When: `PREINIT`, Enabled: `yes`, Timeout: `10`

8. Reboot TrueNAS to apply changes.

## Automated Installation

Via bash script:

1. Execute the following commands on your TrueNAS system:
    ```bash
    curl -O https://raw.githubusercontent.com/gushmazuko/truenas-qemu-guest-agent/master/install.sh
    chmod +x install.sh
    ./install.sh
    ```

2. Reboot TrueNAS to apply changes.

Or via ansible:

1. Execute ansible-playbook on your TrueNAS system:
    ```bash
    ansible-playbook ./install_qemu_guest_agent_on_truenas.yml \
    -e working_host=truenas.example.com \
    -e ansible_ssh_port=22
    ```

2. Reboot TrueNAS to apply changes.

## Conclusion
Following these steps ensures the successful installation and configuration of the `QEMU Guest Agent` on TrueNAS 13, improving its functionality in virtualized environments.
