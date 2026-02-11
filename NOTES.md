# Notes

> Notes...

## NixOS

> Have a test VM or machine ready for setup.
> Download NixOS ISO - https://nixos.org/download/

Boot the machine with NixOS ISO and start the installer.

### Installing NixOS

Configure the partition to install nixos in.

```sh
lsblk

# Find the name of the appropriate device - /dev/vda
# Start the partitioning process
parted /dev/vda

mklabel gpt # Format the partition and create a gpt partition table.
mkpart ESP fat32 1MiB 512MiB # /dev/vda1

set 1 esp on
set 1 boot on

mkpart primary linux-swap 512MiB 8GiB # /dev/vda2
mkpart primary ext4 8GiB 100% # /dev/vda3

print
quit

# Configure the partitions
# Label the partition with appropriate names so its easier to reference
# in nixos hardware-configuration.
mkfs.vfat -F 32 -n boot /dev/vda1
mkswap -L swap /dev/vda2
mkfs.ext4 -L nixos /dev/vda3

# Mount the created partitions
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/vda2

# Install nixos in the mounted partition.
cd /mnt && nixos-install

# Make basic changes to configuration.nix to setup basic things(Install vim).
# NixOS can now be booted to.
```

## Nix Setup

> Setup using flakes

Starter config - https://github.com/Misterio77/nix-starter-configs/tree/main
