#!/usr/bin/env bash
# install script for dotfiles
cd "$(dirname "$0")" || exit 1

SKIP=false
for arg in "$@"; do
    case $arg in
        "--skip" )
	    echo "Skipping installation steps"
            SKIP=true;;
        *) echo >&2 "Invalid option: $arg"; exit 1;;
    esac
done

# install required packages
if [[ "$SKIP" != true ]]; then
    ./package_installers/*.sh
fi

# check if a path exists, then print some info
exists() {
    if [[ "$1" == '' ]]; then
        echo >&2 "$2 installation not found!"
        if [[ "$3" != '' ]]; then
            echo "$3"
        fi
        exit 1
    fi
}

# tools for install
CHEZMOI="$(command -v chezmoi)"
exists "$CHEZMOI" "chezmoi"
FLATPAK="$(command -v flatpak)"
exists "$FLATPAK" "flatpak"
WGET="$(command -v wget)"
exists "$WGET" "wget"
GSETTINGS="$(command -v gsettings)"
exists "$GSETTINGS" "gsettings" "Please ensure your system has GTK3 support"

# install
if [[ "$SKIP" != true ]]; then
    # ensure flathub is added
    flatpak remote-add --if-not-exists --user flathub "https://dl.flathub.org/repo/flathub.flatpakrepo"

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
fi

# apply chezmoi cfg
CHEZMOI_CFG_FILE="$HOME/.config/chezmoi/chezmoi.yaml"
mkdir -p ~/.config/chezmoi/
echo "sourceDir: $PWD" > "$CHEZMOI_CFG_FILE"
cat "./home/private_dot_config/chezmoi/chezmoi.yaml.tmpl" | chezmoi execute-template > "$CHEZMOI_CFG_FILE"
"$CHEZMOI" apply

echo "Please manually update files in etc folder"
