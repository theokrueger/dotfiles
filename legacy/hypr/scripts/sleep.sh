#!/bin/sh

cd "$(dirname "$0")"
swayidle \
	timeout 120 './lock.sh' \
	timeout 240 'hyprctl dispatch dpms off' \
		resume 'hyprctl dispatch dpms on'
