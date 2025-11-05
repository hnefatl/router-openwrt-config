{
  openwrt.router = {
    deploy.host = "10.20.0.1";

    # Use the default system files for these, don't overwrite.
    # They don't have anything particularly interesting, can just be updated with OS updates.
    uci.retain = [
      "luci"
      "rpcd"
      "ucitrack"
      # TODO: delete once network is implemented.
      "network"
      # TODO: delete
      #"adguardhome"
    ];

    uci.settings = {
      system = import ./config/system.nix;

      # TODO: figure out how to express.
      #adguardhome = import ./config/adguardhome.nix;
      dhcp = import ./config/dhcp.nix;
      dropbear = import ./config/dropbear.nix;
      firewall = import ./config/firewall.nix;
      fstab = import ./config/fstab.nix;
      # TODO: port, figure out secrets.
      # network = import ./config/network.nix;
      uhttpd = import ./config/uhttpd.nix;
    };

    # TODO: fill from main nixos-config.
    # And maybe try to move this into the dropbear config file.
    etc."dropbear/authorized_keys".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ46ZX6zJQrMOdffEZqJk5bbgZpTnaExEprMDS9aQUpa keith@laptop
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVXUPyteZDsBXLsiFSVpW8Qr9qXi4wY7NkEQLeADAim keith@desktop
    '';

    packages = [
      "bash"
      "openssh-sftp-server"
      "iperf"
      "vim"
      "diffutils"

      # For dynamic DNS
      "ddns-scripts"
      "luci-app-ddns"
      "wget-ssl"
      "ca-certificates"
      "drill"

      "luci-proto-wireguard"
      "luci-app-wireguard"
      "qrencode"

      "kmod-usb-storage"
      "usbutils"
      "f2fs-tools"
      "kmod-fs-f2fs"

      # For home assistant
      "luci-mod-rpc"

      # For SD card drivers
      "kmod-sdhci-mt7620"
      # For mounting SD card as an extroot storage expansion
      "block-mount"
      "kmod-fs-ext4"
      "e2fsprogs"
      "parted"

      "adguardhome"
    ];
  };
}
