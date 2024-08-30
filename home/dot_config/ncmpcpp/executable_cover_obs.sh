#!/bin/bash

# path to current song
folder="$HOME/backups/mosic/$(dirname "$(mpc --format %file% current)")"
# search for cover image
art="$(find "$folder" -maxdepth 1 | grep -i -m 1 "\(cover\|folder\)\.\(jpg\|png\|gif\|bmp\|jpeg\)")"
if [ "$art" = "" ]; then
    art="$HOME/.config/ncmpcpp/default_cover.jpg" # default
fi

# put location in a file
echo "$art" > /tmp/cover_path
