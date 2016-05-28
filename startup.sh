#!/bin/bash

if [ -f /overlay/.pause ]; then read -p "pausing..."; fi

STEAM_APP_ID=294420

ip route change default via 172.17.42.254
if [ -z "${STEAM_USER}" ]; then STEAM_CREDENTIALS="anonymous"; else STEAM_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi

if [ -f /overlay/.seed ] || [ -f /seed/${CONTAINER_TYPE}/seed ]
then
  ## shell in and rsync /server/* and /root/{Steam,steamcmd}/* to host /seed/$type/{game,steam,steamcmd}
  curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/root/steamcmd/"
  /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit
  apt-get update && apt-get install -y rsync openssh-client && echo && echo "update complete, pausing..." && read && exit
else
  if [ ! -f /overlay/.provisioned ]
  then
    mkdir -p /server /root/{steamcmd,Steam} /overlay/{data,mount}/{root,server,root-steamcmd,root-steam} && touch /overlay/.provisioned
  fi
  
  unionfs-fuse -o cow,nonempty /overlay/data/root=RW:/root=RO /overlay/mount/root && mount -o bind /overlay/mount/root /root
  unionfs-fuse -o cow,nonempty /overlay/data/server=RW:/seed/${CONTAINER_TYPE}/game=RO /overlay/mount/server && mount -o bind /overlay/mount/server /server
  unionfs-fuse -o cow,nonempty /overlay/data/root-steamcmd=RW:/seed/${CONTAINER_TYPE}/steamcmd=RO /overlay/mount/root-steamcmd && mount -o bind /overlay/mount/root-steamcmd /root/steamcmd
  unionfs-fuse -o cow,nonempty /overlay/data/root-steam=RW:/seed/${CONTAINER_TYPE}/steam=RO /overlay/mount/root-steam && mount -o bind /overlay/mount/root-steam /root/Steam
  
  /root/steamcmd/steamcmd.sh +login ${STEAM_CREDENTIALS} +force_install_dir /server +app_update ${STEAM_APP_ID} +quit

  if [ ! -f /server/serveradmin.xml ]; then echo "" > /server/serveradmin.xml; fi
  sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
  sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

  function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

  ulimit -n 2048 && cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
fi
