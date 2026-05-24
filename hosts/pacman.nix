{
  config,
  pkgs,
  username,
  ...
}:

{

  imports = [
    ./common/nixos-gui.nix
  ];

  # Use Grub when dual booting and EFI partitions exist on multiple disks.
  # https://nixos.wiki/wiki/Dual_Booting_NixOS_and_Windows#EFI_with_multiple_disks
  boot.tmp.cleanOnBoot = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    device = "nodev";
    efiSupport = true;
    configurationLimit = 3;
  };

  # Enable OpenGL
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    dnsmasq
    qemu
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  users.users.${username} = {
    extraGroups = [
      "docker"
      "vboxusers"
    ];
  };
}
