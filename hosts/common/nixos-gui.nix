{config, pkgs, username, ...}:

{
  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and wayland
  services.xserver.videoDrivers = ["displaylink" "nvidia" "modesetting"];
  services.power-profiles-daemon.enable = true;

  # Enable polkit to let application esclate previliges if required.
  security.polkit.enable = true;

  services.dbus.enable = true;
  users.users.${username}.extraGroups = [ "video" "input" ];

  # Niri depndencies:
  # Use gnome-keyring as the secret service.
  services.gnome.gnome-keyring.enable = true;

  # Niri is the main gui component.
  programs.niri.enable = true;

  # Display link setup
  environment.systemPackages = with pkgs; [
    displaylink
    swaybg

    # To run X11 apps on wayland.
    xwayland-satellite
  ];
}
