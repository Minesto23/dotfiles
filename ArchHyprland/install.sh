#!/bin/bash
# https://github.com/JaKooLit

clear

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......."
    exit 1
fi

# Automatically set preset values for configuration
use_preset="Y" # This will assume that you want to use the preset settings automatically

# nvidia
nvidia="Y"  # Automatically enable Nvidia GPU configuration
nouveau="Y"  # Automatically blacklist nouveau

# AUR helper
aur_helper="yay"  # Automatically set AUR helper to yay

# Enable everything by default
gtk_themes="Y"
bluetooth="Y"
thunar="Y"
thunar_choice="Y"
input_group="Y"
ags="Y"
sddm="Y"
sddm_theme="Y"
xdph="Y"
zsh="Y"
pokemon_choice="Y"
rog="Y"
dots="Y"

# Check if PulseAudio package is installed
if pacman -Qq | grep -qw '^pulseaudio$'; then
    echo "$ERROR PulseAudio is detected as installed. Uninstall it first or edit install.sh on line 211 (execute_script 'pipewire.sh')."
    exit 1
fi

# Check if base-devel is installed
if pacman -Q base-devel &> /dev/null; then
    echo "base-devel is already installed."
else
    echo "$NOTE Install base-devel.........."

    if sudo pacman -S --noconfirm base-devel; then
        echo "$OK base-devel has been installed successfully."
    else
        echo "$ERROR base-devel not found nor cannot be installed."
        echo "$ACTION Please install base-devel manually before running this script... Exiting"
        exit 1
    fi
fi

clear

# Welcome message
echo "${SKY_BLUE}Welcome to JaKooLit's Arch-Hyprland (2025) Install Script!${RESET}"

# Automatically proceed without asking
echo "${INFO} Automatically proceeding with installation..."

# install pciutils if detected not installed. Necessary for detecting GPU
if ! pacman -Qs pciutils > /dev/null; then
    echo "pciutils is not installed. Installing..."
    sudo pacman -S --noconfirm pciutils
fi

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Set the name of the log file to include the current date and time
LOG="install-$(date +%d-%H%M%S).log"

# Automatically set up everything in the script directory
chmod +x install-scripts/*

# Automatically execute all the scripts without asking questions
execute_script() {
    local script="$1"
    local script_path="install-scripts/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            env USE_PRESET=$use_preset "$script_path"
        else
            echo "Failed to make script '$script' executable."
        fi
    else
        echo "Script '$script' not found in 'install-scripts/'."
    fi
}

# Ensure base-devel is installed
execute_script "00-base.sh"
sleep 1
execute_script "pacman.sh"
sleep 1

# Execute AUR helper script based on user choice
if [ "$aur_helper" == "paru" ]; then
    execute_script "paru.sh"
elif [ "$aur_helper" == "yay" ]; then
    execute_script "yay.sh"
fi

# Install hyprland packages
execute_script "01-hypr-pkgs.sh"

# Install pipewire and pipewire-audio
execute_script "pipewire.sh"

# Install necessary fonts
execute_script "fonts.sh"

# Install hyprland
execute_script "hyprland.sh"

# NVIDIA setup if needed
if [ "$nvidia" == "Y" ]; then
    execute_script "nvidia.sh"
fi
if [ "$nouveau" == "Y" ]; then
    execute_script "nvidia_nouveau.sh"
fi

# GTK themes installation
if [ "$gtk_themes" == "Y" ]; then
    execute_script "gtk_themes.sh"
fi

# Bluetooth setup
if [ "$bluetooth" == "Y" ]; then
    execute_script "bluetooth.sh"
fi

# Install Thunar file manager
if [ "$thunar" == "Y" ]; then
    execute_script "thunar.sh"
fi
if [ "$thunar_choice" == "Y" ]; then
    execute_script "thunar_default.sh"
fi

# Install AGS (Aylur's GTK shell)
if [ "$ags" == "Y" ]; then
    execute_script "ags.sh"
fi

# Install & configure SDDM
if [ "$sddm" == "Y" ]; then
    execute_script "sddm.sh"
fi
if [ "$sddm_theme" == "Y" ]; then
    execute_script "sddm_theme.sh"
fi

# XDG-DESKTOP-PORTAL-HYPRLAND for screen sharing
if [ "$xdph" == "Y" ]; then
    execute_script "xdph.sh"
fi

# Install zsh and configure Pokemon colors
if [ "$zsh" == "Y" ]; then
    execute_script "zsh.sh"
fi
if [ "$pokemon_choice" == "Y" ]; then
    execute_script "zsh_pokemon.sh"
fi

# Add user to input group for Waybar keyboard-state functionality
if [ "$input_group" == "Y" ]; then
    execute_script "InputGroup.sh"
fi

# Asus ROG laptops configuration
if [ "$rog" == "Y" ]; then
    execute_script "rog.sh"
fi

# Install pre-configured dotfiles
if [ "$dots" == "Y" ]; then
    execute_script "dotfiles-main.sh"
fi

clear

# Copy fastfetch config if not already present
if [ ! -f "$HOME/.config/fastfetch/arch.png" ]; then
    cp -r assets/fastfetch "$HOME/.config/"
fi

# Final check for essential packages
execute_script "02-Final-Check.sh"

# Final message and option to reboot
echo "${INFO} Installation complete! You may need to reboot."
echo "To start Hyprland, type 'Hyprland' in your terminal (case-sensitive)."
