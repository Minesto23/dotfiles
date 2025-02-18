#!/bin/bash

# Configuraciones predeterminadas
TIMEZONE="Europe/Berlin"
LOCALE="en_US.UTF-8"
HOSTNAME="Tiamat"

# Preguntar por la partición EFI
echo -e "${YELLOW}Step 18: Please enter your EFI partition (e.g., /dev/sda1) ⚙️${RESET}"
read -p "Enter your EFI partition: " EFI_PARTITION

# Preguntar por el usuario y la contraseña
echo -e "${YELLOW}Step 19: Creating your user 🧑‍💻${RESET}"
read -p "Enter your username: " USERNAME
read -sp "Enter your password for $USERNAME: " USER_PASSWORD
echo
read -sp "Confirm your password: " USER_PASSWORD_CONFIRM
echo

# Verificar que las contraseñas coinciden
if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
  echo -e "${RED}Passwords do not match! Please try again.${RESET}"
  exit 1
fi

# Contraseña de root predeterminada
ROOT_PASSWORD="$USER_PASSWORD"

# Step 12: Setting the time zone ⏳
echo -e "${YELLOW}Step 12: Setting the time zone ⏳${RESET}"
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc
echo -e "${GREEN}Time zone set to $TIMEZONE! 🕰️${RESET}"
sleep 2

# Step 13: Setting up the localization 🌎
echo -e "${YELLOW}Step 13: Setting up the localization 🌎${RESET}"
echo -e "Uncomment the '$LOCALE UTF-8' line in /etc/locale.gen"
sed -i "/$LOCALE/s/^#//" /etc/locale.gen
locale-gen
echo -e "${GREEN}Locale set to $LOCALE! 🌍${RESET}"
sleep 2

# Step 14: Setting the hostname 💻
echo -e "${YELLOW}Step 14: Setting the hostname 💻${RESET}"
echo "$HOSTNAME" > /etc/hostname
echo -e "${GREEN}Hostname set to $HOSTNAME! 🎉${RESET}"
sleep 2

# Step 15: Configuring the network 🌐
echo -e "${YELLOW}Step 15: Configuring the network 🌐${RESET}"
echo -e "Adding 127.0.1.1 entry to /etc/hosts"
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" >> /etc/hosts
echo -e "${GREEN}Network configuration done! 💪${RESET}"
sleep 2

# Step 16: Setting the root password 🔒
echo -e "${YELLOW}Step 16: Setting the root password 🔒${RESET}"
echo "$ROOT_PASSWORD" | passwd --stdin root
echo -e "${GREEN}Root password set! 🔑${RESET}"
sleep 2

# Step 17: Installing the bootloader 🖥️
echo -e "${YELLOW}Step 17: Installing the bootloader 🖥️${RESET}"
pacman -S --noconfirm grub efibootmgr os-prober
echo -e "${CYAN}Installing GRUB bootloader...${RESET}"

# Step 18: Installing GRUB for UEFI systems ⚙️
echo -e "${YELLOW}Step 18: Installing GRUB for UEFI systems ⚙️${RESET}"
grub-install --target=x86_64-efi --efi-directory="$EFI_PARTITION" --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "${GREEN}GRUB installed and configured! ✔️${RESET}"
sleep 2

# Step 19: Creating your user 🧑‍💻
echo -e "${YELLOW}Step 19: Creating your user 🧑‍💻${RESET}"
useradd -m "$USERNAME"
echo "$USER_PASSWORD" | passwd --stdin "$USERNAME"
usermod -aG wheel "$USERNAME"
pacman -S --noconfirm sudo
echo -e "${GREEN}User $USERNAME created and added to the wheel group! 🎉${RESET}"
sleep 2

# Exit chroot, unmount the system and reboot
echo -e "${YELLOW}Exiting the chroot environment and rebooting...${RESET}"

# Exit the chroot environment
exit

# Unmount all mounted partitions
umount -R /mnt


