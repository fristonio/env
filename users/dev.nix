{ pkgs, ... }:

{
  imports = [
    ./common/config.nix
    ./common/pkgs.nix
  ];

  services.podman.enable = true;

  home.packages = with pkgs; [
    # Tooling
    inetutils
    iproute2
    bridge-utils
    tshark

    tldr

    # Languages

    ## C/C++/Rust/Zig
    (gcc // { meta.priority = 1; }) # cpp provided by gcc conflicts with clang. Assign priority to avoid conflict.
    (clang // { meta.priority = 10; })
    clang-tools
    lldb
    llvm

    rustup
    zig
    zls

    ## Python
    python315
    uv
    ty
    ruff

    ## Go
    go
    gopls
    gotools
    golangci-lint
    golangci-lint-langserver
    delve

    ## Other
    marksman # Markdown

    # Containers stuff
    kind
    kubectl
    kubernetes-helm
  ];
}
