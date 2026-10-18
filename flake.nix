{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    # Override using
    #   nix build --override-input openwrt-imagebuilder git+file:///home/keith/projects/nix-openwrt-imagebuilder .#...
    # if using a locally-updated hash set.
    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
  };
  outputs =
    {
      self,
      nixpkgs,
      openwrt-imagebuilder,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { };
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python3
          sshfs
          wireshark

          # To have on hand for firmware flashing.
          dnsmasq
          # For DNS generation.
          dnscontrol
        ];
      };
      packages.${system} = import ./images.nix { inherit pkgs openwrt-imagebuilder; };
    };
}
