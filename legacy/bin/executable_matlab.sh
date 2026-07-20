#!/bin/bash
# set correct env vars and run MATLAB

MATLAB_EXECUTABLE="$HOME/.local/share/matlab/bin/matlab"

AWT_TOOLKIT=MToolkit \
_JAVA_AWT_WM_NONREPARENTING=1 \
QT_QPA_PLATFORM=xcb \
Exec=env \
LD_PRELOAD="/usr/lib/libfreetype.so.6 /lib64/libstdc++.so" \
"$MATLAB_EXECUTABLE"

echo "Press Enter to kill MATLAB and MathWorksServiceHost"
read
echo "Confirm? (Enter)"
killall "$MATLAB_EXECUTABLE"
killall MathWorksServiceHost
