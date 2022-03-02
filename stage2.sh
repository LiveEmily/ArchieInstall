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

# Timezone variables

continents=("Africa" "America" "Antarctica" "Asia" "Atlantic" "Australia" "Brazil" "Canada" "Chile" "Etc" "Europe" "Indian" " Mexico" "Pacific" "US")

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


# Actual stage2 script

# Thingy for swap space in VMs, thanks @lucie for this
echo "vm.swappiness=1" >> /etc/sysctl.d/99-swappiness.conf

# This is dirty but this is the only way I got it working, please don't judge me
continent=$(whiptail --title "Timezone" --inputbox "Please give me the continent for your timezone\nCAPS MATTERS\n\n$(echo ${continents[@]})" 20 60 3>&1 1>&2 2>&3)
city=$(whiptail --title "City" --inputbox "Please give me the city for your timezone\nCAPS MATTERS\n\n$(ls /usr/share/zoneinfo/$continent)" --scrolltext 20 60 3>&1 1>&2 2>&3)
ln -sf /usr/share/zoneinfo/$continent/$city /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

hostName=$(whiptail --title "Hostname" --inputbox "Please give me the name for this machine" 8 78 3>&1 1>&2 2>&3)

echo "$hostName" >> /etc/hostname

systemctl enable NetworkManager.service

rootPasswd=$(whiptail --title "User password"  --passwordbox "Please input a password for the root account" 8 78 3>&1 1>&2 2>&3)

echo "root:$rootPasswd" | chpasswd

userName=$(whiptail --title "New user" --inputbox "Please give me the name for the new user you'd like to add" 8 78 3>&1 1>&2 2>&3)
userPasswd=$(whiptail --title "User password"  --passwordbox "Please input a password for your newly created user" 8 78 3>&1 1>&2 2>&3)

useradd --create-home "$userName"
usermod -a -G wheel "$userName"
chsh -s /bin/zsh "$userName"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
echo "$userName:$userPasswd" | chpasswd

whiptail --title "Setup time" --msgbox "We will now setup all the packages, config files and even xorg for you, the computer will automatically reboot after this so make sure to pay attention incase it bootloops" 8 78

sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf

cp ./aur.txt /home/$userName/

# Downloading all necessary files
runuser -l $userName -c "git clone https://git.codingvm.codes/emily/dotfiles && git clone https://aur.archlinux.org/yay && git clone https://git.liveemily.xyz/Emily/dwm-pkgbuild.git && git clone https://github.com/LukeSmithxyz/st && curl https://liveemily.xyz/archieinstall/wallpaper.png --output ~/wallpaper.png"
# Setup config files
runuser -l $userName -c "mkdir ~/.config && mv dotfiles/nvim dotfiles/zsh dotfiles/shell ~/.config/ && mv dotfiles/.vimrc ~/ && touch ~/.zshrc && echo 'source ~/.config/zsh/.zshrc' >> ~/.zshrc"
# Install yay and all aur packages
runuser -l $userName -c "cd yay && makepkg -si --noconfirm && cd .. && yay -S --noconfirm - < aur.txt"
# Install window manager
runuser -l $userName -c "cd dwm-pkgbuild && makepkg -si --noconfirm --skipchecksums && touch ~/.xinitrc && echo '/etc/dwm/autostart' >> ~/.xinitrc && cd ../st && sudo make install"

# Cleanup time
runuser -l $userName -c "rm -rf ~/dotfiles && rm -rf ~/yay && rm -rf ~/dwm-pkgbuild && rm -rf ~/st && rm -rf ~/.cache/* && rm -rf /tmp/* && rm -rf ~/aur.txt"
runuser -l $userName -c "yay -Scc --noconfirm"
sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

if [[ -d "/sys/firmware/efi" ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
	grub-install --target=i386-pc /dev/"$1"
fi

grub-mkconfig -o /boot/grub/grub.cfg

whiptail --title "Finished!" --msgbox "Phew that was quite some time, but everything should be finished now. Your computer will now reboot and you should be able to login with your username and password. Afterwards please type in the command 'startx' and press enter to get into your new system!" 8 78

rm -rf aur.txt

exit 0