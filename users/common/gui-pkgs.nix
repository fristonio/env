{
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  configPath = name: lib.path.append ./../../configs name;
in
{

  programs = lib.mkIf isLinux {
    waybar.enable = true;

    fuzzel.enable = true;
    wleave.enable = true;
    firefox.enable = true;
  };

  services = lib.mkIf isLinux {
    mako.enable = true;
  };

  home.packages =
    with pkgs;
    [
      zed-editor
      vscode
      obsidian
    ]
    ++ (lib.optionals isDarwin [
      aerospace
    ])
    ++ (lib.optionals isLinux [
      # Installed through brew for darwin systems.
      ghostty
      # Google chrome installed through homebrew on macos
      google-chrome
    ]);

  home.file = lib.mkIf isDarwin {
    "aerospace.toml".source = configPath "aerospace.toml";
  };

  xdg.configFile = {
    # "ghostty" = {
    #   "source" = configPath "ghostty";
    #   recursive = true;
    # };

    # Zed expects mutable settings, for now do manual copy.
    # "zed" = {
    #   source = configPath "zed";
    #   recursive = true;
    # };
  };
}
