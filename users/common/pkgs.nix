{
  pkgs,
  pkgsUnstable,
  ...
}:

{

  programs = {
    bat.enable = true;
    btop.enable = true;
  };

  home.packages = [
    pkgs.git
    pkgs.curl
    pkgs.vim
    pkgs.tmux
    pkgs.fzf
    pkgs.tree
    pkgs.watch
    pkgs.gnumake
    pkgs.file

    pkgs.jq
    pkgs.yq

    pkgs.eza
    pkgs.fd
    pkgs.ripgrep
    pkgs.zoxide

    pkgs.nixfmt
    pkgs.nil

    pkgsUnstable.lima

    pkgsUnstable.helix
    pkgsUnstable.neovim
    pkgsUnstable.nushell
  ];
}
