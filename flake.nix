{
  description = "Tools to build and flash QMK firmwares using Nix";

  inputs =
    {
      nixpkgsUnstable.url = github:nixos/nixpkgs/nixpkgs-unstable;
      flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/master;
    };

  outputs = { self, nixpkgsUnstable, flake-utils-plus }:
    flake-utils-plus.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgsUnstable {
          inherit system;
        };

        qmk-firmware-default-source = import ./utils/qmk-firmware.nix { inherit pkgs; };

        utils-factory = import ./utils {
          inherit pkgs;
          inherit qmk-firmware-default-source;
        };

      in
      {
        inherit utils-factory;
      }
    );
}
