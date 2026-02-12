{ inputs, pkgs, gui, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{

  home.packages = with pkgs; [
    git
    curl
    vim
    tmux
    bat
    btop
    eza
    fd
    ripgrep
    fzf
    tree
    watch
    helix
  ] ++ (lib.optionals gui [
    zed-editor
  ]) ++ (lib.optionals isDarwin [
    aerospace
  ]) ++ (lib.optionals (isLinux && gui) [
    # Installed through brew
    ghostty
    # Google chrome installed through homebrew on macos
    google-chrome
  ]);
}
