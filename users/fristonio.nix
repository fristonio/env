{ inputs, pkgs, username, ... }:

let

  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

in {

  programs = {
    home-manager.enable = true;
  };

  home = {
    username = username;

    homeDirectory = if isDarwin
      then "/Users/${username}"
      else "/home/${username}";

    stateVersion = "25.11";
  };

}
