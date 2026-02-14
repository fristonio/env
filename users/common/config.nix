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

  home.file = {
    # Bash is managed by home manager.
    # ".bashrc".source = configPath "bashrc";
    ".vimrc".source = configPath "vimrc";
    ".tmux.conf".source = configPath "tmux.conf";
    ".gitconfig".source = configPath "gitconfig";
  }
  // (

    if isDarwin then
      {
        ".aerospace.toml".source = configPath "aerospace.toml";
      }
    else
      { }

  );

  xdg.enable = true;
  xdg.configFile = {
    "helix" = {
      source = configPath "helix";
      recursive = true;
    };
  }
  // (
    if (gui || isDarwin) then
      {
        "ghostty" = {
          source = configPath "ghostty";
          recursive = true;
        };

        # Zed expects mutable settings, for now do manual copy.
        # "zed" = {
        #   source = configPath "zed";
        #   recursive = true;
        # };
      }
    else
      { }
  );
}
