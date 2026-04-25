# README

Configs for my network devices. `sync.py` handles symlinking or templating the configs to the right places.

## Fresh Installs

If the config is wiped (e.g. due to a firmware bump that requires deleting settings), here are the high-level steps to follow:

#### Initial Setup

1. Plug laptop via an ethernet cable into a low-pri port on the router (e.g. the Hue port - avoid the WAN port or the port leading to the AP).
1. Laptop should get a `192.168.1.x/24` address via default DHCP configuration (`watch -c -n0 ip -c a`).
1. Open http://192.168.1.1 and log in with no password.
1. Set the password.
1. Add the laptop's SSH public key to the router. At this point, might be able to get off the floor and connect via wifi from a more comfortable chair.
1. Install some minimal QoL packages:

   ```sh
   $ apk add bash vim openssh-sftp-server
   ```

1. Mount the configs from laptop and clone this repo somewhere convenient, to make the next steps easier:

   ```sh
   $ nix run nixpkgs#sshfs -- -o uid=$(id -u),gid=$(id -g) root@router:/etc/config ~/mnt
   $ git clone https://github.com/hnefatl/router-openwrt-config /tmp/config
   # Now can do e.g.:
   $ vim -d /tmp/config/network ~/mnt/network
   ```

#### Extroot

Generally, follow the steps [on this wiki page](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration#partitioning_and_formatting).

1. To make space for adguardhome and other apps, I'm using [extroot](https://openwrt.org/docs/guide-user/additional-software/extroot_configuration). This mounts an external SD card as the mutable root overlay filesystem, instead of the on-device storage. Ideally this should be done first, to minimise how much stuff needs copying over to the card.

   Install necessary packages:

   ```
   $ apk add block-mount kmod-fs-ext4 e2fsprogs parted kmod-usb-storage kmod-sdhci-mt7620 lsblk kmod-usb-core kmod-usb-storage kmod-fs-vfat kmod-fs-f2fs
   ```

   Copy the contents of [`fstab`](/fstab) to the device, then verify the UUIDs are accurate (`lsblk -o name,size,uuid`). `block mount` will try to mount the partitions, to preview any errors.

1. Manually mount the SD card on e.g. `/mnt`. Take a backup, then wipe the contents, and copy the current overlay FS contents to the new one:

   ```sh
   $ mount /dev/mmcblk0p1 /mnt
   # From laptop:
   $ scp -r root@192.168.1.1/mnt /tmp/old_overlay
   # Back on router:
   $ rm -rf /mnt/* /mnt/.*
   $ tar -C /overlay -cvf - . | tar -C /mnt -xf -
   ```

1. Reboot the router. It should come back up with the filesystems mounted correctly.

#### Config merging

It's important to include new defaults from the new version: omitting `compat_version` in a previous update led to me needing to wipe the device more often than necessary.

This can technically be done before the above to be faster, since the contents of the old overlay (which would be modified by these operations) are copied to the new overlay. But for the sake of safe docs, do it in order.

1. Mount the router's configs using sshfs again.
1. Diff the default configs there against the git/original router's configs, and migrate changes over piece by piece. Pay special attention to template files.

#### Reinstall missing packages

1. Reinstall any useful packages from [packages](/packages).
1. Reconfigure anything needing it: check that adguardhome is functioning, and that the wireguard interface looks healthy.
