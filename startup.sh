#!/bin/bash

if [ -f /overlay/.pause ]; then read -p "pausing..."; fi

STEAM_APP_ID=294420

ip route change default via 172.17.42.254
if [ -z "${STEAM_USER}" ]; then STEAM_CREDENTIALS="anonymous"; else STEAM_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi

if [ -f /overlay/.seed ] || [ -f /seed/${CONTAINER_TYPE}/seed ]
then
  tar -cf /overlay/root.tar /root && mkdir /root/steamcmd && curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/root/steamcmd/"
  while [ "$( find /server/ -type f | wc -l )" -lt 1 ]; do /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit; done
  tar -cf /overlay/root-steamcmd.tar /root/steamcmd && tar -cf /overlay/root-steam.tar /root/Steam && echo "seed generation complete, pausing..." && read && exit
else
  if [ ! -f /overlay/.provisioned ]; then mkdir -p /overlay/{root,server,root-steamcmd,root-steam} /server/ && touch /overlay/.provisioned; fi
  mount -t aufs -o noxino -o br=/overlay/root=rw:/seed/${CONTAINER_TYPE}/root=ro none /root
  mount -t aufs -o noxino -o br=/overlay/server=rw:/seed/${CONTAINER_TYPE}/game=ro none /server
  mkdir -p /root/steamcmd && mount -t aufs -o noxino -o br=/overlay/root-steamcmd=rw:/seed/${CONTAINER_TYPE}/root-steamcmd=ro none /root/steamcmd
  mkdir -p /root/Steam && mount -t aufs -o noxino -o br=/overlay/root-steam=rw:/seed/${CONTAINER_TYPE}/root-steam=ro none /root/Steam
  
  /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit

  if [ ! -f /server/serveradmin.xml ]; then ln -s /root/.local/share/7DaysToDie/Saves/serveradmin.xml /server/serveradmin.xml; fi
  sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
  sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

  function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

  ulimit -n 2048 && cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
fi
