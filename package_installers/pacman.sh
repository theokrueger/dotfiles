#!/bin/bash
# installer for basic pacman packages

PACKAGES=""
POST_INSTALL=""
echo "Performing full system upgrade..."
doas pacman -Syyu base-devel git

# install paru AUR helper
if [[ "$(which paru)" == '' ]]; then
    echo "Installing paru as AUR helper..."
    PREV_DIR="$PWD"
    cd "/tmp"
    git clone "https://aur.archlinux.org/paru.git"
    cd "./paru"
    makepkg -si
    cd "$PREV_DIR"
fi

# chezmoi (dotfiles manager, heart of this script)
PACKAGES+="chezmoi "

# flatpak (flatpak package installer)
PACKAGES+="flatpak flatpak-builder flatseal "
# flatpak already adds official repo as default

# system utils
PACKAGES+="wget "

# mako (notification daemon)
PACKAGES+="mako "

# mpd + ncmpcpp (music player)
PACKAGES+="mpc mpd ncmpcpp ueberzugpp tmux openslide "

# sway + extras (window manager)
PACKAGES+="sway swayidle swaylock swaybg autotiling jq \
               wlr-randr wlroots "

# dbus portals
PACKAGES+="xdg-desktop-portal xdg-desktop-portal-gtk \
               xdg-desktop-portal-hyprland xdg-desktop-portal-wlr \
               xwaylandvideobridge "

# printer support
PACKAGES+="cups cups-pdf "

# pipewire (audio support)
PACKAGES+="pipewire pipewire-pulse wireplumber pipewire-alsa "

# tofi (app runner)
PACKAGES+="tofi "

# alacritty (terminal)
PACKAGES+="alacritty "

# firefox-esr (web browser)
PACKAGES+="firefox-esr "

# element (messenger)
PACKAGES+="element-desktop "

# emacs (text editor)
PACKAGES+="emacs-wayland jansson "

# devtools
PACKAGES+="git-lfs rustup "
POST_INSTALL+="rustup toolchain install stable;"

# thunar (file manager)
PACKAGES+="thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman gvfs gvfs-mtp "

# gtk theme (colours yayyy!!)
PACKAGES+="adw-gtk-theme "

# bash completions (shell)
PACKAGES+="bash-completion "

# bashrc greetings
PACKAGES+="fortune-mod lolcat cowsay "

# adb (android debugging + file xfer)
PACKAGES+="adb android-bash-completion "

# keepassxc (password manager)
PACKAGES+="keepassxc "

# zeroconf
PACKAGES+="avahi nss-mdns "

# IME (fcitx)
PACKAGES+="fcitx-im "

# CAD (freecad, kicad, flatcam, autoleveller)
PACKAGES+="freecad \
  kicad kicad-library kicad-library-3d \
  flatcam-git \
  jre8-openjdk "

# misc utilities
PACKAGES+="fastfetch "

# openrc init daemon
openrc_post_install() {
    if [[ "$(which openrc)" == "" ]]; then
        echo "OpenRC not installed; skipping OpenRC setup"
        return
    fi

    OPENRC_PACKAGES=""
    declare -a OPENRC_SERVICES

    # printer support (openrc)
    OPENRC_PACKGES+="cups-openrc "
    OPENRC_SERVICES+=("cupsd default")

    # zeroconf
    OPENRC_PACKAGES+="avahi-openrc "
    OPENRC_SERVICE+=("avahi-daemon default")

    echo "Installing OpenRC Packages:"
    paru -S $OPENRC_PACKAGES

    for service in "${OPENRC_SERVICES[@]}"; do
        sudo rc-update add $service
    done
}

echo "Installing user packages:"
echo $PACKAGES
paru -S $PACKAGES
openrc_post_install
echo "Running Post Install Steps"
echo "$POST_INSTALL"
$POST_INSTALL
