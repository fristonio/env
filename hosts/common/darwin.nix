{ inputs, pkgs, username, ... }:

{
  homebrew = {
    enable = true;
    casks  = [
      "google-chrome"
      "slack"
      "spotify"
    ];

    brews = [];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is.
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.bash;
  };

  # Required for some settings like homebrew to know what user to apply to.
  system.primaryUser = username;
  system.stateVersion = "25.11";
}
