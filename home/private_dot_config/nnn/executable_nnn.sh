#!/bin/bash
# launch nnn with settings
PLUG_DOWNLOADED_FILE="$HOME/.config/nnn/plugins-update"
if ! [[ -e "$PLUG_DOWNLOADED_FILE" ]]; then
  echo "Downloading Plugins"
  sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"
  touch "$PLUG_DOWNLOADED_FILE"
fi

export NNN_TRASH=1
export NNN_COLORS="2136"
export NNN_OPTS="adEx"
export NNN_PLUG="g:preview-tui;c:rsynccp"
export NNN_TERMINAL="alacritty"
nnn
