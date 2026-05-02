{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
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
        ];
      };
    };
}
