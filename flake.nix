{
  description = "Nix flake to manage environments and configurations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix/release-25.11";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    darwin,
    catppuccin,
    ...
  } @ inputs:
  let
    hostBuilder = import ./hosts/builder.nix {
      inherit inputs nixpkgs catppuccin;
    };

    userBuilder = import ./users/builder.nix {
      inherit inputs nixpkgs home-manager catppuccin;
    };

  in {
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

    darwinConfigurations = {
      macbook = hostBuilder "macbook" {
        system = "aarch64-darwin";
        user   = "deepeshpathak";
        darwin = true;

        userConfigAlias = "fristonio";
      };

      macbook-work = hostBuilder "macbook" {
        system = "aarch64-darwin";
        user   = "dpathak";
        darwin = true;

        userConfigAlias = "fristonio";
      };
    };

    # Available through 'home-manager --flake .#<username>'
    homeConfigurations = {
      firstonio = userBuilder "fristonio" {
        system = "aarch64-linux";
      };
    };
  };
}
