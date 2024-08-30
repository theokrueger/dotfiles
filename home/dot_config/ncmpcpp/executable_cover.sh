#!/bin/bash
cd "$(dirname $0)"
if [ ! -f /tmp/cover_path ]; then
  ./cover_obs.sh
fi


INFILE="/tmp/cover_path"
function add_cover {
  echo '{"action": "add", "identifier": "cover","x": 3, "y": 1, "max_width": 25, "max_height": 25, "path":"'$(cat $INFILE)'"}'
}

ueberzugpp layer -o wayland 0< <(
  add_cover
  while inotifywait -q -q -e close_write "$INFILE"; do
    if [[ $(hyprctl activewindow | grep Alacritty) != '' ]]; then
        add_cover
    fi;
  done
)
