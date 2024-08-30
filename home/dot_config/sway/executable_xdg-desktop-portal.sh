#!/bin/bash
# run xdg-deskop-portals
sleep 5
killall xdg-desktop-portal-hyprland
killall xdg-desktop-portal-gtk
killall xdg-desktop-portal-gnome
killall xdg-desktop-portal-wlr
killall xdg-desktop-portal
echo 'killed all xdg-desktop'
sleep 1
/usr/lib/xdg-desktop-portal-gtk &
echo 'xdg-desktop-portal-gtk started'
sleep 1
/usr/lib/xdg-desktop-portal-hyprland &
echo 'xdg-desktop-portal-hyprland started'
sleep 2
/usr/lib/xdg-desktop-portal &
echo 'xdg-desktop-portal started'
