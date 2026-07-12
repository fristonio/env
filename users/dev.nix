{ pkgsUnstable, ... }:

{
  imports = [
    ./common/config.nix
    ./common/pkgs.nix
    ./common/languages.nix
  ];

  services.podman.enable = true;

  home.packages = with pkgsUnstable; [
    # Tooling
    inetutils
    iproute2
    bridge-utils
    tshark

    tldr

    # Containers stuff
    kind
    kubectl
    kubernetes-helm
  ];
}
