#!/bin/bash
ps -x | grep -e "tmux.*ncmpcpp/tsession" | awk '{print $1}' | xargs kill
sleep .2
tmux new-session "tmux source-file ~/.config/ncmpcpp/tsession"
