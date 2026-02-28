{
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  configPath = name: lib.path.append ./../../configs name;
in
{

  programs = lib.mkIf isLinux {
    fuzzel.enable = true;
    firefox.enable = true;
  };

  home.packages = [
    pkgs.zed-editor
    pkgs.vscode
    pkgs.obsidian
  ]
  ++ (lib.optionals isDarwin [
    pkgs.aerospace
  ])
  ++ (lib.optionals isLinux [
    pkgs.apple-cursor
    # Installed through brew for darwin systems.
    pkgs.ghostty
    # Google chrome installed through homebrew on macos
    pkgs.google-chrome
  ]);

  home.file = lib.mkIf isDarwin {
    "aerospace.toml".source = configPath "aerospace.toml";
  };

  home.pointerCursor = {
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
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
