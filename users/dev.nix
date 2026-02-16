{ pkgs, ... }:

{
  imports = [
    ./common/config.nix
    ./common/pkgs.nix
  ];

  home.packages = with pkgs; [
    # devenv to manage development environments.
    devenv

    # Languages
    llvmPackages_20
    go
    gotools
    shellcheck
    python315

    # Tools
    tldr
  ];
}
