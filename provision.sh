#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "Europe/London" > /etc/timezone && dpkg-reconfigure tzdata
apt-get update && apt-get install -qy iproute2 

apt-get install -qy aufs-tools apt-utils ca-certificates lib32gcc1 net-tools lib32stdc++6 lib32z1 lib32z1-dev curl
apt-get install -qy telnet

apt-get clean && rm -Rf /var/lib/apt/lists/*
