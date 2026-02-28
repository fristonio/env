{
  description = "Nix flake to manage environments and configurations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix/release-25.11";
    niri-flake.url = "github:sodiboo/niri-flake";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      darwin,
      catppuccin,
      niri-flake,
      ...
    }@inputs:
    let
      hostBuilder = import ./hosts/builder.nix {
        inherit
          inputs
          nixpkgs
          nixpkgs-unstable
          catppuccin
          niri-flake
          ;
      };

      userBuilder = import ./users/builder.nix {
        inherit
          inputs
          nixpkgs
          nixpkgs-unstable
          home-manager
          catppuccin
          ;
      };

    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#<hostname>'
      nixosConfigurations = {
        vm-aarch64 = hostBuilder "vm" {
          system = "aarch64-linux";
          user = "fristonio";
        };

        pacman = hostBuilder "pacman" {
          system = "x86_64-linux";
          user = "fristonio";
        };
      };

      # For first time configuration on darwin systems.
      # nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch
      #
      # Once instantiated darwin-rebuild can be used to activate the configuration.
      # darwin-rebuild switch --flake .#macbook
      darwinConfigurations = {
        macbook = hostBuilder "macbook" {
          system = "aarch64-darwin";
          user = "deepeshpathak";
          darwin = true;

          userConfigAlias = "fristonio";
        };
      };

      # Available through 'home-manager --flake .#<username>'
      homeConfigurations = {
        lima-vm-aarch64 = userBuilder "lima" {
          system = "aarch64-linux";
          userConfigAlias = "dev";
        };

        lima-vm-x86_64 = userBuilder "lima" {
          system = "x86_64-linux";
          userConfigAlias = "dev";
        };

        macbook-lima-vm = userBuilder "deepeshpathak" {
          system = "aarch64-linux";
          userConfigAlias = "dev";
          homeDirectory = "deepeshpathak.linux";
        };
      };
    };
}
