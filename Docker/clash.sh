#!/bin/bash

# 变量
docker_data="/vol1/1000/Docker"
container="clash"

sudo mkdir -p $docker_data/$container

compose=$(cat <<'EOF'
# docker-compose.yml
version: "3"

services:
  # Clash
  clash:
    image: laoyutang/clash-and-dashboard:latest
    container_name: clash
    volumes:
      - ./:/root/.config/clash
    ports:
      - 7890:7890
      - 7888:8080
    restart: always
    networks:
      - default

# Networks
networks:
  default:
    driver: bridge
    name: clash
EOF
)

# docker-compose
sudo cat <<EOF > $docker_data/$container/docker-compose.yml
$compose
EOF

cd $docker_data/$container
sudo docker-compose up -d

