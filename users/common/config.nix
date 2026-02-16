{
  pkgs,
  lib,
  username,
  homeDirectory,
  gui,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  configPath = name: lib.path.append ./../../configs name;
in
{

  programs.home-manager.enable = true;

  home = {
    username = username;

    homeDirectory = if isDarwin then "/Users/${homeDirectory}" else "/home/${homeDirectory}";
    stateVersion = "25.11";
  };

  programs.command-not-found.enable = true;
  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ./../../configs/bashrc;
    enableCompletion = false;
    historyFileSize = null;
    historySize = null;
    shellOptions = [ ];
  };

  # Home files rarely change.
  home.file = {
    # Bash is managed by home manager.
    # ".bashrc".source = configPath "bashrc";

    ".vimrc".source = configPath "vimrc";
    ".tmux.conf".source = configPath "tmux.conf";
    ".gitconfig".source = configPath "gitconfig";
  };

  xdg.enable = true;
  xdg.configFile = {
    "helix" = {
      source = configPath "helix";
      recursive = true;
    };
  };
}
