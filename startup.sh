#!/bin/bash

read -p "pausing..." && exit

if [ -f /overlay/.pause ]; then read -p "pausing..."; fi

STEAM_APP_ID=294420

ip route change default via 172.17.42.254
if [ -z "${STEAM_USER}" ]; then STEAM_CREDENTIALS="anonymous"; else STEAM_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi

if [ -f /overlay/.seed ] || [ -f /seed/${CONTAINER_TYPE}/seed ]
then
  mkdir /root/steamcmd && curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/root/steamcmd/"
  /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit
  apt-get update && apt-get install -y rsync openssh-client && echo && echo "update complete, pausing..." && read && exit
else
  if [ ! -f /overlay/.provisioned ]; then mkdir -p /overlay/{data,work}/{root,server,root-steamcmd,root-steam} /server/ && touch /overlay/.provisioned; fi
  mount -t overlay overlay -o lowerdir=/seed/${CONTAINER_TYPE}/root,upperdir=/overlay/data/root,workdir=/overlay/work/root /root
  mount -t overlay overlay -o lowerdir=/seed/${CONTAINER_TYPE}/game,upperdir=/overlay/data/server,workdir=/overlay/work/server /server
  mkdir -p /root/steamcmd && mount -t overlay overlay -o lowerdir=/seed/${CONTAINER_TYPE}/root-steamcmd,upperdir=/overlay/data/root-steamcmd,workdir=/overlay/work/root-steamcmd /root/steamcmd
  mkdir -p /root/Steam && mount -t overlay overlay -o lowerdir=/seed/${CONTAINER_TYPE}/root-steam,upperdir=/overlay/data/root-steam,workdir=/overlay/work/root-steam /root/Steam
  
  /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit

  if [ ! -f /server/serveradmin.xml ]; then echo "" > /server/serveradmin.xml; fi
  sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
  sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

  function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

  ulimit -n 2048 && cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
fi
