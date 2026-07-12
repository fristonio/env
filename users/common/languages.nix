{ pkgsUnstable, ... }:

{
  home.packages = with pkgsUnstable; [
    # Language parsers
    tree-sitter

    ## C/C++
    (gcc // { meta.priority = 10; }) # cpp provided by gcc conflicts with clang. Assign priority to avoid conflict.
    (clang // { meta.priority = 1; })
    clang-tools
    lldb
    llvm

    ## Rust/Zig
    rustup
    zig
    zls

    ## Python
    python315
    uv
    ty
    ruff

    # Lua
    lua-language-server
    stylua

    ## Go
    go
    (gopls // { meta.priority = 1; }) # Go 'modernize' conflict
    (gotools // { meta.priority = 10; })
    golangci-lint
    golangci-lint-langserver
    delve

    ## Other
    marksman # Markdown
  ];
}
