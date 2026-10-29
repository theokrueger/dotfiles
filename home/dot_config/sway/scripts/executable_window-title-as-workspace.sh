#!/bin/bash
cd "$(dirname "$0")"
killall sway-window-title-as-workspace
sleep 0.2
./sway-window-title-as-workspace
