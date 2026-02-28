{ pkgs, inputs, ... }:

{

  environment.localBinInPath = true;

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "0";
    efi.canTouchEfiVariables = true;
  };

}
