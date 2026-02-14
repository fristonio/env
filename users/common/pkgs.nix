{
  pkgs,
  gui,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{

  home.packages =
    with pkgs;
    [
      git
      curl
      vim
      tmux
      fzf
      tree
      watch
      gnumake
      file

      bat
      btop
      eza
      fd
      ripgrep
      zoxide

      helix

      nixfmt
      nil
    ]
    ++ (lib.optionals gui [
      zed-editor
      vscode
      obsidian
    ])
    ++ (lib.optionals isDarwin [
      aerospace
    ])
    ++ (lib.optionals (isLinux && gui) [
      # Installed through brew for darwin systems.
      ghostty
      # Google chrome installed through homebrew on macos
      google-chrome
    ]);
}
