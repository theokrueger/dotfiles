#!/bin/bash
cd "$(dirname $0)"
echo "Fixing macbook speaker volume"
pactl remove-sample blank_audio
pactl upload-sample ./blank_audio.ogg
sleep 1
pactl play-sample blank_audio
sleep 1
pactl set-sink-volume @DEFAULT_SINK@ 0%
echo "Finished fixing macbook speaker volume"
