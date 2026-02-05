FROM --platform=$TARGETOS/$TARGETARCH debian:bullseye-slim

LABEL author="Isaac A." maintainer="isaac@isaacs.site"
LABEL org.opencontainers.image.source="https://github.com/pterodactyl/yolks"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    iproute2 \
    tzdata \
    lib32gcc-s1 \
    lib32stdc++6 \
    libgdiplus \
    libsdl2-2.0-0:i386 \
    nodejs \
    node-ws \
 && useradd -d /home/container -m container \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
COPY ./wrapper.js /wrapper.js

CMD ["/bin/bash", "/entrypoint.sh"]
