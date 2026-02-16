{ inputs, pkgs, ... }:

{
  imports = [
    ./common/config.nix
    ./common/pkgs.nix
    ./common/gui-pkgs.nix
  ];
}
