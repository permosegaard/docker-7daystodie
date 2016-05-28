#!/bin/bash

if [ -f /.pause ]; then read -p "pausing..."; fi

ip route change default via 172.17.42.254
if [ -z "${STEAM_USER}" ]; then STEAM_CREDENTIALS="anonymous"; else STEAM_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi

## start seed update section
## shell in and rsync /server/* and /root/{Steam,steamcmd}/* to host /seed/$type/{game,steam,steamcmd}
#curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/root/steamcmd/"
#/root/steamcmd/steamcmd.sh +login $STEAM_CREDENTIALS +force_install_dir /server +app_update 294420 +quit
#apt-get update && apt-get install -y rsync openssh-client && echo && echo "update complete, pausing..." && read && exit
## end seed update section

#if [ "$( find /server/ -type f | wc -l )" -lt "1" ]
#then
#  echo "copying seed across... this may take some time depending on the game size"
#  rm -Rf /server/* /root/Steam/* /root/steamcmd/*
#  cp -Rfs /seed/${CONTAINER_TYPE}/game/* /server/
#  cp -Rfs /seed/${CONTAINER_TYPE}/steamcmd/* /root/steamcmd/
#  cp -Rfs /seed/${CONTAINER_TYPE}/steam/* /root/Steam/
#  cp -f /seed/misc/libksm_preload.so /server/
#fi

unionfs-fuse -o cow,nonempty /overlay/server=RW:/seed/7d2d/game=RO /server
unionfs-fuse -o cow,nonempty /overlay/root/steamcmd=RW:/seed/7d2d/steamcmd=RO /root/steamcmd
unionfs-fuse -o cow,nonempty /overlay/root/Steam=RW:/seed/7d2d/steam=RO /root/Steam

/root/steamcmd/steamcmd.sh +login $STEAM_CREDENTIALS +force_install_dir /server +app_update 294420 +quit

if [ ! -f /server/serveradmin.xml ]; then echo "" > /server/serveradmin.xml; fi
sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

#ulimit -n 2048 && cd /server/ && LD_PRELOAD=/server/libksm_preload.so ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
ulimit -n 2048 && cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
