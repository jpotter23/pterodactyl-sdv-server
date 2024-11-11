#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server
# Image to install with is 'mono:latest'
apt-get -y update
apt-get -y upgrade

## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    echo "Steam Usert is not set, but is required!"
    echo "ERROR: A Steam account that owns Stardew Valley is required for this server to work."
    exit 1
fi
echo -e "Steam user set to ${STEAM_USER}"
if [ "${STEAM_PASS}" == "" ]; then
    echo "Steam Password is not set, but is required!"
    echo "ERROR: A Steam account that owns Stardew Valley is required for this server to work."
    exit 1
fi

if [ "${VNC_PASS}" == "" ]; then
    export VNC_PASS=$(pwgen -1)
    echo "VNC Password is not set, a random password will be generated!"
fi

if [ "${VNC_PORT}" == "" ]; then
    echo "VNC Port is not set, a random port will be assigned!"
    export VNC_PORT=$((5900 + $RANDOM % 99))
fi

echo "Writing VNC Details to /home/container/VNC_INFO"
echo -e "VNC_PASS:$VNC_PASS\nVNC_PORT:$VNC_PORT\n" | tee /mnt/server/VNC_INFO

cd /tmp

mkdir -vp /mnt/server/steamcmd

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
chown -R root:root /mnt
export HOME=/mnt/server

## download and install steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

## install game using steamcmd
./steamcmd.sh +force_install_dir /mnt/server +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID-413150} validate +quit

## set up  libraries
mkdir -vp /mnt/server/.steam/sdk{32,64}
cp -v /mnt/server/steamdcmd/linux32/steamclient.so /mnt/server/.steam/sdk32/steamclient.so
cp -v /mnt/server/steamcmd/linux64/steamclient.so /mnt/server/.steam/sdk64/steamclient.so

## Game specific setup.
cd /mnt/server/
mkdir -vp .config .config/i3 .config/StardewValley ./nexus ./storage ./logs

## Stardew Valley specific setup.
wget https://github.com/Pathoschild/SMAPI/releases/download/4.0.8/SMAPI-4.0.8-installer.zip -qO /mnt/server/nexus.zip
unzip -q /mnt/server/nexus.zip -d /mnt/server/nexus/
export SMAPI_INSTALLER=$(find /mnt/server/nexus -regex '.*/linux/SMAPI.Installer')
export SMAPI_NO_TERMINAL=true SMAPI_USE_CURRENT_SHELL=true 
echo -e '2\n\n' | "$SMAPI_INSTALLER" --install --game-path "/mnt/server"

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/stardew_valley_server.config -qO ./.config/StardewValley/startup_preferences

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/i3.config -qO ./.config/i3/config

wget https://github.com/jpotter23/pterodactyl-sdv-server/raw/main/alwayson.zip -qO ./storage/alwayson.zip
unzip -q ./storage/alwayson.zip -d ./Mods

wget https://github.com/jpotter23/pterodactyl-sdv-server/raw/main/unlimitedplayers.zip -qO ./storage/unlimitedplayers.zip
unzip -q ./storage/unlimitedplayers.zip -d ./Mods

wget https://github.com/jpotter23/pterodactyl-sdv-server/raw/main/autoloadgame.zip -qO ./storage/autoloadgame.zip
unzip -q ./storage/autoloadgame.zip -d ./Mods

rm -fv ./storage/{alwayson,unlimitedplayers,autoloadgame,nexus}.zip

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/alwayson.json -qO ./Mods/Always On Server/config.json

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/unlimitedplayers.json -qO ./Mods/UnlimitedPlayers/config.json

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/autoloadgame.json -qO ./Mods/AutoLoadGame/config.json

wget https://raw.githubusercontent.com/jpotter23/pterodactyl-sdv-server/main/stardew-valley-server.sh -qO ./stardew-valley-server.sh
chmod +x ./stardew-valley-server.sh 

echo 'Stardew Valley Installation complete. Waiting for server restart...'
