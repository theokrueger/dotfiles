#!/bin/bash
# installer for basic pacman packages

    PACKAGES=""
    echo "Performing full system upgrade"
    doas pacman -Syyu base-devel git

    # install paru AUR helper
    if [[ "$(which paru)" == '' ]]; then
        echo "Installing paru as AUR helper"
        PREV_DIR="$PWD"
        cd "/tmp"
        git clone "https://aur.archlinux.org/paru.git"
        cd "./paru"
        makepkg -si
        cd "$PREV_DIR"
    fi

    # chezmoi (dotfiles manager, heart of this script)
    PACKAGES+="chezmoi "

    # mako (notification daemon)
    PACKAGES+="mako "

    # mpd + ncmpcpp (music player)
    PACKAGES+="mpc mpd ncmpcpp ueberzugpp tmux "

    # gradience (gtk3 theme customiser)
    PACKAGES+="gradience "

    # sway + extras (window manager
    PACKAGES+="sway swayidle swaylock swaybg autotiling \
               wlr-randr wlroots \
               xdg-desktop-portal xdg-desktop-portal-gtk \
               xdg-desktop-portal-hyprland xdg-desktop-portal-wlr "

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
    PACKAGES+="emacs "

    # devtools
    PACKAGES+="git-lfs rustup "

    # thunar (file manager)
    PACKAGES+="thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman gvfs gvfs-mtp "

    # bash completions (shell)
    PACKAGES+="bash-completion "

    # adb (android debugging + file xfer)
    PACKAGES+="adb android-bash-completion "

    # misc utilities
    PACKAGES+="fastfetch "

    echo "Installing user packages:"
    echo $PACKAGES
    paru -S $PACKAGES
