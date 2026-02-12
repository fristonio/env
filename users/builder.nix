{ inputs, nixpkgs, home-manager, catppuccin, ... }:

name: {
  system,
  gui ? false,
  userConfigAlias ? "",
}:

let

  pkgs = nixpkgs.legacyPackages.${system};

  userConfig = if userConfigAlias == ""
    then ./${name}.nix
    else ./${userConfigAlias}.nix;

in home-manager.lib.homeManagerConfigurations {
  inherit pkgs;

  modules = [
    userConfig

    catppuccin.homeModules.catppuccin {
      catppuccin.enable = true;
      catppuccin.flavor = "frappe";
    }
  ];

  extraSpecialArgs = {
    username = name;
    gui = gui;
  };
}
