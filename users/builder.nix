{
  inputs,
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
  hunk,
  catppuccin,
  ...
}:

name:
{
  system,
  gui ? false,
  userConfigAlias ? "",
  homeDirectory ? "",
}:

let

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  pkgsUnstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  hunk = inputs.hunk.packages.${pkgsUnstable.stdenv.hostPlatform.system}.hunk;

  userConfig = if userConfigAlias == "" then ./${name}.nix else ./${userConfigAlias}.nix;
  userHomeDirectory = if homeDirectory == "" then name else homeDirectory;

in

home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  modules = [
    userConfig

    catppuccin.homeModules.catppuccin
    {
      catppuccin.enable = true;
      catppuccin.flavor = "frappe";
    }
  ];

  extraSpecialArgs = {
    inherit pkgs pkgsUnstable hunk;

    username = name;
    homeDirectory = userHomeDirectory;
    gui = gui;
  };
}
