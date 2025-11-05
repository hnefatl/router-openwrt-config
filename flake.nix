{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    dewclaw.url = "github:MakiseKurisu/dewclaw";
  };
  outputs =
    {
      self,
      nixpkgs,
      dewclaw,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      doDeploy =
        name: path:
        let
          p = pkgs.callPackage dewclaw {
            configuration = import path;
          };
        in
        pkgs.writeShellApplication {
          inherit name;
          text = "${p}/bin/deploy-${name}";
        };
    in
    {
      formatter."${system}" = pkgs.nixfmt-tree;
      packages."${system}" = {
        router = doDeploy "router" ./router.nix;
      };
    };
}
