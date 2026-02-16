{
  pkgs,
  ...
}:

{

  programs = {
    bat.enable = true;
    btop.enable = true;

    nushell.enable = true;
  };

  home.packages = with pkgs; [
    git
    curl
    vim
    tmux
    fzf
    tree
    watch
    gnumake
    file

    eza
    fd
    ripgrep
    zoxide

    helix

    nixfmt
    nil
  ];
}
