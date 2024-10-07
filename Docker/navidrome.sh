#!/bin/bash

# 变量
docker_data="/vol1/1000/Docker"
container="navidrome"

sudo mkdir -p $docker_data/$container

compose=$(cat <<'EOF'
# docker-compose.yml
version: "3"
services:
  navidrome:
    image: deluan/navidrome:develop
    ports:
      - "14533:4533"
    restart: unless-stopped
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
sudo cat <<EOF > $docker_data/$container/docker-compose.yml
$compose
EOF

cd $docker_data/$container
sudo docker-compose up -d

