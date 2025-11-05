{
  global = [{
    # This came as default on hEX S ¯\_(ツ)_/¯
    delay_root = 5;
    # Experimenting with fsck on boot.
    check_fs = 1;
  }];

  mount = [
    {
      # Mount external USB with data required for persistence between installs.
      target = "/external_usb";
      uuid = "896a893d-048f-43cb-8e74-4ca787c0528d";
      enabled = "1";
    }

    {
      # Mount the original overlay device so we can access it if necessary
      target = "/rootfs_data_original";
      device = "mtdblock9";
      enabled = "1";
    }

    {
      # Mount over the overlay with the external SD card.
      target = "/overlay";
      uuid = "7f0f1d6e-04f0-7443-b81a-85665d48f8f4";
      enabled = "1";
    }
  ];
}
