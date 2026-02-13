{
  inputs,
  nixpkgs,
  catppuccin,
  ...
}:

name:
{
  system,
  user,
  darwin ? false,
  gui ? false,
  userConfigAlias ? "",
}:

let
  # Based on the input system determine the function to use.
  nix-system = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;

  hardwareConfig = ./hardware/${name}.nix;
  machineConfig = ./${name}.nix;

  hostConfig = ./common/${if darwin then "darwin" else "nixos"}.nix;
  commonConfig = ./common/config.nix;
  userConfig =
    if userConfigAlias == "" then ../users/${user}.nix else ../users/${userConfigAlias}.nix;

  catppuccinConfig = {
    catppuccin.enable = true;
    catppuccin.flavor = "frappe";
  };

in
nix-system rec {

  inherit system;

  modules = [
    # Allow unfree packages.
    { nixpkgs.config.allowUnfree = true; }

    # For darwin systems hardware is not managed by nix.
  ]
  ++ (nixpkgs.lib.optionals (!darwin) [
    hardwareConfig
  ])
  ++ [

    machineConfig
    hostConfig
    commonConfig

    # catppuccin nix flake doesn't support nix-darwin.
  ]
  ++ (nixpkgs.lib.optionals (!darwin) [
    catppuccin.nixosModules.catppuccin
    catppuccinConfig
  ])
  ++ [

    # If setting up the host manage home-manager directly for OS.
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";

      home-manager.users.${user} = {
        imports = [
          userConfig
          catppuccin.homeModules.catppuccin
          catppuccinConfig
        ];
      };

      home-manager.extraSpecialArgs = {
        username = user;
        homeDirectory = user;
        gui = (gui || darwin);
      };
    }
  ];

  specialArgs = {
    system = system;
    hostname = name;
    username = user;
  };

}
