#!/bin/bash

set -e  # Exit if any command fails

# === User Input ===
echo "=============================="
echo "     Arch Linux Installer     "
echo "=============================="

# Ask for the disk to install Arch
lsblk
read -p "Enter the disk to install Arch (e.g., /dev/sda, /dev/nvme0n1): " DISK

# Verify disk exists
if [ ! -b "$DISK" ]; then
    echo "[-] Error: Disk $DISK does not exist."
    exit 1
fi

# Ask for hostname
read -p "Enter a hostname for this machine: " HOSTNAME

# Ask for username
read -p "Enter the new username: " USERNAME

# Ask for user password
read -sp "Enter password for $USERNAME: " PASSWORD
echo
read -sp "Confirm password: " PASSWORD_CONFIRM
echo
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "[-] Error: Passwords do not match!"
    exit 1
fi

# Ask for timezone
echo "Available timezones can be found in /usr/share/zoneinfo/"
read -p "Enter your timezone (e.g., America/New_York): " TIMEZONE

# Ask for locale
read -p "Enter system locale (default: en_US.UTF-8): " LOCALE
LOCALE=${LOCALE:-"en_US.UTF-8"}

# Ask for keyboard layout
read -p "Enter keyboard layout (default: us): " KEYMAP
KEYMAP=${KEYMAP:-"us"}

# === Set Keyboard Layout ===
echo "[+] Setting Keyboard Layout: $KEYMAP"
loadkeys $KEYMAP

# === Verify Boot Mode ===
if [ -d "/sys/firmware/efi/efivars" ]; then
    echo "[+] UEFI mode detected."
else
    echo "[-] Not in UEFI mode. Please boot in UEFI."
    exit 1
fi

# === Connect to the Internet ===
echo "[+] Checking Internet Connection..."
ping -c 3 archlinux.org || echo "Warning: No internet connection detected!"

# === Update System Clock ===
echo "[+] Syncing system clock..."
timedatectl set-ntp true

# === Partitioning the Disk ===
echo "[+] Partitioning $DISK"
sgdisk -Z $DISK  # Wipe all partitions
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" $DISK  # EFI Partition
sgdisk -n 2:0:+8G -t 2:8200 -c 2:"Swap" $DISK  # Swap Partition
sgdisk -n 3:0:+40G -t 3:8300 -c 3:"Root" $DISK  # Root Partition
sgdisk -n 4:0:0 -t 4:8300 -c 4:"Home" $DISK  # Home Partition

# === Formatting Partitions ===
echo "[+] Formatting Partitions..."
mkfs.fat -F32 "${DISK}1"
mkswap "${DISK}2" && swapon "${DISK}2"
mkfs.ext4 "${DISK}3"
mkfs.ext4 "${DISK}4"

# === Mounting File Systems ===
echo "[+] Mounting Partitions..."
mount "${DISK}3" /mnt
mkdir -p /mnt/efi /mnt/home
mount "${DISK}1" /mnt/efi
mount "${DISK}4" /mnt/home

# === Select Mirrors ===
echo "[+] Updating Mirror List..."
reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# === Installing Essential Packages ===
echo "[+] Installing Base System..."
pacstrap /mnt base base-devel linux linux-firmware neovim firefox openssh networkmanager

# === Generating fstab ===
echo "[+] Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# === Configuring the System ===
echo "[+] Configuring System..."
arch-chroot /mnt /bin/bash <<EOF
# Set Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localization
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Set Hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME" >> /etc/hosts

# Set Root Password
echo "root:$PASSWORD" | chpasswd

# Create User
useradd -m -G wheel,video,audio,storage -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Enable Services
systemctl enable NetworkManager

# Install Bootloader
echo "[+] Installing Bootloader..."
pacman -Sy --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# === Finish Installation ===
echo "[+] Installation Complete. Unmounting and Rebooting..."
umount -R /mnt
reboot
