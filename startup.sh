#!/bin/bash

ip route change default via 172.17.42.254

function _shutdown() {
  echo "Shutting down gracefully.."
  { echo "saveworld"; sleep 1; echo "shutdown"; sleep 1; } | telnet 127.0.0.1 8081
}
trap _shutdown SIGTERM SIGINT

LD_LIBRARY_PATH=/home/steam/app/ /home/steam/app/7DaysToDieServer.x86_64 -logfile /dev/stdout -configfile=/home/steam/app/serverconfig.xml -quit -batchmode -nographics -dedicated
