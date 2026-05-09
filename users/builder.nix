{
  inputs,
  nixpkgs,
  nixpkgs-unstable,
  home-manager,
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
    inherit pkgs pkgsUnstable;

    username = name;
    homeDirectory = userHomeDirectory;
    gui = gui;
  };
}
