#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Pacman adding up extra-spices #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pacman.log"

# Define Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
SKY_BLUE='\033[0;36m'
RESET='\033[0m'

# Function to log and echo messages
log_message() {
    echo -e "$1" 2>&1 | tee -a "$LOG"
}

# Add Extra Spices in pacman.conf
log_message "${MAGENTA}Adding Extra Spice${RESET} in pacman.conf ..."

pacman_conf="/etc/pacman.conf"

# Function to uncomment a line in pacman.conf
uncomment_line() {
    local line=$1
    if grep -q "^#$line" "$pacman_conf"; then
        sudo sed -i "s/^#$line/$line/" "$pacman_conf"
        log_message "${GREEN}Uncommented: $line${RESET}"
    else
        log_message "${YELLOW}$line is already uncommented.${RESET}"
    fi
}

# Remove comments '#' from specific lines
lines_to_edit=("Color" "CheckSpace" "VerbosePkgLists" "ParallelDownloads")

# Loop through lines to edit and uncomment if necessary
for line in "${lines_to_edit[@]}"; do
    uncomment_line "$line"
done

# Function to add ILoveCandy after ParallelDownloads
add_ilovecandy() {
    if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
        sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
        log_message "${GREEN}Added ${MAGENTA}ILoveCandy${RESET} after ${MAGENTA}ParallelDownloads${RESET}."
    else
        log_message "${YELLOW}ILoveCandy already exists or ParallelDownloads is missing.${RESET} Moving on..."
    fi
}

# Add "ILoveCandy" below ParallelDownloads if it doesn't exist
add_ilovecandy

log_message "${MAGENTA}Pacman.conf spicing up completed${RESET}"

# Updating pacman.conf and syncing repos
log_message "${SKY_BLUE}Synchronizing Pacman Repo${RESET}"
if sudo pacman -Sy; then
    log_message "${GREEN}Pacman repo synchronized successfully.${RESET}"
else
    log_message "${RED}Failed to synchronize Pacman repo. Please check for errors.${RESET}"
    exit 1
fi

# Final confirmation
log_message "${MAGENTA}Pacman conf updated and repo synchronized.${RESET}"

printf "\n%.0s" {1..2}
