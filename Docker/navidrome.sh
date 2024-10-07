#!/bin/bash

# 变量
container_data="/vol1/1000/Docker/navidrome"

sudo mkdir -p $container_data

compose=$(cat <<'EOF'
# docker-compose.yml
version: "3"
services:
  navidrome:
    image: deluan/navidrome:develop
    ports:
      - "4533:4533"
    restart: always
    environment:
      ND_SCANSCHEDULE: 0
      ND_LOGLEVEL: info
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: "/nav"
      ND_PLAYLISTSPATH: "."
      ND_LASTFM_LANGUAGE: "zh"
      ND_LASTFM_APIKEY: "lastfm_apikey"
      ND_LASTFM_SECRET: "lastfm_secret"
      ND_SPOTIFY_ID: "spotify_id"
      ND_SPOTIFY_SECRET: "spotify_secret"
      ND_ENABLEARTWORKPRECACHE: "false"
      ND_ENABLESHARING: "true"
    volumes:
      - "/vol1/1000/Docker/navidrome/data:/data"
      - "/vol1/1000/Docker/navidrome/music:/music:ro"

EOF
)

# docker-compose
sudo cat <<EOF > $container_data/docker-compose.yml
$compose
EOF

cd $container_data
sudo docker-compose up -d

