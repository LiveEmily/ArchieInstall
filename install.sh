#!/usr/bin/env /usr/bin/bash

# Error code documentation
#
# 1 = Whiptail and Dialog not install
# 2 = No valid network connection

swap=false
home=false
ram=$(head /proc/meminfo | grep MemTotal: | awk '/^Mem/ { print $2 }')
ramgb=$(($ram/1000000))
swapSize=0
homeSize=0
disk=""
diskpart=""

read dialog <<< "$(which whiptail dialog 2> /dev/null)"

[[ "$dialog" ]] || {
	printf "Whiptail or Dialog is not installed, please install using 'pacman -Sy whiptail' to continue this installation\n\r"
	exit 1
}

chrooting() {
	"$dialog" --title "Chrooting into system" --msgbox "We will now chroot into your newly installed system to continue..." 10 60
	cp ./install2.sh /mnt/
	chmod +x /mnt/install2.sh
	arch-chroot /mnt ./install2.sh
	umount -R /mnt
	reboot now
}

export_fstab() {
	"$dialog" --title "Generating fstab file" --msgbox "We will now generate your fstab file for mounting the partitions at boot..." 10 60
	genfstab -U /mnt >> /mnt/etc/fstab
	chrooting
}

install_packages() {
	"$dialog" --title "Installing packages" --msgbox "We will now install all required non aur packages, please stand by..." 10 60
	pacstrap /mnt - < ./pkglist.txt
	export_fstab
}

mount_part() {
	"$dialog" --title "Mounting partitions" --msgbox "We will now mount the partitions, please stand by..." 10 60
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
	install_packages
}

partition_disk() {
	"$dialog" --title "Partitioning drive" --msgbox "Your disk will now be partitioned, please stand by..." 10 60
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
	mount_part
}

choose_swap_size() {
	swapSize=$("$dialog" --title "Choose swap size" --inputbox "Please choose the amount of swap space you want in GB(GigaBytes).\nUsually it would be best practice to have double your RAM as swap. So 2x$ramgb in your case." 10 60 3>&1 1>&2 2>&3)
}

choose_home_size() {
	homeSize=$("$dialog" --title "Choose home size" --inputbox "Please choose how big you want your home partition to be in GB(GigaBytes)." 10 60 3>&1 1>&2 2>&3)
}

choose_part() {
	if("$dialog" --title "SWAP space" --yesno "Would you like to have SWAP space?" 10 60 3>&1 1>&2 2>&3) then
		swap=true
	fi
	if("$dialog" --title "Home directory" --yesno "Would you like a seperate partition for /home?" 10 60 3>&1 1>&2 2>&3) then
		home=true
	fi
}

choose_disk() {
	disk=$("$dialog" --title "Storage devices" --inputbox "Please choose the drive you want to install Arch on excluding the '/dev/' part\n\n\n$(lsblk -e7 -e11)" 20 60 3>&1 1>&2 2>&3)
	"$dialog" --title "Disk chosen" --msgbox "You chose disk /dev/$disk!" --ok-button "Continue" 10 60
	choose_part

	if [ $swap == true ]; then
		choose_swap_size
	fi
	if [ $home == true ]; then
		choose_home_size
	fi
	if [ $disk == "nvme0n1" ]; then
		diskpart="nvme0n1p"
	else
		diskpart=$disk
	fi
	partition_disk
}

check_connection() {
	pacman -Sy --noconfirm wget
	wget -q --spider http://google.com

	if [ $? -eq 0 ]; then
		"$dialog" --title "Internet connection found!" --msgbox "Succesfully connected to the internet, this script will now proceed to partitioning" --ok-button "Continue" 10 60
		timedatectl set-ntp true
		wget https://liveemily.xyz/archieinstall/install2.sh
		wget https://liveemily.xyz/archieinstall/pkglist.txt
		choose_disk
	else
		"$dialog"
		exit 2
	fi
}

intro_screen() {
	"$dialog" --title "Archie install script!" --yesno "Welcome to the Archie install script!\nIf you're ready to start, please choose ready, if not choose not ready and come back when you are" --yes-button "Ready" --no-button "Not ready" 10 60
	if [ $? -eq 0 ]; then
		"$dialog" --title "Checking internet connection" --msgbox "This script will now check if there's a valid internet connection, please stand by..." --ok-button "Continue" 10 60
		check_connection
	else
		printf "You chose no!\n\r"
	fi
}

intro_screen
