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

  pkgs = nixpkgs.legacyPackages.${system};
  pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};

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
    inherit pkgsUnstable;

    username = name;
    homeDirectory = userHomeDirectory;
    gui = gui;
  };
}
