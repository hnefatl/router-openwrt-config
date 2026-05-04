# README

Configs for my network devices. This repository acts as the source of intent for my network devices.

Per-device secrets must be placed in a directory named `secrets` at the root and named `${hostname}.toml`.

# Network Layout

Most of this is defined in the router's [`network.tmpl`](/devices/router/network.tmpl).

The IPv6 ULA prefix is `fdf3:685c:acae::/48`.

These are the current VLANs+subnets:

VLAN | Usage | IPv4 | IPv6 ULA
---|---|---|---
1 | Core networking devices | `10.20.1.0/24` | `fdf3:685c:acae:1::/64`
10 | Trusted devices (PC, Laptop, Server) | `10.20.10.0/24` | `fdf3:685c:acae:10::/64`
20 | Untrusted devices | `10.20.20.0/24` | `fdf3:685c:acae:20::/64`
21 | Untrusted devices without internet access | `10.20.21.0/24` | `fdf3:685c:acae:21::/64`

Core networking device IP address are allocated statically (either via literals like `10.20.0.1`, or IPv6 hints). General IPv4 addresses are distributed by DHCPv4, and IPv6 are allocated using SLAAC. Hostname resolution works on the `.lan` domain, e.g. `warthog.lan`, and should be preferred over hardcoding ULAs.

In practice most devices end up in "Trusted", it's used by my main WiFi and most wired devices. These have ~no restrictions, can talk to anything else.

The "Untrusted" and "Untrusted Offline" subnets enforce client isolation where possible, and only allow connections _in_ from "Core"/"Trusted", not _out_ to those subnets. The "Untrusted" network allows connections out to the internet.

## `sync.sh`

Handles populating device configs from configs/templates under [`devices/`](/devices). Makes it easier to compare device state to defined state and sync changes in either direction between them.

Also handles using `sshfs` to connect to the devices.

## Image Builder

[`images.nix`](/images.nix) defines sysupgrade images for each device. This allows for:

- bundling critical packages by default, e.g. `openssh-sftp-server` for `scp`/`sshfs`.
- configuring extroot on `router`, bundling SD card drivers and an `/etc/config/fstab` file (otherwise on-device flash is used on boot, rather than the larger persisted SD card).
- setting up symlinks needed by the config generation pipeline, e.g. `/etc/dropbear/authorized_keys`->`/etc/config/authorized_keys`.

## Fresh Installs

If a device's config is wiped (e.g. due to a firmware bump that requires deleting settings), here are the high-level steps to follow:

#### Initial Setup

1. Plug laptop via an ethernet cable into a low-pri port on the router (e.g. the Hue port - avoid the WAN port or the port leading to the AP).
1. Laptop should get a `192.168.1.x/24` address via default DHCP configuration (`watch -c -n0 ip -c a`).
1. Open http://192.168.1.1 and log in with no password.
1. Set the password.
1. Add the laptop's SSH public key to the router. At this point, might be able to get off the floor and connect via wifi from a more comfortable chair.
1. Clone this repo and run:

   ```sh
   $ ./sync.sh --target=ap2 --target-connection-string=root@192.168.1.1 --no-dry-run
   ```

#### Config merging

It's important to consider include new default settings from the files installed on the new version: omitting `compat_version` in a previous update led to me needing to wipe the device more often than necessary. Pay special attention to template files, since the syntax can be a bit confusing.

You can check the original files installed on the sysupgrade image at `/rom/etc/config/`.

## Hex S flash procedure (similar for all Mikrotik devices)

Use the [23.05.0-rc3 initramfs](https://downloads.openwrt.org/releases/23.05.0-rc3/targets/ramips/mt7621/openwrt-23.05.0-rc3-ramips-mt7621-mikrotik_routerboard-760igs-initramfs-kernel.bin) to make sure it fits, then upgrade to a modern version using sysupgrade.

1. Download the initramfs above, and build the sysupgrade image:
   ```sh
   $ nix build .#router
   ```
1. Disable firewall: `sudo systemctl stop firewall`
1. Plug ethernet into the WAN port on the router
1. ```sh
   INTERFACE=enp195s0f3u1
   
   $ sudo ip addr add 192.168.1.10/24 dev "$INTERFACE"

   $ cd /tmp
   $ sudo dnsmasq -i "$INTERFACE" --no-daemon --port=0 --dhcp-range=192.168.1.11,192.168.1.20 --dhcp-boot=$(pwd)/openwrt-23.05.0-rc3-ramips-mt7621-mikrotik_routerboard-760igs-initramfs-kernel.bin --enable-tftp --tftp-root=$(pwd) --bootp-dynamic
   ```
1. Hold the reset button
1. Power on router
1. Keep holding as the SFP/USR light comes on, flashes, goes solid, then turns off.
1. When SFP/USR turns off, release the reset button.
1. Should have had activity from dnsmasq immediately after the light turned off, like;
   ```
   dnsmasq-dhcp: BOOTP(enp195s0f3u1) 192.168.1.17 04:f4:1c:44:12:3e
   ...
   dnsmasq-tftp: sent /tmp/openwrt-23.05.0-rc3-ramips-mt7621-mikrotik_routerboard-760igs-initramfs-kernel.bin to 192.168.1.14
   ```
1. Wait a few mins.
1. Unplug from WAN, plug into a different port, go to http://192.168.1.1
1. Flash sysupgrade image.
1. Re-enable firewall: `sudo systemctl start firewall`
