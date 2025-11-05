{
  defaults = [{
    input = "ACCEPT";
    output = "ACCEPT";
    forward = "REJECT";
    synflood_protect = 1;
    flow_offloading = 1;
    flow_offloading_hw = 1;
  }];

  forwarding = [{
    src = "lan";
    dest = "wan";
  }];

  zones = {
    "lan" = {
      name = "lan";
      input = "ACCEPT";
      output = "ACCEPT";
      forward = "ACCEPT";
      network = [
        "lan"
        "wg0"
      ];
    };
    "wan" = {
      name = "wan";
      input = "REJECT";
      output = "ACCEPT";
      forward = "REJECT";
      masq = 1;
      mtu_fix = 1;
      network = [
        "wan"
        "wan6"
      ];
    };
  };

  rule = [
    {
      name = "Allow-WireGuard";
      target = "ACCEPT";
      src = "wan";
      dest_port = "5746";
      proto = "udp";
    }
    {
      name = "Block-TV-Internet";
      src = "lan";
      dest = "wan";
      target = "REJECT";
      src_ip = [ "10.20.2.6" ];
      proto = [
        "tcp"
        "udp"
      ];
    }
    # IPv6 rules, not currently used
    #{
    #  name = "Server-HTTP";
    #  target = "ACCEPT";
    #  src = "wan";
    #  dest = "lan";
    #  dest_ip = "2a02:169:5bef:0:82ee:73ff:fed9:2390";
    #  dest_port = "80";
    #}
    #{
    #  name = "Server-HTTPS";
    #  target = "ACCEPT";
    #  src = "wan";
    #  dest = "lan";
    #  dest_ip = "2a02:169:5bef:0:82ee:73ff:fed9:2390";
    #  dest_port = "443";
    #}

    {
      name = "Allow-DHCP-Renew";
      target = "ACCEPT";
      src = "wan";
      proto = "udp";
      dest_port = "68";
      family = "ipv4";
    }
    {
      name = "Allow-Ping";
      target = "ACCEPT";
      src = "wan";
      proto = "icmp";
      icmp_type = "echo-request";
      family = "ipv4";
    }
    {
      name = "Allow-IGMP";
      target = "ACCEPT";
      src = "wan";
      proto = "igmp";
      family = "ipv4";
    }
    {
      name = "Allow-DHCPv6";
      target = "ACCEPT";
      src = "wan";
      proto = "udp";
      src_ip = "fc00::/6";
      dest_ip = "fc00::/6";
      dest_port = "546";
      family = "ipv6";
    }
    {
      name = "Allow-MLD";
      target = "ACCEPT";
      src = "wan";
      proto = "icmp";
      src_ip = "fe80::/10";
      family = "ipv6";

      icmp_type = [
        "130/0"
        "131/0"
        "132/0"
        "143/0"
      ];
    }
    {
      name = "Allow-ICMPv6-Input";
      target = "ACCEPT";
      src = "wan";
      proto = "icmp";
      limit = "1000/sec";
      family = "ipv6";

      icmp_type = [
        "echo-request"
        "echo-reply"
        "destination-unreachable"
        "packet-too-big"
        "time-exceeded"
        "bad-header"
        "unknown-header-type"
        "router-solicitation"
        "neighbour-solicitation"
        "router-advertisement"
        "neighbour-advertisement"
      ];
    }
    {
      name = "Allow-ICMPv6-Forward";
      target = "ACCEPT";
      src = "wan";
      dest = "*";
      proto = "icmp";
      limit = "1000/sec";
      family = "ipv6";

      icmp_type = [
        "echo-request"
        "echo-reply"
        "destination-unreachable"
        "packet-too-big"
        "time-exceeded"
        "bad-header"
        "unknown-header-type"
      ];
    }
    {
      name = "Allow-IPSec-ESP";
      target = "ACCEPT";
      src = "wan";
      dest = "lan";
      proto = "esp";
    }
    {
      name = "Allow-ISAKMP";
      src = "wan";
      dest = "lan";
      dest_port = "500";
      proto = "udp";
      target = "ACCEPT";
    }
  ];

  # Port-forwards.
  redirect = [
    # Server reverse proxy.
    {
      name = "http";
      target = "DNAT";
      src = "wan";
      src_dport = "80";
      dest = "lan";
      dest_port = "80";
      dest_ip = "10.20.1.3";
    }
    {
      name = "https";
      target = "DNAT";
      src = "wan";
      src_dport = "443";
      dest = "lan";
      dest_port = "443";
      dest_ip = "10.20.1.3";
    }

    # Needed for the central plex server to find mine.
    {
      name = "plex";
      target = "DNAT";
      src = "wan";
      src_dport = "32400";
      dest = "lan";
      dest_ip = "10.20.1.3";
      dest_port = "32400";
    }

    {
      name = "external dns";
      target = "DNAT";
      src = "wan";
      src_dport = "53";
      dest = "lan";
      dest_port = "1273";
      dest_ip = "10.20.1.3";
    }
  ];
}
