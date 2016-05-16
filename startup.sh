#!/bin/bash

ip route change default via 172.17.42.254

# uncomment to update seed - when d/l complete, shell in and rsync /server/* and /root/steamcmd/* to host /seed/$type/{game,steamcmd}
# if [ -z "${STEAM_USER}" ]; then CREDENTIALS="anonymous"; else CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi
# /root/steamcmd/steamcmd.sh +login $CREDENTIALS +force_install_dir /server +app_update 294420 validate +quit
# pause && exit

if [ "$( find /server/ -type f | wc -l )" -lt "1" ]
then
  echo "copying seed across... this may take some time depending on the game size"
  rm -Rf /server/* /root/steamcmd/*
  #cp -Rf /seed/${CONTAINER_TYPE}/game/* /server/ # change to hard/soft links
  #cp -Rf /seed/${CONTAINER_TYPE}/steamcmd/* /root/steamcmd/ # change to hard/soft links
fi

if [ -z "${STEAM_USER}" ]; then CREDENTIALS="anonymous"; else CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi
/root/steamcmd/steamcmd.sh +login $CREDENTIALS +force_install_dir /server +app_update 294420 validate +quit

pause

sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

ulimit -n 2048 && cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
