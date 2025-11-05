{
  system = [
    {
      hostname = "openwrt";
      zonename = "Europe/London";
    }
  ];

  timeserver."ntp" = {
    server = [
      "0.openwrt.pool.ntp.org"
      "1.openwrt.pool.ntp.org"
      "2.openwrt.pool.ntp.org"
      "3.openwrt.pool.ntp.org"
    ];
  };

  # Fibre LED: prevents something weird happening to LED when fibre is used as WAN.
  led."led_sfp" = {
    name = "SFP";
    sysfs = "blue:sfp";
    trigger = "netdev";
    mode = "link tx rx";
    dev = "sfp";
  };
}
