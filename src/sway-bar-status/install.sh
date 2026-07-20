#!/usr/bin/env bash
cd "$(dirname "$0")"
EXEC_NAME="sway-bar-status"
OUT_DIR="$HOME/.config/sway/scripts/"
OUT_F="$OUT_DIR/$EXEC_NAME"

killall "$EXEC_NAME"
cargo build --release &&
  mkdir -p "$OUT_DIR" &&
  cp "./target/release/$EXEC_NAME" "$OUT_F" &&
  chmod +x "$OUT_F" &&
  echo "Successfully installed $EXEC_NAME" ||
  exit 1
