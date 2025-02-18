#!/bin/bash

# Definir colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Fun intro message with colors
echo -e "${CYAN}-------------------------------------------"
echo -e "${GREEN}Welcome to the ${MAGENTA}Arch Linux Installation ${GREEN}script!"
echo -e "${CYAN}Get ready to rock your system like a true Arch enthusiast 🚀"
echo -e "${CYAN}-------------------------------------------${RESET}"
sleep 2

# Set the keyboard layout
echo -e "${YELLOW}Step 1: Keyboard Layout Setup (Optional)${RESET}"
echo -e "If you use a ${BLUE}US${RESET} keyboard layout, you can skip this step."
echo -e "Otherwise, let's choose your layout! 🌍"
read -p "Enter your keyboard layout (e.g., 'la-latin1' for Latin America): " layout

# Apply the layout
if [ ! -z "$layout" ]; then
  loadkeys "$layout"
  echo -e "${GREEN}Keyboard layout set to $layout. Sweet! 🎹${RESET}"
else
  echo -e "${GREEN}US layout detected. Proceeding... ⌨️${RESET}"
fi
sleep 2

# Verify boot mode (UEFI or BIOS)
echo -e "${YELLOW}Step 2: Let's check if we're in UEFI or BIOS mode 🖥️${RESET}"
if [ -d /sys/firmware/efi/efivars ]; then
  echo -e "${GREEN}UEFI mode detected! ✅${RESET}"
else
  echo -e "${RED}You're in BIOS (legacy) mode. No worries, we'll manage. 💻${RESET}"
fi
sleep 2

# Connect to the internet (Ethernet or Wi-Fi)
echo -e "${YELLOW}Step 3: Connect to the internet 🌐${RESET}"
echo -e "Ethernet? Just plug in the cable!"
echo -e "Wi-Fi? Let’s connect using iwctl 🧑‍💻"

# Check if you're on Wi-Fi or Ethernet
read -p "Are you using Ethernet or Wi-Fi? (type 'ethernet' or 'wifi'): " network_type
if [ "$network_type" == "ethernet" ]; then
  echo -e "${GREEN}Ethernet connected. You're ready to go! 🌍${RESET}"
elif [ "$network_type" == "wifi" ]; then
  echo -e "${CYAN}Let's find your Wi-Fi network! 🔍${RESET}"
  iwctl
  sleep 1
  echo -e "${YELLOW}Use 'device list' to see your device.${RESET}"
  echo -e "${YELLOW}Scan for networks with 'station your_device scan'.${RESET}"
  read -p "Enter your Wi-Fi device name (e.g., wlan0): " device
  iwctl station "$device" get-networks
  read -p "Enter your SSID: " ssid
  iwctl station "$device" connect "$ssid"
  echo -e "${GREEN}Connected to $ssid! 🎉${RESET}"
else
  echo -e "${RED}You must type 'ethernet' or 'wifi' to proceed.${RESET}"
  exit 1
fi
sleep 2

# Update system clock
echo -e "${YELLOW}Step 4: Synchronizing the system clock ⏰${RESET}"
timedatectl set-ntp true
sleep 2

# Partition the disks (using cfdisk)
echo -e "${YELLOW}Step 5: Disk Partitioning 🗂️${RESET}"
echo -e "Let's partition your disk! You might want to use ${MAGENTA}cfdisk${RESET} for simplicity."
cfdisk
sleep 2

# Format the partitions
echo -e "${YELLOW}Step 6: Formatting your partitions 🧼${RESET}"
echo -e "Let's format the partitions to prepare them for the system!"
echo -e "First, the root partition..."
read -p "Enter the root partition (e.g., /dev/sda1): " root_partition
mkfs.ext4 "$root_partition"
echo -e "${GREEN}Root partition formatted! ✔️${RESET}"

read -p "Enter your home partition (e.g., /dev/sda2) or press Enter to skip: " home_partition
if [ ! -z "$home_partition" ]; then
  mkfs.ext4 "$home_partition"
  echo -e "${GREEN}Home partition formatted! ✔️${RESET}"
fi

read -p "Enter your swap partition (e.g., /dev/sda3) or press Enter to skip: " swap_partition
if [ ! -z "$swap_partition" ]; then
  mkswap "$swap_partition"
  swapon "$swap_partition"
  echo -e "${GREEN}Swap partition enabled! 🔄${RESET}"
fi

# Mount the file systems
echo -e "${YELLOW}Step 7: Mounting the file systems 📂${RESET}"
mount "$root_partition" /mnt
echo -e "${GREEN}Root mounted on /mnt! ✔️${RESET}"

if [ ! -z "$home_partition" ]; then
  mkdir /mnt/home
  mount "$home_partition" /mnt/home
  echo -e "${GREEN}Home mounted on /mnt/home! 📂${RESET}"
fi

# Select the mirrors
echo -e "${YELLOW}Step 8: Let's update your mirrors and choose the best ones 🌍${RESET}"
reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "${GREEN}Mirrors updated! 🚀${RESET}"
sleep 2

# Install essential packages
echo -e "${YELLOW}Step 9: Installing essential packages 💻${RESET}"
pacstrap /mnt base base-devel linux linux-firmware neovim firefox openssh networkmanager
echo -e "${GREEN}Packages installed! You're almost there! 🎉${RESET}"
sleep 2

# Generate fstab
echo -e "${YELLOW}Step 10: Generating the fstab file 📝${RESET}"
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "${GREEN}fstab generated! 📄${RESET}"
sleep 2

# Chroot into the new system
echo -e "${YELLOW}Step 11: Chrooting into your new system 🔐${RESET}"
arch-chroot /mnt
sleep 2

# Set the time zone
echo -e "${YELLOW}Step 12: Setting the time zone ⏳${RESET}"
read -p "Enter your time zone (e.g., 'America/New_York'): " timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc
echo -e "${GREEN}Time zone set to $timezone! 🕰️${RESET}"
sleep 2

# Localization
echo -e "${YELLOW}Step 13: Setting up the localization 🌎${RESET}"
echo -e "Uncomment the 'en_US.UTF-8 UTF-8' line in /etc/locale.gen"
nvim /etc/locale.gen
locale-gen
echo -e "${GREEN}Locale set to en_US.UTF-8! 🌍${RESET}"
sleep 2

# Set hostname
echo -e "${YELLOW}Step 14: Setting the hostname 💻${RESET}"
read -p "Enter your hostname (e.g., 'myarch'): " hostname
echo "$hostname" > /etc/hostname
echo -e "${GREEN}Hostname set to $hostname! 🎉${RESET}"
sleep 2

# Configure network
echo -e "${YELLOW}Step 15: Configuring the network 🌐${RESET}"
echo -e "Adding 127.0.1.1 entry to /etc/hosts"
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname" >> /etc/hosts
echo -e "${GREEN}Network configuration done! 💪${RESET}"
sleep 2

# Root password
echo -e "${YELLOW}Step 16: Setting the root password 🔒${RESET}"
passwd
sleep 2

# Install boot loader
echo -e "${YELLOW}Step 17: Installing the bootloader 🖥️${RESET}"
pacman -S grub efibootmgr os-prober
echo -e "${CYAN}Installing GRUB bootloader...${RESET}"

# UEFI installation
echo -e "${YELLOW}Step 18: Installing GRUB for UEFI systems ⚙️${RESET}"
read -p "Enter your EFI partition (e.g., /dev/sda1): " efi_partition
grub-install --target=x86_64-efi --efi-directory="$efi_partition" --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "${GREEN}GRUB installed and configured! ✔️${RESET}"
sleep 2

# Create user
echo -e "${YELLOW}Step 19: Creating your user 🧑‍💻${RESET}"
read -p "Enter your username: " username
useradd -m "$username"
passwd "$username"
usermod -aG wheel "$username"
pacman -S sudo
echo -e "${GREEN}User $username created and added to the wheel group! 🎉${RESET}"
sleep 2

# Reboot
echo -e "${CYAN}-------------------------------------------"
echo -e "${GREEN}Congratulations, your Arch system is ready to reboot! 🎉"
echo -e "${CYAN}-------------------------------------------"
echo -e "${YELLOW}Please exit chroot, unmount and reboot: ${RESET}"
echo -e "${CYAN}exit\numount -R /mnt\nreboot${RESET}"

exit
