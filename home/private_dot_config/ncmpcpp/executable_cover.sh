#!/bin/bash
cd "$(dirname $0)"
if [ ! -f /tmp/cover_path ]; then
  ./cover_obs.sh
fi


INFILE="/tmp/cover_path"
function add_cover {
  echo '{"action": "add", "identifier": "cover","x": 2, "y": 0, "max_width": 25, "max_height": 13, "path":"'$(cat $INFILE)'"}'
}

# TODO this is a hack
function add_cover_if_applicable {
  if [[ $(swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.focused==true) | .app_id') == '"Alacritty"' ]]; then
    add_cover
  fi
}

ueberzugpp layer -o wayland 0< <(
  add_cover
  while inotifywait -q -q -e close_write "$INFILE"; do
    add_cover_if_applicable
  done
)
