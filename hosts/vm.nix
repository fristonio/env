{ pkgs, inputs, ... }:

{

  environment.localBinInPath = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "0";
    efi.canTouchEfiVariables = true;
  };

}
