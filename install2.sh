#!/usr/bin/env /usr/bin/bash

echo "vm.swappiness=1" >> /etc/sysctl.d/99-swappiness.conf

systemctl enable NetworkManager.service

continent=$(whiptail --title "Timezone" --inputbox "Please give me the continent for your timezone e.g. Europe\nCAPS MATTERS" 10 60 3>&1 1>&2 2>&3)
city=$(whiptail --title "City" --inputbox "Please give me the city for your timezone e.g. Amsterdam\nCAPS MATTERS" 10 60 3>&1 1>&2 2>&3)

ln -sf /usr/share/zoneinfo/$continent/$city /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

hostName=$(whiptail --title "Hostname" --inputbox "Please give me the name for this machine" 10 60 3>&1 1>&2 2>&3)

echo "$hostName" >> /etc/hostname

rootPasswd=$(whiptail --title "Root password" --msgbox "You will now be asked to input a password for the root account" 10 60 3>&1 1>&2 2>&3)

passwd root

userName=$(whiptail --title "New user" --inputbox "Please give me the name for the new user you'd like to add" 10 60 3>&1 1>&2 2>&3)
userPasswd=$(whiptail --title "User password" --msgbox "You will now be asked to input a password for your newly created user" 10 60 3>&1 1>&2 2>&3)

useradd --create-home "$userName"
usermod -a -G wheel "$userName"
chsh -s /bin/zsh "$userName"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
passwd "$userName"

whiptail --title "Setup time" --msgbox "We will now setup all the packages, config files and even xorg for you, the computer will automatically reboot after this so make sure to pay attention incase it bootloops" 10 60

runuser -l $userName -c "git clone https://git.codingvm.codes/emily/dotfiles && mkdir ~/.config && mv dotfiles/nvim dotfiles/zsh dotfiles/shell ~/.config/ && touch ~/.zshrc && echo 'source ~/.config/zsh/.zshrc' >> ~/.zshrc && rm -rf dotfiles"
# New line for readability
sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers
runuser -l $userName -c "git clone https://aur.archlinux.org/yay && cd yay && makepkg -si --noconfirm && cd .. && sudo rm -rf yay && yay -S --noconfirm nerd-fonts-mononoki ttf-material-design-icons brave-bin pcmanfm-qt"
runuser -l $userName -c "git clone https://git.liveemily.xyz/Emily/dwm-pkgbuild.git && cd dwm-pkgbuild && makepkg -si --noconfirm --skipchecksums && cd .. && sudo rm -rf dwm-pkgbuild && touch ~/.xinitrc && echo '/etc/dwm/autostart' >> ~/.xinitrc"
runuser -l $userName -c "git clone https://github.com/LukeSmithxyz/st && cd st && sudo make install && cd .. && sudo rm -rf st"
runuser -l $userName -c "curl https://liveemily.xyz/archieinstall/wallpaper.png --output ~/wallpaper.png"
sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers

disk=$(whiptail --title "Storage devices" --inputbox "As this is now running on a different script, we would kindly like to ask for you to input your drive again as you have last time\n\n\n$(lsblk -e7 -e11)" 40 80 3>&1 1>&2 2>&3)

if [[ -d "/sys/firmware/efi" ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
	grub-install --target=i386-pc /dev/"$disk"
fi

grub-mkconfig -o /boot/grub/grub.cfg

whiptail --title "Finished!" --msgbox "Phew that was quite some time, but everything should be finished now. Your computer will now reboot and you should be able to login with your username and password. Afterwards please type in the command 'startx' and press enter to get into your new system!" 10 60

exit 0
