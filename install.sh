#!/bin/bash
# install script for dotfiles
cd "$(dirname "$0")"

# install required packages
chmod +x ./package_installers/*.sh
if [[ "$(which pacman)" != '' ]]; then
    # artix
    ./package_installers/pacman.sh
fi
if [[ "$(which cargo)" != '' ]]; then
    # rust
    ./package_installers/cargo.sh
fi
if [[ "$(which pip)" != '' ]]; then
    # pip
    ./package_installers/pip.sh
fi

# check if a path exists, then print some info
exists() {
    if [[ "$1" == '' ]]; then
        error "$2 installation not found!"
        if [[ "$3" != '' ]]; then
            echo "$3"
        fi
        exit
    fi
}

# tools for install
CHEZMOI="$(which chezmoi)"
exists "$CHEZMOI" "chezmoi"
FLATPAK="$(which flatpak)"
exists "$FLATPAK" "flatpak"
WGET="$(which wget)"
exists "$WGET" "wget"
GSETTINGS="$(which gsettings)"
exists "$GSETTINGS" "gsettings" "Please ensure your system has GTK3 support"

# aliases
CP="cp --reflink=auto --verbose"

# install adw-gtk3
if [[ -d "$HOME/.local/share/themes/adw-gtk3" ]] || [[ -d "/usr/share/themes/adw-gtk3" ]]; then
    echo "adw-gtk3 is installed!"
else
    echo "Installing adw-gtk3..."
    mkdir -p "$HOME/.local/share/themes"

    ARCHIVE="/tmp/adw-gtk3.tar.xz"
    wget "https://github.com/lassekongo83/adw-gtk3/releases/download/v5.3/adw-gtk3v5.3.tar.xz" -O "$ARCHIVE"
    tar -xf "$ARCHIVE" --directory "$HOME/.local/share/themes/"

    "$GSETTINGS" set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    "$GSETTINGS" set org.gnome.desktop.interface color-scheme 'default'
fi

# install adw-gtk3 via flatpak
if [[ "$("$FLATPAK" list | grep org.gtk.Gtk3theme.adw-gtk3)" !=  "" ]]; then
    echo "adw-gtk flatpak is installed!"
else
    echo "Installing adw-gtk3 flatpak..."
    flatpak install --assumeyes org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
fi

# apply chezmoi cfg
CHEZMOI_CFG_FILE="$HOME/.config/chezmoi/chezmoi.yaml"
if [[ -f "$CHEZMOI_CFG_FILE" ]]; then
    echo "chezmoi config file exists!"
else
    echo "chezmoi config file does not exist, copying it over..."
    mkdir -p ~/.config/chezmoi/
    cat "./home/private_dot_config/chezmoi/chezmoi.yaml.tmpl" | chezmoi execute-template > "$HOME/.config/chezmoi/chezmoi.yaml"
fi
"$CHEZMOI" apply

# copy appropriate assets
WALLPAPER="./assets/wallpapers/"
WALLPAPER_OUT="$HOME/.config/sway/bg.png"
LOCKSCREEN="./assets/lockscreens/"
LOCKSCREEN_OUT="$HOME/.config/sway/lock.png"
case "$HOSTNAME" in
    'gen2desk')
        LOCKSCREEN+="pneguin_lockscreen_(1920x1080).png"
        WALLPAPER+="gen2desk_pink_(1920x1080).png"
        ;;
    'thonkpad')
        LOCKSCREEN+="pneguin_lockscreen_(1280x800).png"
        WALLPAPER+="thonkpad_pink_(1280x800).png"
        ;;
    'linsuslap')
        LOCKSCREEN+="pneguin_lockscreen_(1920x1080).png"
        WALLPAPER+="linsuslap_pink_(1920x1080).png"
        ;;
    *)
        ;;
esac

echo "Copying over assets..."
if [[ -f "$LOCKSCREEN" ]]; then
    $CP "$LOCKSCREEN" "$LOCKSCREEN_OUT"
fi
if [[ -f "$WALLPAPER" ]]; then
    $CP "$WALLPAPER" "$WALLPAPER_OUT"
fi

echo "Please manually update files in etc folder"
