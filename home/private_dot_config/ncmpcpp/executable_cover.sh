#!/bin/bash
cd "$(dirname $0)"
if [ ! -f /tmp/cover_path ]; then
  ./cover_obs.sh
fi


INFILE="/tmp/cover_path"
function add_cf_cover() {
    echo '{"action": "add", "identifier": "cover","x": 1, "y": 1, "max_width": 30, "max_height": 15, "path":"'$(cat $INFILE)'"}'
}

function add_wl_cover() {
    echo '{"action": "add", "identifier": "cover","x": 2, "y": 0, "scaler": "fit_contain", "max_width": 28, "max_height": 14, "path":"'$(cat $INFILE)'"}'
}

function remove_cover() {
  echo '{"action": "remove", "identifier": "cover"}'
}

# TODO this is a hack
function add_cover() {
  if [[ $(swaymsg -t get_tree | jq '.. | (.nodes? // empty)[] | select(.focused==true) | .app_id') == '"Alacritty"' ]]; then
    if [[ "$1" == "wayland" ]]; then
      add_wl_cover
    elif [[ "$1" == "chafa" ]]; then
      remove_cover
    fi
  else
    if [[ "$1" == "wayland" ]]; then
      remove_cover
    elif [[ "$1" == "chafa" ]]; then
      add_cf_cover
    fi
  fi
}

ueberzugpp layer -o chafa 0< <(
  add_cover 'chafa'
  while inotifywait -q -q -e close_write "$INFILE"; do
    add_cover 'chafa'
  done
) &

ueberzugpp layer -o wayland 0< <(
  add_cover 'wayland'
  while inotifywait -q -q -e close_write "$INFILE"; do
    add_cover 'wayland'
  done
)
