# 10.20.0.0/24     networking gear:
#            1        router, static IP since runs DHCP
#            2        access point for untrusted network
#            3        access point for SSID network
# 10.20.1.0/24     statically configured things:
#            3        warthog (physical server)
#            4        printer (HP 5010 keeps trying to use 192.168.1.x/24)
#            5        pikvm
#            6        server cpu
#            7        octoprint
# 10.20.2.0/24     DHCP reservations (e.g. hoover, smart light hub) which use
#                    DHCP but are given fixed addresses
#            5     PC
#            6     physical TV
#            13    NVIDIA Shield
# 10.20.3.0/24     open season, DHCP dynamic assignment space
# 10.20.4.0/24     docker
#
# 10.21.0.0/24     VPN devices.
#
#
# DNS routing goes:
#  dnsmasq (router#53) -> adguard (router#54) -> bind9 (warthog#1273)

{
  # Adguard is used as the primary DNS resolver, dnsmasq is used as a fallback once adguard has filtered out ads.
  #dnsmasq = {
  #  port = 53;
  #  # Allow PTR requests
  #  noresolv = 0;
  #  localise_queries = 1;
  #  rebind_protection = 0;
  #  domain = "lan";
  #  expandhosts = 1;
  #  authoritative = 1;
  #  leasefile = "/tmp/dhcp.leases";
  #  resolvfile = "/tmp/resolv.conf.d/resolv.conf.auto";
  #  localservice = 1;
  #  ednspacket_max = 1232;
  #  server = [ "10.20.0.1#54" ];

  #  # Redirect internally hosted sites to the router"s internal interface directly, to
  #  # avoid resolving the sites as the router"s external IP, causing internal clients to
  #  # show up as external IPs when connecting over e.g. VPN.
  #  # TODO: this causes https:// to fail since the certs aren"t valid for local IPs :(
  #  # unsure how to fix this properly, VPN remains broken until then.
  #  #list address "/keithdns.collister.xyz/10.20.0.1"
  #  #list address "/warthog.keith.collister.xyz/10.20.0.1"
  #  # Some manual redirections. There"s no point redirecting to a reverse proxy
  #  # for these, since they"re probably accessed when the server is down or unhealthy.
  #  address = [
  #    "/pikvm.warthog.keith.collister.xyz/10.20.1.5"
  #    "/servercpu.warthog.keith.collister.xyz/10.20.1.6"
  #  ];
  #};

  dhcp = {
    "lan" = {
      interface = "lan";
      start = 770;
      limit = 253;
      # Some hosts have lower lease times (to detect DHCP misconfigurations
      # faster), but keep the default high so that in the event of a breakage,
      # things keep working for 12h.
      leasetime = "12h";
      dhcpv4 = "server";
      ra_flags = [ "none" ];
      dhcp_option = [
        # Default router/last resort gateway is this device.
        "3,10.20.0.1"
        # DNS is this device.
        "6,10.20.0.1"
      ];
    };
    "wan" = {
      interface = "wan";
      ignore = 1;
    };
  };

  odhcpd."odhcpd" = {
    maindhcp = 0;
    leasefile = "/tmp/hosts/odhcpd";
    leasetrigger = "/usr/sbin/odhcpd-update";
    loglevel = 4;
  };

  boot."linux" = {
    filename = "netboot.xyz.efi";
    serveraddress = "10.20.1.3";
    servername = "warthog";
  };

  host = [
    {
      name = "hoover";
      mac = "50:EC:50:03:26:D9";
      ip = "10.20.2.10";
    }
    {
      name = "phillips-bridge";
      mac = "EC:B5:FA:80:77:5F";
      ip = "10.20.2.11";
      # Detect DHCP misconfigs quickly. Lights not turning on isn"t the end of
      # the world, but very obvious to know something needs fixing.
      leasetime = "10m";
    }
    {
      name = "work-laptop";
      mac = "88:d8:2e:54:5a:1a";
      ip = "10.20.2.12";
    }
    {
      name = "shield";
      # Wifi + ethernet
      mac = "48:B0:2D:59:CF:A5 48:B0:2D:59:CF:A7";
      ip = "10.20.2.13";
    }
    {
      name = "pc";
      mac = "A8:5E:45:11:03:D8";
      ip = "10.20.2.5";
    }
    {
      name = "lg-tv";
      mac = "20:28:BC:14:12:8E";
      ip = "10.20.2.6";
    }
    {
      name = "esp32-bluetooth-proxy";
      mac = "C8:F0:9E:35:85:F4";
      ip = "10.20.5.2";
    }
    {
      name = "pikvm";
      mac = "DC:A6:32:50:9D:3A";
      ip = "10.20.1.5";
    }
    {
      name = "servercpu";
      mac = "00:30:59:28:D0:00";
      ip = "10.20.1.6";
    }
    {
      oname = "octoprint";
      # Ethernet + Wifi
      mac = "D8:3A:DD:58:45:CD D8:3A:DD:58:45:CE";
      ip = "10.20.1.7";
    }
    {
      name = "nintendo-switch";
      # Wifi + ethernet
      mac = "DC:CD:18:5B:D9:50 20:1C:3A:BF:89:8C";
      ip = "10.20.1.9";
    }
  ];
}
