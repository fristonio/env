{ inputs, pkgs, ... }:

{

  environment.shells = with pkgs; [ bashInteractive ];
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    bash
    tmux
    helix
    ripgrep
    yazi
    fd
    jq
    fzf
  ];

}
