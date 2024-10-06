#!/bin/bash

# 变量
docker_data="/vol1/1000/Docker"
container="clash"

sudo mkdir -p $docker_data/$container/svc-clash

# test
config=$(
# config.yaml
port: 7890
socks-port: 7891
allow-lan: false
mode: Rule
log-level: silent
external-controller: 0.0.0.0:9090
secret: "123456"
)

compose=$(
# docker-compose.yml
version: "3"

services:
  # Clash
  svc-clash:
    image: dreamacro/clash
    container_name: svc-clash
    volumes:
      - ./svc-clash/config.yaml:/root/.config/clash/config.yaml
    ports:
      - "7890:7890/tcp"
      - "7890:7890/udp"
      - "9090:9090"
    restart: always
    networks:
      - default
  # Clash Dashboard
  svc-clash-dashboard:
    image: centralx/clash-dashboard
    container_name: svc-clash-dashboard
    ports:
      - "12345:80"
    restart: always
    networks:
      - default

# Networks
networks:
  default:
    driver: bridge
    name: svc
)

# 配置文件
sudo cat <<EOF > $docker_data/$container/svc-clash/config.yaml
$config
EOF

# docker-compose
sudo cat <<EOF > $docker_data/$container/docker-compose.yml
$compose
EOF

cd $docker_data/$container
sudo docker-compose up -d

