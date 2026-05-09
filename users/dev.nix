{ pkgsUnstable, ... }:

{
  imports = [
    ./common/config.nix
    ./common/pkgs.nix
  ];

  services.podman.enable = true;

  home.packages = with pkgsUnstable; [
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
    (gopls // { meta.priority = 1; }) # Go 'modernize' conflict
    (gotools // { meta.priority = 10; })
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
