#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -qy iproute2 
apt-get install -qy apt-utils ca-certificates lib32gcc1 net-tools lib32stdc++6 lib32z1 lib32z1-dev curl telnet
apt-get clean && rm -Rf /var/lib/apt/lists/*

useradd steam
mkdir -p /home/steam/app /home/steam/steamcmd
chown -R steam:steam /home/steam

mkdir -p /home/steam/steamcmd/
curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/home/steam/steamcmd/"

/home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/app +app_update 294420 +quit

apt-get clean && rm -Rf /var/lib/apt/lists/*
