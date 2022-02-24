<h1 align="center">Arch(ie) Linux Install Script!</h1>
<p>
  <img alt="Version" src="https://img.shields.io/badge/Version-1.0-ff69b4" />
  <a href="https://github.com/liveemily/ArchieInstall/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/liveemily/ArchieInstall"/>
  </a>
  <a href="https://twitter.com/LiveEmilyHere" target="_blank">
    <img alt="Twitter: LiveEmilyHere" src="https://img.shields.io/twitter/follow/LiveEmilyHere.svg?style=social" />
  </a>
  <a href="https://ko-fi.com/liveemily">
    <img src="https://www.ko-fi.com/img/githubbutton_sm.svg" />
  </a>
</p>

> The Arch(ie) Linux install script is a fully manually written install script for a barebones Arch ISO so you can get up and running with my (sorta) custom Arch rice!
<br>
This install will include a window manager (DWM), terminal emulator (ST), application menu (dmenu) and a custom DWM status bar.
<br>
For audio this currently ships with PulseAudio and Pavucontrol, I am working on introducing Jack but to be honest, I have no clue how it works haha.

***

## Screenshots of the rice

### Booting into DWM
<img src="https://liveemily.xyz/archieinstall/rice1.png">

### Playing music while browsing Gitea
<img src="https://liveemily.xyz/archieinstall/rice2.png">

***

### On average this will install a total of 5GB of data, I recommend at least a 10GB drive, both SATA and NVME are supported out of the box with swap and a seperate home partition.

## Install Archie Linux from GitHub

```sh
curl -LO https://raw.githubusercontent.com/LiveEmily/ArchieInstall/main/install.sh && sh ./install.sh
```

## Install Archie Linux from liveemily.xyz

```sh
curl -LO https://liveemily.xyz/archieinstall/install.sh && sh ./install.sh
```

***

## List of packages
You could take a look at https://github.com/liveemily/archieinstall/blob/master/pkglist.txt, but let's be honest, who will actually do that.
<br>
>autoconf automake base binutils bison brave-bin curl dmenu dosfstools dunst dwm efibootmgr fakeroot feh file findutils flex gawk gcc gettext git grep groff grub gzip htop jack2 jack2-dbus libtool linux linux-firmware linux-headers m4 make neofetch neovim nerd-fonts-mononoki networkmanager nodejs pacman patch pavucontrol picom pkgconf pulseaudio-jack python qjackctl rofi sed sudo texinfo ttf-joypixels ttf-material-design-icons wget which xclip xf86-video-vesa xorg-bdftopcf xorg-docs xorg-font-util xorg-fonts-100dpi xorg-fonts-75dpi xorg-fonts-encodings xorg-iceauth xorg-mkfontscale xorg-server xorg-server-common xorg-server-devel xorg-server-xephyr xorg-server-xnest xorg-server-xvfb xorg-sessreg xorg-setxkbmap xorg-smproxy xorg-x11perf xorg-xauth xorg-xbacklight xorg-xcmsdb xorg-xcursorgen xorg-xdpyinfo xorg-xdriinfo xorg-xev xorg-xgamma xorg-xhost xorg-xinit xorg-xinput xorg-xkbcomp xorg-xkbevd xorg-xkbutils xorg-xkill xorg-xlsatoms xorg-xlsclients xorg-xmodmap xorg-xpr xorg-xprop xorg-xrandr xorg-xrdb xorg-xrefresh xorg-xset xorg-xsetroot xorg-xvinfo xorg-xwayland xorg-xwd xorg-xwininfo xorg-xwud yay zsh

***

## Contributing

To contribute to this project, please open an issue or PR first before anything. I hand review every issue and PR so I might not reply instantly.

Further instructions will be provided on a later date, for now just make sure you create an issue and/or fork and make a pull request.

## Author

👤 **Emily**

* Website: https://git.liveemily.xyz
* Twitter: [@LiveEmilyHere](https://twitter.com/LiveEmilyHere)
* Github: [@LiveEmily](https://github.com/LiveEmily)

## Show your support

Give a ⭐️ if this project helped you!

***
