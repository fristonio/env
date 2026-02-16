{
  pkgs,
  hostname,
  username,
  ...
}:

{

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  # Convert keyboard mappings
  services.xserver.xkb.options = "caps:escape";
  console.useXkbConfig = true;

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    firewall.enable = false;
  };

  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  time.hardwareClockInLocalTime = true;
  time.timeZone = "America/Vancouver";

  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      emoji = [ "JetBrainsMono Nerd Font" ];
    };
  };
  fonts.fontDir.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3Howq3i0T0GG6Oet3HZA6N2C4b+28XLdIwcxuXovj1 fristonio-dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcItiU3ilEF/1eo5TsZ1G91PZpbcqbZZKUqDLOk5gHM fristonio-work"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  system.stateVersion = "25.11";
}
