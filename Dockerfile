FROM ubuntu:15.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
    iproute2 apt-utils ca-certificates lib32gcc1 net-tools lib32stdc++6 lib32z1 lib32z1-dev curl telnet
RUN apt-get clean && rm -Rf /var/lib/apt/lists/*

RUN useradd steam && \
    mkdir -p /home/steam/app && \
    mkdir -p /home/steam/steamcmd && \
    chown -R steam:steam /home/steam

ADD startup.sh /root/
RUN chmod +x /root/startup.sh

ENTRYPOINT [ "/root/startup.sh" ]

EXPOSE 26900-26902 26900-26902/udp
