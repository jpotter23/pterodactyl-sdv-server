#!/bin/bash
Xvfb :10 -screen 0 ${RESOLUTION-1200x800x24} -ac -nolisten tcp -nolisten unix &

printf "Waiting for X display ..."
while [ ! -z "`xdpyinfo -display :10 2>&1 | grep 'unable to open display'`" ]; do sleep 1; printf "."; done
echo "done!"

echo "Checking & Securing VNC Config ..."
PORT=${VNC_PORT-$((5900 + $RANDOM % 99))}
PASS=${VNC_PASS-$(pwgen -1)}
echo -e "VNC PORT: $PORT\nVNC PASS: $PASS"

export DISPLAY=:10.0
DESKTOP_NAME=${DESKTOP_NAME-StardewValley}
echo "Launching x11vnc Desktop:$DESKTOP_NAME on DISPLAY$DISPLAY ..."
x11vnc -display :10 \
        -rfbport $PORT \
        -noxdamage \
        -rfbportv6 \
        -1 \
        -no6 \
        -noipv6 \
        -httpportv6 \
        -1 \
        -forever \
        -ncache 10 \
        -desktop $DESKTOP_NAME \
        -cursor arrow \
        -passwd $PASS \
        -shared & 
sleep 5
echo "Launching i3 ..."; i3 &
export XAUTHORITY=~/.Xauthority; echo "Set XAUTHORITY=$XAUTHORITY ..."
TERM=xterm; echo "Set TERM=$TERM"
echo "Launcing Game: ./StardewValley"
./StardewValley
