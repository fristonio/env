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

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

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

  users.users.${username} = {
    extraGroups = [
      "docker"
      "vboxusers"
    ];
  };
}
