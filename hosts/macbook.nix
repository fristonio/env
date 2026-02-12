{ config, pkgs, ... }:

{
  nix = {
    # Using nix from determinate systems installer which manages nix.
    enable = false;

    # Enable the Linux builder so we can run Linux builds on our Mac.
    # This can be debugged by running `sudo ssh linux-builder`
    linux-builder = {
      enable = false; # Disabled by default
      ephemeral = true;
      maxJobs = 4;
      config = ({ pkgs, ... }: {
        # Make our builder beefier since we're on a beefy machine.
        virtualisation = {
          cores = 4;
          darwin-builder = {
            diskSize = 64 * 1024; # 100GB
            memorySize = 8 * 1024; # 32GB
          };
        };

        environment.systemPackages = [
          pkgs.btop
        ];
      });
    };
  };
}
