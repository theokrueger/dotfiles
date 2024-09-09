#!/bin/bash
m2i --config ./config.lua --script ./akaimpkmini2.lua &

sleep 2; aconnect 'MPKmini2' 'midi2input_alsa'

read

killall m2i
