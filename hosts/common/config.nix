{ inputs, pkgs, ... }:

{

  fonts.packages = with pkgs; [
    fira-code
    jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  environment.shells = with pkgs; [ bashInteractive ];
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    bash
    tmux
  ];

}
