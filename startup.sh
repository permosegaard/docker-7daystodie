#!/bin/bash

ip route change default via 172.17.42.254

ulimit -n 2048

if [ "$( find /server/ -type f | wc -l )" -lt "1" ]; then echo "copying seed across..."; time cp -Ra /seed/${CONTAINER_TYPE}/ /server/; fi
/root/steamcmd/steamcmd.sh +login anonymous +force_install_dir /server +app_update 294420 validate +quit

sed -i "s%^  <property name=\"ServerPort\"[ \t]*value=\"[0-9]*\"/>%  <property name=\"ServerPort\" value=\"${PORT_26900}\"/>%" /server/serverconfig.xml
sed -i "s%^  <property name=\"ServerName\"[ \t]*value=\"My Game Host\"/>%  <property name=\"ServerName\" value=\"${CONTAINER_NAME}\"/>%" /server/serverconfig.xml

function _shutdown() { { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081; }; trap _shutdown SIGTERM SIGINT

cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
