#!/bin/bash

# Fun intro message
echo "-------------------------------------------"
echo "Welcome to the **Arch Linux Installation** script!"
echo "Get ready to rock your system like a true Arch enthusiast 🚀"
echo "-------------------------------------------"
sleep 2

# Set the keyboard layout
echo "Step 1: Keyboard Layout Setup (Optional)"
echo "If you use a US keyboard layout, you can skip this step."
echo "Otherwise, let's choose your layout! 🌍"
read -p "Enter your keyboard layout (e.g., 'la-latin1' for Latin America): " layout

# Apply the layout
if [ ! -z "$layout" ]; then
  loadkeys "$layout"
  echo "Keyboard layout set to $layout. Sweet! 🎹"
else
  echo "US layout detected. Proceeding... ⌨️"
fi
sleep 2

# Verify boot mode (UEFI or BIOS)
echo "Step 2: Let's check if we're in UEFI or BIOS mode 🖥️"
if [ -d /sys/firmware/efi/efivars ]; then
  echo "UEFI mode detected! ✅"
else
  echo "You're in BIOS (legacy) mode. No worries, we'll manage. 💻"
fi
sleep 2

# Connect to the internet (Ethernet or Wi-Fi)
echo "Step 3: Connect to the internet 🌐"
echo "Ethernet? Just plug in the cable!"
echo "Wi-Fi? Let’s connect using iwctl 🧑‍💻"

# Check if you're on Wi-Fi or Ethernet
read -p "Are you using Ethernet or Wi-Fi? (type 'ethernet' or 'wifi'): " network_type
if [ "$network_type" == "ethernet" ]; then
  echo "Ethernet connected. You're ready to go! 🌍"
elif [ "$network_type" == "wifi" ]; then
  echo "Let's find your Wi-Fi network! 🔍"
  iwctl
  sleep 1
  echo "Use 'device list' to see your device."
  echo "Scan for networks with 'station your_device scan'."
  read -p "Enter your Wi-Fi device name (e.g., wlan0): " device
  iwctl station "$device" get-networks
  read -p "Enter your SSID: " ssid
  iwctl station "$device" connect "$ssid"
  echo "Connected to $ssid! 🎉"
else
  echo "You must type 'ethernet' or 'wifi' to proceed."
  exit 1
fi
sleep 2

# Update system clock
echo "Step 4: Synchronizing the system clock ⏰"
timedatectl set-ntp true
sleep 2

# Partition the disks (using cfdisk)
echo "Step 5: Disk Partitioning 🗂️"
echo "Let's partition your disk! You might want to use cfdisk for simplicity."
cfdisk
sleep 2

# Format the partitions
echo "Step 6: Formatting your partitions 🧼"
echo "Let's format the partitions to prepare them for the system!"
echo "First, the root partition..."
read -p "Enter the root partition (e.g., /dev/sda1): " root_partition
mkfs.ext4 "$root_partition"
echo "Root partition formatted! ✔️"

read -p "Enter your home partition (e.g., /dev/sda2) or press Enter to skip: " home_partition
if [ ! -z "$home_partition" ]; then
  mkfs.ext4 "$home_partition"
  echo "Home partition formatted! ✔️"
fi

read -p "Enter your swap partition (e.g., /dev/sda3) or press Enter to skip: " swap_partition
if [ ! -z "$swap_partition" ]; then
  mkswap "$swap_partition"
  swapon "$swap_partition"
  echo "Swap partition enabled! 🔄"
fi

# Mount the file systems
echo "Step 7: Mounting the file systems 📂"
mount "$root_partition" /mnt
echo "Root mounted on /mnt! ✔️"

if [ ! -z "$home_partition" ]; then
  mkdir /mnt/home
  mount "$home_partition" /mnt/home
  echo "Home mounted on /mnt/home! 📂"
fi

# Select the mirrors
echo "Step 8: Let's update your mirrors and choose the best ones 🌍"
reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
echo "Mirrors updated! 🚀"
sleep 2

# Install essential packages
echo "Step 9: Installing essential packages 💻"
pacstrap /mnt base base-devel linux linux-firmware neovim firefox openssh networkmanager
echo "Packages installed! You're almost there! 🎉"
sleep 2

# Generate fstab
echo "Step 10: Generating the fstab file 📝"
genfstab -U /mnt >> /mnt/etc/fstab
echo "fstab generated! 📄"
sleep 2

# Chroot into the new system
echo "Step 11: Chrooting into your new system 🔐"
arch-chroot /mnt
sleep 2

# Set the time zone
echo "Step 12: Setting the time zone ⏳"
read -p "Enter your time zone (e.g., 'America/New_York'): " timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc
echo "Time zone set to $timezone! 🕰️"
sleep 2

# Localization
echo "Step 13: Setting up the localization 🌎"
echo "Uncomment the 'en_US.UTF-8 UTF-8' line in /etc/locale.gen"
nvim /etc/locale.gen
locale-gen
echo "Locale set to en_US.UTF-8! 🌍"
sleep 2

# Set hostname
echo "Step 14: Setting the hostname 💻"
read -p "Enter your hostname (e.g., 'myarch'): " hostname
echo "$hostname" > /etc/hostname
echo "Hostname set to $hostname! 🎉"
sleep 2

# Configure network
echo "Step 15: Configuring the network 🌐"
echo "Adding 127.0.1.1 entry to /etc/hosts"
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts
echo "Network configuration done! 💪"
sleep 2

# Root password
echo "Step 16: Setting the root password 🔒"
passwd
sleep 2

# Install boot loader
echo "Step 17: Installing the bootloader 🖥️"
pacman -S grub efibootmgr os-prober
echo "Installing GRUB bootloader..."

# UEFI installation
echo "Step 18: Installing GRUB for UEFI systems ⚙️"
read -p "Enter your EFI partition (e.g., /dev/sda1): " efi_partition
grub-install --target=x86_64-efi --efi-directory="$efi_partition" --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB installed! 🎉"
sleep 2

# Create user
echo "Step 19: Creating a user 🧑‍💻"
read -p "Enter your username: " username
useradd -m -G wheel,video,audio,storage -s /bin/bash "$username"
passwd "$username"
echo "User $username created! ✔️"
sleep 2

# Enable sudo for the user
echo "Step 20: Giving $username sudo powers 🦸"
pacman -S sudo
echo "$username ALL=(ALL) ALL" >> /etc/sudoers
sleep 2

# Reboot
echo "-------------------------------------------"
echo "Step 21: Rebooting your system 🔄"
echo "You did it! Time to boot into your fresh Arch Linux system!"
echo "-------------------------------------------"
sleep 2
exit
umount -R /mnt
reboot
