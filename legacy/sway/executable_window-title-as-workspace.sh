#!/bin/bash
# automatically creates a workspace that subscribes to sway events and dynamically renames itself according to the currently focused windowc

# setup
swaymsg workspace "[titlebar]"
alacritty & sleep 0.5
ALACRITTY_PID=$!
swaymsg workspace 1

MAX_LENGTH=100
export SWAY_TITLEBAR_FILE="/tmp/sway_titlebar_title"
sway_set_bar_title_file() {
  echo "[$1]" > "$SWAY_TITLEBAR_FILE"
}
export -f sway_set_bar_title_file

# monitor for changes
swaymsg --type subscribe --monitor '["window"]' |
    stdbuf -oL jq '.container.name' |
    stdbuf -oL cut -c 1-$MAX_LENGTH |
    stdbuf -oL tr -d ",\"'" |
    stdbuf -oL sed "s/^/\"/" |
    stdbuf -oL sed 's/$/"/' |
    stdbuf -oL xargs -L 1 /bin/bash -c 'sway_set_bar_title_file "$@"' ''_'' &

SWAYMSG_PID=$!

on_interrupt() {
  echo "interrupted!"
  kill $SWAYMSG_PID
  kill $ALACRITTY_PID
}
trap "on_interrupt" INT
trap "on_interrupt" TERM

# change title on file change
last_title="[titlebar]"
while inotifywait -q -q "$SWAY_TITLEBAR_FILE"; do
    title=$(cat "$SWAY_TITLEBAR_FILE")
    swaymsg rename workspace "$last_title" to "$title"
    last_title="$title"
done

