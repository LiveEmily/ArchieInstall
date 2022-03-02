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
root=,blue
window=,brightcyan
shadow=,black
border=,brightcyan
title=black,brightcyan
textbox=black,brightcyan
button=brightcyan,black
compactbutton=black,brightcyan
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
timedatectl set-ntp true
wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/stage2.sh
wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/pacman.txt
wget https://raw.githubusercontent.com/LiveEmily/ArchieInstall/v2.0/aur.txt


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


# Optional settings

"$dialog" --title "SWAP space" --yesno "Would you like to have SWAP space?" 8 78 3>&1 1>&2 2>&3
if [ $? -eq 0 ]; then
    swap=true
fi
    
"$dialog" --title "Home directory" --yesno "Would you like a seperate partition for /home?" 8 78 3>&1 1>&2 2>&3
if [ $? -eq 0 ]; then
    home=true
fi

if [ $swap == true ]; then
    while :
    do
        swapSize=$("$dialog" --title "Choose swap size" --inputbox "Please choose the amount of swap space you want in GB(GigaBytes).\nUsually it would be best practice to have double your RAM as swap. So 2x$ramGB in your case." 8 78 3>&1 1>&2 2>&3)
        if [[ $swapSize -gt 0 ]]; then
            break
        else
            "$dialog" --title "Not a valid size!" --msgbox "Please choose a valid size for the swap partition" 20 60 3>&1 1>&2 2>&3
        fi
    done
fi

if [ $home == true ]; then
    while :
    do
        homeSize=$("$dialog" --title "Choose home size" --inputbox "Please choose how big you want your home partition to be in GB(GigaBytes)." 8 78 3>&1 1>&2 2>&3)
        if [[ $homeSize -gt 0 ]]; then
            break
        else
            "$dialog" --title "Not a valid size!" --msgbox "Please choose a valid size for the home partition" 20 60 3>&1 1>&2 2>&3
        fi
    done
fi


# Partitioning the actual disks (This is a huge pain and I'd love to make it simpler)

"$dialog" --title "Partitioning drive" --msgbox "Your disk will now be partitioned, please stand by..." 8 78
if [[ -d "/sys/firmware/efi" ]]; then
	if [ $swap == "true" ] && [ $home == "true" ]; then
		echo ",1048576,6
		,$(($swapSize*2097152)),S
		,$(($homeSize*2097152)),83
		;" | sfdisk /dev/$disk
		mkswap /dev/"$diskpart"2
		swapon /dev/"$diskpart"2
		mkfs.ext4 /dev/"$diskpart"3
		mkfs.ext4 /dev/"$diskpart"4
	elif [ $swap == "true" ] && [ $home == "false" ]; then
		echo ",1048576,6
		,$(($swapSize*2097152)),S
		;" | sfdisk /dev/$disk
		mkswap /dev/"$diskpart"2
		swapon /dev/"$diskpart"2
		mkfs.ext4 /dev/"$diskpart"3
	elif [ $swap == "false" ] && [ $home == "true" ]; then
		echo ",1048576,6
		,$(($homeSize*2097152)),83
		;" | sfdisk /dev/$disk
		mkfs.ext4 /dev/"$diskpart"2
		mkfs.ext4 /dev/"$diskpart"3
	else
		echo ",1048576,6
		;" | sfdisk /dev/$disk
		mkfs.ext4 /dev/"$diskpart"2
	fi
	mkfs.vfat -F32 /dev/"$diskpart"1
else
	if [ $swap == "true" ] && [ $home == "true" ]; then
		echo ",2048,a
		,1048576,6
		,$(($swapSize*2097152)),S
		,,E
		,$(($homeSize*2097152)),83
		;" | sfdisk /dev/$disk
		mkswap /dev/"$diskpart"3
		swapon /dev/"$diskpart"3
		mkfs.ext4 /dev/"$diskpart"5
		mkfs.ext4 /dev/"$diskpart"6
	elif [ $swap == "true" ] && [ $home == "false" ]; then
		echo ",2048,a
		,1048576,6
		,$(($swapSize*2097152)),S
		;" | sfdisk /dev/$disk
		mkswap /dev/"$diskpart"3
		swapon /dev/"$diskpart"3
		mkfs.ext4 /dev/"$diskpart"4
	elif [ $swap == "false" ] && [ $home == "true" ]; then
		echo ",2048,a
		,1048576,6
		,$(($homeSize*2097152)),83
		;" | sfdisk /dev/$disk
		mkfs.ext4 /dev/"$diskpart"3
		mkfs.ext4 /dev/"$diskpart"4
	else
		echo ",2048,a
		,1048576,6
		;" | sfdisk /dev/$disk
		mkfs.ext4 /dev/"$diskpart"3
	fi
	mkfs.vfat -F32 /dev/"$diskpart"2
fi


# Mounting the partitions (Again this is quite painful but bare with me)

"$dialog" --title "Mounting partitions" --msgbox "We will now mount the partitions, please stand by..." 8 78
if [[ -d "/sys/firmware/efi" ]]; then
	if [ $swap == "true" ] && [ $home == "true" ]; then
		mount /dev/"$diskpart"4 /mnt
		mkdir /mnt/boot
		mkdir /mnt/home
		mount /dev/"$diskpart"1 /mnt/boot
		mount /dev/"$diskpart"3 /mnt/home
	elif [ $swap == "false" ] && [ $home == "true" ]; then
		mount /dev/"$diskpart"3 /mnt
		mkdir /mnt/boot
		mkdir /mnt/home
		mount /dev/"$diskpart"1 /mnt/boot
		mount /dev/"$diskpart"2 /mnt/home
	elif [ $swap == "true" ] && [ $home == "false" ]; then
		mount /dev/"$diskpart"3 /mnt
		mkdir /mnt/boot
		mount /dev/"$diskpart"1 /mnt/boot
	else
		mount /dev/"$diskpart"2 /mnt
		mkdir /mnt/boot
		mount /dev/"$diskpart"1 /mnt/boot
	fi
else
	if [ $swap == "true" ] && [ $home == "true" ]; then
		mount /dev/"$diskpart"6 /mnt
		mkdir /mnt/boot
		mkdir /mnt/home
		mount /dev/"$diskpart"2 /mnt/boot
		mount /dev/"$diskpart"5 /mnt/home
	elif [ $swap == "false" ] && [ $home == "true" ]; then
		mount /dev/"$diskpart"4 /mnt
		mkdir /mnt/boot
		mkdir /mnt/home
		mount /dev/"$diskpart"2 /mnt/boot
		mount /dev/"$diskpart"3 /mnt/home
	elif [ $swap == "true" ] && [ $home == "false" ]; then
		mount /dev/"$diskpart"4 /mnt
		mkdir /mnt/boot
		mount /dev/"$diskpart"2 /mnt/boot
	else
		mount /dev/"$diskpart"3 /mnt
		mkdir /mnt/boot
		mount /dev/"$diskpart"2 /mnt/boot
	fi
fi


# The fun part begins, actually installing packages and the system

"$dialog" --title "Installing packages" --msgbox "We will now install all required non aur packages, please stand by..." 8 78
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf
pacstrap /mnt - < ./pacman.txt
genfstab -U /mnt >> /mnt/etc/fstab


# Chrooting time 

"$dialog" --title "Chrooting into system" --msgbox "We will now chroot into your newly installed system to continue..." 8 78
cp ./stage2.sh ./aur.txt /mnt/
chmod +x /mnt/stage2.sh
arch-chroot /mnt ./stage2.sh $disk
rm -rf /mnt/stage2.sh /mnt/aur.txt
umount -R /mnt
reboot now