#!/bin/bash

# 变量
container_data="/vol1/1000/Docker/navidrome"

sudo mkdir -p $container_data

compose=$(cat <<'EOF'
# docker-compose.yml
version: "3"
services:
  navidrome:
    container_name: navidrome
    image: deluan/navidrome:latest
    ports:
      - "4533:4533"
    restart: always
    environment:
      ND_ENABLETRANSCODINGCONFIG: true
      ND_TRANSCODINGCACHESIZE: 0
      ND_SCANSCHEDULE: 1h
      ND_LOGLEVEL: info  
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: ""
    volumes:
      - "/vol1/1000/Docker/navidrome/data:/data"
      - "/vol1/1000/Music:/music:ro"
  
  music-tag:
    image: xhongc/music_tag_web:latest
    container_name: music-tag-web
    ports:
      - "8001:8001"                                    #端口号改成喜欢的
    volumes:
      - "/vol1/1000/Docker/music-tag/data:/app/data"    #docker路径，创建好目录文件照搬即可
      - "/vol1/1000/Music:/app/media:rw"     #改，"曲库目录:/app/media:rw"
    command: /start
    restart: always
EOF
)

# docker-compose
sudo cat <<EOF > $container_data/docker-compose.yml
$compose
EOF

cd $container_data
sudo docker-compose up -d

