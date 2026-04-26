# README

Configs for my network devices. Should be cloned into `/etc/config` on an openwrt device.

## `sync.py`

Handles populating device configs from copies/templates under [`devices/`](/devices). Allows for modifications via Luci/UCI which'll show up either in `git status` (if symlinked) or on the next run of the script, so that the changes can be manually synced back to the source configs.

## Image Builder

To simplify the extroot setup on `router`, there's a nix flake for building sysupgrade images with all the required packages and `fstab` preconfigured. This should be used instead of e.g. attended sysupgrade, otherwise the on-device flash will be used by default instead of the attached SD card.

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

#### Config merging

It's important to include new defaults from the new version: omitting `compat_version` in a previous update led to me needing to wipe the device more often than necessary.

This can technically be done before the above to be faster, since the contents of the old overlay (which would be modified by these operations) are copied to the new overlay. But for the sake of safe docs, do it in order.

1. Mount the router's configs using sshfs again.
1. Diff the default configs there against the git/original router's configs, and migrate changes over piece by piece. Pay special attention to template files.

#### Checks

1. Reconfigure anything needing it: check that adguardhome is functioning, and that the wireguard interface looks healthy.
