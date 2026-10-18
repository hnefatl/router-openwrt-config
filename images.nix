{ pkgs, openwrt-imagebuilder }:
let
  profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };

  base = {
    packages = [
      "bash"
      "vim"
      "curl"

      # Needed for sshfs/scp during recovery
      "openssh-sftp-server"

      # Convenient for debugging
      "tcpdump"
    ];
  };

  hex_s_base =
    profiles.identifyProfile "mikrotik_routerboard-760igs"
    // base
    // {
      packages = base.packages ++ [
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
      packages = base.packages ++ [
        # wpad-mbedtls instead of wpad-basic-mbedtls to support usteer
        "wpad-mbedtls"
        "-wpad-basic-mbedtls"

        # Simple mDNS without reflector support.
        "umdns"

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
      packages = hex_s_base.packages ++ [
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

        # mDNS with reflector support.
        "avahi-daemon"
        "avahi-utils"

        # Wireguard
        "luci-proto-wireguard"
        "qrencode"

        # Home assistant
        "luci-mod-rpc"
      ];

      # Configure extroot on the ROM via fstab.
      files = pkgs.runCommand "image-files" { } ''
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
      packages = hap_ac2_base.packages ++ [
        # Needed for 802.11k/v band steering between 2.4/5GHz.
        "usteer"
        "luci-app-usteer"
      ];
    }
  );

  tvswitch = openwrt-imagebuilder.lib.build hap_ac2_base;
}
