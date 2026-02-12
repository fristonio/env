{ inputs, pkgs, username, ... }:

{

  # System level homebrew packages.
  homebrew = {
    enable = true;
    casks  = [
      "ghostty"
      "google-chrome"
    ];
    brews = [];
  };

  programs.bash.enable = true;

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is.
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.bash;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    # Required for some settings like homebrew to know what user to apply to.
    primaryUser = username;
  };
  system.stateVersion = "25.11";
}
