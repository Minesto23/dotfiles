# ARCH Linux Install guide
![ARCH](https://github.com/Minesto23/dotfiles/blob/main/arch-linux/arch.png)
# Table of Contents
- [Overview](#overview)
- [Set the keyboard layout](set-the-keyboard-layout)
- [Verify the boot mode](verify-the-boot-mode)
- [Connect to the internet](connect-to-the-internet)
- [Update the system clock](update-the-system-clock)
- [Partition the disks](partition-the-disks)
- [Format the partitions](format-the-partitions)
- [Mount the file systems](mount-the-file-systems)
- [Select the mirrors](select-the-mirrors)
- [Install essential packages](install-essential-packages)
- [Fstab](fstab)
- [Chroot](chroot)
- [Time zone](time-zone)
- [Localization](localization)
- [Network configuration](network-configuration)
- [Root password](root-password)
- [Boot loader](boot-loader)
- [Create your user](create-your-user)
- [Reboot](reboot)

# Overview
This is a guide to help you in your path to install arch Linux, I will try to be very clearly with every step
in the installation process. (Remember all the step in this guide and more you can find there the Arch Linux Wiki, I recommend check the wiki).

This guide explains the step after boot arch in a USB, the previous step don't be explained.

# Set the keyboard layout
If you have a Keyboard layout in US you can skip this step.

First Available layouts can be listed with:
```bash
ls /usr/share/kbd/keymaps/**/*.map.gz
```
To modify the layout, append a corresponding file name to loadkeys, omitting path and file extension. For example, to set a Latin America keyboard layout:
```bash
loadkeys la-latin1
```
# Verify the boot mode
To verify the boot mode, list the efivars directory:
```bash
ls /sys/firmware/efi/efivars
```
If the command shows the directory without error, then the system is booted in UEFI mode. If the directory does not exist, the system may be booted in BIOS (or CSM) mode.

# Connect to the internet
To set up a network connection in the live environment, go through the following steps:

### Ethernet
Only plug the cable.

### Wi-Fi
Authenticate to the wireless network using iwctl.

To get an interactive prompt do:
```bash
iwctl
```
The interactive prompt is then displayed with a prefix of [iwd]#. To list all available commands:
```bash
help
```
#### Connect to a network
First, if you do not know your wireless device name, list all Wi-Fi devices:
```bash
device list
```
Then, to scan for networks:
```bash
station your_device scan
```
You can then list all available networks:
```bash
station your_device get-networks
```
Finally, to connect to a network:
```bash
station your_device connect SSID
```
If a passphrase is required, you will be prompted to enter it. Alternatively, you can supply it as a command line argument:
```bash
iwctl --passphrase passphrase station device connect SSID
```
### Verified Connection
The connection may be verified with ping:
```bash
ping archlinux.org
```
# Update the system clock
Use timedatectl to ensure the system clock is accurate:
```bash
timedatectl set-ntp true
```
To check the service status, use timedatectl status.
# Partition the disks
When recognized by the live system, disks are assigned to a block device such as /dev/sda, /dev/nvme0n1 or /dev/mmcblk0. To identify these devices, use lsblk or fdisk.
```bash
fdisk -l
```
You can use fdisk or parted to modify partition tables. For example:
```bash
fdisk /dev/the_disk_to_be_partitioned
```
In my case I prefer to use cfdisk for commodity
```bash
cfdisk
```
### Example layouts

#### BIOS with MBR
| Mount point |  Partition          | Partition type | Suggested size        |
|:-----------:|:-------------------:|:--------------:|:---------------------:|
| [SWAP]      | /dev/swap_partition | Linux swap     |More than 512 MiB      |
| /mnt        | /dev/root_partition | Linux          |Remainder of the device|

#### UEFI with GPT
| Mount point |  Partition          | Partition type | Suggested size        |
|:-----------:|:-------------------:|:--------------:|:---------------------:|
| /mnt/boot or /mnt/efi      | /dev/efi_system_partition | EFI system partition     |At least 260 MiB      |
|[SWAP]	|/dev/swap_partition	|Linux swap	|More than 512 MiB|
| /mnt        | /dev/root_partition | Linux x86-64 root (/) |Remainder of the device|

#### My layout UEFI with GPT
| Mount point |  Partition          | Partition type | Suggested size        |
|:-----------:|:-------------------:|:--------------:|:---------------------:|
| /mnt/boot or /mnt/efi      | /dev/efi_system_partition | EFI system partition     |512 MiB      |
|[SWAP]	|/dev/swap_partition	|Linux swap	| 4 - 8 GB|
| /mnt        | /dev/root_partition | Linux x86-64 root (/) |30 - 50 GB|
|/mnt/home|/dev/home_partition|Linux home|Remainder of the device|
# Format the partitions
Once the partitions have been created, each newly created partition must be formatted with an appropriate file system. 
```bash
mkfs.ext4 /dev/root_partition
mkfs.ext4 /dev/home_partition
mkswap /dev/swap_partition
mkfs.fat -F32 /dev/efi_system_partition
```
# Mount the file systems
Mount the root volume to /mnt. For example, if the root volume is /dev/root_partition:
```bash
mount /dev/root_partition /mnt
```
Create any remaining mount points (such as /mnt/efi) using mkdir and mount their corresponding volumes.
```bash
mkdir /mnt/efi
mkdir /mnt/home
mount /dev/efi_system_partition /mnt/efi
mount /dev/home_partition /mnt/home
```
If you created a swap volume, enable it with swapon:
```bash
swapon /dev/swap_partition
```
# Select the mirrors
Packages to be installed must be downloaded from mirror servers, which are defined in ```/etc/pacman.d/mirrorlist```. On the live system, after connecting to the internet, reflector updates the mirror list by choosing 20 most recently synchronized HTTPS mirrors and sorting them by download rate.
```bash
reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
```
# Install essential packages
Use the pacstrap script to install the base package, Linux kernel and firmware for common hardware:
```bash
pacstrap /mnt base base-devel linux linux-firmware neovim firefox openssh networkmanager
```
# Fstab
Generate an fstab file (use -U or -L to define by UUID or labels, respectively):
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```
Check the resulting /mnt/etc/fstab file, and edit it in case of errors.
# Chroot
Change root into the new system:
```bash
arch-chroot /mnt
```
# Time zone
Set the time zone:
```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
```
Run hwclock to generate /etc/adjtime:
```bash
hwclock --systohc
```
# Localization
Edit /etc/locale.gen and uncomment en_US.UTF-8 UTF-8 and other needed locales. Generate the locales by running:
```bash
nvim /etc/locale.gen # uncomment en_US.UTF-8 UTF-8
locale-gen
```
Create the locale.conf file, and set the LANG variable accordingly:
```bash
nvim /etc/locale.conf # add LANG=en_US.UTF-8
```
If you set the keyboard layout, make the changes persistent in vconsole.conf:
```bash
nvim /etc/vconsole.conf # add /etc/vconsole.conf
```
#  Network configuration

Create the hostname file /etc/hostname and add:
```bash
myhostname
```
Add matching entries to hosts /etc/hosts and add:
```bash
127.0.0.1	localhost
::1		localhost
127.0.1.1	myhostname.localdomain	myhostname
```
# Root password
Set the root password:
```bash
passwd
```
# Boot loader
For Boot loader I use grub first we need to install it.
```bash
pacman -S grub efibootmgr os-prober
```
For Bios System use:
```bash
grub-install --target=i386-pc /dev/partition
grub-mkconfig -o /boot/grub/grub.cfg
```
For UEFI use:
```bash
grub-install --target=x86_64-efi --efi-directory=efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```
# Create your user
Now you can create your user:
```bash
useradd -m username
passwd username
usermod -aG wheel,video,audio,storage username
```
In order to have root privileges we need sudo:
```bash
pacman -S sudo
```
Edit /etc/sudoers with neovim, vim or nano by uncommenting this line:
```bash
## Uncomment to allow members of group wheel to execute any command
# %wheel ALL=(ALL) ALL
```
# Reboot
The final step is reboot your new system
```bash
# Exit out of ISO image, unmount it and remove it
exit
umount -R /mnt
reboot
```
After logging in, your internet should be working just fine, but that's only if your computer is plugged in. If you're on a laptop with no Ethernet ports,this is how you connect to a wireless LAN with this software:
```bash
# List all available networks
nmcli device wifi list
# Connect to your network
nmcli device wifi connect YOUR_SSID password YOUR_PASSWORD
```

In this moment you have a clean Arch Linux in your pc, the next step is install a desktop enviroment, you have many option like KDE, xfce, mate, qtile. In other post i explain you how install qtile and I share you my settings for that desktop enviroment


