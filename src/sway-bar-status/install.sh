#!/bin/bash
# build and install sway executable statusbar
cd "$(dirname "$0")"
EXEC_NAME="sway-bar-status"
OUT_DIR="$HOME/.config/sway/scripts/"

killall "$EXEC_NAME"
cargo build --release &&
  mkdir -p "$OUT_DIR" &&
  cp "./target/release/$EXEC_NAME" "$OUT_DIR$EXEC_NAME" &&
  chmod +x "$OUT_DIR$EXEC_NAME" &&
  rm -r "./target/" &&
  echo "Successfully installed $EXEC_NAME" ||
  echo "Failed to install $EXEC_NAME!"
