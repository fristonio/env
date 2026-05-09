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
    # Common GUI packages
    pkgsUnstable.zed-editor
    pkgsUnstable.vscode
    pkgsUnstable.obsidian
  ]
  ++ (lib.optionals isDarwin [
    pkgsUnstable.aerospace
  ])
  ++ (lib.optionals isLinux [
    # Installed through brew for darwin systems.
    pkgsUnstable.ghostty
    # Google chrome installed through homebrew on macos
    pkgs.google-chrome
    pkgs.apple-cursor
  ]);

  home.file = lib.mkIf isDarwin {
    ".aerospace.toml".source = configPath "aerospace.toml";
  };

  home.pointerCursor = lib.mkIf isLinux {
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
