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
    pkgsUnstable.lima

    pkgs.git
    pkgs.curl
    pkgs.vim
    pkgs.tmux
    pkgs.fzf
    pkgs.tree
    pkgs.watch
    pkgs.gnumake
    pkgs.file

    pkgs.eza
    pkgs.fd
    pkgs.ripgrep
    pkgs.zoxide

    pkgs.helix
    pkgs.nushell

    pkgs.nixfmt
    pkgs.nil
  ];
}
