{
  pkgs,
  username,
  ...
}:

{
  services.xserver.enable = true;

  # Load nvidia driver for Xorg and wayland
  services.xserver.videoDrivers = [
    "displaylink"
    # "modesetting"
    # "nvidia"
  ];
  systemd.services.dlm.wantedBy = [ "multi-user.target" ];
  services.power-profiles-daemon.enable = true;

  # Enable polkit to let application esclate previliges if required.
  security.polkit.enable = true;

  services.dbus.enable = true;
  users.users.${username}.extraGroups = [
    "video"
    "input"
    "render"
    "tty"
  ];

  # Niri depndencies:
  # Use gnome-keyring as the secret service.
  services.gnome.gnome-keyring.enable = true;

  # Niri is the main gui component.
  # Niri package alraedy enables required xdg portals.
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  # Enable display manager.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Display link setup
  environment.systemPackages = with pkgs; [
    displaylink
    swaybg

    # To run X11 apps on wayland.
    xwayland-satellite
  ];
}
