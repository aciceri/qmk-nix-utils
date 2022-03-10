{ pkgs }:
let
  attrs = builtins.fromJSON (builtins.readFile ./qmk-firmware.json);
in
pkgs.fetchFromGitHub {
  owner = attrs.owner;
  repo = attrs.repo;
  rev = attrs.rev;
  sha256 = attrs.sha256;
  fetchSubmodules = true;
}
