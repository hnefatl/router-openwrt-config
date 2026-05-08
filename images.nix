{ pkgs, openwrt-imagebuilder }:
let
  profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };

  base = {
    packages = [
      "bash"
      "vim"
      "curl"

      "avahi-daemon"
    ];
  };

  hex_s_base =
    profiles.identifyProfile "mikrotik_routerboard-760igs"
    // base
    // {
      packages = [
        # Needed for sshfs/scp during recovery
        "openssh-sftp-server"

        # Core packages from the package list at
        # https://firmware-selector.openwrt.org/?version=25.12.2&target=ramips%2Fmt7621&id=mikrotik_routerboard-760igs
        "apk-mbedtls"
        "base-files"
        "ca-bundle"
        "dnsmasq"
        "dropbear"
        "firewall4"
        "fstools"
        "kmod-crypto-hw-eip93"
        "kmod-gpio-button-hotplug"
        "kmod-leds-gpio"
        "kmod-nft-offload"
        "libc"
        "libgcc"
        "libustream-mbedtls"
        "logd"
        "mtd"
        "netifd"
        "nftables"
        "odhcp6c"
        "odhcpd-ipv6only"
        "ppp"
        "ppp-mod-pppoe"
        "procd-ujail"
        "uboot-envtools"
        "uci"
        "uclient-fetch"
        "urandom-seed"
        "urngd"
        "wpad-basic-mbedtls"
        "kmod-usb3"
        "-uboot-envtools"
        "kmod-sfp"
        "-wpad-basic-mbedtls"
        "luci"
        "luci-app-attendedsysupgrade"
      ];
    };
  hap_ac2_base =
    profiles.identifyProfile "mikrotik_hap-ac2"
    // base
    // {
      packages = [
        # Needed for sshfs/scp during recovery
        "openssh-sftp-server"
        # Needed for 802.11k/v band steering for better 5GHz usage
        "usteer"
        "luci-app-usteer"

        # wpad-mbedtls instead of wpad-basic-mbedtls to support usteer
        "wpad-mbedtls"
        "-wpad-basic-mbedtls"

        # https://firmware-selector.openwrt.org/?version=25.12.2&target=ipq40xx%2Fmikrotik&id=mikrotik_hap-ac2
        "apk-mbedtls"
        "ath10k-firmware-qca4019-ct"
        "base-files"
        "ca-bundle"
        "dnsmasq"
        "dropbear"
        "firewall4"
        "fstools"
        "kmod-ath10k-ct"
        "kmod-gpio-button-hotplug"
        "kmod-leds-gpio"
        "kmod-nft-offload"
        "kmod-usb-dwc3"
        "kmod-usb-dwc3-qcom"
        "kmod-usb3"
        "libc"
        "libgcc"
        "libustream-mbedtls"
        "logd"
        "mtd"
        "netifd"
        "nftables"
        "odhcp6c"
        "odhcpd-ipv6only"
        "ppp"
        "ppp-mod-pppoe"
        "procd-ujail"
        "uboot-envtools"
        "uci"
        "uclient-fetch"
        "urandom-seed"
        "urngd"
        "wpad-basic-mbedtls"
        "-kmod-ath10k-ct"
        "kmod-ath10k-ct-smallbuffers"
        "luci"
        "luci-app-attendedsysupgrade"
      ];
    };
in
{
  router = openwrt-imagebuilder.lib.build (
    hex_s_base
    // {
      packages = [
        # Needed for extroot below
        "block-mount"
        "e2fsprogs"
        # sd card
        "kmod-sdhci-mt7620"
        "kmod-fs-ext4"
        # USB stick
        "kmod-fs-f2fs"
        "kmod-usb-storage"
        "kmod-usb-core"
        "kmod-usb-storage"

        # DNS
        "bind-server"
        "bind-tools"
      ];

      # Configure extroot on the ROM via fstab.
      files = pkgs.runCommand "image-files" { } ''
        mkdir -p "$out/etc/uci-defaults"
        cat > $out/etc/uci-defaults/99-symlink-dropbear <<EOF
        touch /etc/config/authorized_keys
        ln -sf /etc/config/authorized_keys /etc/dropbear/authorized_keys

        cat > $out/etc/uci-defaults/99-symlink-bind <<EOF
        mkdir -p /etc/config/bind
        chown -R bind /etc/config/bind
        ln -sf /etc/config/bind /etc/bind

        cat > $out/etc/uci-defaults/99-symlink-avahi <<EOF
        touch /etc/config/avahi
        ln -sf /etc/config/avahi /etc/avahi/avahi-daemon.conf

        mkdir -p $out/etc/config
        cat > $out/etc/config/fstab <<EOF
        config global
            option anon_swap '0'
            option anon_mount '0'
            option auto_swap '1'
            option auto_mount '1'
            option delay_root '5'
            option check_fs '0'

        # Mount external USB with data required for persistence between installs.
        config mount
            option target '/external_usb'
            option uuid '896a893d-048f-43cb-8e74-4ca787c0528d'
            option enabled '1'
            option options 'ro,noexec'

        # Mount the original overlay device so we can access it if necessary
        config mount
            option target '/rootfs_data_original'
            option device 'mtdblock9'
            option enabled '1'

        # Mount over the overlay with the external SD card.
        config mount
            option target '/overlay'
            option uuid '4a3ae55a-84fe-4cca-a1a3-7762fdcc13b9'
            option enabled '1'
        EOF
      '';
    }
  );

  ap2 = openwrt-imagebuilder.lib.build (
    hap_ac2_base
    // {
      files = pkgs.runCommand "image-files" { } ''
        mkdir -p "$out/etc/uci-defaults"
        cat > $out/etc/uci-defaults/99-symlink-dropbear <<EOF
        touch /etc/config/authorized_keys
        ln -sf /etc/config/authorized_keys /etc/dropbear/authorized_keys

        cat > $out/etc/uci-defaults/99-symlink-avahi <<EOF
        touch /etc/config/avahi
        ln -sf /etc/config/avahi /etc/avahi/avahi-daemon.conf
        EOF
      '';
    }
  );

  tvswitch = openwrt-imagebuilder.lib.build (
    hex_s_base
    // {
      files = pkgs.runCommand "image-files" { } ''
        mkdir -p "$out/etc/uci-defaults"
        cat > $out/etc/uci-defaults/99-symlink-dropbear <<EOF
        touch /etc/config/authorized_keys
        ln -sf /etc/config/authorized_keys /etc/dropbear/authorized_keys
        EOF
      '';
    }
  );
}
