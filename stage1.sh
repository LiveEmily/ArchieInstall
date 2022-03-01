#!/usr/bin/env /usr/bin/bash

# Error code documentation
#
# 0 = Succesful exit
# 1 = Whiptail and Dialog not install
# 2 = User triggered exit

# Setup for using extended globbing in bash

shopt -s extglob

# Global variables
swap=false
home=false
ram=$(head /proc/meminfo | grep MemTotal: | awk '/^Mem/ {print $2}')
ramGB=$(($ram/1000000))
swapSize=0
homeSize=0
disk=""
diskPart=""

# aliases for printing colours quickly
# rprintf -> prints to STDERR instead out STDOUT

alias rprintf="printf '\\033[0;31m%s\\n''\\033[0;37m' >&2"
alias gprintf="printf '\\033[0;32m%s\\n''\\033[0;37m'"
alias yprintf="printf '\\033[0;33m%s\\n''\\033[0;37m'"
alias bprintf="printf '\\033[0;34m%s''\\033[0;37m'"

# Whiptail enviornment variables

export NEWT_COLORS='
root=,cyan
window=,brightblue
shadow=,black
border=,brightblue
title=black,brightblue
textbox=black,brightblue
button=brightblue,black
compactbutton=black,brightblue
'


# Actual script starts here
# Check for whiptail

read dialog <<< "$(which whiptail 2> /dev/null)"

[[ "$dialog" ]] || {
    rprintf "Whiptail is not installed, please install using 'pacman -Sy whiptail' to continue this installation"
    exit 1
}

gprintf "Successfully found whiptail!"


# Intro screen

"$dialog" --title "Archie install script!" --yesno "Welcome to the Archie install script!\nIf you're ready to start, please choose ready, if not choose not ready and come back when you are" --yes-button "Ready" --no-button "Not ready" 8 78
if [ $? -ne 0 ]; then
    yprintf "You chose no!"
    exit 2
fi


# Install wget, set time and download other stages

pacman -Sy --noconfirm wget
#timedatectl set-ntp true
#wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/stage2.sh
#wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/pacman.txt
#wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/yay.txt


# Choose a disk

while :
do
    disk=$("$dialog" --title "Storage devices" --inputbox "Please choose the drive you want to install Arch on excluding the '/dev/' part\n\n\n$(lsblk -e7 -e11)" 20 60 3>&1 1>&2 2>&3)

    if [[ "$disk" == "sd"[a-z] ]]; then
        diskpart=$disk
        break
    elif [[ "$disk" == "nvme0n"[1-9] ]]; then
        diskpart=$disk"p"
        break
    else
        "$dialog" --title "Not a valid disk!" --msgbox "Please choose a valid disk instead!" 20 60 3>&1 1>&2 2>&3
    fi
    echo $diskpart
done