#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# base devel + archlinux-keyring #

base=( 
  base-devel
  archlinux-keyring
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_base.log"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}base-devel${RESET} \n" "${NOTE}"

for PKG1 in "${base[@]}"; do
  # Attempt to install the package
  install_package_pacman "$PKG1" "$LOG"
  
  if [[ $? -eq 0 ]]; then
    # If the installation was successful, print a success message in green
    printf "${GREEN}Successfully installed ${PKG1}${RESET}\n"
  else
    # If there was an error, print an error message in red
    printf "${RED}Error installing ${PKG1}. Check the log file: $LOG${RESET}\n"
  fi
done

printf "\n%.0s" {1..2}
