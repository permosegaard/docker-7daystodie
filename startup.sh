#!/bin/bash

ip route change default via 172.17.42.254

sed -i "s%^  <property name=\"ServerPort\" 				value=\"[0-9]{0,5}\"/>%  <property name=\"ServerPort\" 				value=\"${PORT_26900}\"/>%" /server/serverconfig.xml

function _shutdown() {
  echo "Shutting down gracefully.."
  { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081
}
trap _shutdown SIGTERM SIGINT

cd /server/ && ./7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=./serverconfig.xml -quit -batchmode -nographics -dedicated
