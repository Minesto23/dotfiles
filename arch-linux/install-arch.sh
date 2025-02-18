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

# Set the keyboard layout automatically to US if no other layout is provided
echo -e "${YELLOW}Step 1: Keyboard Layout Setup ${RESET}"
echo -e "Setting the default keyboard layout to ${BLUE}US${RESET}... ⌨️"

# Apply the US layout by default
loadkeys "us"
echo -e "${GREEN}Keyboard layout set to US. Sweet! 🎹${RESET}"

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

# Print the partition table
echo -e "${GREEN}Here are your current disk partitions: 🧐${RESET}"
lsblk
# Alternatively, you can use fdisk if you prefer detailed information
# fdisk -l


# Format the partitions
echo -e "${YELLOW}Step 6: Formatting your partitions 🧼${RESET}"
echo -e "Let's format the partitions to prepare them for the system!"
echo -e "First, the root partition..."

# Format root partition
read -p "Enter the root partition (e.g., /dev/sda1): " root_partition
mkfs.ext4 "$root_partition"
echo -e "${GREEN}Root partition formatted! ✔️${RESET}"

# Format home partition (optional)
read -p "Enter your home partition (e.g., /dev/sda2) or press Enter to skip: " home_partition
if [ ! -z "$home_partition" ]; then
  mkfs.ext4 "$home_partition"
  echo -e "${GREEN}Home partition formatted! ✔️${RESET}"
fi

# Format swap partition (optional)
read -p "Enter your swap partition (e.g., /dev/sda3) or press Enter to skip: " swap_partition
if [ ! -z "$swap_partition" ]; then
  mkswap "$swap_partition"
  swapon "$swap_partition"
  echo -e "${GREEN}Swap partition enabled! 🔄${RESET}"
fi

# Format EFI partition (optional)
read -p "Enter your EFI partition (e.g., /dev/sda4) or press Enter to skip: " efi_partition
if [ ! -z "$efi_partition" ]; then
  mkfs.fat -F32 "$efi_partition"
  echo -e "${GREEN}EFI partition formatted! ✔️${RESET}"
fi

# Mount the file systems
echo -e "${YELLOW}Step 7: Mounting the file systems 📂${RESET}"

# Mount root partition
mount "$root_partition" /mnt
echo -e "${GREEN}Root mounted on /mnt! ✔️${RESET}"

# Mount home partition (optional)
if [ ! -z "$home_partition" ]; then
  mkdir /mnt/home
  mount "$home_partition" /mnt/home
  echo -e "${GREEN}Home mounted on /mnt/home! 📂${RESET}"
fi

# Mount EFI partition (optional)
if [ ! -z "$efi_partition" ]; then
  mkdir /mnt/efi
  mount "$efi_partition" /mnt/efi
  echo -e "${GREEN}EFI mounted on /mnt/efi! 🔌${RESET}"
fi

# Enable swap partition (optional)
if [ ! -z "$swap_partition" ]; then
  swapon "$swap_partition"
  echo -e "${GREEN}Swap enabled! 🔄${RESET}"
fi


# Select the mirrors
echo -e "${YELLOW}Step 8: Let's update your mirrors and choose the best ones 🌍${RESET}"
reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
echo -e "${GREEN}Mirrors updated! 🚀${RESET}"
sleep 2

# Install essential packages
echo -e "${YELLOW}Step 9: Installing essential packages 💻${RESET}"
pacstrap /mnt base base-devel linux linux-firmware neovim openssh networkmanager
echo -e "${GREEN}Packages installed! You're almost there! 🎉${RESET}"
sleep 2

# Generate fstab
echo -e "${YELLOW}Step 10: Generating the fstab file 📝${RESET}"
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "${GREEN}fstab generated! 📄${RESET}"
sleep 2

# Chroot into the new system
echo -e "${YELLOW}Step 11: Chrooting into your new system 🔐${RESET}"
echo -e "${YELLOW}Downloading the script from GitHub... ⬇️${RESET}"

# Clone the dotfiles repository into /mnt/home
git clone https://github.com/Minesto23/dotfiles.git /mnt/home/dotfiles
echo -e "${GREEN}Script downloaded and now time to execute it! 🎉${RESET}"
# Make the downloaded script executable
echo -e "${YELLOW}Making the script executable... 🖥️${RESET}"
chmod +x /mnt/home/dotfiles/arch/install_chroot.sh
arch-chroot /mnt
sleep 2


# Reboot
echo -e "${CYAN}-------------------------------------------"
echo -e "${GREEN}Congratulations, your Arch system is ready to reboot! 🎉"
echo -e "${CYAN}-------------------------------------------"
# Reboot the system
reboot

exit
